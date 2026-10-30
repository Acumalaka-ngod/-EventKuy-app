# EventKuy - verifikasi E2E backend (P0.3 + P0.4)
# Jalankan dari root repo:
#   pwsh -File tool/verify-e2e.ps1
#
# Alur:
#   1. Login attendee dan organizer.
#   2. Checkout event seed dengan voucher EVENTKUY.
#   3. Pastikan tiket dan transaksi tersimpan.
#   4. Pastikan attendee tidak boleh check-in.
#   5. Check-in oleh organizer, lalu pastikan duplikasi ditolak.
#
# Script membuat satu tiket uji baru setiap kali dijalankan.

[CmdletBinding()]
param(
  [string]$Url,
  [string]$AnonKey,
  [string]$ConfigPath,
  [string]$OrganizerEmail,
  [string]$OrganizerPassword,
  [string]$AttendeeEmail,
  [string]$AttendeePassword,
  [string]$EventId = "11111111-1111-4111-8111-000000000001",
  [string]$VoucherCode = "EVENTKUY"
)

$ErrorActionPreference = "Stop"

if ($PSVersionTable.PSVersion.Major -lt 7) {
  throw "Script ini membutuhkan PowerShell 7 (pwsh), bukan Windows PowerShell 5.1."
}

$root = Split-Path -Parent $PSScriptRoot
if (-not $ConfigPath) { $ConfigPath = Join-Path $root "supabase.local.json" }
if (-not (Test-Path $ConfigPath)) {
  throw "File $ConfigPath tidak ditemukan. Salin supabase.local.example.json menjadi supabase.local.json."
}

$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json

if (-not $Url) { $Url = $env:SUPABASE_URL }
if (-not $AnonKey) { $AnonKey = $env:SUPABASE_ANON_KEY }
if (-not $Url) { $Url = $config.SUPABASE_URL }
if (-not $AnonKey) { $AnonKey = $config.SUPABASE_ANON_KEY }

if (-not $OrganizerEmail) { $OrganizerEmail = $config.E2E_ORGANIZER_EMAIL }
if (-not $OrganizerPassword) { $OrganizerPassword = $config.E2E_ORGANIZER_PASSWORD }
if (-not $AttendeeEmail) { $AttendeeEmail = $config.E2E_ATTENDEE_EMAIL }
if (-not $AttendeePassword) { $AttendeePassword = $config.E2E_ATTENDEE_PASSWORD }

if (-not $Url -or -not $AnonKey) {
  throw "SUPABASE_URL / SUPABASE_ANON_KEY belum diisi di $ConfigPath."
}
if (-not $OrganizerEmail -or -not $OrganizerPassword) {
  throw "E2E_ORGANIZER_EMAIL / E2E_ORGANIZER_PASSWORD belum diisi di $ConfigPath."
}
if (-not $AttendeeEmail -or -not $AttendeePassword) {
  throw "E2E_ATTENDEE_EMAIL / E2E_ATTENDEE_PASSWORD belum diisi di $ConfigPath."
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
  apikey         = $script:AnonKey
  "Content-Type" = "application/json"
}

function Get-Session {
  param(
    [Parameter(Mandatory = $true)][string]$Email,
    [Parameter(Mandatory = $true)][string]$Password,
    [Parameter(Mandatory = $true)][string]$Label
  )

  $login = Invoke-Supa -Method Post -Path "/auth/v1/token?grant_type=password" -Headers $jsonHeaders -Body @{
    email    = $Email
    password = $Password
  }

  if ($login.Status -ge 400 -or -not $login.Body.access_token) {
    Fail "Login $Label gagal (HTTP $($login.Status): $($login.Raw))."
  }

  Write-Ok "Login ${Label}: $Email"
  return [pscustomobject]@{
    UserId  = [string]$login.Body.user.id
    Headers = @{
      apikey         = $script:AnonKey
      Authorization  = "Bearer $($login.Body.access_token)"
      "Content-Type" = "application/json"
    }
  }
}

Write-Host "EventKuy E2E backend" -ForegroundColor White
Write-Host "URL: $Url"
Write-Host "Event: $EventId"

# ------------------------------------------------------------
Write-Step "1. Login attendee dan organizer"
# ------------------------------------------------------------
$attendee = Get-Session -Email $AttendeeEmail -Password $AttendeePassword -Label "attendee"
$organizer = Get-Session -Email $OrganizerEmail -Password $OrganizerPassword -Label "organizer"

# ------------------------------------------------------------
Write-Step "2. Checkout dengan voucher $VoucherCode"
# ------------------------------------------------------------
$checkout = Invoke-Supa -Method Post -Path "/rest/v1/rpc/checkout" -Headers $attendee.Headers -Body @{
  p_event_id       = $EventId
  p_voucher_code   = $VoucherCode
  p_payment_method = "GoPay"
}

if ($checkout.Status -ge 400) {
  Fail "Checkout gagal (HTTP $($checkout.Status): $($checkout.Raw))."
}

$ticket = $checkout.Body
$ticketCode = [string]$ticket.ticket_code
$transactionId = [string]$ticket.transaction_id

if (-not $ticketCode) { Fail "Respons checkout tidak berisi ticket_code." }
if ([string]$ticket.status -ne "paid") { Fail "Status tiket setelah checkout: $($ticket.status)." }
Write-Ok "Tiket dibuat: $ticketCode"
Write-Ok "Total: Rp $($ticket.total) (diskon Rp $($ticket.discount))"

# ------------------------------------------------------------
Write-Step "3. Tiket & transaksi tersimpan di Supabase"
# ------------------------------------------------------------
$ticketRead = Invoke-Supa -Method Get -Path "/rest/v1/tickets?select=code,event_id,status&code=eq.$ticketCode" -Headers $attendee.Headers
if ($ticketRead.Status -ge 400 -or @($ticketRead.Body).Count -ne 1) {
  Fail "Tiket tidak terbaca setelah checkout (HTTP $($ticketRead.Status): $($ticketRead.Raw))."
}
Write-Ok "Tiket terbaca oleh attendee: status=$(@($ticketRead.Body)[0].status)"

$transactionRead = Invoke-Supa -Method Get -Path "/rest/v1/transactions?select=id,event_id,status,total&id=eq.$transactionId" -Headers $attendee.Headers
if ($transactionRead.Status -ge 400 -or @($transactionRead.Body).Count -ne 1) {
  Fail "Transaksi tidak terbaca setelah checkout (HTTP $($transactionRead.Status): $($transactionRead.Raw))."
}
Write-Ok "Transaksi terbaca: status=$(@($transactionRead.Body)[0].status)"

# ------------------------------------------------------------
Write-Step "4. RLS: organizer melihat tiket event"
# ------------------------------------------------------------
$organizerRead = Invoke-Supa -Method Get -Path "/rest/v1/tickets?select=code,status&code=eq.$ticketCode" -Headers $organizer.Headers
if ($organizerRead.Status -ge 400 -or @($organizerRead.Body).Count -ne 1) {
  Fail "Organizer tidak bisa melihat tiket event (HTTP $($organizerRead.Status): $($organizerRead.Raw))."
}
Write-Ok "Organizer melihat tiket yang sama"

# ------------------------------------------------------------
Write-Step "5. Attendee tidak boleh check-in"
# ------------------------------------------------------------
$attendeeCheckIn = Invoke-Supa -Method Post -Path "/rest/v1/rpc/check_in_ticket" -Headers $attendee.Headers -Body @{
  p_code = $ticketCode
}

if ($attendeeCheckIn.Status -lt 400 -or $attendeeCheckIn.Raw -notmatch "Hanya organizer event") {
  Fail "Attendee tidak ditolak dengan pesan 'Hanya organizer event' (HTTP $($attendeeCheckIn.Status): $($attendeeCheckIn.Raw))."
}
Write-Ok "Attendee ditolak: $($attendeeCheckIn.Body.message)"

# ------------------------------------------------------------
Write-Step "6. Organizer check-in tiket"
# ------------------------------------------------------------
$organizerCheckIn = Invoke-Supa -Method Post -Path "/rest/v1/rpc/check_in_ticket" -Headers $organizer.Headers -Body @{
  p_code = $ticketCode
}

if ($organizerCheckIn.Status -ge 400 -or -not $organizerCheckIn.Body.ok) {
  Fail "Check-in organizer gagal (HTTP $($organizerCheckIn.Status): $($organizerCheckIn.Raw))."
}
Write-Ok "Check-in berhasil: $($organizerCheckIn.Body.event_title) / $($organizerCheckIn.Body.code)"

# ------------------------------------------------------------
Write-Step "7. Duplikasi check-in ditolak"
# ------------------------------------------------------------
$duplicate = Invoke-Supa -Method Post -Path "/rest/v1/rpc/check_in_ticket" -Headers $organizer.Headers -Body @{
  p_code = $ticketCode
}

if ($duplicate.Status -lt 400 -or $duplicate.Raw -notmatch "sudah pernah check-in") {
  Fail "Duplikasi tidak ditolak dengan pesan yang benar (HTTP $($duplicate.Status): $($duplicate.Raw))."
}
Write-Ok "Duplikasi ditolak: $($duplicate.Body.message)"

$finalTicket = Invoke-Supa -Method Get -Path "/rest/v1/tickets?select=code,status&code=eq.$ticketCode" -Headers $attendee.Headers
$finalStatus = [string](@($finalTicket.Body)[0].status)
if ($finalStatus -ne "checked_in") {
  Fail "Status akhir tiket '$finalStatus', seharusnya 'checked_in'."
}
Write-Ok "Status akhir tiket: $finalStatus"

Write-Host "`nSEMUA PEMERIKSAAN E2E LULUS" -ForegroundColor Green
Write-Host "Tiket uji: $ticketCode" -ForegroundColor DarkGray
Write-Host "Langkah berikutnya: uji tampilan tiket/PDF di aplikasi dan scan kamera." -ForegroundColor DarkGray
