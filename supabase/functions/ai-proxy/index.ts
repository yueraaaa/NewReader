import { createClient } from "jsr:@supabase/supabase-js@2";

const DEEPSEEK_API_KEY = Deno.env.get("DEEPSEEK_API_KEY")!;
const DEEPSEEK_BASE_URL = Deno.env.get("DEEPSEEK_BASE_URL") || "https://api.deepseek.com/v1";
const DAILY_LIMIT = 50;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface AIRequest {
  provider: "deepseek" | "openai" | "anthropic";
  action: "summarize" | "translate";
  model: string;
  messages: Array<{ role: string; content: string }>;
  params?: Record<string, unknown>;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  // Auth: verify JWT from client
  const authHeader = req.headers.get("authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return new Response(JSON.stringify({ error: "unauthorized" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
  const jwt = authHeader.slice(7);

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const supabase = createClient(supabaseUrl, supabaseKey);

  const { data: { user }, error: authError } = await supabase.auth.getUser(jwt);
  if (authError || !user) {
    return new Response(JSON.stringify({ error: "unauthorized" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  // Rate limit: count today's calls for this user
  const today = new Date().toISOString().slice(0, 10);
  const { count, error: countError } = await supabase
    .from("ai_usage")
    .select("*", { count: "exact", head: true })
    .eq("user_id", user.id)
    .eq("date", today);

  if (countError || (count ?? 0) >= DAILY_LIMIT) {
    return new Response(JSON.stringify({ error: "daily_limit_reached" }), {
      status: 429,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  // Parse request body
  let body: AIRequest;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "invalid_body" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  if (!["summarize", "translate"].includes(body.action)) {
    return new Response(JSON.stringify({ error: "invalid_action" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  // Log usage
  await supabase.from("ai_usage").insert({
    user_id: user.id,
    date: today,
    action: body.action,
  });

  // Forward to DeepSeek API
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
    return new Response(JSON.stringify({ error: "ai_api_error", detail: errText }), {
      status: 502,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const dsData = await dsResp.json();
  return new Response(JSON.stringify(dsData), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
