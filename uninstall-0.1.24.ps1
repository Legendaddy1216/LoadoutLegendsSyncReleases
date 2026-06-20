$ErrorActionPreference = "Stop"

$appName = "Loadout Legends Sync"
$appId = "LoadoutLegendsSync"
$installRoot = Join-Path $env:LOCALAPPDATA "Programs\LoadoutLegendsSync"

Get-Process -Name "LoadoutLegendsSync" -ErrorAction SilentlyContinue |
    Where-Object { $_.Path -ne $null -and $_.Path.StartsWith($installRoot, [StringComparison]::OrdinalIgnoreCase) } |
    Stop-Process -Force

$programs = [Environment]::GetFolderPath("Programs")
$desktop = [Environment]::GetFolderPath("DesktopDirectory")
Remove-Item -LiteralPath (Join-Path $programs "$appName.lnk") -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $desktop "$appName.lnk") -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$appId" -Recurse -Force -ErrorAction SilentlyContinue

$cleanup = Join-Path $env:TEMP ("LoadoutLegendsSync-uninstall-" + [Guid]::NewGuid().ToString("N") + ".ps1")
@"
Start-Sleep -Milliseconds 500
Remove-Item -LiteralPath '$installRoot' -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath '$cleanup' -Force -ErrorAction SilentlyContinue
"@ | Set-Content -LiteralPath $cleanup -Encoding UTF8

Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$cleanup`"" -WindowStyle Hidden
