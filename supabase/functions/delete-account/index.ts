// Supabase Edge Function: delete-account
//
// Dipakai oleh halaman web penghapusan akun (docs/delete-account.html).
// Caller mengirim access token user (bukan service role key) dan body
// `{ "confirm": true }`. Function memverifikasi token, lalu memanggil RPC
// `delete_account` sebagai user tersebut. RPC berjalan security definer:
// data pribadi dianonimkan, riwayat tiket/transaksi pembeli dipertahankan,
// dan baris auth.users dihapus.

import { createClient } from 'jsr:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (req.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405);
  }

  const authHeader = req.headers.get('authorization') ?? '';
  const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : '';
  if (!token) return json({ error: 'Token akses wajib diisi' }, 401);

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return json({ error: 'Body JSON wajib diisi' }, 400);
  }
  if (
    typeof body !== 'object' ||
    body === null ||
    (body as { confirm?: unknown }).confirm !== true
  ) {
    return json(
      { error: 'Konfirmasi eksplisit wajib dikirim: { "confirm": true }' },
      400,
    );
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY');
  if (!supabaseUrl || !anonKey) {
    return json({ error: 'Konfigurasi Supabase belum lengkap' }, 500);
  }

  // Klien memakai JWT pemilik akun supaya auth.uid() bekerja di RPC
  // delete_account. Tidak perlu service role key di function ini.
  const supabase = createClient(supabaseUrl, anonKey, {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { headers: { Authorization: `Bearer ${token}` } },
  });

  try {
    const { data, error } = await supabase.auth.getUser(token);
    if (error || !data.user) {
      return json({ error: 'Token tidak valid' }, 401);
    }

    const { error: rpcError } = await supabase.rpc('delete_account');
    if (rpcError) throw rpcError;

    return json({ deleted: true });
  } catch (error) {
    console.error('delete-account gagal: ', error);
    return json({ error: 'Gagal menghapus akun' }, 500);
  }
});
