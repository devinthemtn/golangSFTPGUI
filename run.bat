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

echo 📦 Installing dependencies...
go mod tidy
if %errorlevel% neq 0 (
    echo ❌ Error: Failed to install dependencies
    pause
    exit /b 1
)

echo 🔨 Building SFTP Client GUI...
go build -o sftp-client-gui.exe main.go app_icon.go
if %errorlevel% neq 0 (
    echo ❌ Error: Build failed
    pause
    exit /b 1
)

echo ✅ Build successful!

REM Check if binary was created
if not exist "sftp-client-gui.exe" (
    echo ❌ Error: Binary not found after build
    pause
    exit /b 1
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
