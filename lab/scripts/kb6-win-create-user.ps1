<#
.SYNOPSIS
  KB6 - Tao roi xoa user local lab (Event 4720 / 4726) tren may Windows.
.NOTES
  Can PowerShell Run as Administrator.
  Chi chay tren may lab co Wazuh Agent. User tam: wazuh_lab_demo.
#>
[CmdletBinding()]
param(
  [string]$UserName = 'wazuh_lab_demo',
  [int]$WaitSeconds = 20
)

$ErrorActionPreference = 'Stop'

function Test-IsAdmin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $p = New-Object Security.Principal.WindowsPrincipal($id)
  return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

Write-Host "== KB6 Windows Create Local User (lab) ==" -ForegroundColor Cyan

if (-not (Test-IsAdmin)) {
  Write-Host "Can chay PowerShell Admin (Right-click -> Run as administrator)." -ForegroundColor Red
  Write-Host "Roi: .\lab\scripts\kb6-win-create-user.ps1"
  exit 1
}

try {
  auditpol /set /subcategory:"User Account Management" /success:enable /failure:enable | Out-Null
  Write-Host "Da bat audit: User Account Management (success+failure)." -ForegroundColor Green
} catch {
  Write-Host "Khong set duoc auditpol (tiep tuc): $($_.Exception.Message)" -ForegroundColor Yellow
}

$plain = 'WazuhLab!Demo98'
$secure = ConvertTo-SecureString $plain -AsPlainText -Force

Write-Host "[1] Tao user local: $UserName"
$existing = Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue
if ($existing) {
  Write-Host "    User da ton tai - xoa truoc..." -ForegroundColor Yellow
  Remove-LocalUser -Name $UserName -ErrorAction SilentlyContinue
  Start-Sleep -Seconds 2
}

New-LocalUser -Name $UserName -Password $secure -Description 'NOS Wazuh lab demo user (temporary)' `
  -PasswordNeverExpires -UserMayNotChangePassword -ErrorAction Stop | Out-Null
Write-Host "    Da tao. Doi Event 4720 (~$WaitSeconds s)..." -ForegroundColor Green
Start-Sleep -Seconds $WaitSeconds

Write-Host "[2] Xoa user: $UserName"
Remove-LocalUser -Name $UserName -ErrorAction Stop
Write-Host "    Da xoa. Event 4726 (neu audit bat)." -ForegroundColor Green

Write-Host ""
Write-Host "Event Viewer: Security -> 4720 (created) / 4726 (deleted)" -ForegroundColor Yellow
Write-Host ""
Write-Host "Dashboard (Threat Hunting), loc:" -ForegroundColor Cyan
Write-Host '  data.win.system.eventID:(4720 OR 4726)'
Write-Host '  rule.groups:windows OR rule.groups:win_authentication_failures'
Write-Host '  data.win.eventdata.targetUserName:wazuh_lab_demo'
Write-Host ""
Write-Host "Screenshot goi y: lab\screenshots\08-win-create-user.png"
