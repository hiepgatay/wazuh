<#
.SYNOPSIS
  Ho tro thu nghiem lab Wazuh tren Windows (Nhom 5).
.NOTES
  Chi chay tren moi truong lab cua nhom. Khong nham he thong ben ngoai.
  Huong dan: lab/HUONG-DAN-DEMO-KICH-BAN.md
#>
[CmdletBinding()]
param(
  [ValidateSet(
    'status','fim','ssh','system-file','custom-log','load-rules',
    'win-auth-fail','win-create-user','help'
  )]
  [string]$Scenario = 'help',

  [string]$Target = '',
  [string]$SshUser = 'nosuchuser',
  [int]$Attempts = 10
)

$ErrorActionPreference = 'Stop'
$LabRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$Scripts = $PSScriptRoot

function Get-WazuhManagerName {
  $name = docker ps --format '{{.Names}}' | Where-Object { $_ -match 'wazuh\.manager' } | Select-Object -First 1
  if (-not $name) { throw "Khong tim thay container wazuh.manager. Hay chay docker compose up -d truoc." }
  return $name
}

function Show-Status {
  Write-Host "== Docker compose ps ==" -ForegroundColor Cyan
  Push-Location (Join-Path $LabRoot 'wazuh-docker\single-node')
  docker compose ps
  Pop-Location
  Write-Host "`nDashboard: https://localhost  (admin / 123456)" -ForegroundColor Green
  Write-Host "Huong dan demo: lab\HUONG-DAN-DEMO-KICH-BAN.md" -ForegroundColor Yellow
}

function Invoke-LoadRules {
  $mgr = Get-WazuhManagerName
  $rules = Join-Path $LabRoot 'rules\local_rules.xml'
  if (-not (Test-Path $rules)) { throw "Khong thay $rules" }
  docker cp $rules "${mgr}:/var/ossec/etc/rules/local_rules.xml"
  docker exec $mgr /var/ossec/bin/wazuh-control restart
  Write-Host "Da nap local_rules.xml va restart manager ($mgr)." -ForegroundColor Green
  Write-Host "Rule lab: 100100 (WAZUH_LAB_ALERT), 100110 (passwd/shadow)," -ForegroundColor Cyan
  Write-Host "           100120 (FIM C:\wazuh-lab), 100130 (Win create user)." -ForegroundColor Cyan
}

function Invoke-FimLab {
  $dir = 'C:\wazuh-lab'
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $f = Join-Path $dir 'test.txt'
  Write-Host "== KB2 FIM (Windows) ==" -ForegroundColor Cyan
  Write-Host "[1/3] Tao $f"
  'hello-wazuh-lab' | Set-Content -Path $f -Encoding UTF8
  Start-Sleep -Seconds 3
  Write-Host "[2/3] Sua $f"
  "modified-$(Get-Date -Format o)" | Add-Content -Path $f -Encoding UTF8
  Start-Sleep -Seconds 3
  Write-Host "[3/3] Xoa $f"
  Remove-Item $f -Force
  Write-Host "Xong. Agent Windows phai giam sat $dir (realtime)." -ForegroundColor Green
  Write-Host "Dashboard: rule.groups:syscheck  |  syscheck.path:*wazuh-lab*  |  rule.id:100120" -ForegroundColor Yellow
}

function Invoke-SshBrute {
  Write-Host "== KB1 SSH Brute Force ==" -ForegroundColor Cyan
  if (-not $Target) {
    Write-Host @"
Can IP victim lab. Vi du:
  .\run-scenarios.ps1 -Scenario ssh -Target 192.168.1.50
  .\run-scenarios.ps1 -Scenario ssh -Target 192.168.1.50 -SshUser nosuchuser -Attempts 12

Hoac chay bang tay / WSL / Git Bash:
  bash lab/scripts/kb1-ssh-bruteforce.sh <IP_VICTIM>

Thu cong (thuyet trinh):
  ssh nosuchuser@<IP_VICTIM>
  -> nhap SAI mat khau 8-12 lan

Dashboard: rule.id:(5710 OR 5716 OR 5763 OR 5551)
"@
    return
  }

  $script = Join-Path $LabRoot 'scripts\kb1-ssh-bruteforce.sh'
  if (Get-Command wsl -ErrorAction SilentlyContinue) {
    $wslPath = (wsl wslpath -a "$script" 2>$null)
    if ($LASTEXITCODE -eq 0 -and $wslPath) {
      Write-Host "Chay qua WSL: $wslPath $Target $SshUser $Attempts"
      wsl bash "$wslPath" "$Target" "$SshUser" "$Attempts"
      return
    }
  }
  if (Get-Command bash -ErrorAction SilentlyContinue) {
    bash "$script" "$Target" "$SshUser" "$Attempts"
    return
  }
  Write-Host "Khong tim thay WSL/bash. Hay SSH thu cong toi $Target ($Attempts lan sai mat khau)." -ForegroundColor Yellow
  Write-Host "ssh $SshUser@$Target" -ForegroundColor Green
}

function Invoke-SystemFile {
  Write-Host "== KB3 System file ==" -ForegroundColor Cyan
  Write-Host @"
Kich ban nay chay tren Linux Agent (can sudo):

  sudo bash lab/scripts/kb3-system-file.sh

Hoac thu cong (an toan - chi them comment):
  echo '# wazuh-lab-demo' | sudo tee -a /etc/passwd
  # Doi alert rule 100110, roi:
  sudo sed -i '/# wazuh-lab-demo/d' /etc/passwd

Tren Windows: dung -Scenario win-create-user (Event 4720) thay cho /etc/passwd.

Dashboard: rule.id:100110  |  rule.groups:nos_lab
Can da nap luat: .\run-scenarios.ps1 -Scenario load-rules
"@ -ForegroundColor Yellow
}

function Invoke-CustomLog {
  $mgr = $null
  try { $mgr = Get-WazuhManagerName } catch { $mgr = $null }

  $line = "$(Get-Date -Format 'MMM dd HH:mm:ss') $env:COMPUTERNAME noslab: WAZUH_LAB_ALERT custom detection test"
  Write-Host "== KB4 Custom Rule ==" -ForegroundColor Cyan

  $dir = 'C:\wazuh-lab'
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $logFile = Join-Path $dir 'lab-alerts.log'
  Add-Content -Path $logFile -Value $line -Encoding UTF8
  Write-Host "Da ghi vao $logFile" -ForegroundColor Green
  Write-Host "  (Can localfile theo doi file nay - xem Phu luc A trong HUONG-DAN-DEMO-KICH-BAN.md)"

  try {
    [System.Diagnostics.EventLog]::WriteEntry(
      'Application',
      'WAZUH_LAB_ALERT custom detection test (NOS lab)',
      [System.Diagnostics.EventLogEntryType]::Warning,
      4100
    )
    Write-Host "Da ghi Application Event Log (source Application, ID 4100)." -ForegroundColor Green
  } catch {
    Write-Host "Khong ghi duoc Event Log (bo qua): $($_.Exception.Message)" -ForegroundColor Yellow
  }

  if ($mgr) {
    Write-Host "`nManager: $mgr - logtest offline:" -ForegroundColor Cyan
    Write-Host "  docker exec -it $mgr /var/ossec/bin/wazuh-logtest"
    Write-Host "  Dan: Jan 1 12:00:00 testhost app: WAZUH_LAB_ALERT test message"
    docker exec $mgr bash -lc "echo '$line' >> /var/ossec/logs/active-responses.log" 2>$null
  }

  Write-Host "`nDashboard: rule.id:100100  |  rule.groups:nos_lab" -ForegroundColor Cyan
  Write-Host "Uu tien Linux agent: bash lab/scripts/kb4-custom-rule.sh" -ForegroundColor Yellow
}

function Invoke-WinAuthFail {
  $script = Join-Path $Scripts 'kb5-win-failed-logon.ps1'
  & $script -Attempts $Attempts
}

function Invoke-WinCreateUser {
  $script = Join-Path $Scripts 'kb6-win-create-user.ps1'
  & $script
}

switch ($Scenario) {
  'status'           { Show-Status }
  'load-rules'       { Invoke-LoadRules }
  'fim'              { Invoke-FimLab }
  'ssh'              { Invoke-SshBrute }
  'system-file'      { Invoke-SystemFile }
  'custom-log'       { Invoke-CustomLog }
  'win-auth-fail'    { Invoke-WinAuthFail }
  'win-create-user'  { Invoke-WinCreateUser }
  default {
    Write-Host @"
Cach dung (xem chi tiet: lab\HUONG-DAN-DEMO-KICH-BAN.md):

  .\run-scenarios.ps1 -Scenario status
  .\run-scenarios.ps1 -Scenario load-rules
  .\run-scenarios.ps1 -Scenario ssh -Target <IP_VICTIM>
  .\run-scenarios.ps1 -Scenario fim
  .\run-scenarios.ps1 -Scenario system-file
  .\run-scenarios.ps1 -Scenario custom-log
  .\run-scenarios.ps1 -Scenario win-auth-fail
  .\run-scenarios.ps1 -Scenario win-create-user

Thu tu demo goi y:
  Linux:  status -> load-rules -> ssh -> fim -> system-file -> custom-log
  Windows: status -> load-rules -> fim -> win-auth-fail -> win-create-user -> custom-log
  Chup anh vao lab\screenshots
"@
  }
}
