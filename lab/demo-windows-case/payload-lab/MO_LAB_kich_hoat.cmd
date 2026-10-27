@echo off
REM LAB DEMO ONLY - vo hai.
setlocal
set "LABTEMP=%TEMP%\wazuh-lab-att"
mkdir "%LABTEMP%" >nul 2>&1
echo WAZUH_LAB_WINRAR_CHILD> "%LABTEMP%\lab-marker.txt"
copy /Y "%SystemRoot%\System32\hostname.exe" "%LABTEMP%\hostname.exe" >nul

set "DOC=%~dp0975tb_Thong_bao_tuyen_sinh_Thac_si_Dot_2_nam_2025.pdf"
if not exist "%DOC%" set "DOC=C:\wazuh-lab\demo-case\payload-lab\975tb_Thong_bao_tuyen_sinh_Thac_si_Dot_2_nam_2025.pdf"
if not exist "%DOC%" set "DOC=C:\wazuh-lab\demo-case\payload-lab\975tb_Thong_bao_tuyen_sinh_Thac_si_Dot_2_nam_2025.html"
if exist "%DOC%" (start "" "%DOC%") else (echo Khong tim thay file moi LAB & timeout /t 2 >nul)

"%LABTEMP%\hostname.exe"
ping -n 12 127.0.0.1 >nul
endlocal
exit /b 0