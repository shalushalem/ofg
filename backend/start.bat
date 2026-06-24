# OFG Connects Backend — Start Script
# Run this to start the local development server

@echo off
echo Starting OFG Connects Backend Server...
echo.

REM Check if venv exists, create if not
if not exist "venv\" (
    echo Creating virtual environment...
    python -m venv venv
    echo Installing dependencies...
    venv\Scripts\pip install -r requirements.txt
    echo.
)

echo Activating virtual environment...
call venv\Scripts\activate.bat

echo.
echo [OFG Connects] Server starting on http://0.0.0.0:8787
echo [OFG Connects] Android Emulator: http://10.0.2.2:8787
echo [OFG Connects] Real Device: Use your PC LAN IP:8787
echo.
python server.py
