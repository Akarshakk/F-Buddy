@echo off
echo ========================================
echo Starting Finzo Backend Server
echo ========================================
echo.

cd backend

echo Checking configuration...
call npm run check
if errorlevel 1 (
    echo.
    echo Configuration check failed!
    echo Please fix the errors above.
    pause
    exit /b 1
)

echo.
echo Starting server...
echo.
call npm run dev

pause
