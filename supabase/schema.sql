-- ============================================================
-- EventKuy - Skema Supabase
-- Jalankan di Supabase Dashboard -> SQL Editor.
-- Cakupan: tabel aplikasi, trigger profil, RLS, dan RPC.
-- ============================================================

create extension if not exists pgcrypto;

-- ------------------------------------------------------------
-- Tabel
-- ------------------------------------------------------------

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  name text not null default '',
  role text not null default 'pengguna'
    check (role in ('pengguna', 'organizer', 'admin')),
  avatar_url text,
  created_at timestamptz not null default now()
);

create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  organizer_id uuid references auth.users (id) on delete set null,
  title text not null,
  description text not null default '',
  date date not null,
  location text not null,
  price numeric(12, 2) not null default 0,
  quota integer not null default 0,
  image_url text not null default '',
  image_urls text[] not null default '{}',
  category text not null default 'Lainnya',
  tags text[] not null default '{}',
  time_range text not null default '',
  created_at timestamptz not null default now()
);

-- Migrasi aditif: galeri foto event (aman dijalankan berulang).
alter table public.events
  add column if not exists image_urls text[] not null default '{}';

create table if not exists public.tickets (
  id uuid primary key default gen_random_uuid(),
  code text not null unique
    default ('EVK-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 12))),
  event_id uuid not null references public.events (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'paid', 'checked_in')),
  created_at timestamptz not null default now()
);

create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  event_id uuid not null references public.events (id) on delete cascade,
  ticket_id uuid not null unique references public.tickets (id) on delete cascade,
  subtotal numeric(12, 2) not null default 0,
  admin_fee numeric(12, 2) not null default 0,
  discount numeric(12, 2) not null default 0,
  total numeric(12, 2) not null default 0,
  payment_method text not null default 'GoPay',
  status text not null default 'pending'
    check (status in ('pending', 'paid', 'failed', 'refunded')),
  created_at timestamptz not null default now()
);

create table if not exists public.favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  event_id uuid not null references public.events (id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, event_id)
);

create table if not exists public.vouchers (
  code text primary key,
  discount numeric(12, 2) not null default 0,
  active_from timestamptz not null default now(),
  active_to timestamptz not null default now() + interval '1 year',
  quota integer not null default 0
);

create index if not exists tickets_event_id_idx on public.tickets (event_id);
create index if not exists tickets_user_id_idx on public.tickets (user_id);
create index if not exists transactions_user_id_idx on public.transactions (user_id);
create index if not exists favorites_user_id_idx on public.favorites (user_id);

-- ------------------------------------------------------------
-- Profil otomatis saat user baru mendaftar (auth.users)
-- ------------------------------------------------------------

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'name', split_part(new.email, '@', 1)),
    'pengguna'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- Helper: cek apakah user yang login berperan organizer/admin.
-- Dipakai oleh policy event agar user biasa tidak bisa membuat event.
create or replace function public.is_organizer()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role in ('organizer', 'admin')
  );
$$;

revoke all on function public.is_organizer() from public;
grant execute on function public.is_organizer() to authenticated;

-- ------------------------------------------------------------
-- Row Level Security
-- ------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.events enable row level security;
alter table public.tickets enable row level security;
alter table public.transactions enable row level security;
alter table public.favorites enable row level security;
alter table public.vouchers enable row level security;

-- profiles: hanya pemilik
drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own" on public.profiles
  for select to authenticated
  using (auth.uid() = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles
  for update to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- events: semua user login boleh membaca; organizer mengelola miliknya
drop policy if exists "events_select_authenticated" on public.events;
create policy "events_select_authenticated" on public.events
  for select to authenticated
  using (true);

drop policy if exists "events_insert_organizer" on public.events;
create policy "events_insert_organizer" on public.events
  for insert to authenticated
  with check (auth.uid() = organizer_id and public.is_organizer());

drop policy if exists "events_update_organizer" on public.events;
create policy "events_update_organizer" on public.events
  for update to authenticated
  using (auth.uid() = organizer_id and public.is_organizer())
  with check (auth.uid() = organizer_id and public.is_organizer());

drop policy if exists "events_delete_organizer" on public.events;
create policy "events_delete_organizer" on public.events
  for delete to authenticated
  using (auth.uid() = organizer_id and public.is_organizer());

-- tickets: milik sendiri atau tiket pada event milik organizer
drop policy if exists "tickets_select_own_or_organizer" on public.tickets;
create policy "tickets_select_own_or_organizer" on public.tickets
  for select to authenticated
  using (
    auth.uid() = user_id
    or exists (
      select 1 from public.events e
      where e.id = tickets.event_id and e.organizer_id = auth.uid()
    )
  );

-- transactions: hanya pemilik
drop policy if exists "transactions_select_own" on public.transactions;
create policy "transactions_select_own" on public.transactions
  for select to authenticated
  using (auth.uid() = user_id);

-- favorites: CRUD milik sendiri
drop policy if exists "favorites_select_own" on public.favorites;
create policy "favorites_select_own" on public.favorites
  for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists "favorites_insert_own" on public.favorites;
create policy "favorites_insert_own" on public.favorites
  for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "favorites_delete_own" on public.favorites;
create policy "favorites_delete_own" on public.favorites
  for delete to authenticated
  using (auth.uid() = user_id);

-- vouchers: dibaca user login yang masih berlaku
drop policy if exists "vouchers_select_active" on public.vouchers;
create policy "vouchers_select_active" on public.vouchers
  for select to authenticated
  using (now() between active_from and active_to and quota > 0);

-- Profil: user hanya boleh mengubah nama/avatar. Perubahan role hanya
-- lewat SQL Editor / service role agar tidak bisa privilege escalation.
revoke insert, delete, update on table public.profiles from authenticated;
grant update (name, avatar_url) on table public.profiles to authenticated;

-- ------------------------------------------------------------
-- RPC checkout (simulasi pembayaran: langsung paid)
-- ------------------------------------------------------------

create or replace function public.checkout(
  p_event_id uuid,
  p_voucher_code text default null,
  p_payment_method text default 'GoPay'
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_event public.events%rowtype;
  v_voucher public.vouchers%rowtype;
  v_ticket public.tickets%rowtype;
  v_transaction public.transactions%rowtype;
  v_sold integer;
  v_admin_fee numeric(12, 2) := 2500;
  v_discount numeric(12, 2) := 0;
  v_total numeric(12, 2);
  v_has_voucher boolean := false;
begin
  if v_uid is null then
    raise exception 'Harus login untuk melakukan checkout';
  end if;

  select * into v_event from public.events where id = p_event_id for update;
  if not found then
    raise exception 'Event tidak ditemukan';
  end if;

  select count(*) into v_sold
  from public.tickets
  where event_id = p_event_id and status in ('paid', 'checked_in');

  if v_event.quota > 0 and v_sold >= v_event.quota then
    raise exception 'Kuota tiket sudah habis';
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

    v_has_voucher := true;
    v_discount := v_voucher.discount;
  end if;

  v_total := greatest(v_event.price + v_admin_fee - v_discount, 0);

  insert into public.tickets (event_id, user_id, status)
  values (p_event_id, v_uid, 'paid')
  returning * into v_ticket;

  insert into public.transactions (
    user_id, event_id, ticket_id, subtotal, admin_fee, discount,
    total, payment_method, status
  )
  values (
    v_uid, p_event_id, v_ticket.id, v_event.price, v_admin_fee, v_discount,
    v_total, p_payment_method, 'paid'
  )
  returning * into v_transaction;

  if v_has_voucher then
    update public.vouchers set quota = quota - 1 where code = v_voucher.code;
  end if;

  return jsonb_build_object(
    'ticket_id', v_ticket.id,
    'ticket_code', v_ticket.code,
    'transaction_id', v_transaction.id,
    'subtotal', v_event.price,
    'admin_fee', v_admin_fee,
    'discount', v_discount,
    'total', v_total,
    'event_id', v_event.id,
    'event_title', v_event.title,
    'status', v_ticket.status
  );
end;
$$;

revoke all on function public.checkout(uuid, text, text) from public;
grant execute on function public.checkout(uuid, text, text) to authenticated;

-- ------------------------------------------------------------
-- RPC check-in tiket (khusus organizer pemilik event)
-- ------------------------------------------------------------

create or replace function public.check_in_ticket(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_ticket public.tickets%rowtype;
  v_event public.events%rowtype;
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

  select * into v_event from public.events where id = v_ticket.event_id;

  if v_event.organizer_id is distinct from v_uid then
    raise exception 'Hanya organizer event yang dapat melakukan check-in';
  end if;

  if v_ticket.status = 'checked_in' then
    raise exception 'Tiket sudah pernah check-in';
  end if;

  if v_ticket.status <> 'paid' then
    raise exception 'Tiket belum dibayar';
  end if;

  update public.tickets set status = 'checked_in' where id = v_ticket.id;

  return jsonb_build_object(
    'ok', true,
    'code', v_ticket.code,
    'event_title', v_event.title
  );
end;
$$;

revoke all on function public.check_in_ticket(text) from public;
grant execute on function public.check_in_ticket(text) to authenticated;
