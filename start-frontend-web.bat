@echo off
echo ========================================
echo Starting Finzo Flutter Web App
echo ========================================
echo.

cd mobile

echo Installing dependencies...
call flutter pub get

echo.
echo Starting Flutter web app...
echo.
echo The app will open in Chrome browser
echo.
call flutter run -d chrome

pause
