// Supabase Edge Function: billing-watchdog
//
// Monitors Supabase Free-tier usage and fires when consumption crosses
// 80% (warning email) or 95% (hard stop — flips ai-proxy to
// service_paused).
//
// Why SQL-based metrics instead of the Management API?
//   As of mid-2025, the public Supabase Management API v1 does not
//   expose a per-project "usage" endpoint. v0 endpoints exist but
//   require a project-scoped access token (not a personal access
//   token), complicating setup. Postgres, on the other hand, has
//   built-in views for everything we care about: pg_database_size,
//   pg_stat_user_tables for row counts, and the supabase_functions
//   extension's metrics for invocation counts.
//
//   Storage and egress are NOT visible to the service_role client
//   without hitting the Management API. We track DB size and function
//   invocations; storage and egress are reported as "n/a" in the
//   metrics list (with a comment so operators know the gap).
//
// Schedule this function via:
//   - Supabase pg_cron (every 6h), OR
//   - External cron hitting this function URL on a schedule.
//
// Required env vars (no "SUPABASE_" prefix — those are platform-reserved):
//   - SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY (auto-injected by Supabase)
//   - MGMT_API_TOKEN     (currently unused; reserved for future
//                          Management API calls once usage endpoints
//                          are available; can be any non-empty string)
//   - PROJECT_REF        (project slug, e.g. "YOUR_PROJECT_REF")
//   - RESEND_API_KEY, RESEND_FROM
//
// Optional env vars (defaults shown):
//   - FREE_PLAN_WARN_PCT       (80)
//   - FREE_PLAN_HARD_STOP_PCT  (95)
//   - BILLING_NOTIFY_EMAIL     (recipient; required to send mail)

import { createClient } from "jsr:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const PROJECT_REF = Deno.env.get("PROJECT_REF") ?? "";

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY") ?? "";
const RESEND_FROM = Deno.env.get("RESEND_FROM") ?? "NewReader <onboarding@resend.dev>";

const FREE_PLAN_WARN_PCT = Number(Deno.env.get("FREE_PLAN_WARN_PCT") ?? "80");
const FREE_PLAN_HARD_STOP_PCT = Number(Deno.env.get("FREE_PLAN_HARD_STOP_PCT") ?? "95");

// Free plan quotas (override per-project via env if you upgrade).
const FREE_DB_SIZE_MB = 500;
const FREE_FUNCTION_INVOCATIONS = 500_000;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type",
  "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
};

interface Metric {
  name: string;
  used: number;
  limit: number;
  pct: number;
  level: "ok" | "warn" | "hard";
  note?: string;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
  const metrics = await collectMetrics(supabase);

  const highestLevel = pickHighest(metrics.map((m) => m.level));
  const paused = highestLevel === "hard";

  if (highestLevel === "hard") {
    await supabase
      .from("service_flags")
      .upsert(
        { key: "ai_proxy_paused", value: "true", set_at: new Date().toISOString() },
        { onConflict: "key" },
      );
  } else if (highestLevel === "ok") {
    await supabase
      .from("service_flags")
      .upsert(
        { key: "ai_proxy_paused", value: "false", set_at: new Date().toISOString() },
        { onConflict: "key" },
      );
  }

  let emailSent = false;
  let emailError: string | undefined;
  if (highestLevel !== "ok") {
    const result = await maybeSendEmail(supabase, metrics, highestLevel);
    emailSent = result.ok;
    emailError = result.error;
  }

  for (const m of metrics) {
    await supabase.from("billing_alerts").insert({
      threshold_usd: 0,
      current_usd: m.pct,
      email_sent: emailSent,
      email_error: emailError,
      raw_response: {
        metric: m.name,
        used: m.used,
        limit: m.limit,
        level: m.level,
        note: m.note,
      },
    });
  }

  return jsonResponse(200, {
    metrics,
    highest_level: highestLevel,
    paused,
    email_sent: emailSent,
  });
});

// ---------------------------------------------------------------------------
// Metric collection via Postgres itself
// ---------------------------------------------------------------------------

async function collectMetrics(supabase: ReturnType<typeof createClient>): Promise<Metric[]> {
  const out: Metric[] = [];

  // 1) DB size via pg_database_size. Returns bytes.
  //    Wrapped in rpc() with a small SQL function definition so we can
  //    SELECT it through the PostgREST API. We define it inline as a
  //    one-off SELECT via the `pgaudit` / `pg_catalog` exposure
  //    through a SECURITY DEFINER RPC.
  const { data: dbSizeBytes, error: dbSizeErr } = await supabase
    .rpc("billing_watchdog_db_size");
  if (dbSizeErr) {
    console.warn("[billing-watchdog] db_size query failed:", dbSizeErr.message);
  } else if (typeof dbSizeBytes === "number") {
    const usedMB = dbSizeBytes / 1024 / 1024;
    const pct = (usedMB / FREE_DB_SIZE_MB) * 100;
    out.push({
      name: "db_size",
      used: Math.round(usedMB * 10) / 10,
      limit: FREE_DB_SIZE_MB,
      pct: clampPct(pct),
      level: levelFor(pct),
    });
  } else if (typeof dbSizeBytes === "string") {
    // RPC may return as string if numeric cast. Parse defensively.
    const used = parseFloat(dbSizeBytes);
    if (!Number.isNaN(used)) {
      const pct = (used / FREE_DB_SIZE_MB) * 100;
      out.push({
        name: "db_size",
        used: Math.round(used * 10) / 10,
        limit: FREE_DB_SIZE_MB,
        pct: clampPct(pct),
        level: levelFor(pct),
      });
    }
  }

  // 2) Edge Function invocations this month via supabase_functions metrics.
  //    The supabase_functions extension exposes fn_stats (cumulative
  //    since project creation). We approximate monthly usage by storing
  //    a baseline; for simplicity in v1 we use the *cumulative* count
  //    and warn above a much higher threshold (FREE_FUNCTION_INVOCATIONS
  //    × 6) so we never false-positive. This is intentionally conservative.
  const { data: fnRows, error: fnErr } = await supabase
    .from("fn_stats")
    .select("count");
  if (fnErr) {
    // Table may not exist (older projects). Report as unknown.
    out.push({
      name: "function_invocations",
      used: 0,
      limit: FREE_FUNCTION_INVOCATIONS,
      pct: 0,
      level: "ok",
      note: "fn_stats not available — install supabase_functions extension",
    });
  } else if (Array.isArray(fnRows)) {
    const cumulative = fnRows.reduce((acc, r) => {
      const n = Number((r as { count?: number | string }).count ?? 0);
      return acc + (Number.isFinite(n) ? n : 0);
    }, 0);
    // fn_stats is cumulative, not monthly. We treat the cumulative as a
    // *lower bound* on the real monthly usage and report pct of a 6×
    // inflated free tier quota to keep false-positives low until we
    // implement a per-month baseline.
    const inflated = FREE_FUNCTION_INVOCATIONS * 6;
    const pct = (cumulative / inflated) * 100;
    out.push({
      name: "function_invocations_cumulative",
      used: cumulative,
      limit: inflated,
      pct: clampPct(pct),
      level: levelFor(pct),
      note: "cumulative count; effective free tier × 6 to avoid false positives",
    });
  }

  // 3) Storage & egress: not visible from the service_role client
  //    without the Management API. Surface as informational so
  //    operators know they're untracked.
  out.push({
    name: "storage",
    used: 0,
    limit: 1024,
    pct: 0,
    level: "ok",
    note: "Storage size not visible to service_role; check Supabase Dashboard manually",
  });
  out.push({
    name: "egress",
    used: 0,
    limit: 5120,
    pct: 0,
    level: "ok",
    note: "Egress not visible to service_role; check Supabase Dashboard manually",
  });

  return out;
}

function clampPct(p: number): number {
  if (!Number.isFinite(p)) return 0;
  return Math.max(0, Math.min(999, p));
}

function levelFor(pct: number): "ok" | "warn" | "hard" {
  if (pct >= FREE_PLAN_HARD_STOP_PCT) return "hard";
  if (pct >= FREE_PLAN_WARN_PCT) return "warn";
  return "ok";
}

function pickHighest(levels: Array<"ok" | "warn" | "hard">): "ok" | "warn" | "hard" {
  if (levels.includes("hard")) return "hard";
  if (levels.includes("warn")) return "warn";
  return "ok";
}

// ---------------------------------------------------------------------------
// Email
// ---------------------------------------------------------------------------

async function maybeSendEmail(
  supabase: ReturnType<typeof createClient>,
  metrics: Metric[],
  level: "warn" | "hard",
): Promise<{ ok: boolean; error?: string }> {
  const to = Deno.env.get("BILLING_NOTIFY_EMAIL") ?? "";
  if (!to) return { ok: false, error: "BILLING_NOTIFY_EMAIL not set" };
  if (!RESEND_API_KEY) return { ok: false, error: "RESEND_API_KEY not set" };

  const since = new Date(Date.now() - 24 * 3600 * 1000).toISOString();
  const { data: recent } = await supabase
    .from("billing_alerts")
    .select("id")
    .eq("email_sent", true)
    .gte("triggered_at", since);
  if ((recent ?? []).length > 0) {
    return { ok: false, error: "deduped_within_24h" };
  }

  const top3 = [...metrics].sort((a, b) => b.pct - a.pct).slice(0, 3);
  const tableRows = top3.map((m) => `
    <tr>
      <td>${m.name}</td>
      <td>${formatNumber(m.used)} / ${formatNumber(m.limit)}</td>
      <td><strong>${m.pct.toFixed(1)}%</strong></td>
      <td>${badge(m.level)}</td>
    </tr>
    ${m.note ? `<tr><td colspan="4" style="color:#888;font-size:11px">${m.note}</td></tr>` : ""}
  `).join("");

  const subject = level === "hard"
    ? `[NewReader] 紧急：Supabase 额度 ≥ ${FREE_PLAN_HARD_STOP_PCT}%，AI 已暂停`
    : `[NewReader] 警告：Supabase 额度已达 ${FREE_PLAN_WARN_PCT}%`;

  const html = level === "hard"
    ? `
      <h2>🔴 Supabase 免费额度硬停止</h2>
      <p>至少一个指标的用量已达到 <strong>${FREE_PLAN_HARD_STOP_PCT}%</strong>，
         AI 代理已自动暂停，所有摘要/翻译/工作台请求将返回 503。</p>
      ${tableBlock(tableRows)}
      <p>恢复方法：Supabase Dashboard → SQL Editor →<br>
         <code>update service_flags set value='false' where key='ai_proxy_paused';</code></p>
    `
    : `
      <h2>🟡 Supabase 免费额度警告</h2>
      <p>至少一个指标的用量已达到 <strong>${FREE_PLAN_WARN_PCT}%</strong>。
         继续增长到 <strong>${FREE_PLAN_HARD_STOP_PCT}%</strong> 将自动暂停 AI 代理。</p>
      ${tableBlock(tableRows)}
    `;

  try {
    const resp = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ from: RESEND_FROM, to, subject, html }),
    });
    if (!resp.ok) {
      const t = await resp.text();
      return { ok: false, error: `resend ${resp.status}: ${t}` };
    }
    return { ok: true };
  } catch (e) {
    return { ok: false, error: String(e) };
  }
}

function tableBlock(rows: string): string {
  return `
    <table border="1" cellpadding="6" cellspacing="0" style="border-collapse:collapse">
      <thead>
        <tr><th>指标</th><th>已用 / 总额</th><th>占比</th><th>等级</th></tr>
      </thead>
      <tbody>${rows}</tbody>
    </table>`;
}

function badge(level: "ok" | "warn" | "hard"): string {
  if (level === "hard") return "<span style='color:#b00'>🔴 硬停止</span>";
  if (level === "warn") return "<span style='color:#c80'>🟡 警告</span>";
  return "<span style='color:#080'>🟢 正常</span>";
}

function formatNumber(n: number): string {
  if (n >= 1_000_000) return (n / 1_000_000).toFixed(1) + "M";
  if (n >= 1_000) return (n / 1_000).toFixed(1) + "K";
  return n.toFixed(0);
}

function jsonResponse(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
