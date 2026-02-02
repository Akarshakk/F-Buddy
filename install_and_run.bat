@echo off
set ADB="C:\Users\DHRUV\AppData\Local\Sdk\Sdk\platform-tools\adb.exe"

echo ===================================================
echo   FINZO: AUTO INSTALLER & LAUNCHER
echo ===================================================
echo.

:CHECK_DEVICE
echo [1/3] Looking for your phone...
%ADB% devices | findstr /R /C:"[a-zA-Z0-9]" | findstr /V "List" > nul
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ❌ NO PHONE DETECTED!
    echo.
    echo Please follow these steps:
    echo 1. Unplug your USB cable.
    echo 2. Enable Developer Options (Settings > About Phone > Tap 'Build Number' 7 times).
    echo 3. Enable USB Debugging (Settings > System > Developer Options).
    echo 4. Plug the USB cable back in.
    echo 5. Watch your phone screen and tap 'ALLOW' on the popup.
    echo.
    echo Waiting 5 seconds to try again...
    timeout /t 5 > nul
    goto CHECK_DEVICE
)

echo ✅ Phone Detected!
echo.

echo [2/3] Setting up Network Connection...
%ADB% reverse tcp:5001 tcp:5001
if %ERRORLEVEL% EQU 0 (
    echo    - Network bridge established.
) else (
    echo    - Warning: potential network issue.
)

echo.
echo [3/3] Building and Installing App...
echo      (This might take a minute...)
echo.

cd mobile
call flutter run

echo.
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Installation Failed.
) else (
    echo ✅ App Verified Closing.
)
pause
