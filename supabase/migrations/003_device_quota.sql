-- Device-level rate limiting for AI proxy access.
--
-- Defense in depth: this table limits unauthenticated abuse BEFORE the
-- per-user `ai_usage` counter runs. A single physical device (identified by
-- a UUID generated in the client and stored in the Keychain) can call the
-- ai-proxy function at most N times per UTC day, even if it spins up many
-- throwaway Supabase auth accounts.
--
-- Requires: Supabase service_role bypasses RLS, so this table is locked
-- down with a deny-by-default policy and only writable by service_role.
-- The Edge Function uses the service_role client to UPSERT.

create table if not exists public.device_quota (
    device_id   text        primary key,
    date        date        not null default current_date,
    count       int         not null default 0,
    last_seen   timestamptz not null default now()
);

create unique index if not exists idx_device_quota_device_date
    on public.device_quota (device_id, date);

-- RLS: deny all client access. Only the service_role (used inside the
-- Edge Function) can read/write. Anon/authenticated clients cannot.
alter table public.device_quota enable row level security;

drop policy if exists "deny all on device_quota" on public.device_quota;
create policy "deny all on device_quota"
    on public.device_quota
    for all
    using (false)
    with check (false);

comment on table public.device_quota is
    'Per-device daily counter for ai-proxy abuse mitigation. Read/written only by service_role from the Edge Function.';

-- Atomic increment-and-return. Two concurrent requests for the same
-- (device_id, date) row will both increment correctly under the unique
-- index. The Edge Function uses this RPC for race-free quota tracking.
create or replace function public.device_quota_increment(
    p_device_id text,
    p_date date
)
returns table (count int)
language plpgsql
security definer
set search_path = public
as $$
begin
    return query
    insert into public.device_quota (device_id, date, count, last_seen)
    values (p_device_id, p_date, 1, now())
    on conflict (device_id, date)
    do update set count = public.device_quota.count + 1,
                  last_seen = now()
    returning public.device_quota.count;
end;
$$;

revoke all on function public.device_quota_increment(text, date) from public;
grant execute on function public.device_quota_increment(text, date) to service_role;

-- Read the current database size in bytes. Used by the billing-watchdog
-- Edge Function to monitor Free-tier DB quota (500 MB). SECURITY DEFINER
-- + restricted to service_role so anon clients can't probe DB size.
create or replace function public.billing_watchdog_db_size()
returns bigint
language sql
security definer
set search_path = public
as $
  select pg_database_size(current_database());
$;

revoke all on function public.billing_watchdog_db_size() from public;
grant execute on function public.billing_watchdog_db_size() to service_role;

comment on function public.billing_watchdog_db_size() is
    'Returns current database size in bytes. Called by billing-watchdog Edge Function.';
