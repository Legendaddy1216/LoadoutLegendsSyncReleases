@echo off
setlocal
set "VERSION=0.1.24"
set "BASE=https://raw.githubusercontent.com/Legendaddy1216/LoadoutLegendsSyncReleases/main"
set "WORK=%TEMP%\LoadoutLegendsSync-update-%VERSION%"

if exist "%WORK%" rmdir /s /q "%WORK%"
mkdir "%WORK%" || exit /b 1

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';" ^
  "$base='%BASE%'; $work='%WORK%';" ^
  "Invoke-WebRequest -Uri ($base + '/LoadoutLegendsSync-app-%VERSION%.zip') -OutFile (Join-Path $work 'app.zip');" ^
  "Invoke-WebRequest -Uri ($base + '/install-%VERSION%.ps1') -OutFile (Join-Path $work 'install.ps1');" ^
  "Invoke-WebRequest -Uri ($base + '/uninstall-%VERSION%.ps1') -OutFile (Join-Path $work 'uninstall.ps1');" ^
  "& (Join-Path $work 'install.ps1') -Version '%VERSION%';"

exit /b %ERRORLEVEL%
