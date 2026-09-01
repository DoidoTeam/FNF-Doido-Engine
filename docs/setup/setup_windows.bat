@echo off

cd /d "%~dp0..\.."

haxelib --global install hxpkg
echo.

:askProfile
echo Available Profiles:
echo    [1] Default
echo    [2] Default + Video
echo    [3] Default + Android
echo    [4] Full Install
echo.
set /p i0="Select profile [1-4]: "

set profile=
if "%i0%"=="1" (
    set profile=
) else if "%i0%"=="2" (
    set profile=video
) else if "%i0%"=="3" (
    set profile=android
) else if "%i0%"=="4" (
    set profile=video android
) else (
    echo Invalid selection
    echo.
    goto askProfile
)
echo.

:askGlobal
set /p i1= "Would you like to install these libraries globally (might interfere with other mods) [y/n]: "

set global=
if "%i1%"=="n" (
    set global=
) else if "%i1%"=="y" (
    set global=--global
) else (
    echo Invalid selection
    echo.
    goto askGlobal
)

haxelib --global run hxpkg install --force %global% %profile%
echo.

:askBuild
set /p i2= "All versions set!! Would you like to build the game now [y/n]: "
if "%i2%"=="y" (
    haxelib run lime test windows
) else if not "%i2%"=="n" (
    goto askBuild
)

pause