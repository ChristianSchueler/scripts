@echo off

rem enable extensions and make sure we start in directory where this batch resides
setlocal enableextensions enabledelayedexpansion
cd /d "%~dp0"

rem (c) 2015 - 2016 Wetouch, www.wetouch.at

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

rem TODO
rem - add firewall rule for node!!!
rem -add ffmpeg
REM ffmpeg and ffprobe
REM fluent-ffmpeg requires ffmpeg >= 0.9 to work. It may work with previous versions but several features won't be available (and the library is not tested with lower versions anylonger).
REM If the FFMPEG_PATH environment variable is set, fluent-ffmpeg will use it as the full path to the ffmpeg executable. Otherwise, it will attempt to call ffmpeg directly (so it should be in your PATH). You must also have ffprobe installed (it comes with ffmpeg in most distributions). Similarly, fluent-ffmpeg will use the FFPROBE_PATH environment variable if it is set, otherwise it will attempt to call it in the PATH.
REM Most features should work when using avconv and avprobe instead of ffmpeg and ffprobe, but they are not officially supported at the moment.
REM Windows users: most probably ffmpeg and ffprobe will not be in your %PATH, so you must set %FFMPEG_PATH and %FFPROBE_PATH.
rem -rename hub-install to something like kiosk mode
rem -install mongodb
rem -install nircmd
rem -install imagemagick

REM 7. services.msc starten und Service "Touch screen keyboard and handwriting panel" stoppen und 
REM in Eigenschaften auf "Disabled" stellen
REM 8. In Stift- und Fingereingabe Einstellungen "Bei Berührung des Bildschirms visualles Feedback anzeigen" deaktivieren.
REM 9. host/enable-kiosk-mode.bat starten
REM - vorher sicherstellen, dass Username und Passwort in der Datei korrekt sind (Media / media)
REM - Achtung: ab jetzt startet der PC keinen Explorer mehr, sondern nur noch die Applikation
REM 10. Neu starten

rem this is for continuing after restart
rem ********************************************************
REM @echo off
REM call :Resume
REM goto %current%
REM goto :eof

REM :one
REM ::Add script to Run key
REM reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Run /v %~n0 /d %~dpnx0 /f
REM echo two >%~dp0current.txt
REM echo -- Section one --
REM pause
REM shutdown -r -t 0
REM goto :eof

REM :two
REM echo three >%~dp0current.txt
REM echo -- Section two --
REM pause
REM shutdown -r -t 0
REM goto :eof

REM :three
REM ::Remove script from Run key
REM reg delete HKCU\Software\Microsoft\Windows\CurrentVersion\Run /v %~n0 /f
REM del %~dp0current.txt
REM echo -- Section three --
REM pause
REM goto :eof

REM :resume
REM if exist %~dp0current.txt (
    REM set /p current=<%~dp0current.txt
REM ) else (
    REM set current=one
REM )
rem ********************************************************

echo Ready to install the Wetouch Hub, (c) 2014-2015 Wetouch, www.wetouch.at.
echo Dependencies will be installed for x64 based systems.
rem echo Press Ctrl-C to cancel, any other key to continue.
rem echo
rem echo IMPORTANT: This installer might automatically reboot the machine without asking.
rem echo            Please start this installer again after reboot to make sure the 
rem echo            installation will be finished.
echo.

rem --------------------------------------------------------------------------------------------------
rem --------------------------------- ensure privileged access (UAC) ---------------------------------
rem --------------------------------------------------------------------------------------------------

rem Automatically check & get admin rights
:checkPrivileges
NET FILE 1>NUL 2>NUL
if '%errorlevel%' == '0' ( goto StartInstallation ) else ( goto getPrivileges )

:getPrivileges
if '%1'=='ELEV' (shift & goto StartInstallation)

setlocal DisableDelayedExpansion
set "batchPath=%~0"
setlocal EnableDelayedExpansion
ECHO Set UAC = CreateObject^("Shell.Application"^) > "%temp%\OEgetPrivileges.vbs"
ECHO UAC.ShellExecute "!batchPath!", "ELEV", "", "runas", 1 >> "%temp%\OEgetPrivileges.vbs"
"%temp%\OEgetPrivileges.vbs"
exit /B

:StartInstallation

rem --------------------------------------------------------------------------------------------------
rem --------------------------------------- installation resume --------------------------------------
rem --------------------------------------------------------------------------------------------------

rem first check if we are resuming a previous install
call :CheckResume
goto %current%

:Resume
::remove installer from autorun and remove resume.txt. then continue installation (i.e. simply start it over)
reg delete HKCU\Software\Microsoft\Windows\CurrentVersion\Run /v %~n0 /f
del "%~dp0resume.txt"
goto FirstStart

rem this is the first start of the installation, so no resume
:FirstStart

rem --------------------------------------------------------------------------------------------------
rem ----------------------------------- installation configuration -----------------------------------
rem --------------------------------------------------------------------------------------------------

set BASE_PATH=%~d0\Wetouch
set HUB_PATH=%BASE_PATH%\hub
set BACKUP_PATH=%BASE_PATH%\_backup
set INCOMING_PATH=%BASE_PATH%\_incoming
set TEMP_PATH=%BASE_PATH%\_temp
set DB_PATH=%HUB_PATH%\db\data

inifile.exe setup.ini [Setup]> tmp.bat
call tmp.bat
del tmp.bat

echo Project to be installed: %HUB_VERSION:~0,-4%
echo.

rem ET /P ANSWER=Click Y to continue or N to stop (Y/N)
choice /M "Press Y to continue or N to stop" /c YN
if errorlevel 2 (
  exit /b
) else if errorlevel 1 (
	echo.
	echo Starting installation.
) else if errorlevel 0 (
  exit /b
)

rem pause

echo Installing the Wetouch Hub...
call :killHost
if DEFINED CHROME_VERSION (
	call :DeInstallChrome
	call :InstallChrome
)
if DEFINED DOTNET_VERSION (
	call :InstallDotNet
)
if DEFINED POWERSHELL_VERSION (
	call :InstallPowerShell	
)
call :EnsureDirs
call :Backup
if DEFINED NODE_VERSION (
	Call :DeInstallNode
	call :InstallNode
)

if DEFINED IE_VERSION (
	call :InstallIE11
)
if DEFINED Enable-IE11-Grassfish (
	call :EnableIE11Grassfish
)
if DEFINED CompleteReinstall (
	call :CompleteReinstall
)
call :InstallHub
if DEFINED HostAutostart (
	call :CreateHostAutostart
)
if DEFINED PinToTaskbar (
	call :PinToTaskbar
)
call :CleanUp
echo Wetouch Hub installed.
rem echo Press any key to restart and finish the installation. Press Ctrl-C to restart later manually.
echo.
pause
rem call :RestartWindows
exit /b

rem --------------------------------------------------------------------------------------------------
rem ----------------------------------- installation of components -----------------------------------
rem --------------------------------------------------------------------------------------------------
:killHost
echo Killing host.exe
taskkill /im host.exe /f /T
echo Done.
goto :eof
rem install latest PowerShell
:InstallPowerShell
echo Updating PowerShell if necessary...
call %POWERSHELL_VERSION% /quiet /warnrestart
echo Done.
goto :eof

rem make sure all directories exist
:EnsureDirs
echo Creating Wetouch Hub directory structure...
mkdir %BASE_PATH%
mkdir %HUB_PATH%
mkdir %BACKUP_PATH%
mkdir %INCOMING_PATH%
mkdir %TEMP_PATH%
Echo Done.
goto :eof

rem create backup of HUB folder
:Backup
for /f "delims=" %%a in ('wmic OS Get localdatetime  ^| find "."') do set dt=%%a
set YYYY=%dt:~0,4%
set MM=%dt:~4,2%
set DD=%dt:~6,2%
set HH=%dt:~8,2%
set Min=%dt:~10,2%
set Sec=%dt:~12,2%
set stamp=%YYYY%-%MM%-%DD%_%HH%-%Min%-%Sec%
set BACKUP_ZIP=%BACKUP_PATH%\%stamp%_backup.zip
echo Creating backup %BACKUP_ZIP%...
powershell.exe -nologo -noprofile -command "& { Add-Type -A 'System.IO.Compression.FileSystem'; [IO.Compression.ZipFile]::CreateFromDirectory('%HUB_PATH%', '%BACKUP_ZIP%'); }"
echo Done.
goto :eof

:DeInstallNode
echo Removing Node...
wmic product where name="Node.js" call uninstall /nointeractive
rem install Node JS
echo Done.
goto :eof
:InstallNode
echo Installing node...
msiexec.exe /i %NODE_VERSION% /qn
echo Done.
call :NodeFirewallRule
goto :eof

:DeInstallChrome
echo Removing Current Chrome Installation
for /f "tokens=2*" %%a in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\MICROSOFT\WINDOWS\CurrentVersion\Uninstall\Google Chrome" /v UninstallString') do set "uninstall=%%~b"
echo "%uninstall% --force-uninstall
echo Done.
goto :eof

rem install Chrome Web Browser
:InstallChrome
echo Installing Chrome...
call %CHROME_VERSION% /silent /install
echo Done.
goto :eof

:CompleteReinstall
echo Removing Current Hub Folder
rmdir %BASE_PATH%\hub /s /q
mkdir %HUB_PATH%
echo Done.
goto :eof

rem extract Wetouch Hub contents into destination folder
:InstallHub
echo Extracting and copying Wetouch Hub and project %HUB_VERSION:~0,-4%...
if exist "%TEMP_PATH%\hub" (
	rmdir /s /q "%TEMP_PATH%\hub"
)
powershell.exe -nologo -noprofile -command "& { Add-Type -A 'System.IO.Compression.FileSystem'; [IO.Compression.ZipFile]::ExtractToDirectory('%HUB_VERSION%', '%TEMP_PATH%\hub'); }"
robocopy "%TEMP_PATH%\hub" %HUB_PATH% /e /nfl /ndl /njh /njs
echo Done.
goto :eof

rem add an autostart entry for host.exe
:CreateHostAutostart
echo Activating Wetouch Host at startup...
powershell.exe -nologo -noprofile -command "& { $objShell = New-Object -ComObject ('WScript.Shell'); $objShortCut = $objShell.CreateShortcut([environment]::getfolderpath('Startup') + '\Wetouch Host.lnk'); $objShortCut.TargetPath='%HUB_PATH%\backend\host\host.exe'; $objShortCut.Save(); }"
echo Done.
goto :eof

rem pin host.exe to taskbar
:PinToTaskbar
echo Pinning Wetouch Hub Host to taskbar...
powershell.exe -nologo -noprofile -command "& { $o = new-object -com Shell.Application; $file = $o.NameSpace('%HUB_PATH%\backend\host').ParseName('host.exe'); $file.InvokeVerb('taskbarpin'); }"
rem $sa = new-object -c shell.application
rem $pn = $sa.namespace($env:windir).parsename('notepad.exe')
rem $pn.invokeverb('taskbarpin')
rem %AppData%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar
rem $o.Namespace(“c:\windows”).ParseName(“regedit.exe”).InvokeVerb(“taskbarunpin”)
rem powershell.exe -nologo -noprofile -command "& { Add-Type -A 'System.IO.Compression.FileSystem'; [IO.Compression.ZipFile]::ExtractToDirectory('%HUB_VERSION%', '%TEMP_PATH%\hub'); }"
rem powershell.exe -nologo -noprofile -command "& { $objShell = New-Object -ComObject ('WScript.Shell'); $objShortCut = $objShell.CreateShortcut([environment]::getfolderpath('Startup') + '\Wetouch Host.lnk'); $objShortCut.TargetPath='%HUB_PATH%\host\host.exe'; $objShortCut.Save(); }"
echo Done.
goto :eof

rem enabled IE11 for grassfish player
:EnableIE11Grassfish
echo Enabling IE11 Support for Grassfish Player...
reg add "HKLM\SOFTWARE\Wow6432Node\Microsoft\Internet Explorer\MAIN\FeatureControl\FEATURE_BROWSER_EMULATION" /v player.exe /t REG_DWORD /d 0x00002af9 /f
echo Done.
goto :eof

rem install Internet Explorer 11
:InstallIE11
echo Updating to Internet Explorer 11...
call %IE_VERSION% /quiet /norestart /update-no
echo Done.
goto :eof

rem set autorun for this script, create resume marker and restart windows
:RestartAndResume
echo Reboot needed. Scheduling resume and rebooting...
reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Run /v %~n0 /d %~dpnx0 /f
echo Resume >"%~dp0resume.txt"
echo Done.
call :RestartWindows
goto :eof

rem install the .NET framework with given version
:InstallDotNet
echo Upgrading .NET Framework if necessary...
call %DOTNET_VERSION% /q /norestart
if %errorlevel% equ 1641 call :RestartAndResume
if %errorlevel% equ 3010 call :RestartAndResume
echo Done.
goto :eof

rem remove temporary files and folder
:CleanUp
echo Cleaning up...
rd "%TEMP_PATH%" /s /q
echo Done.
goto :eof

rem TODO this is only for reference
:InstallMongoDB
echo Installing MongoDB...
rem C:\Program Files\MongoDB\Server\3.0\
msiexec.exe /q /i %MONGO_DB_VERSION% INSTALLLOCATION="C:\mongodb" ADDLOCAL="all"
mkdir "%DB_PATH%"
rem C:\mongodb\bin\mongod.exe --dbpath "%DB_PATH%" --bind_ip 127.0.0.1
echo Done.
goto :eof

rem force Windows to restart immediately
:RestartWindows
echo Restarting Windows...
shutdown /r /f /t 0
echo Done.
exit /b

rem --------------------------------------------------------------------------------------------------
rem -------------------------------------- install resume logic --------------------------------------
rem --------------------------------------------------------------------------------------------------

rem see if this is a resume
:CheckResume
if exist "%~dp0resume.txt" (
	echo Resuming a previous installation.
    set /p current=<%~dp0resume.txt
) else (
    set current=FirstStart
)
goto :eof

rem create a firewall rule for Node JS
:NodeFirewallRule
echo Creating firewall rule for Node JS...
netsh advfirewall firewall show rule name=%Node.js: Server-side JavaScript% >nul
if not ERRORLEVEL 1 (
    rem Rule %RULE_NAME% already exists.
    echo Firewall rule already exists.
) else (
    rem echo Rule %RULE_NAME% does not exist. Creating...
	if exist "%ProgramFiles(x86)%\nodejs\node.exe" (
		netsh advfirewall firewall add rule name="Node.js: Server-side JavaScript" dir=in action=allow program="%ProgramFiles(x86)%\nodejs\node.exe" enable=yes
	) else (
		netsh advfirewall firewall add rule name="Node.js: Server-side JavaScript" dir=in action=allow program="%ProgramFiles%\nodejs\node.exe" enable=yes
	)
    rem netsh advfirewall firewall add rule name="Node.js: Server-side JavaScript TCP" dir=in action=allow protocol=TCP
	rem netsh advfirewall firewall add rule name="Node.js: Server-side JavaScript UDP" dir=in action=allow protocol=UDP
)
echo Done.
goto :eof
