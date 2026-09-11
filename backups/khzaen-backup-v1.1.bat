@echo off
setlocal enabledelayedexpansion

set "PROJECT=C:\Users\bnala\Claude\Projects\Khzaen"
cd /d "%PROJECT%" || (echo ERROR: project folder not found: %PROJECT% & pause & exit /b 1)

set "BACKUPDIR=%PROJECT%\backups"
set "STAGE=%TEMP%\khzaen_backup_stage"
if not exist "%BACKUPDIR%" mkdir "%BACKUPDIR%"
if exist "%STAGE%" rmdir /s /q "%STAGE%"

rem Get a locale-safe timestamp from PowerShell instead of slicing %date%/%time%,
rem which breaks on non-US date formats.
for /f "usebackq delims=" %%i in (`powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmm"`) do set "DATESTAMP=%%i"

set "LOGFILE=%BACKUPDIR%\backup-log-%DATESTAMP%.txt"
set "ZIPNAME=khzaen-backup-%DATESTAMP%.zip"
set "ZIPPATH=%BACKUPDIR%\%ZIPNAME%"

echo ================================================
echo  Khzaen Website - Full Backup
echo  Started: %date% %time%
echo ================================================
echo.

echo [1/4] Staging a full project copy (excluding regenerable/build folders)...
robocopy "%PROJECT%" "%STAGE%" /E /R:2 /W:5 /NFL /NDL /NJH /TEE ^
  /XD node_modules .git .idea .vscode backups ^
  /XF *.tmp ^
  /LOG:"%LOGFILE%"

set "RC=%ERRORLEVEL%"
rem Robocopy exit codes 0-7 are all "success" variants (bit flags for copied/
rem extra/mismatched files). 8+ means real errors - some files could not be
rem copied (permissions, locked files, etc).
if %RC% GEQ 8 (
  echo.
  echo *** BACKUP FAILED *** robocopy reported errors (exit code %RC%^).
  echo See log: %LOGFILE%
  goto :fail
)
echo Robocopy OK (exit code %RC%, this is normal for robocopy^).

echo.
echo [2/4] Compressing backup...
if exist "%ZIPPATH%" del /f /q "%ZIPPATH%"

rem IMPORTANT: Compress-Archive -Path 'folder\*' silently SKIPS hidden files
rem (e.g. .gitignore, .cpanel.yml) because the wildcard expansion doesn't
rem include hidden items by default. We use Get-ChildItem -Force to make sure
rem nothing gets silently dropped - .cpanel.yml especially, since losing it
rem would break the Bluehost auto-deploy config with no warning.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop'; try { $items = Get-ChildItem -Path '%STAGE%' -Force; Compress-Archive -Path $items.FullName -DestinationPath '%ZIPPATH%' -CompressionLevel Optimal -Force; exit 0 } catch { Write-Host ('COMPRESS ERROR: ' + $_.Exception.Message); exit 1 }"

if errorlevel 1 (
  echo.
  echo *** BACKUP FAILED *** could not create the zip archive.
  goto :fail
)

echo.
echo [3/4] Verifying the backup archive...
rem Khzaen is a small static site (index.html, styles.css, script.js,
rem .gitignore, .cpanel.yml, etc.) - a handful of files, not hundreds - so
rem the "suspiciously small" threshold is much lower than a full app project.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop'; try { Add-Type -AssemblyName System.IO.Compression.FileSystem; $z=[System.IO.Compression.ZipFile]::OpenRead('%ZIPPATH%'); $n=$z.Entries.Count; $z.Dispose(); if ($n -lt 3) { Write-Host \"Only $n entries found in the archive - suspiciously small, treating as failure.\"; exit 1 }; Write-Host \"$n files verified inside the archive.\"; exit 0 } catch { Write-Host ('VERIFY ERROR: ' + $_.Exception.Message); exit 1 }"

if errorlevel 1 (
  echo.
  echo *** BACKUP FAILED *** the archive could not be verified.
  goto :fail
)

for %%A in ("%ZIPPATH%") do set "ZIPSIZE=%%~zA"
echo Archive size: %ZIPSIZE% bytes

echo.
echo [4/4] Cleaning up staging folder...
rmdir /s /q "%STAGE%"

echo.
echo ================================================
echo  BACKUP SUCCEEDED
echo  File: %ZIPPATH%
echo  Log:  %LOGFILE%
echo ================================================
pause
exit /b 0

:fail
if exist "%STAGE%" rmdir /s /q "%STAGE%"
echo.
echo Backup did NOT complete successfully. Check the messages above and: %LOGFILE%
pause
exit /b 1
