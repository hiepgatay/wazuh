<#
.SYNOPSIS
  KB7 - Tan cong mo phong + phong thu Windows (Sysmon / rule 100010-100012 / AR).
.DESCRIPTION
  Mo phong cay tien trinh bang lenh vo hai (echo, ping 127.0.0.1, hostname).
  Khong tao payload, file nen khai thac, reverse shell hay keylogger.
.NOTES
  -Mode Setup : PowerShell Admin.
  -Mode Sim   : Sinh su kien cho rule 100010 va 100011.
#>
[CmdletBinding()]
param(
  [ValidateSet('Setup', 'Sim')]
  [string]$Mode = 'Sim'
)

$ErrorActionPreference = 'Stop'
$LabRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$AgentConf = 'C:\Program Files (x86)\ossec-agent\ossec.conf'
$AgentBin = 'C:\Program Files (x86)\ossec-agent\active-response\bin'
$ToolsDir = 'C:\wazuh-lab\tools'
$SysmonConfigAscii = Join-Path $ToolsDir 'sysmonconfig-lab.xml'
$SysmonConfigRepo = Join-Path $LabRoot 'config\sysmonconfig-lab.xml'
$ArSource = Join-Path $PSScriptRoot 'active-response'
$Marker = 'WAZUH_LAB_WINRAR_CHILD'

function Test-IsAdmin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $p = New-Object Security.Principal.WindowsPrincipal($id)
  return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Ensure-SysmonBinary {
  New-Item -ItemType Directory -Force -Path $ToolsDir | Out-Null
  $local = @(
    (Join-Path $ToolsDir 'Sysmon\Sysmon64.exe'),
    'C:\Windows\Sysmon64.exe',
    'C:\Windows\Sysmon.exe'
  ) | Where-Object { Test-Path $_ } | Select-Object -First 1
  if ($local) { return $local }

  $cmd = Get-Command Sysmon64.exe -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }

  Write-Host "Tai Sysmon (Sysinternals) ve $ToolsDir ..." -ForegroundColor Yellow
  $zip = Join-Path $ToolsDir 'Sysmon.zip'
  Invoke-WebRequest -Uri 'https://download.sysinternals.com/files/Sysmon.zip' -OutFile $zip -UseBasicParsing
  Expand-Archive -Path $zip -DestinationPath (Join-Path $ToolsDir 'Sysmon') -Force
  $bin = Join-Path $ToolsDir 'Sysmon\Sysmon64.exe'
  if (-not (Test-Path $bin)) { throw 'Khong tim thay Sysmon64.exe sau khi giai nen.' }
  return $bin
}

function Install-AgentSysmonChannel {
  if (-not (Test-Path $AgentConf)) {
    Write-Host "Khong thay $AgentConf. Cai Wazuh Agent truoc." -ForegroundColor Yellow
    return
  }
  $text = Get-Content -Path $AgentConf -Raw -Encoding UTF8
  if ($text -match 'Microsoft-Windows-Sysmon/Operational') {
    Write-Host 'Agent da doc kenh Sysmon.' -ForegroundColor Green
    return
  }
  $block = @"

  <localfile>
    <location>Microsoft-Windows-Sysmon/Operational</location>
    <log_format>eventchannel</log_format>
  </localfile>
"@
  $updated = $text -replace '</ossec_config>', ($block + "`r`n</ossec_config>")
  if ($updated -eq $text) { throw 'Khong tim thay </ossec_config> trong ossec.conf cua agent.' }
  Copy-Item $AgentConf "$AgentConf.bak-kb7" -Force
  Set-Content -Path $AgentConf -Value $updated -Encoding UTF8
  Restart-Service WazuhSvc -ErrorAction SilentlyContinue
  Restart-Service Wazuh -ErrorAction SilentlyContinue
  Write-Host 'Da them kenh Sysmon vao agent va restart dich vu.' -ForegroundColor Green
}

function Install-ActiveResponseFiles {
  if (-not (Test-Path $AgentBin)) {
    Write-Host "Khong thay $AgentBin. Bo qua chep Active Response." -ForegroundColor Yellow
    return
  }
  Copy-Item (Join-Path $ArSource 'kill_malware.cmd') $AgentBin -Force
  Copy-Item (Join-Path $ArSource 'kill_malware.ps1') $AgentBin -Force
  Write-Host 'Da chep kill_malware.cmd/.ps1 vao agent.' -ForegroundColor Green
}

function Install-ManagerActiveResponse {
  $mgr = docker ps --format '{{.Names}}' 2>$null | Where-Object { $_ -match 'wazuh\.manager' } | Select-Object -First 1
  if (-not $mgr) {
    Write-Host 'Khong thay container wazuh.manager. Tu dan lab\config\manager-ar-winrar-snippet.xml vao ossec.conf roi restart manager.' -ForegroundColor Yellow
    return
  }
  $has = docker exec $mgr grep -c 'win_kill_malware' /var/ossec/etc/ossec.conf
  if ($has -match '^[1-9]') {
    Write-Host 'Manager da co command win_kill_malware.' -ForegroundColor Green
    return
  }
  $snippet = Join-Path $LabRoot 'config\manager-ar-winrar-snippet.xml'
  $patcher = Join-Path $PSScriptRoot 'kb7-patch-manager.py'
  docker cp $snippet "${mgr}:/tmp/kb7-ar.xml"
  docker cp $patcher "${mgr}:/tmp/kb7-patch-manager.py"
  docker exec $mgr python3 /tmp/kb7-patch-manager.py
  if ($LASTEXITCODE -ne 0) { throw "Khong sua duoc ossec.conf trong $mgr." }
  docker exec $mgr /var/ossec/bin/wazuh-control restart | Out-Null
  Write-Host 'Da them Active Response win_kill_malware va restart manager.' -ForegroundColor Green
}

function Invoke-Setup {
  Write-Host '== KB7 Setup (Sysmon + Agent + Active Response) ==' -ForegroundColor Cyan
  if (-not (Test-IsAdmin)) {
    Write-Host 'Can PowerShell Admin cho buoc Setup / Prepare.' -ForegroundColor Red
    exit 1
  }

  New-Item -ItemType Directory -Force -Path $ToolsDir | Out-Null
  Copy-Item -Force $SysmonConfigRepo $SysmonConfigAscii
  $sysmon = Ensure-SysmonBinary

  Write-Host "Cai/ap Sysmon bang config ASCII: $SysmonConfigAscii"
  & $sysmon -accepteula -i $SysmonConfigAscii
  if ($LASTEXITCODE -ne 0) {
    Write-Host 'Install moi that bai (co the da cai) - thu cap nhat config (-c).' -ForegroundColor Yellow
    & $sysmon -c $SysmonConfigAscii
  }
  Write-Host 'Sysmon OK.' -ForegroundColor Green

  Install-AgentSysmonChannel
  Install-ActiveResponseFiles
  try { Install-ManagerActiveResponse } catch {
    Write-Host ("Manager: " + $_.Exception.Message) -ForegroundColor Yellow
  }

  Write-Host ''
  Write-Host 'Tiep theo:' -ForegroundColor Cyan
  Write-Host '  .\lab\scripts\run-scenarios.ps1 -Scenario load-rules'
  Write-Host '  .\lab\scripts\win-attack-defense.ps1 -Phase Attack'
}

function Invoke-Sim {
  Write-Host '== Tan cong mo phong: WinRAR -> cmd -> Temp (khong ma doc) ==' -ForegroundColor Cyan
  $simDir = 'C:\wazuh-lab\simulate'
  $tempDir = Join-Path $env:TEMP 'wazuh-lab-att'
  New-Item -ItemType Directory -Force -Path $simDir, $tempDir | Out-Null

  $fakeParent = Join-Path $simDir 'WinRAR.exe'
  $markerExe = Join-Path $tempDir 'hostname.exe'
  Copy-Item -Path (Join-Path $env:SystemRoot 'System32\cmd.exe') -Destination $fakeParent -Force
  Copy-Item -Path (Join-Path $env:SystemRoot 'System32\hostname.exe') -Destination $markerExe -Force
  Set-Content -Path (Join-Path $simDir 'README.txt') -Value @(
    'Ban sao cmd.exe dat ten WinRAR.exe de kiem thu rule 100010.',
    'Khong phai WinRAR that va khong phai ma doc.',
    'Xem lab\HUONG-DAN-KICH-BAN-WINDOWS.md'
  ) -Encoding UTF8

  Write-Host '[Red 1/2] WinRAR.exe tao cmd.exe (echo + ping 127.0.0.1) -> rule 100010'
  $inner = 'echo ' + $Marker + ' & ping -n 25 127.0.0.1 >nul'
  $cmdPath = Join-Path $env:SystemRoot 'System32\cmd.exe'
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = $fakeParent
  $psi.Arguments = '/c "' + $cmdPath + '" /c "' + $inner + '"'
  $psi.UseShellExecute = $false
  $psi.CreateNoWindow = $true
  $parent = [System.Diagnostics.Process]::Start($psi)

  Write-Host '[Red 2/2] cmd.exe chay hostname.exe trong %TEMP%\wazuh-lab-att -> rule 100011'
  $shell = Start-Process -FilePath $cmdPath -ArgumentList @('/c', $markerExe) -WindowStyle Hidden -PassThru

  Write-Host 'Doi 20 giay (Agent / Active Response)...' -ForegroundColor Yellow
  Start-Sleep -Seconds 20

  $tree = @($parent.Id, $shell.Id)
  $kids = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object { $tree -contains $_.ParentProcessId })
  $tree += @($kids | ForEach-Object { $_.ProcessId })
  $grand = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object { $tree -contains $_.ParentProcessId })
  foreach ($procId in (@($grand | ForEach-Object { $_.ProcessId }) + $tree | Select-Object -Unique)) {
    Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
  }

  Remove-Item $fakeParent -Force -ErrorAction SilentlyContinue
  Remove-Item $markerExe -Force -ErrorAction SilentlyContinue

  Write-Host ''
  Write-Host '[Blue] Kiem tra Dashboard:' -ForegroundColor Green
  Write-Host '  rule.id:(100010 OR 100011)  /  rule.groups:att_win'
  Write-Host '  Active Response log: C:\wazuh-lab\active-response.log'
  Write-Host 'Huong dan day du: lab\HUONG-DAN-KICH-BAN-WINDOWS.md'
}

if ($Mode -eq 'Setup') { Invoke-Setup } else { Invoke-Sim }