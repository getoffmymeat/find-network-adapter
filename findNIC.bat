@echo off
:: made by @1kinte on discord
title network adapter tool
setlocal enabledelayedexpansion

:: get active nic GUID & classGUID
for /f "usebackq delims=" %%a in (`powershell -NoProfile -Command ^
  "Get-CimInstance Win32_NetworkAdapter | Where-Object { $_.NetConnectionStatus -eq 2 } | Select-Object -First 1 -Property GUID,ClassGuid | ForEach-Object { Write-Output ($_.GUID + '|' + $_.ClassGuid) }"`) do (
    set "adapterInfo=%%a"
)

for /f "tokens=1,2 delims=|" %%a in ("!adapterInfo!") do (
    set "adapterGUID=%%a"
    set "adapterClsGuid=%%b"
)

set "adapterGUID=!adapterGUID:{=!}"
set "adapterGUID=!adapterGUID:}=!"
set "adapterClsGuid=!adapterClsGuid:{=!}"
set "adapterClsGuid=!adapterClsGuid:}=!"

:: searching for matching guid
set "classBase=HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}"
set "matchedKey="
set "driverDesc="

for /f "tokens=*" %%k in ('reg query "%classBase%"') do (
    set "subkey=%%k"
    set "linkageKey=%%k\Linkage"

    reg query "!linkageKey!" >nul 2>&1
    if !errorlevel! == 0 (
        for /f "tokens=3*" %%v in ('reg query "!linkageKey!" /v Bind 2^>nul ^| find /i "{!adapterGUID!}"') do (
            set "matchedKey=%%k"
        )
        for /f "tokens=3*" %%v in ('reg query "!linkageKey!" /v Export 2^>nul ^| find /i "{!adapterGUID!}"') do (
            set "matchedKey=%%k"
        )
    )
)

:: results
if defined matchedKey (
    for /f "tokens=3*" %%d in ('reg query "!matchedKey!" /v DriverDesc 2^>nul ^| find /i "DriverDesc"') do (
        set "driverDesc=%%d %%e"
    )

powershell -Command "Write-Host '=== active network adapter ===' -BackgroundColor Black -ForegroundColor White"
powershell -Command "Write-Host 'name: ' -BackgroundColor Black  -ForegroundColor White -NoNewline; Write-Host '!driverDesc!' -ForegroundColor Magenta" 
    echo.
powershell -Command "Write-Host 'guid: ' -BackgroundColor Black  -ForegroundColor White -NoNewline; Write-Host '{!adapterGUID!}' -ForegroundColor DarkMagenta"  
    echo.
powershell -Command "Write-Host 'registry: ' -BackgroundColor Black  -ForegroundColor White -NoNewline; Write-Host '!matchedKey!' -ForegroundColor DarkRed"  
) else (
    echo No matching registry key found for adapter GUID: {!adapterGUID!}
)

pause
