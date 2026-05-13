@echo off
:: No title yet to avoid early crash points
echo ===================================================
echo     AutoLK Admin Panel - Diagnostic Launcher
echo ===================================================
echo.
echo 1. Script is starting.
echo 2. Current Path: "%~dp0"
echo.

:: Check Node.js existence
echo 3. Checking for Node.js (node -v)...
node -v >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Node.js is NOT found on this system.
    echo Please download and install it from https://nodejs.org/
    echo.
    echo Press any key to close...
    pause >nul
    exit /b
)
echo [OK] Node.js detected.

:: Check for the admin_panel folder
echo 4. Checking for 'admin_panel' folder...
if not exist "%~dp0admin_panel" (
    echo [ERROR] Could not find the 'admin_panel' folder.
    echo Make sure this .bat file is in the SAME folder as 'admin_panel'.
    echo currently looking in: "%~dp0admin_panel"
    echo.
    echo Press any key to close...
    pause >nul
    exit /b
)
echo [OK] Folder found.

:: Navigate to the folder
echo 5. Entering admin_panel folder...
cd /d "%~dp0admin_panel"
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Failed to switch directory.
    pause
    exit /b
)

:: Run NPM Install
echo 6. Running 'npm install' (this ensures all files are ready)...
echo Please wait...
call npm install
if %ERRORLEVEL% neq 0 (
    echo.
    echo [WARNING] 'npm install' failed or returned an error.
    echo We will try to launch anyway, but it might fail.
    pause
)

:: Launch the Dashboard
echo 7. Launching Dashboard...
start "" http://localhost:3000

echo.
echo ---------------------------------------------------
echo     Admin Panel is starting up!
echo     KEEP THIS WINDOW OPEN to stay connected.
echo ---------------------------------------------------
echo.

npm run dev

echo.
echo Server stopped.
pause
