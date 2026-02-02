@echo off
echo ========================================
echo Starting Finzo RAG Service
echo ========================================
echo.

cd backend\rag_service

echo Checking Python installation...
python --version
if errorlevel 1 (
    echo ERROR: Python is not installed or not in PATH
    pause
    exit /b 1
)

echo.
echo Installing/Updating Python dependencies...
pip install -r requirements.txt

echo.
echo Starting RAG Service on port 5002...
echo.
echo Press Ctrl+C to stop the service
echo.

python rag_server.py

pause
