@echo off

rem REMARKS
rem - restore needs and empty and formatted disk first
rem - best to restore from a bootable usb stick

rem enable extensions and make sure we start in on drive and in directory where this batch resides
setlocal enableextensions enabledelayedexpansion
cd /d "%~dp0"

rem (c) 2015 - 2026 Christian Schüler, christianschueler.at

rem 31.01.2026, v2.0.0
rem ==================
rem - complete rework to capture and stream a disk to google drive

rem 16.03.2016, v1.4.0
rem ==================
rem - added resume after reboot
rem - added needs reboot detection for .NET install
rem - added choice
rem - added firewall rule for node
rem - added more comments
rem - removed unnecessary reboot message

rem 17.07.2015, v1.3.0
rem ==================
rem - added .NET installer
rem - more verbose instructions

rem 20.05.2015, v1.2.0
rem ==================
rem ....

rem --------------------------------------------------------------------------------------------------
rem ------------------------------------------ all parameters ----------------------------------------
rem --------------------------------------------------------------------------------------------------

set BASE_PATH=%~dp0
set BACKUP_VOLUME=C:/
rem enter right image here!!!!!
set BACKUP_IMAGE=HOSTNAME_YYYY-MM-DD_HH-mm-SS.pwim
set BACKUP_RCLONE_STORAGE=google_workspace
set BACKUP_PATH=/Archiv/machine_backups
set WIMLIB_PATH=%BASE_PATH%wimlib
set RCLONE_PATH=%BASE_PATH%rclone

rem --------------------------------------------------------------------------------------------------
rem -------------------------------------------- ask user --------------------------------------------
rem --------------------------------------------------------------------------------------------------

echo Ready to restore this machine from image at Google Cloud.
echo    Capture disk/drive:             %BACKUP_VOLUME%
echo    Backup image file name:         %BACKUP_IMAGE%
echo    Backup name:                    %BACKUP_NAME%
echo    Cloud Backup path using rclone: %BACKUP_RCLONE_STORAGE%:%BACKUP_PATH%
echo.
echo Important: if this is not started as administrator, this script will restart itself 
echo            again as administrator and ask for elevated rights before doing so.
echo.
choice /M "Press Y to continue or N to stop" /c YN
if errorlevel 2 (
  goto :eof
) else if errorlevel 1 (
  echo.
) else if errorlevel 0 (
  goto :eof
)

rem --------------------------------------------------------------------------------------------------
rem --------------------------------- ensure privileged access (UAC) ---------------------------------
rem --------------------------------------------------------------------------------------------------

rem Automatically check & get admin rights
:checkPrivileges
NET FILE 1>NUL 2>NUL
if '%errorlevel%' == '0' ( goto Start ) else ( goto getPrivileges )

:getPrivileges
if '%1'=='ELEV' (shift & goto Start)

setlocal DisableDelayedExpansion
set "batchPath=%~0"
setlocal EnableDelayedExpansion
ECHO Set UAC = CreateObject^("Shell.Application"^) > "%temp%\OEgetPrivileges.vbs"
ECHO UAC.ShellExecute "!batchPath!", "ELEV", "", "runas", 1 >> "%temp%\OEgetPrivileges.vbs"
"%temp%\OEgetPrivileges.vbs"
exit /B

rem --------------------------------------------------------------------------------------------------
rem --------------------------------------- main starting point --------------------------------------
rem --------------------------------------------------------------------------------------------------

:Start

call :RestoreDiskFromGoogle
pause

rem --------------------------------------------------------------------------------------------------
rem ------------------------------------------ end of script -----------------------------------------
rem --------------------------------------------------------------------------------------------------
exit /b

rem ==================================================================================================
rem ==================================================================================================
rem ====================================== SUBROUTINES FOLLOWING =====================================
rem ==================================================================================================
rem ==================================================================================================

rem --------------------------------------------------------------------------------------------------
rem ------------------------------------------- capture disk -----------------------------------------
rem --------------------------------------------------------------------------------------------------

:CaptureDiskToGoogle
echo Capturing image and uploading to Google Cloud...
call "%WIMLIB_PATH%\wimcapture" "%BACKUP_VOLUME%" - "%BACKUP_NAME%" --snapshot | "%RCLONE_PATH%\rclone" --config="%BASE_PATH%rclone.conf" rcat "%BACKUP_RCLONE_STORAGE%:%BACKUP_PATH%/%BACKUP_IMAGE%"
echo Done.
goto :eof

:CaptureDisk
echo Capturing image to disk...
call "%WIMLIB_PATH%\wimcapture" "%BACKUP_VOLUME%" "%BACKUP_IMAGE%" "%BACKUP_NAME%" --snapshot
echo Done.
goto :eof

:CleanUpCaptureDisk
echo Cleaning up...
del %BACKUP_IMAGE%
echo Done.
goto :eof

:RestoreDiskFromGoogle
echo Restoring image from Google Cloud...
call "%RCLONE_PATH%\rclone" --config="%BASE_PATH%rclone.conf" cat "%BACKUP_RCLONE_STORAGE%:%BACKUP_PATH%/%BACKUP_IMAGE%" | "%WIMLIB_PATH%\wimapply" - "%BACKUP_VOLUME%"
echo Done.
goto :eof
