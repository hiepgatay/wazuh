<#
.SYNOPSIS
  Kich ban tan cong (mo phong) + phong thu Windows — ATTT / Wazuh lab.
.DESCRIPTION
  Prepare : Admin — Sysmon, Agent Sysmon channel, Active Response, goi y load-rules.
  Attack  : Mo phong cay WinRAR -> cmd -> file trong Temp (lenh vo hai).
  Status  : Kiem tra Sysmon, Agent, rule, Docker.
.NOTES
  Khong tao malware, RAR CVE, reverse shell hay keylogger.
  Huong dan: lab\HUONG-DAN-KICH-BAN-WINDOWS.md
#>
[CmdletBinding()]
param(
  [ValidateSet('Prepare', 'Attack', 'Status')]
  [string]$Phase = 'Status'
)

$ErrorActionPreference = 'Stop'
$Kb7 = Join-Path $PSScriptRoot 'kb7-win-sysmon-sim.ps1'

switch ($Phase) {
  'Prepare' {
    Write-Host "== Windows Attack/Defense: PREPARE (Blue Team) ==" -ForegroundColor Cyan
    & $Kb7 -Mode Setup
    Write-Host ""
    Write-Host "Bat buoc: nap luat neu chua nap." -ForegroundColor Yellow
    Write-Host "  .\lab\scripts\run-scenarios.ps1 -Scenario load-rules"
    Write-Host "Roi chay tan cong mo phong:" -ForegroundColor Yellow
    Write-Host "  .\lab\scripts\win-attack-defense.ps1 -Phase Attack"
  }
  'Attack' {
    Write-Host "== Windows Attack/Defense: ATTACK (mo phong Red Team) ==" -ForegroundColor Cyan
    Write-Host "Chi mo phong hanh vi. Khong payload / exploit / reverse shell." -ForegroundColor Yellow
    & $Kb7 -Mode Sim
  }
  'Status' {
    Write-Host "== Windows Attack/Defense: STATUS ==" -ForegroundColor Cyan
    Write-Host "May: $env:COMPUTERNAME"
    $svc = Get-Service -Name 'WazuhSvc', 'Wazuh', 'Sysmon64', 'Sysmon' -ErrorAction SilentlyContinue
    if ($svc) { $svc | Format-Table Name, Status -AutoSize } else { Write-Host "Khong thay dich vu Wazuh/Sysmon." -ForegroundColor Yellow }

    $sysmonLog = Get-WinEvent -ListLog 'Microsoft-Windows-Sysmon/Operational' -ErrorAction SilentlyContinue
    if ($sysmonLog) {
      Write-Host ("Sysmon log: enabled={0} records~{1}" -f $sysmonLog.IsEnabled, $sysmonLog.RecordCount) -ForegroundColor Green
    } else {
      Write-Host "Chua co log Sysmon/Operational (can Prepare bang Admin)." -ForegroundColor Yellow
    }

    try {
      $mgr = docker ps --format '{{.Names}}' 2>$null | Where-Object { $_ -match 'wazuh\.manager' } | Select-Object -First 1
      if ($mgr) {
        Write-Host "Manager: $mgr" -ForegroundColor Green
        docker exec $mgr bash -lc "grep '100010\|100011\|100012' /var/ossec/etc/rules/local_rules.xml | head -8; grep -c win_kill_malware /var/ossec/etc/ossec.conf || true"
      } else {
        Write-Host "Khong thay container wazuh.manager." -ForegroundColor Yellow
      }
    } catch {
      Write-Host "Docker: $($_.Exception.Message)" -ForegroundColor Yellow
    }

    if (Test-Path 'C:\wazuh-lab\active-response.log') {
      Write-Host "`nAR log (cuoi):" -ForegroundColor Cyan
      Get-Content 'C:\wazuh-lab\active-response.log' -Tail 8
    }

    Write-Host "`nHuong dan: lab\HUONG-DAN-KICH-BAN-WINDOWS.md" -ForegroundColor Cyan
    Write-Host "Dashboard loc: rule.groups:att_win   hoac   rule.id:(100010 OR 100011)"
  }
}
