# EventKuy - smoke test koneksi & skema Supabase (P0)
# Jalankan dari root repo:
#   pwsh -File tool/verify-supabase.ps1
#
# Membaca supabase.local.json, atau parameter/env:
#   $env:SUPABASE_URL / $env:SUPABASE_ANON_KEY
#
# Script ini membuat akun uji eventkuy.smoke@gmail.com (atau login bila sudah ada),
# lalu memeriksa profil, event seed, voucher, RPC check-in, dan proteksi role.

[CmdletBinding()]
param(
  [string]$Url,
  [string]$AnonKey,
  [string]$ConfigPath,
  [string]$Email = "eventkuy.smoke@gmail.com",
  [string]$Password
)

$ErrorActionPreference = "Stop"

if ($PSVersionTable.PSVersion.Major -lt 7) {
  throw "Script ini membutuhkan PowerShell 7 (pwsh), bukan Windows PowerShell 5.1."
}

$root = Split-Path -Parent $PSScriptRoot
if (-not $ConfigPath) { $ConfigPath = Join-Path $root "supabase.local.json" }

$config = $null
if (Test-Path $ConfigPath) {
  $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
}

if (-not $Url) { $Url = $env:SUPABASE_URL }
if (-not $AnonKey) { $AnonKey = $env:SUPABASE_ANON_KEY }

if ($config) {
  if (-not $Url) { $Url = $config.SUPABASE_URL }
  if (-not $AnonKey) { $AnonKey = $config.SUPABASE_ANON_KEY }
  if (-not $Password) { $Password = $config.E2E_ATTENDEE_PASSWORD }
}

if (-not $Password) { $Password = $env:SUPABASE_SMOKE_PASSWORD }

if (-not $Password) {
  throw "Password akun uji belum diisi. Pakai -Password, env SUPABASE_SMOKE_PASSWORD, atau E2E_ATTENDEE_PASSWORD di supabase.local.json."
}

if (-not $Url -or -not $AnonKey) {
  throw "SUPABASE_URL / SUPABASE_ANON_KEY belum diisi. Salin supabase.local.example.json menjadi supabase.local.json lalu isi nilainya."
}

$Url = $Url.TrimEnd("/")
$script:Url = $Url
$script:AnonKey = $AnonKey

function Write-Step([string]$Text) {
  Write-Host "`n== $Text" -ForegroundColor Cyan
}

function Write-Ok([string]$Text) {
  Write-Host "  OK  $Text" -ForegroundColor Green
}

function Fail([string]$Text) {
  throw "GAGAL: $Text"
}

function Invoke-Supa {
  param(
    [Parameter(Mandatory = $true)][string]$Method,
    [Parameter(Mandatory = $true)][string]$Path,
    [hashtable]$Headers,
    $Body
  )

  if (-not $Headers) {
    $Headers = @{ apikey = $script:AnonKey }
  }

  $params = @{
    Method             = $Method
    Uri                = "$script:Url$Path"
    Headers            = $Headers
    ContentType        = "application/json"
    SkipHttpErrorCheck = $true
  }

  if ($null -ne $Body) {
    $params.Body = ($Body | ConvertTo-Json -Depth 8 -Compress)
  }

  $response = Invoke-WebRequest @params
  $parsed = $null
  if ($response.Content) {
    try {
      $parsed = $response.Content | ConvertFrom-Json
    } catch {
      $parsed = $response.Content
    }
  }

  return [pscustomobject]@{
    Status = [int]$response.StatusCode
    Body   = $parsed
    Raw    = [string]$response.Content
  }
}

$jsonHeaders = @{
  apikey       = $script:AnonKey
  "Content-Type" = "application/json"
}

Write-Host "EventKuy Supabase smoke test" -ForegroundColor White
Write-Host "URL: $Url"

# ------------------------------------------------------------
Write-Step "1. Auth: signup / login akun smoke test"
# ------------------------------------------------------------
$settings = Invoke-Supa -Method Get -Path "/auth/v1/settings" -Headers $jsonHeaders
if ($settings.Status -ge 400) {
  Fail "Gagal membaca konfigurasi Auth (HTTP $($settings.Status): $($settings.Raw))."
}
if (-not $settings.Body.external.email) {
  Fail "Provider Email masih nonaktif. Aktifkan Authentication > Sign In / Providers > Email."
}
if (-not $settings.Body.mailer_autoconfirm) {
  Fail "Confirm email masih AKTIF. Matikan toggle 'Confirm email' di Authentication > Sign In / Providers > Email, lalu Save."
}
Write-Ok "Provider Email aktif, konfirmasi email nonaktif"

$signup = Invoke-Supa -Method Post -Path "/auth/v1/signup" -Headers $jsonHeaders -Body @{
  email    = $Email
  password = $Password
  data     = @{ name = "Smoke Test" }
}

$session = $null
if ($signup.Status -ge 200 -and $signup.Status -lt 300 -and $signup.Body.access_token) {
  $session = $signup.Body
  Write-Ok "Akun baru dibuat: $Email"
} else {
  $login = Invoke-Supa -Method Post -Path "/auth/v1/token?grant_type=password" -Headers $jsonHeaders -Body @{
    email    = $Email
    password = $Password
  }

  if ($login.Status -ge 400 -or -not $login.Body.access_token) {
    if ($login.Raw -match "email_provider_disabled") {
      Fail "Provider Email sedang dinonaktifkan. Buka Authentication > Sign In / Providers > Email, aktifkan 'Enable email provider', lalu matikan 'Confirm email'."
    }
    Fail "Signup tidak menghasilkan session dan login gagal (HTTP $($login.Status): $($login.Raw)). Aktifkan provider Email dan nonaktifkan konfirmasi email di Authentication > Sign In / Providers > Email, atau pakai -Email/-Password akun yang sudah terkonfirmasi."
  }

  $session = $login.Body
  Write-Ok "Login berhasil: $Email"
}

$token = $session.access_token
$userId = $session.user.id
$authHeaders = @{
  apikey        = $script:AnonKey
  Authorization = "Bearer $token"
  "Content-Type" = "application/json"
}
Write-Ok "User ID: $userId"

# ------------------------------------------------------------
Write-Step "2. Profil otomatis (trigger handle_new_user)"
# ------------------------------------------------------------
$profileResult = $null
for ($i = 0; $i -lt 5; $i++) {
  $profileResult = Invoke-Supa -Method Get -Path "/rest/v1/profiles?select=id,name,role&limit=1" -Headers $authHeaders
  if ($profileResult.Status -eq 200 -and @($profileResult.Body).Count -eq 1) { break }
  Start-Sleep -Milliseconds 400
}

if ($profileResult.Status -ge 400) {
  Fail "Gagal membaca profil (HTTP $($profileResult.Status): $($profileResult.Raw)). Pastikan schema.sql sudah dijalankan."
}

$profiles = @($profileResult.Body)
if ($profiles.Count -ne 1) {
  Fail "Profil untuk user baru tidak ditemukan. Trigger handle_new_user belum terpasang."
}

$roleBefore = [string]$profiles[0].role
Write-Ok "Profil: $($profiles[0].name) / role=$roleBefore"

# ------------------------------------------------------------
Write-Step "3. Event seed & RLS authenticated"
# ------------------------------------------------------------
$eventsResult = Invoke-Supa -Method Get -Path "/rest/v1/events?select=id,title&order=date.asc&limit=3" -Headers $authHeaders
if ($eventsResult.Status -ge 400) {
  Fail "Gagal membaca events (HTTP $($eventsResult.Status): $($eventsResult.Raw))."
}

$events = @($eventsResult.Body)
if ($events.Count -lt 1) {
  Fail "Tidak ada event. Jalankan supabase/seed.sql."
}
$firstEvent = $events[0]
Write-Ok "Event seed terbaca: $($firstEvent.title) ($($firstEvent.id))"

# ------------------------------------------------------------
Write-Step "4. Voucher seed"
# ------------------------------------------------------------
$vouchersResult = Invoke-Supa -Method Get -Path "/rest/v1/vouchers?select=code,discount&limit=10" -Headers $authHeaders
if ($vouchersResult.Status -ge 400) {
  Fail "Gagal membaca vouchers (HTTP $($vouchersResult.Status): $($vouchersResult.Raw))."
}

$voucherCodes = @(@($vouchersResult.Body) | ForEach-Object { $_.code })
if ($voucherCodes -notcontains "EVENTKUY") {
  Fail "Voucher EVENTKUY tidak ditemukan. Jalankan supabase/seed.sql."
}
Write-Ok "Voucher aktif: $($voucherCodes -join ', ')"

# ------------------------------------------------------------
Write-Step "5. Favorit: insert, baca, hapus (RLS write)"
# ------------------------------------------------------------
$favoritePath = "/rest/v1/favorites?user_id=eq.$userId&event_id=eq.$($firstEvent.id)"
Invoke-Supa -Method Delete -Path $favoritePath -Headers $authHeaders | Out-Null

$insertFavorite = Invoke-Supa -Method Post -Path "/rest/v1/favorites" -Headers $authHeaders -Body @{
  user_id  = $userId
  event_id = $firstEvent.id
}
if ($insertFavorite.Status -ge 400) {
  Fail "Gagal menambah favorit (HTTP $($insertFavorite.Status): $($insertFavorite.Raw))."
}

$readFavorite = Invoke-Supa -Method Get -Path "/rest/v1/favorites?select=event_id&event_id=eq.$($firstEvent.id)" -Headers $authHeaders
if ($readFavorite.Status -ge 400 -or @($readFavorite.Body).Count -ne 1) {
  Fail "Favorit tidak terbaca setelah insert."
}

$deleteFavorite = Invoke-Supa -Method Delete -Path $favoritePath -Headers $authHeaders
if ($deleteFavorite.Status -ge 400) {
  Fail "Gagal menghapus favorit (HTTP $($deleteFavorite.Status): $($deleteFavorite.Raw))."
}
Write-Ok "CRUD favorit berhasil"

# ------------------------------------------------------------
Write-Step "6. RPC check_in_ticket terpasang"
# ------------------------------------------------------------
$badCheckIn = Invoke-Supa -Method Post -Path "/rest/v1/rpc/check_in_ticket" -Headers $authHeaders -Body @{
  p_code = "SMOKE-INVALID-CODE"
}

if ($badCheckIn.Status -ge 500) {
  Fail "RPC check_in_ticket error server (HTTP $($badCheckIn.Status): $($badCheckIn.Raw))."
}
if ($badCheckIn.Raw -match "Could not find the function|does not exist") {
  Fail "RPC check_in_ticket tidak ditemukan. Jalankan ulang schema.sql."
}
if ($badCheckIn.Raw -notmatch "Tiket tidak ditemukan") {
  Fail "Respons RPC check_in_ticket tidak sesuai (HTTP $($badCheckIn.Status): $($badCheckIn.Raw))."
}
Write-Ok "RPC check_in_ticket terpasang dan menolak kode tidak dikenal"

# ------------------------------------------------------------
Write-Step "7. Proteksi role (tidak boleh privilege escalation)"
# ------------------------------------------------------------
$rolePatch = Invoke-Supa -Method Patch -Path "/rest/v1/profiles?id=eq.$userId" -Headers $authHeaders -Body @{
  role = "organizer"
}

if ($rolePatch.Status -ge 200 -and $rolePatch.Status -lt 300) {
  Fail "BERBAHAYA: user biasa berhasil mengubah role sendiri. Pastikan revoke/grant kolom profiles di schema.sql sudah dijalankan."
}
Write-Ok "Perubahan role ditolak (HTTP $($rolePatch.Status))"

$profileAfter = Invoke-Supa -Method Get -Path "/rest/v1/profiles?select=role&limit=1" -Headers $authHeaders
$roleAfter = [string](@($profileAfter.Body)[0].role)
if ($roleAfter -ne $roleBefore) {
  Fail "Role berubah dari '$roleBefore' menjadi '$roleAfter'."
}
Write-Ok "Role tetap '$roleAfter'"

# ------------------------------------------------------------
Write-Host "`nSEMUA PEMERIKSAAN LULUS" -ForegroundColor Green
Write-Host "Akun uji: $Email" -ForegroundColor DarkGray
Write-Host "Langkah berikutnya: jalankan aplikasi dengan --dart-define-from-file=supabase.local.json" -ForegroundColor DarkGray
