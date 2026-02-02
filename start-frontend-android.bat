@echo off
echo ========================================
echo Starting Finzo Flutter Android App
echo ========================================
echo.

cd mobile

echo Installing dependencies...
call flutter pub get

echo.
echo Checking connected devices...
call flutter devices

echo.
echo Starting Flutter Android app...
echo.
call flutter run

pause
