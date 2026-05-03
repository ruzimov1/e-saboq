@echo off
setlocal EnableExtensions
set "PATH=C:\Program Files\Git\cmd;%LOCALAPPDATA%\Pub\Cache\bin;%PATH%"

cd /d "%~dp0"

echo Git:
where git 2>nul || echo XATO: Git topilmadi.
echo.
echo FlutterFire:
where flutterfire 2>nul || echo XATO: dart pub global activate flutterfire_cli
echo.
echo Standart chiqish: lib\firebase_options.dart
echo.
flutterfire configure --overwrite-firebase-options --platforms=web,windows,android

echo.
pause
