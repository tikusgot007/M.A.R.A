@echo off
REM =====================================================================
REM  enable-openssh.bat  -  run ON THE TARGET PC (double-click it there).
REM  Installs OpenSSH Server, places the driver machine's public key,
REM  opens port 22 to the local subnet, and logs every step to D:\<name>.log
REM  so the driving machine can read it over the share.
REM
REM  BEFORE HANDING OVER: set PUBKEY and TARGET below.
REM  Shape is the one that worked in the field; the TARGET guard is added
REM  so a mis-click on the driving PC cannot install sshd on the wrong box.
REM =====================================================================

setlocal EnableExtensions
set "TARGET=AULIA-DP1"
set "PUBKEY=ssh-ed25519 AAAA...replace-me hermes@driver-pc"
set "TAG=hermes@driver-pc"

set "SETUPDIR=%SystemDrive%\ssh-setup"
set "SELF=%~nx0"
set "SRC=%~dp0"

if /i not "%COMPUTERNAME%"=="%TARGET%" goto wrongpc

net session >nul 2>&1
if %errorlevel% neq 0 goto elevate
goto run

:wrongpc
echo.
echo PERHATIAN: komputer ini bernama %COMPUTERNAME%, bukan %TARGET%.
echo Script ini untuk %TARGET%. Dibatalkan - tidak ada yang diubah.
pause
exit /b 1

:elevate
REM Elevated from a mapped drive? The elevated token has no drive mappings,
REM so stage the script locally first and elevate the local copy.
echo.
echo Menyalin file ke %SETUPDIR% ...
if not exist "%SETUPDIR%" mkdir "%SETUPDIR%"
copy /y "%~f0" "%SETUPDIR%\" >nul 2>&1
if not exist "%SETUPDIR%\%SELF%" echo GAGAL menyalin file ke %SETUPDIR%
echo Meminta izin Administrator - klik Yes pada kotak UAC ...
powershell -NoProfile -Command "Start-Process -FilePath '%SETUPDIR%\%SELF%' -Verb RunAs"
echo.
echo Kalau kotak UAC tidak muncul: klik kanan file ini, pilih Run as administrator.
pause
exit /b

:run
REM Start the log on a drive the driving machine can read; fall back locally.
set "LOG=D:\enable-openssh.log"
>>"%LOG%" echo. 2>nul
if not exist "%LOG%" set "LOG=%SETUPDIR%\enable-openssh.log"

cd /d "%SETUPDIR%"
>"%LOG%" echo ==================================================
>>"%LOG%" echo  enable-openssh.bat  %DATE% %TIME%
>>"%LOG%" echo ==================================================

call :log "PC   : %COMPUTERNAME%"
call :log "User : %USERNAME%"
call :log "Dir  : %SETUPDIR%"
call :log "Dijalankan dari : %SRC%"

REM --- diagnostics first: they decide whether PowerShell may be used later ---
call :log "=== 0/7  Diagnostik ==="
>>"%LOG%" echo --- whoami ---
whoami >>"%LOG%" 2>&1
>>"%LOG%" echo --- where powershell ---
where powershell >>"%LOG%" 2>&1
>>"%LOG%" echo --- tes powershell ---
powershell -NoProfile -Command "Get-Date" >>"%LOG%" 2>&1
call :log "   powershell exit code: %errorlevel%"

call :log "=== 1/7  Pasang OpenSSH Server (lama: 2-5 menit) ==="
dism /online /add-capability /capabilityname:OpenSSH.Server~~~~0.0.1.0 >>"%LOG%" 2>&1
call :log "   dism exit code: %errorlevel% (0=ok, 3010=perlu reboot)"

call :log "=== 2/7  Service sshd ==="
sc config sshd start= auto >>"%LOG%" 2>&1
call :log "   sc config exit code: %errorlevel%"
sc start sshd >>"%LOG%" 2>&1
call :log "   sc start exit code: %errorlevel% (START_PENDING itu normal)"
sc query sshd >>"%LOG%" 2>&1

REM DefaultShell left at the Windows default (cmd.exe) on purpose: only set it
REM to PowerShell after the diagnostic above proves PowerShell runs here.

call :log "=== 3/7  Public key untuk Administrator ==="
if not exist "%ProgramData%\ssh" mkdir "%ProgramData%\ssh"
findstr /c:"%TAG%" "%ProgramData%\ssh\administrators_authorized_keys" >nul 2>&1
if errorlevel 1 >>"%ProgramData%\ssh\administrators_authorized_keys" echo %PUBKEY%
icacls "%ProgramData%\ssh\administrators_authorized_keys" /inheritance:r /grant *S-1-5-32-544:F /grant *S-1-5-18:F >>"%LOG%" 2>&1
call :log "   administrators_authorized_keys siap"

call :log "=== 4/7  Public key untuk akun ini ==="
if not exist "%USERPROFILE%\.ssh" mkdir "%USERPROFILE%\.ssh"
findstr /c:"%TAG%" "%USERPROFILE%\.ssh\authorized_keys" >nul 2>&1
if errorlevel 1 >>"%USERPROFILE%\.ssh\authorized_keys" echo %PUBKEY%
call :log "   %USERPROFILE%\.ssh\authorized_keys siap"

call :log "=== 5/7  Firewall port 22 (subnet lokal) ==="
netsh advfirewall firewall delete rule name="OpenSSH Server (sshd)" >>"%LOG%" 2>&1
netsh advfirewall firewall add rule name="OpenSSH Server (sshd)" dir=in action=allow protocol=TCP localport=22 remoteip=localsubnet >>"%LOG%" 2>&1
call :log "   netsh exit code: %errorlevel%"

call :log "=== 6/7  Restart dan cek ==="
sc stop sshd >>"%LOG%" 2>&1
ping -n 4 127.0.0.1 >nul
sc start sshd >>"%LOG%" 2>&1
ping -n 4 127.0.0.1 >nul
sc query sshd | findstr /i "STATE" >>"%LOG%" 2>&1

call :log "=== 7/7  Ringkasan ==="
call :log "Nama PC : %COMPUTERNAME%"
call :log "Akun    : %USERNAME%"
>>"%LOG%" echo --- port 22 yang LISTENING ---
netstat -ano | findstr /i "LISTENING" | findstr ":22" >>"%LOG%" 2>&1
>>"%LOG%" echo --- alamat IPv4 ---
ipconfig | findstr /i "ipv4" >>"%LOG%" 2>&1
>>"%LOG%" echo ===== selesai %DATE% %TIME% =====

echo.
echo =============== ISI LOG (%LOG%) ===============
type "%LOG%"
echo.
echo Kirim file %LOG% ke Hermes, atau bilang saja - Hermes bisa baca sendiri.
pause
exit /b

:log
echo %~1
>>"%LOG%" echo %~1
exit /b
