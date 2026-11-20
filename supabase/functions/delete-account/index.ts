// Supabase Edge Function: delete-account
//
// Dipakai oleh halaman web penghapusan akun (docs/delete-account.html).
// Caller mengirim access token user (bukan service role key). Function
// memverifikasi token, lalu menghapus data profil dan akun auth.

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

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!supabaseUrl || !serviceKey) {
    return json({ error: 'Konfigurasi Supabase belum lengkap' }, 500);
  }

  const admin = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false },
  });

  try {
    const { data, error } = await admin.auth.getUser(token);
    if (error || !data.user) {
      return json({ error: 'Token tidak valid' }, 401);
    }
    const userId = data.user.id;

    // Urutan mengikuti foreign key; sisa data ber-cascade saat auth.users dihapus.
    const targets: Array<[string, string]> = [
      ['voucher_redemptions', 'user_id'],
      ['notifications', 'user_id'],
      ['device_tokens', 'user_id'],
      ['favorites', 'user_id'],
      ['transactions', 'user_id'],
      ['tickets', 'user_id'],
      ['events', 'organizer_id'],
      ['organizers', 'owner_id'],
      ['profiles', 'id'],
    ];
    for (const [table, column] of targets) {
      const { error: deleteError } = await admin
        .from(table)
        .delete()
        .eq(column, userId);
      if (deleteError) console.error(`Gagal menghapus ${table}: `, deleteError);
    }

    const { error: authError } = await admin.auth.deleteUser(userId);
    if (authError) throw authError;

    return json({ deleted: true });
  } catch (error) {
    console.error('delete-account gagal: ', error);
    return json({ error: 'Gagal menghapus akun' }, 500);
  }
});
