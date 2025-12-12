@echo off
REM SFTP Client GUI Launcher Script for Windows
REM This script builds and runs the SFTP GUI client

setlocal enabledelayedexpansion

echo 🚀 SFTP Client GUI Launcher
echo ==========================

REM Check if Go is installed
where go >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Error: Go is not installed or not in PATH
    echo    Please install Go from https://golang.org/downloads/
    pause
    exit /b 1
)

REM Get Go version
for /f "tokens=3" %%i in ('go version') do set GO_VERSION=%%i
set GO_VERSION=!GO_VERSION:go=!
echo ✅ Go version: !GO_VERSION!

REM Change to script directory
cd /d "%~dp0"

REM Check if we're in the right directory
if not exist "main.go" (
    echo ❌ Error: main.go not found in current directory
    echo    Please run this script from the golang-ftpClient directory
    pause
    exit /b 1
)

REM Check for C compiler (required for Fyne GUI)
where gcc >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ⚠️  WARNING: No C compiler found!
    echo    The GUI version requires CGO and a C compiler ^(gcc/MinGW^).
    echo.
    echo 📋 To install build tools:
    echo    1. Download TDM-GCC from: https://jmeubank.github.io/tdm-gcc/
    echo    2. Install with "Add to PATH" checked
    echo    3. Restart command prompt and run this script again
    echo.
    echo 🔸 Alternative: Use CLI version ^(works without C compiler^)
    echo.

    set /p choice="Build CLI version instead? (y/n): "
    if /i "!choice!" == "y" (
        goto build_cli
    ) else (
        echo Please install a C compiler and try again.
        pause
        exit /b 1
    )
)

echo 📦 Installing dependencies...
go mod tidy
if %errorlevel% neq 0 (
    echo ❌ Error: Failed to install dependencies
    pause
    exit /b 1
)

echo 🔨 Building SFTP Client GUI...
set CGO_ENABLED=1
go build -o sftp-client-gui.exe main.go app_icon.go
if %errorlevel% neq 0 (
    echo ❌ Error: GUI Build failed - trying CLI version...
    goto build_cli
)

echo ✅ GUI Build successful!

REM Check if binary was created
if not exist "sftp-client-gui.exe" (
    echo ❌ Error: Binary not found after build
    goto build_cli
)

echo 🎯 Launching SFTP Client GUI...
echo.

REM Launch the application
start "" "sftp-client-gui.exe"

echo 🎉 SFTP Client GUI is now running!
echo.
echo 💡 Tips:
echo    • Fill in the connection details in the top panel
echo    • Choose between password or SSH key authentication
echo    • Use the file browsers to navigate and transfer files
echo    • Check the activity log for operation status
echo.
echo 📚 For help and documentation, see README.md

pause
exit /b 0

:build_cli
echo.
echo 🔨 Building CLI version as fallback...
go build -o sftp-client-cli.exe cli-main.go
if %errorlevel% neq 0 (
    echo ❌ Error: CLI build also failed
    pause
    exit /b 1
)

echo ✅ CLI Build successful!
echo    Executable: sftp-client-cli.exe
echo.
echo 🎯 Launching CLI version...
echo.
echo 💡 CLI Usage:
echo    • Type 'help' for available commands
echo    • Type 'connect host port username password' to connect
echo    • Type 'quit' to exit
echo.

.\sftp-client-cli.exe

pause
