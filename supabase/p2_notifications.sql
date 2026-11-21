-- ============================================================
-- EventKuy - Migrasi P2: Notifikasi (Scaffold, Tanpa Firebase)
-- Jalankan di Supabase Dashboard -> SQL Editor, setelah schema.sql.
-- Aman dijalankan berulang (idempotent).
--
-- Policy/RLS final untuk notifications dan device_tokens ada di
-- `security_hardening.sql`. Jalankan file itu TERAKHIR setelah file ini.
-- ============================================================

-- ------------------------------------------------------------
-- Tabel device_tokens (token FCM per perangkat per user)
-- ------------------------------------------------------------

create table if not exists public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  token text not null,
  platform text not null default 'unknown',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, token)
);

-- ------------------------------------------------------------
-- Tabel notifications (feed in-app per user)
-- ------------------------------------------------------------

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null default '',
  body text not null default '',
  event_id uuid references public.events (id) on delete set null,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists notifications_user_id_idx on public.notifications (user_id);
create index if not exists notifications_read_at_idx on public.notifications (read_at);

-- ------------------------------------------------------------
-- Row Level Security
-- ------------------------------------------------------------

alter table public.device_tokens enable row level security;
alter table public.notifications enable row level security;

-- device_tokens: user hanya bisa mengelola token miliknya
drop policy if exists "device_tokens_select_own" on public.device_tokens;
create policy "device_tokens_select_own" on public.device_tokens
  for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists "device_tokens_insert_own" on public.device_tokens;
create policy "device_tokens_insert_own" on public.device_tokens
  for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "device_tokens_update_own" on public.device_tokens;
create policy "device_tokens_update_own" on public.device_tokens
  for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "device_tokens_delete_own" on public.device_tokens;
create policy "device_tokens_delete_own" on public.device_tokens
  for delete to authenticated
  using (auth.uid() = user_id);

grant select on table public.device_tokens to authenticated;
grant insert on table public.device_tokens to authenticated;
grant update on table public.device_tokens to authenticated;
grant delete on table public.device_tokens to authenticated;

-- notifications: user hanya bisa membaca dan menandai miliknya
drop policy if exists "notifications_select_own" on public.notifications;
create policy "notifications_select_own" on public.notifications
  for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists "notifications_update_own" on public.notifications;
create policy "notifications_update_own" on public.notifications
  for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

grant select on table public.notifications to authenticated;
grant update on table public.notifications to authenticated;

-- ------------------------------------------------------------
-- Catatan: adapter FCM (token registration dari Firebase) ditunda
-- sampai kredensial Firebase tersedia. Tabel device_tokens siap
-- diisi oleh client saat push diaktifkan di masa depan.
-- ============================================================
