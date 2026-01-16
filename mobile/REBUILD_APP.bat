@echo off
echo ========================================
echo F-Buddy Android Build Fix Script
echo ========================================
echo.

echo Step 1: Cleaning Flutter build cache...
call flutter clean

echo.
echo Step 2: Getting dependencies...
call flutter pub get

echo.
echo Step 3: Analyzing code...
call flutter analyze

echo.
echo Step 4: Building APK for your phone...
call flutter build apk --debug

echo.
echo ========================================
echo Build Complete!
echo ========================================
echo.
echo APK Location: build\app\outputs\flutter-apk\app-debug.apk
echo.
echo To install on your phone:
echo 1. Connect phone via USB
echo 2. Enable USB debugging
echo 3. Run: flutter install
echo.
pause
