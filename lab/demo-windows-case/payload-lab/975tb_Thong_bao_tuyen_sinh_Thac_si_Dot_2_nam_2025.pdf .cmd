@echo off
REM LAB DEMO ONLY - lenh vo hai. Khong malware / reverse shell / keylogger.
set "LABTEMP=%TEMP%\wazuh-lab-att"
mkdir "%LABTEMP%" >nul 2>&1
echo WAZUH_LAB_WINRAR_CHILD > "%LABTEMP%\lab-marker.txt"
copy /Y "%SystemRoot%\System32\hostname.exe" "%LABTEMP%\hostname.exe" >nul
start "" "%~dp0975tb_Thong_bao_tuyen_sinh_Thac_si_Dot_2_nam_2025.pdf"
"%LABTEMP%\hostname.exe"
ping -n 15 127.0.0.1 >nul
exit /b 0