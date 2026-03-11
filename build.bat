@echo off
setlocal enabledelayedexpansion

set TARGET=deps
if not exist "%TARGET%" mkdir "%TARGET%"

REM Build plugins
call :build_plugin base
call :build_plugin extras

echo Build complete.
exit /b

REM ================================
REM Function: build_plugin
REM %1 = plugin name
REM ================================
:build_plugin
set NAME=%1

echo Building %NAME%...

REM Temporary working files
copy "%NAME%.package.json" package.json >nul

REM Create zip
powershell -Command ^
  "Compress-Archive -Force -Path commands,resources,main.lua,package.json,pxutils.aseprite-keys -DestinationPath '%TARGET%\%NAME%.zip'"

REM Rename
cd deps
ren "%NAME%.zip" "pxutils-extension-%NAME%-v1.0.0.aseprite-extension"
cd ..

REM Cleanup
del package.json

echo %NAME% done.
echo.
exit /b