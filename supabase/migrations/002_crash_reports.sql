-- Crash report storage bucket + encrypted email notification
-- Run: paste into Supabase SQL Editor
--
-- SECURITY: Secrets (email, API key) are stored in Supabase Vault (encrypted at rest).
-- This file contains NO real email addresses or API keys — safe to commit to GitHub.

-- ============================================================
-- 1. Extensions
-- ============================================================
create extension if not exists pg_net;
create extension if not exists supabase_vault;

-- ============================================================
-- 2. Storage bucket (private, 5 MB per file)
-- ============================================================
insert into storage.buckets (id, name, public, file_size_limit)
values ('crash-reports', 'crash-reports', false, 5242880)
on conflict (id) do nothing;

drop policy if exists "Allow anon crash uploads" on storage.objects;
create policy "Allow anon crash uploads"
on storage.objects
for insert
to anon
with check (bucket_id = 'crash-reports');

drop policy if exists "Allow authenticated read" on storage.objects;
create policy "Allow authenticated read"
on storage.objects
for select
to authenticated
using (bucket_id = 'crash-reports');

-- ============================================================
-- 3. Trigger function — reads secrets from Vault at runtime
--    No plaintext email or API key anywhere in this file.
-- ============================================================
create or replace function notify_crash_report()
returns trigger
language plpgsql
security definer
as $$
declare
  notify_email text;
  resend_key   text;
  email_body   text;
  file_name    text;
begin
  if new.bucket_id = 'crash-reports' then

    -- Decrypt secrets from Vault (only available to privileged roles)
    select decrypted_secret into notify_email
      from vault.decrypted_secrets where name = 'crash_notify_email';
    select decrypted_secret into resend_key
      from vault.decrypted_secrets where name = 'crash_resend_key';

    file_name := split_part(new.name, '/', -1);

    email_body := format(
      '<h2>🔴 NewReader 崩溃报告</h2>'
      '<p><strong>文件:</strong> %s</p>'
      '<p><strong>存储路径:</strong> %s</p>'
      '<p><strong>上传时间:</strong> %s</p>'
      '<hr>'
      '<p>前往 <a href="https://supabase.com/dashboard/project/YOUR_PROJECT_REF/storage/buckets/crash-reports">Supabase Storage</a> 查看详情。</p>',
      file_name,
      new.name,
      new.created_at
    );

    perform net.http_post(
      url := 'https://api.resend.com/emails',
      headers := jsonb_build_object(
        'Content-Type',  'application/json',
        'Authorization', 'Bearer ' || resend_key
      ),
      body := jsonb_build_object(
        'from',    'NewReader <onboarding@resend.dev>',
        'to',      notify_email,
        'subject', format('[NewReader] 崩溃报告 — %s', file_name),
        'html',    email_body
      )
    );
  end if;
  return new;
end;
$$;

drop trigger if exists on_crash_report_uploaded on storage.objects;
create trigger on_crash_report_uploaded
  after insert on storage.objects
  for each row
  execute function notify_crash_report();
