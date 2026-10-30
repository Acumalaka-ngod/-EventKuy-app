-- ------------------------------------------------------------
-- Migrasi: beli banyak tiket (qty) + stok + voucher sekali pakai
-- ------------------------------------------------------------
-- Jalankan sekali di Supabase Studio -> SQL Editor untuk database
-- yang sudah berjalan. Isinya sama dengan bagian terkait di schema.sql,
-- dan aman dijalankan berulang (idempotent).
--
-- Yang dibuat/diubah:
--   1. tabel voucher_redemptions  -> satu voucher hanya sekali per user
--   2. view event_stock           -> jumlah tiket terjual per event
--   3. RPC checkout(uuid, int, text, text) dengan qty + validasi stok
-- ------------------------------------------------------------

-- 1. Catatan pemakaian voucher ---------------------------------

create table if not exists public.voucher_redemptions (
  code text not null references public.vouchers (code) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  ticket_id uuid references public.tickets (id) on delete set null,
  created_at timestamptz not null default now(),
  primary key (code, user_id)
);

alter table public.voucher_redemptions enable row level security;

drop policy if exists "voucher_redemptions_select_own" on public.voucher_redemptions;
create policy "voucher_redemptions_select_own" on public.voucher_redemptions
  for select to authenticated
  using (auth.uid() = user_id);

grant select on table public.voucher_redemptions to authenticated;

-- 2. Stok tiket per event --------------------------------------

create or replace view public.event_stock as
select
  e.id as event_id,
  e.quota,
  coalesce(count(t.id) filter (where t.status in ('paid', 'checked_in')), 0)::int as sold
from public.events e
left join public.tickets t on t.event_id = e.id
group by e.id, e.quota;

grant select on public.event_stock to authenticated;

-- 3. RPC checkout dengan qty -----------------------------------

-- Versi lama hanya menerima 1 tiket; hapus supaya tidak ambigu.
drop function if exists public.checkout(uuid, text, text);

create or replace function public.checkout(
  p_event_id uuid,
  p_qty integer default 1,
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
  v_qty integer := greatest(coalesce(p_qty, 1), 1);
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
  i integer;
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
      where code = v_voucher.code and user_id = v_uid
    ) then
      raise exception 'Voucher % sudah pernah kamu pakai.', v_voucher.code;
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

  for i in 1..v_qty loop
    insert into public.tickets (event_id, user_id, status)
    values (p_event_id, v_uid, 'paid')
    returning * into v_ticket;

    v_codes := v_codes || v_ticket.code;
    if v_first_ticket is null then
      v_first_ticket := v_ticket.id;
    end if;

    insert into public.transactions (
      user_id, event_id, ticket_id, subtotal, admin_fee, discount,
      total, payment_method, status
    )
    values (
      v_uid, p_event_id, v_ticket.id, v_event.price, v_admin_fee,
      case when i = 1 then v_discount else 0 end,
      greatest(
        v_event.price + v_admin_fee - (case when i = 1 then v_discount else 0 end),
        0
      ),
      p_payment_method, 'paid'
    )
    returning * into v_transaction;

    if v_first_transaction is null then
      v_first_transaction := v_transaction.id;
    end if;
  end loop;

  if v_has_voucher then
    update public.vouchers set quota = quota - 1 where code = v_voucher.code;
    insert into public.voucher_redemptions (code, user_id, ticket_id)
    values (v_voucher.code, v_uid, v_first_ticket)
    on conflict (code, user_id) do nothing;
  end if;

  return jsonb_build_object(
    'ticket_id', v_first_ticket,
    'ticket_code', v_codes[1],
    'ticket_codes', to_jsonb(v_codes),
    'transaction_id', v_first_transaction,
    'qty', v_qty,
    'subtotal', v_subtotal,
    'admin_fee', v_admin_total,
    'discount', v_discount,
    'total', v_total,
    'event_id', v_event.id,
    'event_title', v_event.title,
    'status', 'paid'
  );
end;
$$;

revoke all on function public.checkout(uuid, integer, text, text) from public;
grant execute on function public.checkout(uuid, integer, text, text) to authenticated;

-- Verifikasi cepat:
-- select * from public.event_stock order by event_id;
-- select code, user_id from public.voucher_redemptions;
