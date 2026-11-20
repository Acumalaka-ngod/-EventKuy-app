// Supabase Edge Function: send-push
//
// Mengirim FCM HTTP v1 ke seluruh device_tokens milik seorang user.
// Dipanggil oleh trigger `notifications` (lihat supabase/push_webhook.sql)
// atau manual dari backend dengan Authorization: Bearer <service role key>.
//
// Secrets yang dibutuhkan (Supabase Dashboard -> Project Settings -> Edge Functions):
//   SUPABASE_URL                 (otomatis)
//   SUPABASE_SERVICE_ROLE_KEY    (otomatis)
//   FIREBASE_SERVICE_ACCOUNT     (JSON service account Firebase, seluruh isi file)

import { createClient } from 'jsr:@supabase/supabase-js@2';

const FCM_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';
const TOKEN_URL = 'https://oauth2.googleapis.com/token';

let cachedAccessToken: { token: string; expiresAt: number } | null = null;

type ServiceAccount = {
  project_id: string;
  client_email: string;
  private_key: string;
};

type PushRequest = {
  user_id: string;
  title: string;
  body: string;
  event_id?: string | null;
  notification_id?: string | null;
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

function base64Url(data: Uint8Array): string {
  let binary = '';
  for (const byte of data) binary += String.fromCharCode(byte);
  return btoa(binary)
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

function encodeText(value: string): Uint8Array {
  return new TextEncoder().encode(value);
}

function readServiceAccount(): ServiceAccount {
  const raw = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');
  if (!raw) throw new Error('FIREBASE_SERVICE_ACCOUNT belum diatur');
  const account = JSON.parse(raw) as ServiceAccount;
  if (!account.project_id || !account.client_email || !account.private_key) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT tidak lengkap');
  }
  return account;
}

async function createGoogleAccessToken(account: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = base64Url(encodeText(JSON.stringify({ alg: 'RS256', typ: 'JWT' })));
  const claims = base64Url(
    encodeText(
      JSON.stringify({
        iss: account.client_email,
        scope: FCM_SCOPE,
        aud: TOKEN_URL,
        iat: now,
        exp: now + 3600,
      }),
    ),
  );
  const unsigned = `${header}.${claims}`;

  const key = await crypto.subtle.importKey(
    'pkcs8',
    encodeText(account.private_key.replace(/\\n/g, '\n')),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    encodeText(unsigned),
  );
  const assertion = `${unsigned}.${base64Url(new Uint8Array(signature))}`;

  const response = await fetch(TOKEN_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }).toString(),
  });
  if (!response.ok) {
    throw new Error(`Gagal bertukar token Google: ${await response.text()}`);
  }
  const result = (await response.json()) as {
    access_token: string;
    expires_in: number;
  };
  return result.access_token;
}

async function getAccessToken(account: ServiceAccount): Promise<string> {
  const now = Date.now();
  if (cachedAccessToken && cachedAccessToken.expiresAt > now + 60_000) {
    return cachedAccessToken.token;
  }
  const token = await createGoogleAccessToken(account);
  cachedAccessToken = { token, expiresAt: now + 55 * 60 * 1000 };
  return token;
}

function isInvalidToken(status: number, reason: string): boolean {
  return (
    status === 404 ||
    reason.includes('UNREGISTERED') ||
    reason.includes('INVALID_ARGUMENT') ||
    reason.includes('NOT_FOUND')
  );
}

Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405);
  }

  const secretKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  const authHeader = req.headers.get('authorization') ?? '';
  if (!secretKey || !authHeader || authHeader !== `Bearer ${secretKey}`) {
    return json({ error: 'Unauthorized' }, 401);
  }

  let payload: PushRequest;
  try {
    payload = (await req.json()) as PushRequest;
  } catch {
    return json({ error: 'Body harus JSON' }, 400);
  }
  if (
    !payload.user_id ||
    typeof payload.title !== 'string' ||
    typeof payload.body !== 'string'
  ) {
    return json({ error: 'user_id, title, dan body wajib diisi' }, 400);
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!supabaseUrl || !serviceKey) {
    return json({ error: 'Konfigurasi Supabase belum lengkap' }, 500);
  }

  try {
    const supabase = createClient(supabaseUrl, serviceKey, {
      auth: { persistSession: false },
    });
    const { data: tokens, error: tokenError } = await supabase
      .from('device_tokens')
      .select('id, token')
      .eq('user_id', payload.user_id);

    if (tokenError) throw tokenError;
    if (!tokens || tokens.length === 0) {
      return json({ sent: 0, failed: 0, removedTokens: 0 });
    }

    const account = readServiceAccount();
    const accessToken = await getAccessToken(account);
    const url =
      `https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`;

    const data: Record<string, string> = {
      title: payload.title,
      body: payload.body,
    };
    if (payload.event_id) data.eventId = payload.event_id;
    if (payload.notification_id) data.notificationId = payload.notification_id;

    let sent = 0;
    let failed = 0;
    const invalidTokenIds: string[] = [];

    for (const row of tokens) {
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          message: {
            token: row.token,
            notification: { title: payload.title, body: payload.body },
            data,
            android: {
              notification: { clickAction: 'FLUTTER_NOTIFICATION_CLICK' },
            },
            apns: {
              payload: { aps: { 'content-available': 1, sound: 'default' } },
            },
          },
        }),
      });

      if (response.ok) {
        sent += 1;
        continue;
      }

      failed += 1;
      const errorText = await response.text();
      const reason = errorText.toLowerCase();
      console.error(`FCM gagal untuk token ${row.id}: ${errorText}`);
      if (isInvalidToken(response.status, reason)) {
        invalidTokenIds.push(row.id);
      }
    }

    if (invalidTokenIds.length > 0) {
      const { error: cleanupError } = await supabase
        .from('device_tokens')
        .delete()
        .in('id', invalidTokenIds);
      if (cleanupError) console.error('Gagal membersihkan token: ', cleanupError);
    }

    return json({ sent, failed, removedTokens: invalidTokenIds.length });
  } catch (error) {
    console.error('send-push gagal: ', error);
    return json({ error: 'Gagal mengirim notifikasi' }, 500);
  }
});
