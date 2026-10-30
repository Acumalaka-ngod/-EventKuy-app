# EventKuy - verifikasi akun organizer (P0.2)
# Jalankan dari root repo:
#   pwsh -File tool/verify-organizer.ps1
#
# Script membaca supabase.local.json dan memakai kredensial E2E_*.
# Tidak mencetak password. Prasyarat: SQL promosi organizer sudah dijalankan.

[CmdletBinding()]
param(
  [string]$Url,
  [string]$AnonKey,
  [string]$ConfigPath,
  [string]$OrganizerEmail,
  [string]$OrganizerPassword,
  [string]$AttendeeEmail,
  [string]$AttendeePassword
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
      apikey        = $script:AnonKey
      Authorization = "Bearer $($login.Body.access_token)"
      "Content-Type" = "application/json"
    }
  }
}

function Get-Profile {
  param(
    [Parameter(Mandatory = $true)]$Session,
    [Parameter(Mandatory = $true)][string]$Label
  )

  $result = Invoke-Supa -Method Get -Path "/rest/v1/profiles?select=id,name,role&id=eq.$($Session.UserId)" -Headers $Session.Headers
  if ($result.Status -ge 400) {
    Fail "Gagal membaca profil $Label (HTTP $($result.Status): $($result.Raw))."
  }

  $rows = @($result.Body)
  if ($rows.Count -ne 1) {
    Fail "Profil $Label tidak ditemukan (jumlah baris: $($rows.Count))."
  }
  return $rows[0]
}

function Test-IsOrganizer {
  param(
    [Parameter(Mandatory = $true)]$Session,
    [Parameter(Mandatory = $true)][bool]$Expected,
    [Parameter(Mandatory = $true)][string]$Label
  )

  $result = Invoke-Supa -Method Post -Path "/rest/v1/rpc/is_organizer" -Headers $Session.Headers -Body @{}
  if ($result.Status -ge 400) {
    Fail "RPC is_organizer gagal untuk $Label (HTTP $($result.Status): $($result.Raw))."
  }

  $actual = [bool]$result.Body
  if ($actual -ne $Expected) {
    Fail "is_organizer($Label) = $actual, seharusnya $Expected."
  }
  Write-Ok "is_organizer($Label) = $actual"
}

Write-Host "EventKuy verifikasi organizer" -ForegroundColor White
Write-Host "URL: $Url"

# ------------------------------------------------------------
Write-Step "1. Login organizer & profil"
# ------------------------------------------------------------
$organizer = Get-Session -Email $OrganizerEmail -Password $OrganizerPassword -Label "organizer"
$organizerProfile = Get-Profile -Session $organizer -Label "organizer"
$organizerRole = [string]$organizerProfile.role

if ($organizerRole -notin @("organizer", "admin")) {
  Fail "Role organizer masih '$organizerRole'. Jalankan SQL promosi di Supabase SQL Editor:
  update public.profiles set role = 'organizer'
  where id = (select id from auth.users where email = '$OrganizerEmail');"
}
Write-Ok "Profil organizer: $($organizerProfile.name) / role=$organizerRole"
Test-IsOrganizer -Session $organizer -Expected $true -Label "organizer"

# ------------------------------------------------------------
Write-Step "2. Event milik organizer"
# ------------------------------------------------------------
$ownedResult = Invoke-Supa -Method Get -Path "/rest/v1/events?select=id,title,organizer_id&organizer_id=eq.$($organizer.UserId)&order=date.asc" -Headers $organizer.Headers
if ($ownedResult.Status -ge 400) {
  Fail "Gagal membaca event organizer (HTTP $($ownedResult.Status): $($ownedResult.Raw))."
}

$ownedEvents = @($ownedResult.Body)
if ($ownedEvents.Count -lt 1) {
  Fail "Belum ada event dengan organizer_id = $($organizer.UserId). Jalankan:
  update public.events
  set organizer_id = (select id from auth.users where email = '$OrganizerEmail')
  where id = '11111111-1111-4111-8111-000000000001';"
}

$targetEvent = $ownedEvents | Where-Object { $_.id -eq "11111111-1111-4111-8111-000000000001" } | Select-Object -First 1
if (-not $targetEvent) {
  Fail "Event seed 11111111-1111-4111-8111-000000000001 tidak ditemukan di daftar event organizer."
}
Write-Ok "Event organizer: $($targetEvent.title) ($($targetEvent.id))"

# ------------------------------------------------------------
Write-Step "3. Akses tiket event oleh organizer (RLS)"
# ------------------------------------------------------------
$ticketsResult = Invoke-Supa -Method Get -Path "/rest/v1/tickets?select=code,event_id,status&event_id=eq.$($targetEvent.id)" -Headers $organizer.Headers
if ($ticketsResult.Status -ge 400) {
  Fail "Organizer tidak bisa membaca tiket event (HTTP $($ticketsResult.Status): $($ticketsResult.Raw))."
}
Write-Ok "Organizer bisa membaca tiket event (jumlah: $(@($ticketsResult.Body).Count))"

# ------------------------------------------------------------
Write-Step "4. Akun attendee tetap bukan organizer"
# ------------------------------------------------------------
$attendee = Get-Session -Email $AttendeeEmail -Password $AttendeePassword -Label "attendee"
$attendeeProfile = Get-Profile -Session $attendee -Label "attendee"
$attendeeRole = [string]$attendeeProfile.role

if ($attendeeRole -ne "pengguna") {
  Fail "Role attendee '$attendeeRole', seharusnya 'pengguna'."
}
Write-Ok "Profil attendee: $($attendeeProfile.name) / role=$attendeeRole"
Test-IsOrganizer -Session $attendee -Expected $false -Label "attendee"

Write-Host "`nSEMUA PEMERIKSAAN ORGANIZER LULUS" -ForegroundColor Green
Write-Host "Langkah berikutnya: login organizer di aplikasi, buka Dashboard Organizer dan Scan QR." -ForegroundColor DarkGray
