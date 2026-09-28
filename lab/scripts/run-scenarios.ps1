<#
.SYNOPSIS
  Hỗ trợ thử nghiệm lab Wazuh trên Windows (Nhóm 5).
.NOTES
  Chỉ chạy trên môi trường lab của nhóm. Không nhắm hệ thống bên ngoài.
#>
[CmdletBinding()]
param(
  [ValidateSet('status','fim','custom-log','help')]
  [string]$Scenario = 'help'
)

$ErrorActionPreference = 'Stop'
$LabDir = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
if (-not (Test-Path (Join-Path $PSScriptRoot '..\wazuh-docker\single-node'))) {
  $LabRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
} else {
  $LabRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
}

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
}

function Invoke-FimLab {
  $dir = 'C:\wazuh-lab'
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $f = Join-Path $dir 'fim-test.txt'
  'hello-lab' | Set-Content -Path $f -Encoding UTF8
  Start-Sleep -Seconds 2
  'modified' | Add-Content -Path $f -Encoding UTF8
  Start-Sleep -Seconds 2
  Remove-Item $f -Force
  Write-Host "Da tao/sua/xoa file trong $dir" -ForegroundColor Green
  Write-Host "Neu Agent Windows dang giam sat thu muc nay (FIM), kiem tra Dashboard: rule.groups:syscheck" -ForegroundColor Yellow
  Write-Host "Huong dan them directories FIM: xem HUONG-DAN-CAI-DAT.md" -ForegroundColor Yellow
}

function Invoke-CustomLog {
  $mgr = Get-WazuhManagerName
  $line = "$(Get-Date -Format 'MMM dd HH:mm:ss') $env:COMPUTERNAME noslab: WAZUH_LAB_ALERT custom detection test"
  Write-Host "Manager: $mgr" -ForegroundColor Cyan
  Write-Host "Thu logtest voi dong:" -ForegroundColor Cyan
  Write-Host $line
  Write-Host "`nChay tuong tac:" -ForegroundColor Yellow
  Write-Host "  docker exec -it $mgr /var/ossec/bin/wazuh-logtest"
  Write-Host "Roi dan dong log tren.`n"

  # Ghi vào log manager để dễ kích hoạt nếu có decoder/syslog theo dõi
  docker exec $mgr bash -lc "echo '$line' >> /var/ossec/logs/active-responses.log" 2>$null
  Write-Host "Da thu append log trong container (co the can cau hinh them). Uu tien: dung agent + logger tren endpoint." -ForegroundColor Yellow
  Write-Host "Tren Linux agent: logger 'WAZUH_LAB_ALERT custom detection test'" -ForegroundColor Green
}

switch ($Scenario) {
  'status'     { Show-Status }
  'fim'        { Invoke-FimLab }
  'custom-log' { Invoke-CustomLog }
  default {
    Write-Host @"
Cach dung:
  .\run-scenarios.ps1 -Scenario status
  .\run-scenarios.ps1 -Scenario fim
  .\run-scenarios.ps1 -Scenario custom-log

Thu tu goi y:
  1) status
  2) Nap lab\rules\local_rules.xml len manager
  3) custom-log + fim
  4) Chup anh Dashboard vao lab\screenshots
"@
  }
}
