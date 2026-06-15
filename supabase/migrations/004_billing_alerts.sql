-- Billing alert tracking for the billing-watchdog Edge Function.
--
-- The watchdog polls Supabase Management API for current-month spend and
-- writes a row here whenever a threshold is crossed. Also stores the
-- most recent snapshot so we can dedupe emails (one per threshold per day).

create table if not exists public.billing_alerts (
    id              bigint generated always as identity primary key,
    threshold_usd   numeric(10, 2) not null,
    current_usd     numeric(10, 2) not null,
    triggered_at    timestamptz    not null default now(),
    email_sent      boolean        not null default false,
    email_error     text,
    raw_response    jsonb
);

create index if not exists idx_billing_alerts_threshold_time
    on public.billing_alerts (threshold_usd, triggered_at desc);

-- A "service pause" KV: when set to true, ai-proxy returns 503
-- service_paused without spending any DeepSeek budget.
create table if not exists public.service_flags (
    key   text primary key,
    value text not null,
    set_at timestamptz not null default now()
);

insert into public.service_flags (key, value)
values ('ai_proxy_paused', 'false')
on conflict (key) do nothing;

-- RLS: deny all client access. service_role only.
alter table public.billing_alerts enable row level security;
alter table public.service_flags   enable row level security;

drop policy if exists "deny all on billing_alerts" on public.billing_alerts;
create policy "deny all on billing_alerts"
    on public.billing_alerts for all using (false) with check (false);

drop policy if exists "deny all on service_flags" on public.service_flags;
create policy "deny all on service_flags"
    on public.service_flags for all using (false) with check (false);
