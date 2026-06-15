// Supabase Edge Function: ai-proxy
//
// Forwards authenticated requests to the DeepSeek chat completion API,
// gated by three layers of defense:
//
//   1. JWT verification via Supabase auth (existing).
//   2. Cloudflare Turnstile captcha verification (header X-Captcha-Token).
//      Prevents a single human from mass-creating throwaway accounts.
//   3. Per-device daily counter (`device_quota` table). One physical
//      device, identified by a Keychain-stored UUID, can call the proxy
//      at most DEVICE_DAILY_LIMIT times per UTC day — even if the user
//      keeps signing up for new accounts.
//
// On hard-stop (service_flags.ai_proxy_paused = 'true'), the function
// short-circuits with 503 service_paused. This is flipped by
// billing-watchdog when monthly spend exceeds BILLING_HARD_STOP_AT_USD.
//
// Environment variables:
//   - DEEPSEEK_API_KEY          (required)
//   - DEEPSEEK_BASE_URL         (optional, default https://api.deepseek.com/v1)
//   - CLOUDFLARE_TURNSTILE_SECRET (required in prod; dev may set to "dev"
//     to bypass verification while logging a warning)
//   - DAILY_LIMIT               (optional, default 50 — per-user quota)

import { createClient } from "jsr:@supabase/supabase-js@2";

const DEEPSEEK_API_KEY = Deno.env.get("DEEPSEEK_API_KEY")!;
const DEEPSEEK_BASE_URL =
  Deno.env.get("DEEPSEEK_BASE_URL") || "https://api.deepseek.com/v1";
const DAILY_LIMIT = Number(Deno.env.get("DAILY_LIMIT") || "50");
const DEVICE_DAILY_LIMIT = Number(Deno.env.get("DEVICE_DAILY_LIMIT") || "5");

const TURNSTILE_SECRET = Deno.env.get("CLOUDFLARE_TURNSTILE_SECRET") ?? "";
const TURNSTILE_VERIFY_URL =
  "https://challenges.cloudflare.com/turnstile/v0/siteverify";
const TURNSTILE_BYPASS = TURNSTILE_SECRET === "" || TURNSTILE_SECRET === "dev";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type, x-device-id, x-captcha-token",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface AIRequest {
  provider: "deepseek" | "openai" | "anthropic";
  action: "summarize" | "translate";
  model: string;
  messages: Array<{ role: string; content: string }>;
  params?: Record<string, unknown>;
}

interface TurnstileVerifyResponse {
  success: boolean;
  challenge_ts?: string;
  hostname?: string;
  "error-codes"?: string[];
  action?: string;
  cdata?: string;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError(405, "method_not_allowed");
  }

  // Resolve Supabase service client (used for DB checks; bypasses RLS).
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const supabase = createClient(supabaseUrl, supabaseServiceKey);

  // Check service-wide pause flag. The watchdog flips this when spend
  // exceeds the hard-stop threshold.
  const { data: flagRow } = await supabase
    .from("service_flags")
    .select("value")
    .eq("key", "ai_proxy_paused")
    .single();
  if (flagRow?.value === "true") {
    return jsonError(503, "service_paused");
  }

  // ---------- Auth ----------
  const authHeader = req.headers.get("authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return jsonError(401, "unauthorized");
  }
  const jwt = authHeader.slice(7);
  const { data: { user }, error: authError } = await supabase.auth.getUser(jwt);
  if (authError || !user) {
    return jsonError(401, "unauthorized");
  }

  // ---------- Device id (required) ----------
  const deviceId = req.headers.get("x-device-id")?.trim();
  if (!deviceId) {
    return jsonError(400, "device_id_required");
  }
  if (deviceId.length > 128) {
    // Defensive: cap incoming header length to keep the unique index
    // and logs reasonable.
    return jsonError(400, "device_id_too_long");
  }

  // ---------- Captcha ----------
  const captchaToken = req.headers.get("x-captcha-token")?.trim() ?? "";
  if (TURNSTILE_BYPASS) {
    console.warn(
      "[ai-proxy] CLOUDFLARE_TURNSTILE_SECRET not set — bypassing captcha. Do NOT run this in production.",
    );
  } else {
    if (captchaToken.isEmpty) {
      return jsonError(400, "captcha_required");
    }
    const ok = await verifyTurnstile(captchaToken, req);
    if (!ok) {
      return jsonError(403, "captcha_invalid");
    }
  }

  // ---------- Per-device daily quota ----------
  // UPSERT today + increment. If the resulting count exceeds the limit,
  // reject. Note: the increment happens regardless of downstream success
  // — this is intentional. The cost of an extra call is bounded by
  // DEVICE_DAILY_LIMIT, and the alternative (rollback on failure)
  // requires a transaction that's not worth the complexity.
  const today = new Date().toISOString().slice(0, 10);
  const { data: quotaRow, error: quotaErr } = await supabase
    .rpc("device_quota_increment", {
      p_device_id: deviceId,
      p_date: today,
    })
    .single();

  // Fallback for environments where the RPC hasn't been created yet
  // (manual migration drift). The SELECT-then-UPDATE form is racy under
  // load; prefer the RPC.
  let count = (quotaRow as { count: number } | null)?.count;
  if (quotaErr || count === undefined) {
    const { data: row, error: upsertErr } = await supabase
      .from("device_quota")
      .upsert(
        { device_id: deviceId, date: today, count: 1, last_seen: new Date().toISOString() },
        { onConflict: "device_id,date", ignoreDuplicates: false },
      )
      .select("count")
      .single();
    if (upsertErr) {
      console.error("[ai-proxy] device_quota upsert failed:", upsertErr);
      // Fail open: allow the request if we can't enforce the quota.
    } else {
      count = (row as { count: number } | null)?.count ?? 1;
    }
  }
  if ((count ?? 0) > DEVICE_DAILY_LIMIT) {
    return jsonError(429, "device_quota_exceeded");
  }

  // ---------- Per-user daily quota (existing) ----------
  const { count: userCount, error: countError } = await supabase
    .from("ai_usage")
    .select("*", { count: "exact", head: true })
    .eq("user_id", user.id)
    .eq("date", today);

  if (countError || (userCount ?? 0) >= DAILY_LIMIT) {
    return jsonError(429, "daily_limit_reached");
  }

  // ---------- Parse body ----------
  let body: AIRequest;
  try {
    body = await req.json();
  } catch {
    return jsonError(400, "invalid_body");
  }
  if (!["summarize", "translate"].includes(body.action)) {
    return jsonError(400, "invalid_action");
  }

  // ---------- Log usage (per-user) ----------
  await supabase.from("ai_usage").insert({
    user_id: user.id,
    date: today,
    action: body.action,
  });

  // ---------- Forward to DeepSeek ----------
  const deepseekPayload = {
    model: body.model || "deepseek-chat",
    messages: body.messages,
    temperature: body.params?.temperature ?? 0.3,
    max_tokens: body.params?.max_tokens ?? 1024,
    ...(body.params?.top_p !== undefined ? { top_p: body.params.top_p } : {}),
  };

  const dsResp = await fetch(`${DEEPSEEK_BASE_URL}/chat/completions`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${DEEPSEEK_API_KEY}`,
    },
    body: JSON.stringify(deepseekPayload),
  });

  if (!dsResp.ok) {
    const errText = await dsResp.text();
    return new Response(
      JSON.stringify({ error: "ai_api_error", detail: errText }),
      { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  const dsData = await dsResp.json();
  return new Response(JSON.stringify(dsData), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function jsonError(status: number, error: string): Response {
  return new Response(
    JSON.stringify({ error }),
    {
      status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    },
  );
}

async function verifyTurnstile(token: string, req: Request): Promise<boolean> {
  // Cloudflare expects application/x-www-form-urlencoded.
  const body = new URLSearchParams();
  body.set("secret", TURNSTILE_SECRET);
  body.set("response", token);
  // Best-effort: forward the caller's IP so Cloudflare can apply
  // its own heuristics. Deno Deploy exposes the original client IP
  // via the standard headers.
  const ip = req.headers.get("cf-connecting-ip") ??
    req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "";
  if (ip) body.set("remoteip", ip);

  try {
    const resp = await fetch(TURNSTILE_VERIFY_URL, {
      method: "POST",
      body,
    });
    if (!resp.ok) {
      console.error("[ai-proxy] turnstile HTTP", resp.status);
      return false;
    }
    const data = (await resp.json()) as TurnstileVerifyResponse;
    if (!data.success) {
      console.warn("[ai-proxy] turnstile rejected:", data["error-codes"]);
      return false;
    }
    return true;
  } catch (e) {
    console.error("[ai-proxy] turnstile fetch failed:", e);
    // Fail closed: if Cloudflare is unreachable, don't accept the token.
    return false;
  }
}
