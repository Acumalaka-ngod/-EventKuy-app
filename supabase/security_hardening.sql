-- ============================================================
-- EventKuy - Hardening keamanan & konsistensi alur bisnis
-- ============================================================
-- Jalankan di Supabase Dashboard -> SQL Editor SETELAH semua migrasi
-- berikut (urutan bebas selama file ini terakhir):
--
--   schema.sql
--   p2_event_content.sql
--   p2_notifications.sql
--   p2_checkout_buyer.sql
--   qty_voucher_stock.sql
--   notification_generation.sql
--   push_webhook.sql (opsional)
--   storage.sql / avatars.sql
--   seed.sql
--
-- File ini idempotent dan boleh dijalankan berulang. Isinya:
--   1. Mode pembayaran eksplisit (simulation/live) + konfirmasi webhook.
--   2. RLS organizers berbasis owner, bukan "semua user boleh ubah".
--   3. Grant kolom events (rating/organizer_profile_id tidak bisa diubah).
--   4. Storage event-images: batas ukuran/MIME + kepemilikan folder.
--   5. Penghapusan akun yang tidak menghapus riwayat pembeli.
--   6. device_tokens unik per token + RPC klaim token lintas akun.
--   7. Voucher single-use global yang konsisten dengan UI.
--   8. Audit check-in (checked_in_at/checked_in_by) + validasi tanggal.
--   9. Pencegahan event dengan tiket terjual dihapus (cascade ke pembeli).
--
-- CATATAN PENTING:
-- - Mode default adalah `simulation` agar demo tetap berjalan. Pada mode
--   ini tiket langsung `paid` TANPA uang sungguhan. Ini disengaja dan
--   ditampilkan di aplikasi. Jangan mengaktifkan `live` sebelum gateway
--   pembayaran + webhook signature benar-benar siap.
-- - Untuk mengaktifkan mode nyata:
--     update public.app_settings set value = 'live', updated_at = now()
--     where key = 'payment_mode';
--   Setelah itu checkout hanya membuat transaksi `pending`; tiket menjadi
--   `paid` hanya lewat RPC `confirm_payment` yang dipanggil server pembayaran.
-- ============================================================

-- ------------------------------------------------------------
-- 0. Tabel/pengaturan dasar yang dipakai hardening
-- ------------------------------------------------------------

create table if not exists public.app_settings (
  key text primary key,
  value text not null,
  updated_at timestamptz not null default now()
);

alter table public.app_settings enable row level security;
revoke all on table public.app_settings from anon, authenticated;

insert into public.app_settings (key, value)
values ('payment_mode', 'simulation')
on conflict (key) do nothing;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'app_settings_payment_mode_check'
      and conrelid = 'public.app_settings'::regclass
  ) then
    alter table public.app_settings
      add constraint app_settings_payment_mode_check
      check (key <> 'payment_mode' or value in ('simulation', 'live'));
  end if;
end $$;

-- Pastikan kolom/tabel dari migrasi P2 tersedia walau file ini dijalankan
-- langsung setelah schema.sql.
create table if not exists public.organizers (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references auth.users (id) on delete set null,
  name text not null default '',
  bio text not null default '',
  avatar_url text,
  city text not null default '',
  verified boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.events
  add column if not exists organizer_profile_id uuid
    references public.organizers (id) on delete set null;
alter table public.events
  add column if not exists rating numeric(2, 1) not null default 0;
alter table public.events
  add column if not exists rating_count integer not null default 0;

alter table public.transactions
  add column if not exists buyer_name text not null default '';
alter table public.transactions
  add column if not exists buyer_email text not null default '';
alter table public.transactions
  add column if not exists buyer_phone text not null default '';

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null default '',
  body text not null default '',
  event_id uuid references public.events (id) on delete set null,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  token text not null,
  platform text not null default 'unknown',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 1. Helper admin + proteksi kolom sensitif
-- ------------------------------------------------------------

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;

-- ------------------------------------------------------------
-- 2. Constraint nilai bisnis
-- ------------------------------------------------------------

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'events_price_nonnegative'
      and conrelid = 'public.events'::regclass
  ) then
    alter table public.events
      add constraint events_price_nonnegative check (price >= 0) not valid;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'events_quota_nonnegative'
      and conrelid = 'public.events'::regclass
  ) then
    alter table public.events
      add constraint events_quota_nonnegative check (quota >= 0) not valid;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'events_rating_range'
      and conrelid = 'public.events'::regclass
  ) then
    alter table public.events
      add constraint events_rating_range check (rating >= 0 and rating <= 5) not valid;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'events_rating_count_nonnegative'
      and conrelid = 'public.events'::regclass
  ) then
    alter table public.events
      add constraint events_rating_count_nonnegative
      check (rating_count >= 0) not valid;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'vouchers_discount_nonnegative'
      and conrelid = 'public.vouchers'::regclass
  ) then
    alter table public.vouchers
      add constraint vouchers_discount_nonnegative check (discount >= 0) not valid;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'vouchers_quota_nonnegative'
      and conrelid = 'public.vouchers'::regclass
  ) then
    alter table public.vouchers
      add constraint vouchers_quota_nonnegative check (quota >= 0) not valid;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'vouchers_quota_single_use'
      and conrelid = 'public.vouchers'::regclass
  ) then
    alter table public.vouchers
      add constraint vouchers_quota_single_use check (quota <= 1) not valid;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'transactions_money_nonnegative'
      and conrelid = 'public.transactions'::regclass
  ) then
    alter table public.transactions
      add constraint transactions_money_nonnegative
      check (
        subtotal >= 0 and admin_fee >= 0 and discount >= 0 and total >= 0
      ) not valid;
  end if;
end $$;

-- ------------------------------------------------------------
-- 3. RLS organizers: hanya owner (atau admin/service) yang menulis
-- ------------------------------------------------------------

alter table public.organizers enable row level security;

drop policy if exists "organizers_insert_service" on public.organizers;
drop policy if exists "organizers_update_service" on public.organizers;
drop policy if exists "organizers_insert_own" on public.organizers;
drop policy if exists "organizers_update_own" on public.organizers;
drop policy if exists "organizers_select_authenticated" on public.organizers;

create policy "organizers_select_authenticated" on public.organizers
  for select to authenticated
  using (true);

create policy "organizers_insert_own" on public.organizers
  for insert to authenticated
  with check (
    owner_id = auth.uid()
    and public.is_organizer()
  );

create policy "organizers_update_own" on public.organizers
  for update to authenticated
  using (owner_id = auth.uid() and public.is_organizer())
  with check (owner_id = auth.uid() and public.is_organizer());

revoke all on table public.organizers from anon, authenticated;
grant select on table public.organizers to authenticated;
grant insert (owner_id, name, bio, avatar_url, city)
  on table public.organizers to authenticated;
grant update (name, bio, avatar_url, city)
  on table public.organizers to authenticated;

create or replace function public.guard_organizer_write()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  -- Operasi sistem (mis. delete_account) boleh melewati guard.
  if current_setting('eventkuy.system_write', true) = 'on' then
    return new;
  end if;

  if auth.uid() is not null and not public.is_admin() then
    if tg_op = 'INSERT' then
      if new.owner_id is distinct from auth.uid() then
        raise exception 'owner_id organizer harus sama dengan akun yang login.';
      end if;
      if new.verified then
        raise exception 'Status verified organizer hanya dapat diubah admin.';
      end if;
    elsif tg_op = 'UPDATE' then
      if new.owner_id is distinct from old.owner_id
         or new.verified is distinct from old.verified then
        raise exception 'owner_id dan verified organizer hanya dapat diubah admin.';
      end if;
    end if;
  end if;

  return new;
end;
$$;

revoke all on function public.guard_organizer_write() from public;
drop trigger if exists organizers_guard_write on public.organizers;
create trigger organizers_guard_write
  before insert or update on public.organizers
  for each row execute function public.guard_organizer_write();

-- ------------------------------------------------------------
-- 4. Grant kolom events + guard rating/organizer_profile_id/harga
-- ------------------------------------------------------------

revoke insert, update, delete on table public.events from anon, authenticated;
grant select on table public.events to authenticated;
grant insert (
  organizer_id, organizer_profile_id, title, description, date, location,
  price, quota, image_url, image_urls, category, tags, time_range
) on table public.events to authenticated;
grant update (
  title, description, date, location, price, quota,
  image_url, image_urls, category, tags, time_range
) on table public.events to authenticated;

create or replace function public.guard_event_write()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_sold integer := 0;
begin
  -- Operasi sistem (mis. delete_account) boleh melewati guard.
  if current_setting('eventkuy.system_write', true) = 'on' then
    return new;
  end if;

  if auth.uid() is not null and not public.is_admin() then
    if tg_op = 'INSERT' then
      if new.organizer_id is distinct from auth.uid() then
        raise exception 'organizer_id event harus sama dengan akun yang login.';
      end if;
      if new.organizer_profile_id is not null and not exists (
        select 1 from public.organizers
        where id = new.organizer_profile_id
          and owner_id = auth.uid()
      ) then
        raise exception 'Profil organizer tidak valid untuk akun ini.';
      end if;
    else
      if new.id is distinct from old.id
         or new.organizer_id is distinct from old.organizer_id
         or new.organizer_profile_id is distinct from old.organizer_profile_id
         or new.rating is distinct from old.rating
         or new.rating_count is distinct from old.rating_count
         or new.created_at is distinct from old.created_at then
        raise exception 'Kolom identitas, organizer, dan rating hanya dapat diubah admin.';
      end if;
    end if;
  end if;

  if tg_op = 'UPDATE' then
    select count(*) into v_sold
    from public.tickets
    where event_id = old.id and status in ('paid', 'checked_in');

    if new.price is distinct from old.price and v_sold > 0 then
      raise exception 'Harga tidak dapat diubah setelah ada tiket terjual.';
    end if;

    if new.quota > 0 and new.quota < v_sold then
      raise exception 'Kuota tidak boleh kurang dari % tiket yang sudah terjual.', v_sold;
    end if;
  end if;

  return new;
end;
$$;

revoke all on function public.guard_event_write() from public;
drop trigger if exists events_guard_write on public.events;
create trigger events_guard_write
  before insert or update on public.events
  for each row execute function public.guard_event_write();

-- Event dengan tiket tidak boleh dihapus; mencegah cascade menghapus
-- tiket/transaksi pembeli.
create or replace function public.prevent_event_delete_with_tickets()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if current_setting('eventkuy.system_write', true) = 'on' then
    return old;
  end if;

  if exists (
    select 1 from public.tickets where event_id = old.id
  ) then
    raise exception 'Event yang sudah memiliki tiket tidak dapat dihapus.';
  end if;

  return old;
end;
$$;

revoke all on function public.prevent_event_delete_with_tickets() from public;
drop trigger if exists events_prevent_delete_with_tickets on public.events;
create trigger events_prevent_delete_with_tickets
  before delete on public.events
  for each row execute function public.prevent_event_delete_with_tickets();

-- ------------------------------------------------------------
-- 5. Stok tiket: tiket pending (mode live) ikut mereservasi stok 30 menit
-- ------------------------------------------------------------

create or replace view public.event_stock as
select
  e.id as event_id,
  e.quota,
  coalesce(
    count(t.id) filter (
      where t.status in ('paid', 'checked_in')
         or (
           t.status = 'pending'
           and t.created_at > now() - interval '30 minutes'
         )
    ),
    0
  )::int as sold
from public.events e
left join public.tickets t on t.event_id = e.id
group by e.id, e.quota;

grant select on public.event_stock to authenticated;

-- ------------------------------------------------------------
-- 6. Tiket & transaksi: audit check-in + histori pembeli tetap ada
--    saat akun dihapus (user_id menjadi NULL, bukan cascade).
-- ------------------------------------------------------------

alter table public.tickets
  add column if not exists checked_in_at timestamptz;
alter table public.tickets
  add column if not exists checked_in_by uuid
    references auth.users (id) on delete set null;

alter table public.tickets alter column user_id drop not null;
alter table public.tickets drop constraint if exists tickets_user_id_fkey;
alter table public.tickets
  add constraint tickets_user_id_fkey
  foreign key (user_id) references auth.users (id) on delete set null;

alter table public.transactions alter column user_id drop not null;
alter table public.transactions drop constraint if exists transactions_user_id_fkey;
alter table public.transactions
  add constraint transactions_user_id_fkey
  foreign key (user_id) references auth.users (id) on delete set null;

alter table public.transactions
  add column if not exists checkout_group_id uuid;
update public.transactions
set checkout_group_id = gen_random_uuid()
where checkout_group_id is null;
alter table public.transactions
  alter column checkout_group_id set default gen_random_uuid();
alter table public.transactions
  alter column checkout_group_id set not null;

alter table public.transactions
  add column if not exists paid_at timestamptz;
alter table public.transactions
  add column if not exists payment_reference text;

create index if not exists tickets_status_idx on public.tickets (status);
create index if not exists transactions_checkout_group_id_idx
  on public.transactions (checkout_group_id);

-- ------------------------------------------------------------
-- 7. device_tokens: satu token hanya boleh dimiliki satu akun
-- ------------------------------------------------------------

-- Buang duplikat lama; pertahankan baris yang paling baru diperbarui.
delete from public.device_tokens a
using public.device_tokens b
where a.token = b.token
  and (a.updated_at, a.id) < (b.updated_at, b.id);

do $$
declare
  r record;
begin
  for r in
    select c.conname
    from pg_constraint c
    where c.conrelid = 'public.device_tokens'::regclass
      and c.contype = 'u'
      and exists (
        select 1
        from unnest(c.conkey) as k(attnum)
        join pg_attribute a
          on a.attrelid = c.conrelid and a.attnum = k.attnum
        where a.attname = 'token'
      )
  loop
    execute format(
      'alter table public.device_tokens drop constraint %I',
      r.conname
    );
  end loop;
end $$;

create unique index if not exists device_tokens_token_key
  on public.device_tokens (token);

revoke insert, update, delete on table public.device_tokens
  from anon, authenticated;
grant select on table public.device_tokens to authenticated;

create or replace function public.claim_device_token(
  p_token text,
  p_platform text default 'unknown'
)
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_uid uuid := auth.uid();
  v_token text := trim(coalesce(p_token, ''));
  v_platform text := left(
    coalesce(nullif(trim(p_platform), ''), 'unknown'),
    50
  );
begin
  if v_uid is null then
    raise exception 'Harus login untuk menyimpan token perangkat.';
  end if;
  if length(v_token) < 10 or length(v_token) > 4096 then
    raise exception 'Token perangkat tidak valid.';
  end if;

  -- Klaim token dari akun lama di perangkat yang sama.
  delete from public.device_tokens
  where token = v_token and user_id <> v_uid;

  insert into public.device_tokens (user_id, token, platform, updated_at)
  values (v_uid, v_token, v_platform, now())
  on conflict (token) do update
    set user_id = excluded.user_id,
        platform = excluded.platform,
        updated_at = now();
end;
$$;

create or replace function public.release_device_token(p_token text)
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'Harus login untuk menghapus token perangkat.';
  end if;

  delete from public.device_tokens
  where token = trim(coalesce(p_token, '')) and user_id = v_uid;
end;
$$;

revoke all on function public.claim_device_token(text, text)
  from public, anon, authenticated;
revoke all on function public.release_device_token(text)
  from public, anon, authenticated;
grant execute on function public.claim_device_token(text, text) to authenticated;
grant execute on function public.release_device_token(text) to authenticated;

alter table public.device_tokens enable row level security;
drop policy if exists "device_tokens_select_own" on public.device_tokens;
create policy "device_tokens_select_own" on public.device_tokens
  for select to authenticated
  using (auth.uid() = user_id);

alter table public.notifications enable row level security;
drop policy if exists "notifications_select_own" on public.notifications;
create policy "notifications_select_own" on public.notifications
  for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists "notifications_update_own" on public.notifications;
create policy "notifications_update_own" on public.notifications
  for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

revoke all on table public.notifications from anon, authenticated;
grant select on table public.notifications to authenticated;
grant update (read_at) on table public.notifications to authenticated;

-- ------------------------------------------------------------
-- 8. Voucher: single-use global (sesuai teks Syarat & Ketentuan)
-- ------------------------------------------------------------

create table if not exists public.voucher_redemptions (
  code text primary key references public.vouchers (code) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  ticket_id uuid references public.tickets (id) on delete set null,
  transaction_id uuid references public.transactions (id) on delete cascade,
  status text not null default 'redeemed',
  reserved_until timestamptz,
  created_at timestamptz not null default now()
);

alter table public.voucher_redemptions
  add column if not exists transaction_id uuid
    references public.transactions (id) on delete cascade;
alter table public.voucher_redemptions
  add column if not exists status text not null default 'redeemed';
alter table public.voucher_redemptions
  add column if not exists reserved_until timestamptz;

update public.voucher_redemptions
set status = 'redeemed'
where status is null;

alter table public.voucher_redemptions
  alter column status set default 'redeemed';
alter table public.voucher_redemptions
  alter column status set not null;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'voucher_redemptions_status_check'
      and conrelid = 'public.voucher_redemptions'::regclass
  ) then
    alter table public.voucher_redemptions
      add constraint voucher_redemptions_status_check
      check (status in ('reserved', 'redeemed'));
  end if;
end $$;

-- Satu kode = satu baris redemption. Simpan yang paling awal bila ada
-- duplikat dari skema lama (code, user_id).
delete from public.voucher_redemptions a
using public.voucher_redemptions b
where a.code = b.code
  and (a.created_at, a.user_id) > (b.created_at, b.user_id);

do $$
declare
  v_conname text;
  v_cols text[];
begin
  select c.conname, array_agg(a.attname order by a.attname)
  into v_conname, v_cols
  from pg_constraint c
  join unnest(c.conkey) as k(attnum) on true
  join pg_attribute a
    on a.attrelid = c.conrelid and a.attnum = k.attnum
  where c.conrelid = 'public.voucher_redemptions'::regclass
    and c.contype = 'p'
  group by c.conname;

  if v_conname is null then
    alter table public.voucher_redemptions add primary key (code);
  elsif v_cols <> array['code'] then
    execute format(
      'alter table public.voucher_redemptions drop constraint %I',
      v_conname
    );
    alter table public.voucher_redemptions add primary key (code);
  end if;
end $$;

create index if not exists voucher_redemptions_transaction_id_idx
  on public.voucher_redemptions (transaction_id);
create index if not exists voucher_redemptions_status_idx
  on public.voucher_redemptions (status, reserved_until);

alter table public.voucher_redemptions enable row level security;
drop policy if exists "voucher_redemptions_select_own" on public.voucher_redemptions;
create policy "voucher_redemptions_select_own" on public.voucher_redemptions
  for select to authenticated
  using (auth.uid() = user_id);

revoke all on table public.voucher_redemptions from anon, authenticated;
grant select on table public.voucher_redemptions to authenticated;

-- Voucher demo/aktif menjadi single-use global. Voucher yang sudah punya
-- redemption tidak boleh tampil sebagai "masih tersedia".
update public.vouchers v
set quota = 0
where exists (
  select 1 from public.voucher_redemptions r where r.code = v.code
);

update public.vouchers set quota = 1 where quota > 1;

-- ------------------------------------------------------------
-- 9. Bersihkan checkout pending yang kedaluwarsa
-- ------------------------------------------------------------

create or replace function public.expire_pending_checkouts()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  r record;
begin
  -- Kembalikan kuota voucher yang reservasinya kedaluwarsa.
  for r in
    select code
    from public.voucher_redemptions
    where status = 'reserved'
      and reserved_until is not null
      and reserved_until < now()
  loop
    update public.vouchers
    set quota = least(quota + 1, 1)
    where code = r.code;

    delete from public.voucher_redemptions where code = r.code;
  end loop;

  -- Tiket pending yang lebih tua dari 30 menit dilepas. Transaksi terkait
  -- ikut terhapus lewat FK on delete cascade.
  delete from public.tickets
  where status = 'pending'
    and created_at < now() - interval '30 minutes';
end;
$$;

revoke all on function public.expire_pending_checkouts() from public;

-- ------------------------------------------------------------
-- 10. Checkout: simulation -> paid; live -> pending + reservasi
-- ------------------------------------------------------------

drop function if exists public.checkout(uuid, integer, text, text);
drop function if exists public.checkout(uuid, text, text);
drop function if exists public.checkout(uuid, integer, text, text, text, text, text);

create function public.checkout(
  p_event_id uuid,
  p_qty integer default 1,
  p_voucher_code text default null,
  p_payment_method text default 'GoPay',
  p_buyer_name text default '',
  p_buyer_email text default '',
  p_buyer_phone text default ''
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_uid uuid := auth.uid();
  v_event public.events%rowtype;
  v_voucher public.vouchers%rowtype;
  v_ticket public.tickets%rowtype;
  v_transaction public.transactions%rowtype;
  v_sold integer;
  v_qty integer;
  v_sisa integer;
  v_admin_fee numeric(12, 2) := 2500;
  v_subtotal numeric(12, 2);
  v_admin_total numeric(12, 2);
  v_discount numeric(12, 2) := 0;
  v_total numeric(12, 2);
  v_codes text[] := '{}';
  v_first_ticket uuid;
  v_first_transaction uuid;
  v_has_voucher boolean := false;
  v_payment_mode text;
  v_payment_method text;
  v_order_status text;
  v_checkout_group uuid := gen_random_uuid();
  v_expires_at timestamptz;
  v_buyer_name text;
  v_buyer_email text;
  v_buyer_phone text;
  i integer;
begin
  if v_uid is null then
    raise exception 'Harus login untuk melakukan checkout';
  end if;

  v_qty := coalesce(p_qty, 1);
  if v_qty < 1 or v_qty > 10 then
    raise exception 'Jumlah tiket harus antara 1 dan 10.';
  end if;

  v_payment_method := trim(coalesce(p_payment_method, ''));
  if v_payment_method not in ('GoPay', 'Virtual Account', 'Kartu') then
    raise exception 'Metode pembayaran tidak valid.';
  end if;

  v_buyer_name := trim(coalesce(p_buyer_name, ''));
  v_buyer_email := trim(coalesce(p_buyer_email, ''));
  v_buyer_phone := trim(coalesce(p_buyer_phone, ''));

  if length(v_buyer_name) < 2 or length(v_buyer_name) > 100 then
    raise exception 'Nama pembeli harus antara 2 dan 100 karakter.';
  end if;
  if length(v_buyer_email) = 0 or length(v_buyer_email) > 254
     or v_buyer_email !~* '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
    raise exception 'Email pembeli tidak valid.';
  end if;
  if v_buyer_phone !~ '^\+?[0-9]{9,15}$' then
    raise exception 'Nomor HP pembeli tidak valid.';
  end if;

  select value into v_payment_mode
  from public.app_settings
  where key = 'payment_mode';

  v_payment_mode := coalesce(v_payment_mode, 'simulation');
  if v_payment_mode not in ('simulation', 'live') then
    raise exception 'Mode pembayaran tidak valid.';
  end if;

  -- Serialisasi checkout per user+event agar double tap tidak berlomba.
  perform pg_advisory_xact_lock(
    hashtextextended(v_uid::text || ':' || p_event_id::text, 0)
  );

  perform public.expire_pending_checkouts();

  select * into v_event
  from public.events
  where id = p_event_id
  for update;

  if not found then
    raise exception 'Event tidak ditemukan';
  end if;

  select count(*) into v_sold
  from public.tickets
  where event_id = p_event_id
    and (
      status in ('paid', 'checked_in')
      or (
        status = 'pending'
        and created_at > now() - interval '30 minutes'
      )
    );

  if v_event.quota > 0 then
    v_sisa := greatest(v_event.quota - v_sold, 0);
    if v_sisa = 0 then
      raise exception 'Stok tiket habis.';
    end if;
    if v_qty > v_sisa then
      raise exception 'Sisa tiket tinggal %.', v_sisa;
    end if;
  end if;

  if p_voucher_code is not null and length(trim(p_voucher_code)) > 0 then
    select * into v_voucher
    from public.vouchers
    where code = upper(trim(p_voucher_code))
      and now() between active_from and active_to
      and quota > 0
    for update;

    if not found then
      raise exception 'Voucher tidak valid atau kedaluwarsa';
    end if;

    if exists (
      select 1 from public.voucher_redemptions
      where code = v_voucher.code
    ) then
      raise exception 'Voucher % sudah dipakai.', v_voucher.code;
    end if;

    v_has_voucher := true;
    v_discount := least(
      v_voucher.discount,
      v_event.price * v_qty + v_admin_fee * v_qty
    );
  end if;

  v_subtotal := v_event.price * v_qty;
  v_admin_total := v_admin_fee * v_qty;
  v_total := greatest(v_subtotal + v_admin_total - v_discount, 0);

  if v_payment_mode = 'simulation' then
    v_order_status := 'paid';
    v_expires_at := null;
  else
    v_order_status := 'pending';
    v_expires_at := now() + interval '30 minutes';
  end if;

  for i in 1..v_qty loop
    insert into public.tickets (event_id, user_id, status)
    values (p_event_id, v_uid, v_order_status)
    returning * into v_ticket;

    v_codes := v_codes || v_ticket.code;
    if v_first_ticket is null then
      v_first_ticket := v_ticket.id;
    end if;

    insert into public.transactions (
      user_id, event_id, ticket_id, subtotal, admin_fee, discount,
      total, payment_method, status, buyer_name, buyer_email, buyer_phone,
      checkout_group_id, paid_at
    )
    values (
      v_uid, p_event_id, v_ticket.id, v_event.price, v_admin_fee,
      case when i = 1 then v_discount else 0 end,
      greatest(
        v_event.price + v_admin_fee
          - (case when i = 1 then v_discount else 0 end),
        0
      ),
      v_payment_method, v_order_status,
      v_buyer_name, v_buyer_email, v_buyer_phone,
      v_checkout_group,
      case when v_payment_mode = 'simulation' then now() else null end
    )
    returning * into v_transaction;

    if v_first_transaction is null then
      v_first_transaction := v_transaction.id;
    end if;
  end loop;

  if v_has_voucher then
    insert into public.voucher_redemptions (
      code, user_id, ticket_id, transaction_id, status, reserved_until
    )
    values (
      v_voucher.code, v_uid, v_first_ticket, v_first_transaction,
      case when v_payment_mode = 'simulation' then 'redeemed' else 'reserved' end,
      case when v_payment_mode = 'simulation' then null else v_expires_at end
    )
    on conflict (code) do nothing;

    if not found then
      raise exception 'Voucher % sudah dipakai.', v_voucher.code;
    end if;

    update public.vouchers
    set quota = greatest(quota - 1, 0)
    where code = v_voucher.code;
  end if;

  if v_payment_mode = 'simulation' then
    insert into public.notifications (user_id, title, body, event_id)
    values (
      v_uid,
      'Pembelian tiket berhasil',
      format(
        'Tiket %s untuk "%s" sudah aktif. Lihat detail pesananmu.',
        v_qty,
        v_event.title
      ),
      v_event.id
    );
  end if;

  return jsonb_build_object(
    'ticket_id', v_first_ticket,
    'ticket_code', v_codes[1],
    'ticket_codes', to_jsonb(v_codes),
    'transaction_id', v_first_transaction,
    'checkout_group_id', v_checkout_group,
    'qty', v_qty,
    'subtotal', v_subtotal,
    'admin_fee', v_admin_total,
    'discount', v_discount,
    'total', v_total,
    'event_id', v_event.id,
    'event_title', v_event.title,
    'status', v_order_status,
    'payment_mode', v_payment_mode,
    'expires_at', v_expires_at,
    'buyer_name', v_buyer_name,
    'buyer_email', v_buyer_email,
    'buyer_phone', v_buyer_phone
  );
end;
$$;

revoke all on function public.checkout(
  uuid, integer, text, text, text, text, text
) from public, anon, authenticated;
grant execute on function public.checkout(
  uuid, integer, text, text, text, text, text
) to authenticated;

-- ------------------------------------------------------------
-- 11. Konfirmasi/gagal pembayaran (khusus server pembayaran)
-- ------------------------------------------------------------

create or replace function public.confirm_payment(
  p_checkout_group_id uuid,
  p_provider_reference text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_tx record;
  v_count integer := 0;
  v_user_id uuid;
  v_event_id uuid;
  v_event_title text;
begin
  if coalesce(auth.role(), 'service_role') <> 'service_role' then
    raise exception 'Hanya server pembayaran yang dapat mengonfirmasi pembayaran.';
  end if;

  if p_checkout_group_id is null then
    raise exception 'ID pesanan wajib diisi.';
  end if;

  for v_tx in
    select *
    from public.transactions
    where checkout_group_id = p_checkout_group_id
      and status = 'pending'
    for update
  loop
    update public.transactions
    set status = 'paid',
        paid_at = now(),
        payment_reference = coalesce(
          nullif(trim(p_provider_reference), ''),
          payment_reference
        )
    where id = v_tx.id;

    update public.tickets
    set status = 'paid'
    where id = v_tx.ticket_id and status = 'pending';

    update public.voucher_redemptions
    set status = 'redeemed', reserved_until = null
    where transaction_id = v_tx.id and status = 'reserved';

    v_count := v_count + 1;
    v_user_id := v_tx.user_id;
    v_event_id := v_tx.event_id;
  end loop;

  if v_count = 0 then
    if exists (
      select 1 from public.transactions
      where checkout_group_id = p_checkout_group_id and status = 'paid'
    ) then
      return jsonb_build_object(
        'ok', true, 'already_paid', true, 'confirmed', 0
      );
    end if;
    raise exception 'Pesanan tidak ditemukan atau sudah gagal.';
  end if;

  select title into v_event_title
  from public.events
  where id = v_event_id;

  if v_user_id is not null then
    insert into public.notifications (user_id, title, body, event_id)
    values (
      v_user_id,
      'Pembayaran berhasil',
      format(
        'Pembayaran untuk "%s" sudah dikonfirmasi. E-tiketmu aktif.',
        coalesce(v_event_title, 'event')
      ),
      v_event_id
    );
  end if;

  return jsonb_build_object(
    'ok', true,
    'confirmed', v_count,
    'event_id', v_event_id,
    'event_title', v_event_title
  );
end;
$$;

create or replace function public.fail_payment(
  p_checkout_group_id uuid,
  p_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_tx record;
  v_code text;
  v_count integer := 0;
begin
  if coalesce(auth.role(), 'service_role') <> 'service_role' then
    raise exception 'Hanya server pembayaran yang dapat menggagalkan pembayaran.';
  end if;

  if p_checkout_group_id is null then
    raise exception 'ID pesanan wajib diisi.';
  end if;

  for v_tx in
    select *
    from public.transactions
    where checkout_group_id = p_checkout_group_id
      and status = 'pending'
    for update
  loop
    -- Lepaskan reservasi voucher dan kembalikan kuotanya.
    for v_code in
      select code
      from public.voucher_redemptions
      where transaction_id = v_tx.id and status = 'reserved'
    loop
      update public.vouchers
      set quota = least(quota + 1, 1)
      where code = v_code;

      delete from public.voucher_redemptions where code = v_code;
    end loop;

    update public.transactions
    set status = 'failed',
        payment_reference = coalesce(
          nullif(trim(p_reason), ''),
          payment_reference
        )
    where id = v_tx.id;

    v_count := v_count + 1;
  end loop;

  return jsonb_build_object('ok', true, 'failed', v_count);
end;
$$;

revoke all on function public.confirm_payment(uuid, text)
  from public, anon, authenticated;
revoke all on function public.fail_payment(uuid, text)
  from public, anon, authenticated;

do $$
begin
  if exists (select 1 from pg_roles where rolname = 'service_role') then
    execute 'grant execute on function public.confirm_payment(uuid, text) to service_role';
    execute 'grant execute on function public.fail_payment(uuid, text) to service_role';
  end if;
end $$;

-- ------------------------------------------------------------
-- 12. Check-in: audit trail + hanya pada/ setelah tanggal event
-- ------------------------------------------------------------

create or replace function public.check_in_ticket(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_uid uuid := auth.uid();
  v_ticket public.tickets%rowtype;
  v_event public.events%rowtype;
  v_checked_in_at timestamptz := now();
begin
  if v_uid is null then
    raise exception 'Harus login untuk check-in';
  end if;

  select * into v_ticket
  from public.tickets
  where upper(code) = upper(trim(p_code))
  for update;

  if not found then
    raise exception 'Tiket tidak ditemukan';
  end if;

  select * into v_event
  from public.events
  where id = v_ticket.event_id;

  if v_event.organizer_id is distinct from v_uid then
    raise exception 'Hanya organizer event yang dapat melakukan check-in';
  end if;

  if v_event.date > (now() at time zone 'Asia/Jakarta')::date then
    raise exception 'Check-in baru dibuka pada tanggal event.';
  end if;

  if v_ticket.status = 'checked_in' then
    raise exception 'Tiket sudah pernah check-in';
  end if;

  if v_ticket.status <> 'paid' then
    raise exception 'Tiket belum dibayar';
  end if;

  update public.tickets
  set status = 'checked_in',
      checked_in_at = v_checked_in_at,
      checked_in_by = v_uid
  where id = v_ticket.id;

  if v_ticket.user_id is not null then
    insert into public.notifications (user_id, title, body, event_id)
    values (
      v_ticket.user_id,
      'Check-in berhasil',
      format(
        'Tiketmu untuk "%s" sudah di-check-in. Selamat menikmati acara!',
        v_event.title
      ),
      v_event.id
    );
  end if;

  return jsonb_build_object(
    'ok', true,
    'code', v_ticket.code,
    'event_title', v_event.title,
    'checked_in_at', v_checked_in_at
  );
end;
$$;

revoke all on function public.check_in_ticket(text) from public, anon, authenticated;
grant execute on function public.check_in_ticket(text) to authenticated;

-- ------------------------------------------------------------
-- 13. Hapus akun: pertahankan event + riwayat transaksi pembeli
-- ------------------------------------------------------------

create or replace function public.delete_account()
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_uid uuid := auth.uid();
  r record;
begin
  if v_uid is null then
    raise exception 'Harus login untuk menghapus akun.';
  end if;

  -- Guard trigger tidak boleh menghalangi operasi penghapusan akun.
  perform set_config('eventkuy.system_write', 'on', true);

  -- Reservasi voucher yang masih pending dikembalikan kuotanya.
  for r in
    select code from public.voucher_redemptions
    where user_id = v_uid and status = 'reserved'
  loop
    update public.vouchers set quota = least(quota + 1, 1) where code = r.code;
  end loop;

  -- Data pribadi pembeli dianonimkan, tetapi baris transaksi/tiket tetap
  -- ada agar organizer dan laporan penjualan tidak kehilangan data.
  update public.transactions
  set buyer_name = 'Akun dihapus',
      buyer_email = '',
      buyer_phone = ''
  where user_id = v_uid;

  -- Event dan profil organizer dipertahankan; kepemilikan dilepas.
  update public.events
  set organizer_id = null
  where organizer_id = v_uid;

  update public.organizers
  set owner_id = null
  where owner_id = v_uid;

  -- Hapus data yang memang milik pribadi pengguna.
  delete from public.voucher_redemptions where user_id = v_uid;
  delete from public.favorites where user_id = v_uid;
  delete from public.notifications where user_id = v_uid;
  delete from public.device_tokens where user_id = v_uid;
  delete from public.profiles where id = v_uid;

  -- Tiket/transaksi tidak dihapus: FK user_id on delete set null membuat
  -- riwayat tetap ada tanpa mengait ke akun yang sudah dihapus.
  delete from auth.users where id = v_uid;
end;
$$;

revoke all on function public.delete_account() from public, anon, authenticated;
grant execute on function public.delete_account() to authenticated;

-- ------------------------------------------------------------
-- 14. Storage event-images: batas file + kepemilikan folder
-- ------------------------------------------------------------

insert into storage.buckets (
  id, name, public, file_size_limit, allowed_mime_types
)
values (
  'event-images',
  'event-images',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "event_images_public_read" on storage.objects;
create policy "event_images_public_read"
on storage.objects for select
using (bucket_id = 'event-images');

drop policy if exists "event_images_organizer_insert" on storage.objects;
create policy "event_images_organizer_insert"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'event-images'
  and public.is_organizer()
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "event_images_organizer_update" on storage.objects;
create policy "event_images_organizer_update"
on storage.objects for update
to authenticated
using (
  bucket_id = 'event-images'
  and public.is_organizer()
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'event-images'
  and public.is_organizer()
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "event_images_organizer_delete" on storage.objects;
create policy "event_images_organizer_delete"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'event-images'
  and public.is_organizer()
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- ------------------------------------------------------------
-- 15. Profil: kunci kolom role (idempotent)
-- ------------------------------------------------------------

revoke insert, delete, update on table public.profiles
  from anon, authenticated;
grant update (name, avatar_url) on table public.profiles to authenticated;

-- ------------------------------------------------------------
-- Verifikasi cepat (jalankan manual):
--   select key, value from public.app_settings;
--   select conname, pg_get_constraintdef(oid)
--     from pg_constraint
--     where conrelid = 'public.voucher_redemptions'::regclass and contype = 'p';
--   select indexname, indexdef from pg_indexes
--     where tablename = 'device_tokens';
--   select polname, pg_get_expr(polqual, polrelid) as using_expr
--     from pg_policy where polrelid = 'public.organizers'::regclass;
-- ------------------------------------------------------------
