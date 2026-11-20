-- ------------------------------------------------------------
-- Migrasi: penghapusan akun (delete_account RPC).
-- Jalankan sekali di Supabase Studio -> SQL Editor untuk database
-- yang sudah berjalan. Aman dijalankan berulang.
-- ------------------------------------------------------------
create or replace function public.delete_account()
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'Harus login untuk menghapus akun.';
  end if;

  -- Hapus data milik pengguna.
  delete from public.voucher_redemptions where user_id = v_uid;
  delete from public.favorites where user_id = v_uid;
  delete from public.transactions where user_id = v_uid;
  delete from public.tickets where user_id = v_uid;
  delete from public.events where organizer_id = v_uid;
  delete from public.organizers where owner_id = v_uid;
  delete from public.profiles where id = v_uid;

  -- Hapus akun auth (security definer berjalan sebagai postgres).
  delete from auth.users where id = v_uid;
end;
$$;

revoke all on function public.delete_account() from public;
grant execute on function public.delete_account() to authenticated;
