@echo off
color 9

cd ..
cd ..

::
:: RUN HMM INSTALL
::
haxelib --global install hmm

:askGlobal
set /p i1= "Would you like to install these libraries globally (might interfere with other mods) [y/n] ? "

::
:: INSTALL EITHER LOCALLY OR GLOBALLY
::
if "%i1%"=="n" (
    haxelib --global run hmm init
    haxelib --global run hmm install
) else if "%i1%"=="y" (
    haxe -cp ./art/setup/deps/ -D analyzer-optimize -main Setup --interp
) else (
    goto askGlobal
)

:askInstallVideo
set /p i2= "(OPTIONAL) Install libraries required for video support [y/n] ? "

::
:: OPTIONAL VIDEO SUPPORT LIBRARY
::
if "%i2%"=="y" (
    haxelib git hxvlc https://github.com/MAJigsaw77/hxvlc bfff4207bec31ce849be7a90f0050235724da5a9
) else if not "%i2%"=="n" (
    goto askInstallVideo
)

:askBuild
set /p i3= "All versions set!! Would you like to build the game now [y/n] ? "
if "%i3%"=="y" (
    haxelib run lime test windows
) else if not "%i3%"=="n" (
    goto askBuild
)

pause