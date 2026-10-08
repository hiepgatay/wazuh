<#
.SYNOPSIS
  KB5 - Mo phong dang nhap Windows that bai (Event ID 4625) tren may lab.
.NOTES
  Chi chay tren may Windows co Wazuh Agent do nhom quan ly.
#>
[CmdletBinding()]
param(
  [int]$Attempts = 8,
  [string]$FakeUser = 'nosuchuser_wazuhlab'
)

$ErrorActionPreference = 'Continue'

Write-Host "== KB5 Windows Failed Logon (lab) ==" -ForegroundColor Cyan
Write-Host "May     : $env:COMPUTERNAME"
Write-Host "User gia: $FakeUser"
Write-Host "So lan  : $Attempts"
Write-Host ""

$logonType = @'
using System;
using System.Runtime.InteropServices;
public class WazuhLabLogon {
  [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
  public static extern bool LogonUser(
    string lpszUsername, string lpszDomain, string lpszPassword,
    int dwLogonType, int dwLogonProvider, out IntPtr phToken);
  [DllImport("kernel32.dll", SetLastError = true)]
  public static extern bool CloseHandle(IntPtr hObject);
}
'@

try {
  if (-not ([System.Management.Automation.PSTypeName]'WazuhLabLogon').Type) {
    Add-Type -TypeDefinition $logonType -ErrorAction Stop
  }
} catch {
  Write-Host 'Khong Add-Type duoc. Fallback: net use IPC$.' -ForegroundColor Yellow
}

$domain = $env:COMPUTERNAME
$wrongPass = 'WrongPassLab123!'
$okCount = 0

for ($i = 1; $i -le $Attempts; $i++) {
  Write-Host "[$i/$Attempts] LogonUser $FakeUser@$domain (sai mat khau)..."
  $token = [IntPtr]::Zero
  $usedApi = $false
  try {
    if ([System.Management.Automation.PSTypeName]'WazuhLabLogon'.Type) {
      [void][WazuhLabLogon]::LogonUser($FakeUser, $domain, $wrongPass, 2, 0, [ref]$token)
      if ($token -ne [IntPtr]::Zero) {
        [void][WazuhLabLogon]::CloseHandle($token)
      }
      $usedApi = $true
      $okCount++
    }
  } catch {
    $usedApi = $false
  }

  if (-not $usedApi) {
    $ipc = '\\127.0.0.1\IPC$'
    cmd /c "net use $ipc /user:$FakeUser $wrongPass" 2>$null | Out-Null
    cmd /c "net use $ipc /delete /y" 2>$null | Out-Null
    $okCount++
  }
  Start-Sleep -Seconds 1
}

Write-Host ""
Write-Host "Da thuc hien $okCount lan dang nhap that bai (lab)." -ForegroundColor Green
Write-Host ""
Write-Host "Kiem tra Event Viewer (may Agent):" -ForegroundColor Yellow
Write-Host "  Windows Logs -> Security -> Event ID 4625"
Write-Host ""
Write-Host "Dashboard (Threat Hunting), loc:" -ForegroundColor Cyan
Write-Host '  data.win.system.eventID:4625'
Write-Host '  rule.groups:authentication_failed'
Write-Host '  rule.id:(60104 OR 60105 OR 60106 OR 60107)'
Write-Host ""
Write-Host "Neu khong thay 4625: bat Audit Logon (Local Security Policy -> Audit Policy)." -ForegroundColor Yellow
Write-Host '  auditpol /set /subcategory:"Logon" /failure:enable'
Write-Host "  (can chay PowerShell Admin)"
