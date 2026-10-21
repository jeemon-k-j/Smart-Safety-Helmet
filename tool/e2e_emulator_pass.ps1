# End-to-end Android emulator pass for Smart Safety Helmet (no real email).
$ErrorActionPreference = 'Continue'
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$dev = 'emulator-5554'
$shotDir = 'E:\Projects\Academic 2026\Smart-Safety-Helmet\screenshots\e2e'
$base = 'https://smart-safety-helmet-93f6d-default-rtdb.firebaseio.com'
$report = [System.Collections.Generic.List[string]]::new()
$script:controlCount = 0
$script:controlExercised = 0
$script:shotIndex = 0

function Log($msg) { Write-Host $msg; $report.Add($msg) | Out-Null }
function Shot($name) {
  $script:shotIndex++
  $path = Join-Path $shotDir ("{0:D2}-{1}.png" -f $script:shotIndex, $name)
  & $adb -s $dev exec-out screencap -p > $path
  Log "SHOT $path"
  return $path
}
function DumpXml {
  & $adb -s $dev shell uiautomator dump /sdcard/ui.xml | Out-Null
  & $adb -s $dev pull /sdcard/ui.xml "$env:TEMP\ssh-e2e.xml" | Out-Null
  return (Get-Content "$env:TEMP\ssh-e2e.xml" -Raw)
}
function Descs([string]$raw) {
  return ([regex]::Matches($raw, 'content-desc="([^"]+)"') | ForEach-Object { $_.Groups[1].Value }) | Select-Object -Unique
}
function TapBounds([string]$raw, [string]$desc) {
  $script:controlCount++
  $pat = [regex]::Escape($desc)
  if ($raw -match "content-desc=`"$pat`"[^>]*bounds=`"\[(\d+),(\d+)\]\[(\d+),(\d+)\]`"") {
    $cx = [int](([int]$Matches[1] + [int]$Matches[3]) / 2)
    $cy = [int](([int]$Matches[2] + [int]$Matches[4]) / 2)
    & $adb -s $dev shell input tap $cx $cy
    $script:controlExercised++
    Log "TAP ok '$desc' @ $cx,$cy"
    Start-Sleep -Milliseconds 800
    return $true
  }
  Log "TAP miss '$desc'"
  return $false
}
function ExpectDesc([string]$raw, [string]$fragment, [string]$label) {
  if ($raw -match [regex]::Escape($fragment)) {
    Log "PASS $label"
    return $true
  }
  Log "FAIL $label (missing '$fragment')"
  return $false
}
function Put-Status($map) {
  $map['updatedAt'] = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
  $body = $map | ConvertTo-Json -Compress
  Invoke-WebRequest -Method Put -Uri "$base/devices/helmet-001/status.json" -ContentType 'application/json' -Body $body -UseBasicParsing | Out-Null
  Log "RTDB status $body"
}
function Put-Accident($map) {
  if (-not $map.ContainsKey('detectedAt')) {
    $map['detectedAt'] = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
  }
  $body = $map | ConvertTo-Json -Compress
  Invoke-WebRequest -Method Put -Uri "$base/devices/helmet-001/accident.json" -ContentType 'application/json' -Body $body -UseBasicParsing | Out-Null
  Log "RTDB accident $body"
}
function ScrollDown {
  & $adb -s $dev shell input swipe 670 2200 670 900 400
  Start-Sleep -Milliseconds 600
}
function ScrollUp {
  & $adb -s $dev shell input swipe 670 900 670 2200 400
  Start-Sleep -Milliseconds 600
}

New-Item -ItemType Directory -Force -Path $shotDir | Out-Null
Log '=== E2E START ==='

# --- Unavailable / empty nodes ---
Invoke-WebRequest -Method Put -Uri "$base/devices/helmet-001/status.json" -ContentType 'application/json' -Body 'null' -UseBasicParsing | Out-Null
Put-Accident @{ eventId = ''; active = $false; severity = 'low'; cancelled = $false; notificationSent = $false }
Log 'RTDB cleared status for unavailable test'

# Wait for app (caller launches flutter run)
Start-Sleep 6
$raw = DumpXml
$descs = Descs $raw
Log ("UI descs: " + ($descs -join ' | '))
Shot '01-launch'

# If login screen, note controls then rely on auto-login relaunch; if Safety, continue
if ($raw -match 'Sign in') {
  Log 'SCREEN Login'
  $script:controlCount += 4 # email, password, sign in, register toggle
  Shot '02-login'
  TapBounds $raw 'Need an account? Register' | Out-Null
  Start-Sleep 1
  $raw = DumpXml
  ExpectDesc $raw 'Register' 'Login register mode'
  Shot '03-login-register-mode'
  TapBounds $raw 'Already have an account? Sign in' | Out-Null
  Start-Sleep 1
  $raw = DumpXml
  Shot '04-login-signin-mode'
  # Validation: tap Sign in empty
  TapBounds $raw 'Sign in' | Out-Null
  Start-Sleep 1
  $raw = DumpXml
  ExpectDesc $raw 'valid email' 'Login empty validation' | Out-Null
  Shot '05-login-validation'
  Log 'BLOCKED Login typed credentials via adb (Flutter text entry unreliable); using INTEGRATION_EMAIL auto-login session for authenticated screens'
}

# Authenticated Safety
$raw = DumpXml
if ($raw -notmatch 'Safety status|Safety overview|helmet-001') {
  Log 'WAIT for Safety after auto-login'
  Start-Sleep 5
  $raw = DumpXml
}
if ($raw -match 'Safety|helmet-001') {
  Log 'SCREEN Safety'
  Shot '10-safety-unavailable-or-current'
  ExpectDesc $raw 'Unknown' 'Unavailable/unknown when status empty' | Out-Null
  ScrollDown
  Shot '11-safety-scrolled'
  ScrollUp
} else {
  Log 'FAIL Safety screen not reached'
}

# --- Sensor matrix ---
Put-Status @{ alcoholDetected = $true; helmetClipped = $false; ignitionAllowed = $false; ignitionActive = $false; drowsy = $false; warningActive = $false }
Start-Sleep 2
$raw = DumpXml
ExpectDesc $raw 'Detected' 'Alcohol detected UI'
ExpectDesc $raw 'Not clipped' 'Helmet unclipped UI'
ExpectDesc $raw 'Blocked' 'Ignition blocked UI'
Shot '12-safety-alcohol-danger'

Put-Status @{ alcoholDetected = $false; helmetClipped = $true; ignitionAllowed = $true; ignitionActive = $false; drowsy = $false; warningActive = $false }
Start-Sleep 2
$raw = DumpXml
ExpectDesc $raw 'Clear' 'Alcohol clear UI'
ExpectDesc $raw 'Clipped' 'Helmet clipped UI'
ExpectDesc $raw 'Allowed' 'Ignition allowed UI'
Shot '13-safety-clear'

Put-Status @{ alcoholDetected = $false; helmetClipped = $true; ignitionAllowed = $true; ignitionActive = $true; drowsy = $true; warningActive = $true }
Start-Sleep 2
$raw = DumpXml
ExpectDesc $raw 'Active' 'Ignition active UI'
ExpectDesc $raw 'Drowsy' 'Drowsiness detected UI'
Shot '14-safety-drowsy'

# --- Alerts tab (NavigationBar content-desc includes "Tab N of M") ---
$raw = DumpXml
$script:controlCount++
$alertsTapped = $false
if ($raw -match 'content-desc="([^"]*Alerts[^"]*)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"') {
  $cx = [int](([int]$Matches[2] + [int]$Matches[4]) / 2)
  $cy = [int](([int]$Matches[3] + [int]$Matches[5]) / 2)
  & $adb -s $dev shell input tap $cx $cy
  $script:controlExercised++
  $alertsTapped = $true
  Log "TAP ok Alerts @ $cx,$cy"
  Start-Sleep 1
}
if ($alertsTapped) {
  $raw = DumpXml
  Log 'SCREEN Alerts'
  ExpectDesc $raw 'Alert recipients' 'Alerts recipients section'
  Shot '20-alerts'
  ScrollDown
  Shot '21-alerts-scrolled'
  $script:controlCount++
  if (TapBounds $raw 'Add email') {
    Start-Sleep 1
    $raw = DumpXml
    ExpectDesc $raw 'Add alert recipient' 'Add recipient dialog'
    Shot '22-add-recipient-dialog'
    $script:controlCount++
    TapBounds $raw 'Cancel' | Out-Null
    Start-Sleep 1
    Shot '23-alerts-after-dialog-cancel'
  }
}

# Back to Safety
$raw = DumpXml
if ($raw -match 'content-desc="([^"]*Safety[^"]*Tab[^"]*)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"') {
  $cx = [int](([int]$Matches[2] + [int]$Matches[4]) / 2)
  $cy = [int](([int]$Matches[3] + [int]$Matches[5]) / 2)
  & $adb -s $dev shell input tap $cx $cy
  Start-Sleep 1
} else {
  TapBounds $raw 'Safety' | Out-Null
}

# --- Accident countdown + cancel ---
$eid = "acc-e2e-$(Get-Date -Format 'yyyyMMddHHmmss')"
Put-Accident @{
  eventId = $eid
  active = $true
  severity = 'high'
  cancelled = $false
  notificationSent = $false
}
Start-Sleep 2
$raw = DumpXml
ExpectDesc $raw 'Accident alert' 'Accident countdown panel'
ExpectDesc $raw 'Cancel false alert' 'Cancel control visible'
Shot '30-accident-countdown'
$script:controlCount++
if (TapBounds $raw 'Cancel false alert') {
  Start-Sleep 2
  $raw = DumpXml
  ExpectDesc $raw 'Emergency email was not sent' 'Cancel prevents email'
  Shot '31-accident-cancelled'
} else {
  Log 'FAIL Cancel false alert'
}

# --- Accident countdown complete with RECORD_NOTIFICATIONS (no SMTP) ---
$eid2 = "acc-e2e-send-$(Get-Date -Format 'yyyyMMddHHmmss')"
Put-Accident @{
  eventId = $eid2
  active = $true
  severity = 'high'
  cancelled = $false
  notificationSent = $false
}
Log "Waiting 12s for countdown completion ($eid2) with RECORD_NOTIFICATIONS"
Start-Sleep 12
$raw = DumpXml
Shot '32-accident-after-countdown'
if ($raw -match 'Emergency email sent|Notification processed|Phone location|Obtaining phone GPS|Sending emergency|Could not send') {
  Log 'PASS Accident notification preparation path exercised (recorded, not SMTP)'
} else {
  Log 'FAIL Accident post-countdown status message not observed'
  Log ("Descs: " + ((Descs $raw) -join ' | '))
}

# Sign out then (caller may relaunch); capture sign-out once
$raw = DumpXml
ScrollUp
$script:controlCount++
if (TapBounds $raw 'Sign out') {
  Start-Sleep 2
  $raw = DumpXml
  ExpectDesc $raw 'Sign in' 'Sign out returns to login'
  Shot '40-after-signout'
}

# Restore neutral (keep cancelled accident id, inactive)
$ts = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
Put-Status @{
  alcoholDetected = $false
  helmetClipped = $true
  ignitionAllowed = $true
  ignitionActive = $false
  drowsy = $false
  warningActive = $false
}
Put-Accident @{
  eventId = $eid2
  active = $false
  severity = 'high'
  cancelled = $true
  notificationSent = $false
  detectedAt = $ts
}
Log 'RTDB restored to neutral'

Log "CONTROLS discovered≈$script:controlCount exercised=$script:controlExercised shots=$script:shotIndex"
$reportPath = Join-Path $shotDir 'e2e-report.txt'
$report | Set-Content $reportPath
Log "REPORT $reportPath"
