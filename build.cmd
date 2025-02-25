@echo off
echo ===== Build Script =====
echo.
echo This script builds and sets up a complete game folder
echo with all necessary configuration files.
echo.

echo Step 1: Setting up the build environment...
cd /d "%~dp0src"

echo Step 2: Creating output directories...
if not exist "..\game" mkdir "..\game"
if not exist "..\game\mod_tf" mkdir "..\game\mod_tf"
if not exist "..\game\mod_tf\bin" mkdir "..\game\mod_tf\bin"
if not exist "..\game\mod_tf\bin\x64" mkdir "..\game\mod_tf\bin\x64"
if not exist "..\game\bin" mkdir "..\game\bin"
if not exist "..\game\bin\x64" mkdir "..\game\bin\x64"

echo Step 3: Generating project files...
call createallprojects.bat

echo Step 4: Finding Visual Studio...
if exist "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\Common7\Tools\VsDevCmd.bat" (
  call "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\Common7\Tools\VsDevCmd.bat" -arch=amd64
) else if exist "C:\Program Files\Microsoft Visual Studio\2022\Professional\Common7\Tools\VsDevCmd.bat" (
  call "C:\Program Files\Microsoft Visual Studio\2022\Professional\Common7\Tools\VsDevCmd.bat" -arch=amd64
) else if exist "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat" (
  call "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat" -arch=amd64
) else (
  echo ERROR: Could not find Visual Studio 2022 Developer Command Prompt
  pause
  exit /b 1
)

echo Step 5: Starting MSBuild...
where msbuild

echo Building core TF2 components in RELEASE mode...
echo Building client.dll...
msbuild everything.sln /p:Configuration=Release /p:Platform=win64 /m /nodeReuse:false /p:DebugType=none /p:DebugSymbols=false /p:ZipRelease=true /t:"client_win64_tf"

echo Building server.dll...
msbuild everything.sln /p:Configuration=Release /p:Platform=win64 /m /nodeReuse:false /p:DebugType=none /p:DebugSymbols=false /p:ZipRelease=true /t:"server_win64_tf"

echo Building mod_tf_win64.exe...
msbuild everything.sln /p:Configuration=Release /p:Platform=win64 /m /nodeReuse:false /p:DebugType=none /p:DebugSymbols=false /p:ZipRelease=true /t:"launcher_main_win64_tf"

echo Building utility executables...
echo Building captioncompiler...
msbuild everything.sln /p:Configuration=Release /p:Platform=win64 /m /nodeReuse:false /p:DebugType=none /p:DebugSymbols=false /p:ZipRelease=true /t:"captioncompiler_win64"

echo Building glview...
msbuild everything.sln /p:Configuration=Release /p:Platform=win64 /m /nodeReuse:false /p:DebugType=none /p:DebugSymbols=false /p:ZipRelease=true /t:"glview_win64"

echo Building height2normal...
msbuild everything.sln /p:Configuration=Release /p:Platform=win64 /m /nodeReuse:false /p:DebugType=none /p:DebugSymbols=false /p:ZipRelease=true /t:"height2normal_win64"

echo Building motionmapper...
msbuild everything.sln /p:Configuration=Release /p:Platform=win64 /m /nodeReuse:false /p:DebugType=none /p:DebugSymbols=false /p:ZipRelease=true /t:"motionmapper_win64"

echo Building qc_eyes with MFC support...
echo Checking for MFC library...
if exist "..\src\lib\public\x64\nafxcw.lib" (
  echo Found nafxcw.lib, using it for qc_eyes build
  msbuild everything.sln /p:Configuration=Release /p:Platform=win64 /m /nodeReuse:false /p:DebugType=none /p:DebugSymbols=false /p:ZipRelease=true /t:"qc_eyes_win64"
) else (
  echo WARNING: Cannot build qc_eyes.exe
)

echo Building tgadiff...
msbuild everything.sln /p:Configuration=Release /p:Platform=win64 /m /nodeReuse:false /p:DebugType=none /p:DebugSymbols=false /p:ZipRelease=true /t:"tgadiff_win64"

echo Building vbsp...
msbuild everything.sln /p:Configuration=Release /p:Platform=win64 /m /nodeReuse:false /p:DebugType=none /p:DebugSymbols=false /p:ZipRelease=true /t:"vbsp_win64"

echo Building vice...
msbuild everything.sln /p:Configuration=Release /p:Platform=win64 /m /nodeReuse:false /p:DebugType=none /p:DebugSymbols=false /p:ZipRelease=true /t:"vice_win64"

echo Building vrad...
msbuild everything.sln /p:Configuration=Release /p:Platform=win64 /m /nodeReuse:false /p:DebugType=none /p:DebugSymbols=false /p:ZipRelease=true /t:"vrad_launcher_win64"

echo Building vtf2tga...
msbuild everything.sln /p:Configuration=Release /p:Platform=win64 /m /nodeReuse:false /p:DebugType=none /p:DebugSymbols=false /p:ZipRelease=true /t:"vtf2tga_win64"

echo Building vtfdiff...
msbuild everything.sln /p:Configuration=Release /p:Platform=win64 /m /nodeReuse:false /p:DebugType=none /p:DebugSymbols=false /p:ZipRelease=true /t:"vtfdiff_win64"

echo Building vvis...
msbuild everything.sln /p:Configuration=Release /p:Platform=win64 /m /nodeReuse:false /p:DebugType=none /p:DebugSymbols=false /p:ZipRelease=true /t:"vvis_launcher_win64"

echo Building DLL libraries...
echo Building vrad_dll...
msbuild everything.sln /p:Configuration=Release /p:Platform=win64 /m /nodeReuse:false /p:DebugType=none /p:DebugSymbols=false /p:ZipRelease=true /t:"vrad_dll_win64"

echo Building vvis_dll...
msbuild everything.sln /p:Configuration=Release /p:Platform=win64 /m /nodeReuse:false /p:DebugType=none /p:DebugSymbols=false /p:ZipRelease=true /t:"vvis_dll_win64"

echo Step 6: Setting up required game files and directories...
cd ..

echo Removing all PDB files...
del /s /q "game\*.pdb"

echo Removing game_shader_generic_example.dll...
if exist "game\mod_tf\bin\x64\game_shader_generic_example.dll" del "game\mod_tf\bin\x64\game_shader_generic_example.dll"

echo Removing mod_hl2mp directory...
if exist "game\mod_hl2mp" rmdir /s /q "game\mod_hl2mp"

echo Copying Steam API to bin\x64...
if exist "game_ideal\bin\x64\steam_api64.dll" (
  copy "game_ideal\bin\x64\steam_api64.dll" "game\bin\x64\steam_api64.dll"
) else (
  echo WARNING: steam_api64.dll not found in game_ideal
)

echo Creating required game directories...
mkdir "game\mod_tf\cfg" 2>nul
mkdir "game\mod_tf\scripts" 2>nul
mkdir "game\mod_tf\resource" 2>nul
mkdir "game\mod_tf\resource\ui" 2>nul
mkdir "game\mod_tf\materials\logo" 2>nul

echo Copying required game configuration files...
REM Config files
if exist "game_ideal\mod_tf\cfg" (
  xcopy /Y /E "game_ideal\mod_tf\cfg\*.*" "game\mod_tf\cfg\"
) else (
  echo WARNING: mod_tf\cfg directory not found in game_ideal
)

REM Script files
if exist "game_ideal\mod_tf\scripts" (
  xcopy /Y /E "game_ideal\mod_tf\scripts\*.*" "game\mod_tf\scripts\"
) else (
  echo WARNING: mod_tf\scripts directory not found in game_ideal
)

REM Resource files
if exist "game_ideal\mod_tf\resource" (
  xcopy /Y /E "game_ideal\mod_tf\resource\*.*" "game\mod_tf\resource\"
) else (
  echo WARNING: mod_tf\resource directory not found in game_ideal
)

REM Materials
if exist "game_ideal\mod_tf\materials\logo" (
  xcopy /Y /E "game_ideal\mod_tf\materials\logo\*.*" "game\mod_tf\materials\logo\"
) else (
  echo WARNING: mod_tf\materials\logo directory not found in game_ideal
)

REM Gameinfo and steam.inf
if exist "game_ideal\mod_tf\gameinfo.txt" (
  copy "game_ideal\mod_tf\gameinfo.txt" "game\mod_tf\gameinfo.txt"
) else (
  echo WARNING: mod_tf\gameinfo.txt not found in game_ideal
)

echo Downloading steam.inf from GitHub...
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/mastercomfig/tc2/refs/heads/tc2-mod/game/tc2/steam.inf' -OutFile 'game\mod_tf\steam.inf'"
if %ERRORLEVEL% NEQ 0 (
  echo WARNING: Failed to download steam.inf from GitHub
  if exist "game_ideal\mod_tf\steam.inf" (
    echo Using local steam.inf from game_ideal as fallback
    copy "game_ideal\mod_tf\steam.inf" "game\mod_tf\steam.inf"
  ) else (
    echo WARNING: No steam.inf available
  )
) else (
  echo Updating steam.inf values...
  echo ProductName=mod_tf > game\mod_tf\steam.inf.new
  echo appID=243750 >> game\mod_tf\steam.inf.new
  echo ServerAppID=244310 >> game\mod_tf\steam.inf.new
  
  powershell -Command "(Get-Content 'game\mod_tf\steam.inf') | Where-Object { $_ -notmatch '^ProductName=' -and $_ -notmatch '^appID=' -and $_ -notmatch '^ServerAppID=' } | Add-Content 'game\mod_tf\steam.inf.new'"
  move /y game\mod_tf\steam.inf.new game\mod_tf\steam.inf
)

if exist "game_ideal\mod_tf\texture_preload_list.txt" (
  copy "game_ideal\mod_tf\texture_preload_list.txt" "game\mod_tf\texture_preload_list.txt"
) else (
  echo WARNING: mod_tf\texture_preload_list.txt not found in game_ideal
)

REM Third-party legal notices
if exist "thirdpartylegalnotices.txt" (
  copy "thirdpartylegalnotices.txt" "game\thirdpartylegalnotices.txt"
) else (
  echo WARNING: thirdpartylegalnotices.txt not found
)

REM Steam appid
if exist "game_ideal\steam_appid.txt" (
  copy "game_ideal\steam_appid.txt" "game\steam_appid.txt"
) else (
  echo WARNING: steam_appid.txt not found
)

REM Startup cmd file
if exist "game_ideal\mod_tf.cmd" (
  copy "game_ideal\mod_tf.cmd" "game\mod_tf.cmd"
) else (
  echo WARNING: mod_tf.cmd not found in game_ideal
)

echo Step 7: Verifying exact match with game_ideal structure...
echo Checking for required core files...
set MISSING_FILES=0

if not exist "game\mod_tf\bin\x64\client.dll" (
  echo MISSING: game\mod_tf\bin\x64\client.dll
  set MISSING_FILES=1
)
if not exist "game\mod_tf\bin\x64\server.dll" (
  echo MISSING: game\mod_tf\bin\x64\server.dll
  set MISSING_FILES=1
)
if not exist "game\mod_tf_win64.exe" (
  echo MISSING: game\mod_tf_win64.exe
  set MISSING_FILES=1
)

echo Checking for required utility files...
if not exist "game\bin\x64\captioncompiler.exe" echo MISSING: game\bin\x64\captioncompiler.exe
if not exist "game\bin\x64\glview.exe" echo MISSING: game\bin\x64\glview.exe
if not exist "game\bin\x64\height2normal.exe" echo MISSING: game\bin\x64\height2normal.exe
if not exist "game\bin\x64\motionmapper.exe" echo MISSING: game\bin\x64\motionmapper.exe
if not exist "game\bin\x64\qc_eyes.exe" echo MISSING: game\bin\x64\qc_eyes.exe
if not exist "game\bin\x64\tgadiff.exe" echo MISSING: game\bin\x64\tgadiff.exe
if not exist "game\bin\x64\vbsp.exe" echo MISSING: game\bin\x64\vbsp.exe
if not exist "game\bin\x64\vice.exe" echo MISSING: game\bin\x64\vice.exe
if not exist "game\bin\x64\vrad.exe" echo MISSING: game\bin\x64\vrad.exe
if not exist "game\bin\x64\vtf2tga.exe" echo MISSING: game\bin\x64\vtf2tga.exe
if not exist "game\bin\x64\vtfdiff.exe" echo MISSING: game\bin\x64\vtfdiff.exe
if not exist "game\bin\x64\vvis.exe" echo MISSING: game\bin\x64\vvis.exe

echo Checking for required DLLs...
if not exist "game\bin\x64\steam_api64.dll" echo MISSING: game\bin\x64\steam_api64.dll
if not exist "game\bin\x64\vrad_dll.dll" echo MISSING: game\bin\x64\vrad_dll.dll
if not exist "game\bin\x64\vvis_dll.dll" echo MISSING: game\bin\x64\vvis_dll.dll

echo Checking for required configuration files...
if not exist "game\mod_tf\gameinfo.txt" echo MISSING: game\mod_tf\gameinfo.txt
if not exist "game\mod_tf\steam.inf" echo MISSING: game\mod_tf\steam.inf
if not exist "game\mod_tf\cfg\valve.rc" echo MISSING: game\mod_tf\cfg\valve.rc
if not exist "game\mod_tf\cfg\default.cfg" echo MISSING: game\mod_tf\cfg\default.cfg
if not exist "game\mod_tf\materials\logo\new_tf2_logo.vmt" echo MISSING: game\mod_tf\materials\logo\new_tf2_logo.vmt
if not exist "game\mod_tf\materials\logo\new_tf2_logo.vtf" echo MISSING: game\mod_tf\materials\logo\new_tf2_logo.vtf
if not exist "game\mod_tf\resource\mod_tf_english.txt" echo MISSING: game\mod_tf\resource\mod_tf_english.txt
if not exist "game\thirdpartylegalnotices.txt" echo MISSING: game\thirdpartylegalnotices.txt
if not exist "game\steam_appid.txt" echo MISSING: game\steam_appid.txt
if not exist "game\mod_tf.cmd" echo MISSING: game\mod_tf.cmd

echo.
if %MISSING_FILES%==0 (
  echo ✓ Build successfully created core files matching game_ideal structure.
  echo.
  echo Game files are available in:
  echo - game\mod_tf_win64.exe
  echo - game\mod_tf\bin\x64\client.dll and server.dll
  echo - game\bin\x64\*.exe and *.dll (utility tools)
  echo - game\mod_tf\cfg, game\mod_tf\scripts, game\mod_tf\resource, etc. (configuration files)
) else (
  echo ✗ Some core files are missing.
  echo.
  echo Please check the messages above for missing files.
)

echo.
echo WARNING: The game_shader_generic_example.dll has been removed to match game_ideal structure.
echo If the game crashes, this DLL might be required but is just not included in game_ideal.
echo.
echo Build process complete!
echo.
pause
