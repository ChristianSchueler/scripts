echo off
rem (c) 2025 Christian Schüler, christianschueler.at
rem
rem This Windows batch script compresses all top level folders in the current directory
rem into separate ZIP files, using 7-Zip. It a ZIP file already exists, it skips the
rem compression. Please be aware that if you cancel the scipt mid-runtine and a folder
rem is halfway compressed, this ZIP will also be skipped. Use with care.
rem
rem Bonus TIPP: use -sdel option to immediately delete the folders, thus replacing folders
rem with ZIP archives.

FOR /d %%i IN (*.*) DO (
	echo Compressing "%%i" into "%%i.zip"...
	if not exist "%%i.zip" (
		"C:\Program Files\7-Zip\7z.exe" a "%%i.zip" "%%i" -sdel
		rem "C:\Program Files\7-Zip\7z.exe" a "%%i.zip" "%%i"
	) else (
		echo ZIP already exists, skipping folder.
	)
)
