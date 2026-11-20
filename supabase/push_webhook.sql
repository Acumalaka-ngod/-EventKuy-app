-- ============================================================
-- EventKuy - Webhook notifikasi -> Edge Function send-push
-- Jalankan di Supabase SQL Editor setelah p2_notifications.sql.
--
-- Prasyarat:
-- 1. Edge Function `send-push` sudah di-deploy.
-- 2. Secret FIREBASE_SERVICE_ACCOUNT sudah diatur di Dashboard.
-- 3. Dua secret berikut dibuat lewat SQLEditor (sekali saja):
--      select vault.create_secret(
--        'eventkuy_push_function_url',
--        'https://<project-ref>.supabase.co/functions/v1/send-push'
--      );
--      select vault.create_secret(
--        'eventkuy_service_role_key',
--        '<SUPABASE_SERVICE_ROLE_KEY>'
--      );
--    Jangan commit nilai service role key ke repository.
-- ============================================================

create extension if not exists pg_net with schema extensions;

create or replace function public.enqueue_push_on_notification()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_url text;
  v_key text;
begin
  select decrypted_secret into v_url
  from vault.decrypted_secrets
  where name = 'eventkuy_push_function_url';

  select decrypted_secret into v_key
  from vault.decrypted_secrets
  where name = 'eventkuy_service_role_key';

  -- Tanpa konfigurasi, trigger tidak melakukan apa-apa (aman untuk dev).
  if v_url is null or v_key is null then
    return new;
  end if;

  perform extensions.net.http_post(
    url := v_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_key
    ),
    body := jsonb_build_object(
      'user_id', new.user_id::text,
      'title', new.title,
      'body', new.body,
      'event_id', new.event_id::text,
      'notification_id', new.id::text
    )
  );

  return new;
end;
$$;

revoke all on function public.enqueue_push_on_notification() from public, anon, authenticated;

drop trigger if exists notifications_send_push on public.notifications;
create trigger notifications_send_push
  after insert on public.notifications
  for each row execute function public.enqueue_push_on_notification();
