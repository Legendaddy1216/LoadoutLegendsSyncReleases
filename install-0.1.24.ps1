param(
    [string]$Version = "0.0.0",
    [switch]$NoLaunch
)

$ErrorActionPreference = "Stop"

$appName = "Loadout Legends Sync"
$appId = "LoadoutLegendsSync"
$publisher = "Loadout Legends"
$installRoot = Join-Path $env:LOCALAPPDATA "Programs\LoadoutLegendsSync"
$exePath = Join-Path $installRoot "LoadoutLegendsSync.exe"
$payloadZip = Join-Path $PSScriptRoot "app.zip"
$logPath = Join-Path $env:TEMP "LoadoutLegendsSync-install.log"

try {
    "[$(Get-Date -Format o)] Installing $appName $Version" | Set-Content -LiteralPath $logPath -Encoding UTF8

    if (-not (Test-Path -LiteralPath $payloadZip)) {
        throw "Installer payload was missing: $payloadZip"
    }

    Get-Process -Name "LoadoutLegendsSync" -ErrorAction SilentlyContinue |
        Where-Object { $_.Path -ne $null -and $_.Path.StartsWith($installRoot, [StringComparison]::OrdinalIgnoreCase) } |
        Stop-Process -Force

    $staging = Join-Path $env:TEMP ("LoadoutLegendsSync-install-" + [Guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Force -Path $staging | Out-Null

    Expand-Archive -LiteralPath $payloadZip -DestinationPath $staging -Force

    New-Item -ItemType Directory -Force -Path $installRoot | Out-Null
    Copy-Item -Path (Join-Path $staging "*") -Destination $installRoot -Recurse -Force
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "uninstall.ps1") -Destination (Join-Path $installRoot "uninstall.ps1") -Force

    if (-not (Test-Path -LiteralPath $exePath)) {
        throw "Installed executable was not created: $exePath"
    }

    $programs = [Environment]::GetFolderPath("Programs")
    if ([string]::IsNullOrWhiteSpace($programs)) {
        $programs = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
    }

    $desktop = [Environment]::GetFolderPath("DesktopDirectory")
    if ([string]::IsNullOrWhiteSpace($desktop)) {
        $desktop = Join-Path $env:USERPROFILE "Desktop"
    }

    New-Item -ItemType Directory -Force -Path $programs | Out-Null
    New-Item -ItemType Directory -Force -Path $desktop -ErrorAction SilentlyContinue | Out-Null

    $startMenuShortcut = Join-Path $programs "$appName.lnk"
    $desktopShortcut = Join-Path $desktop "$appName.lnk"

    $shell = New-Object -ComObject WScript.Shell
    foreach ($shortcutPath in @($startMenuShortcut)) {
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $exePath
        $shortcut.WorkingDirectory = $installRoot
        $shortcut.IconLocation = "$exePath,0"
        $shortcut.Description = $appName
        $shortcut.Save()
    }

    if (Test-Path -LiteralPath $desktop) {
        $shortcut = $shell.CreateShortcut($desktopShortcut)
        $shortcut.TargetPath = $exePath
        $shortcut.WorkingDirectory = $installRoot
        $shortcut.IconLocation = "$exePath,0"
        $shortcut.Description = $appName
        $shortcut.Save()
    }

    $uninstallRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$appId"
    $uninstallCommand = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$installRoot\uninstall.ps1`""
    if (-not (Test-Path -LiteralPath $uninstallRegPath)) {
        New-Item -Path $uninstallRegPath -Force | Out-Null
    }

    New-ItemProperty -Path $uninstallRegPath -Name "DisplayName" -Value $appName -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $uninstallRegPath -Name "DisplayVersion" -Value $Version -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $uninstallRegPath -Name "Publisher" -Value $publisher -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $uninstallRegPath -Name "InstallLocation" -Value $installRoot -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $uninstallRegPath -Name "DisplayIcon" -Value $exePath -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $uninstallRegPath -Name "UninstallString" -Value $uninstallCommand -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $uninstallRegPath -Name "NoModify" -Value 1 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $uninstallRegPath -Name "NoRepair" -Value 1 -PropertyType DWord -Force | Out-Null

    $uninstallValues = Get-ItemProperty -LiteralPath $uninstallRegPath
    foreach ($requiredValue in @("DisplayName", "DisplayVersion", "Publisher", "InstallLocation", "UninstallString")) {
        if ([string]::IsNullOrWhiteSpace($uninstallValues.$requiredValue)) {
            throw "Could not write uninstall registry value: $requiredValue"
        }
    }

    if (-not $NoLaunch) {
        Start-Process -FilePath $exePath -WorkingDirectory $installRoot
    }

    "[$(Get-Date -Format o)] Install complete: $exePath" | Add-Content -LiteralPath $logPath -Encoding UTF8
}
catch {
    $message = "Loadout Legends Sync failed to install.`r`n`r`n$($_.Exception.Message)`r`n`r`nLog: $logPath"
    $message | Add-Content -LiteralPath $logPath -Encoding UTF8
    try {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show($message, "Loadout Legends Sync Setup", "OK", "Error") | Out-Null
    }
    catch {
        Write-Error $message
    }

    exit 1
}
finally {
    if ($staging -and (Test-Path -LiteralPath $staging)) {
        Remove-Item -LiteralPath $staging -Recurse -Force -ErrorAction SilentlyContinue
    }
}
