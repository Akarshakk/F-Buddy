@echo off
echo ========================================
echo Connecting Phone to Local Backend
echo ========================================
echo.
echo NOTE: Make sure your phone is connected and USB Debugging is ON.
echo.
echo Running ADB Reverse...
"C:\Users\DHRUV\AppData\Local\Sdk\Sdk\platform-tools\adb.exe" reverse tcp:5001 tcp:5001

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ SUCCESS! Your phone is now connected to the backend.
    echo you can now run 'flutter run' in the mobile folder.
) else (
    echo.
    echo ❌ FAILED. Please check:
    echo 1. Phone is connected via USB
    echo 2. USB Debugging is enabled in Developer Options
    echo 3. You accepted the trust popup on your phone screen
)
echo.
pause
