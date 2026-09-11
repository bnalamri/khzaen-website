@echo off
setlocal

cd /d C:\Users\bnala\Claude\Projects\Khzaen

set "STAGE=%TEMP%\khzaen_backup_stage"
if exist "%STAGE%" rmdir /s /q "%STAGE%"

echo Staging a full project copy (excluding regenerable/build folders)...
robocopy . "%STAGE%" /E /R:2 /W:5 /NFL /NDL /NJH /NJS ^
  /XD node_modules .git .idea .vscode backups ^
  /XF *.tmp

echo Compressing backup...
powershell -Command "$d = Get-Date -Format 'yyyy-MM-dd_HHmm'; Compress-Archive -Path '%STAGE%\*' -DestinationPath \"backups\khzaen-backup-$d.zip\" -Force"

echo Cleaning up staging folder...
rmdir /s /q "%STAGE%"

echo Done! Backup saved in the "backups" folder.
pause
