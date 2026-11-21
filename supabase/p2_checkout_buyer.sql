-- ============================================================
-- EventKuy - Migrasi P2: Data Pembeli di Transaksi
-- Jalankan di Supabase Dashboard -> SQL Editor, setelah schema.sql.
-- Aman dijalankan berulang (idempotent).
--
-- File ini mendefinisikan RPC checkout() versi lama. Versi final ada di
-- `security_hardening.sql`, jadi jalankan file itu TERAKHIR setelah
-- migrasi ini.
-- ============================================================

-- ------------------------------------------------------------
-- Kolom data pembeli pada transactions
-- ------------------------------------------------------------

alter table public.transactions
  add column if not exists buyer_name text not null default '';

alter table public.transactions
  add column if not exists buyer_email text not null default '';

alter table public.transactions
  add column if not exists buyer_phone text not null default '';

-- ------------------------------------------------------------
-- RPC checkout baru: menerima data pembeli
-- ------------------------------------------------------------

-- Hapus versi lama agar PostgREST tidak ambigu.
drop function if exists public.checkout(uuid, integer, text, text);

create or replace function public.checkout(
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

  -- Validasi data pembeli tidak boleh kosong.
  if length(trim(p_buyer_name)) = 0 then
    raise exception 'Nama pembeli wajib diisi.';
  end if;
  if length(trim(p_buyer_email)) = 0 then
    raise exception 'Email pembeli wajib diisi.';
  end if;
  if length(trim(p_buyer_phone)) = 0 then
    raise exception 'Nomor HP pembeli wajib diisi.';
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
      total, payment_method, status,
      buyer_name, buyer_email, buyer_phone
    )
    values (
      v_uid, p_event_id, v_ticket.id, v_event.price, v_admin_fee,
      case when i = 1 then v_discount else 0 end,
      greatest(
        v_event.price + v_admin_fee - (case when i = 1 then v_discount else 0 end),
        0
      ),
      p_payment_method, 'paid',
      trim(p_buyer_name), trim(p_buyer_email), trim(p_buyer_phone)
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
    'status', 'paid',
    'buyer_name', trim(p_buyer_name),
    'buyer_email', trim(p_buyer_email),
    'buyer_phone', trim(p_buyer_phone)
  );
end;
$$;

revoke all on function public.checkout(uuid, integer, text, text, text, text, text) from public;
grant execute on function public.checkout(uuid, integer, text, text, text, text, text) to authenticated;

-- ============================================================
-- Catatan: jalankan migrasi ini di Supabase Studio sebelum
-- menggunakan fitur checkout dengan data pembeli di aplikasi.
-- ============================================================
