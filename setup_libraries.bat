@echo off
color 9
::
:: LIBRARIES
::
haxelib set lime 8.2.2
haxelib set openfl 9.4.1
haxelib set flixel 5.8.0
haxelib set flixel-ui 2.6.1
haxelib git flxanimate-doido https://github.com/DoidoTeam/flxanimate-doido
haxelib git tjson https://github.com/DoidoTeam/TJSON
haxelib git hscript-iris https://github.com/crowplexus/hscript-iris d9dc99526d51e63cbab86122624625aebe5349c2
haxelib git hxdiscord_rpc https://github.com/MAJigsaw77/hxdiscord_rpc 19518713cbd59fc5705f899144fffdbf9ae6695c
haxelib git hxcpp https://github.com/DoidoTeam/hxcpp

:askInstallVideo
set /p i= "(OPTIONAL) Install libraries required for video support [y/n] ? "
::
:: OPTIONAL VIDEO SUPPORT LIBRARY
::
if "%i%"=="y" (
    haxelib git hxvlc https://github.com/MAJigsaw77/hxvlc 243593311edcc7a8424d73806cda13bd1317bfdd
) else if not "%i%"=="n" (
    goto askInstallVideo
)

echo "All versions set!! The game should build properly now."
pause