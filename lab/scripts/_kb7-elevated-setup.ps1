# Chay bang Admin: chep Active Response script moi vao Agent
$ErrorActionPreference = 'Stop'
$src = 'C:\wazuh-lab\tools'
$bin = 'C:\Program Files (x86)\ossec-agent\active-response\bin'
Copy-Item -Force (Join-Path $src 'kill_malware.cmd') $bin
Copy-Item -Force (Join-Path $src 'kill_malware.ps1') $bin
Restart-Service WazuhSvc -Force
Write-Host 'Da chep kill_malware.* va restart Wazuh Agent.' -ForegroundColor Green
Write-Host 'Bay gio: mo Thong_bao_LAB.rar trong WinRAR, double-click MO_LAB_kich_hoat.cmd'
Write-Host 'Sau 30s xem C:\wazuh-lab\active-response.log (dong START / da tat PID)'
pause
