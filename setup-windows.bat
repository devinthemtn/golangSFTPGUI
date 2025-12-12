@echo off
REM Windows Setup Script for Go SFTP GUI Client
REM This script helps set up the build environment for Windows

setlocal enabledelayedexpansion

echo 🛠️  Go SFTP GUI Client - Windows Setup
echo =====================================
echo.

REM Check if Go is installed
where go >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Error: Go is not installed or not in PATH
    echo    Please install Go from https://golang.org/downloads/
    echo    Make sure to restart your command prompt after installation
    pause
    exit /b 1
)

REM Get Go version
for /f "tokens=3" %%i in ('go version') do set GO_VERSION=%%i
set GO_VERSION=!GO_VERSION:go=!
echo ✅ Go version: !GO_VERSION!

REM Check CGO status
for /f %%i in ('go env CGO_ENABLED') do set CGO_STATUS=%%i
echo 🔧 CGO Status: !CGO_STATUS!

REM Check for C compiler
where gcc >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ⚠️  WARNING: No C compiler found!
    echo    The GUI version requires CGO and a C compiler.
    echo.
    echo 📋 To install build tools, choose one option:
    echo.
    echo 🔹 Option 1: TDM-GCC ^(Recommended - Easiest^)
    echo    1. Download from: https://jmeubank.github.io/tdm-gcc/
    echo    2. Install with default settings
    echo    3. Make sure "Add to PATH" is checked
    echo    4. Restart command prompt and run this script again
    echo.
    echo 🔹 Option 2: MinGW-w64
    echo    1. Download from: https://www.mingw-w64.org/downloads/
    echo    2. Install to C:\mingw64
    echo    3. Add C:\mingw64\bin to your PATH environment variable
    echo    4. Restart command prompt and run this script again
    echo.
    echo 🔹 Option 3: Visual Studio Build Tools
    echo    1. Download Visual Studio Installer
    echo    2. Install "C++ build tools" workload
    echo    3. Restart command prompt and run this script again
    echo.
    echo 🔸 Alternative: Use CLI version ^(works without C compiler^)
    echo    The CLI version is fully functional and doesn't require CGO.
    echo.

    set /p choice="Do you want to try building the CLI version now? (y/n): "
    if /i "!choice!" == "y" (
        goto build_cli
    ) else (
        echo.
        echo Please install a C compiler and run this script again for GUI support.
        pause
        exit /b 0
    )
) else (
    for /f "tokens=*" %%i in ('gcc --version 2^>^&1 ^| findstr /C:"gcc"') do (
        echo ✅ C Compiler: %%i
        goto build_gui
    )
)

:build_cli
echo.
echo 📦 Building CLI Version...
echo ========================

go build -o sftp-client-cli.exe cli-main.go
if %errorlevel% neq 0 (
    echo ❌ Error: CLI build failed
    pause
    exit /b 1
)

echo ✅ CLI Version built successfully!
echo    Executable: sftp-client-cli.exe
echo.
echo 🎯 Testing CLI version...
echo.

REM Test the CLI version
echo Type 'quit' to exit the CLI client
.\sftp-client-cli.exe

echo.
echo 💡 CLI Version Usage:
echo    • Run: .\sftp-client-cli.exe
echo    • Type 'help' for available commands
echo    • Type 'connect host port username password' to connect
echo    • Type 'quit' to exit
echo.
goto end

:build_gui
echo.
echo 📦 Installing Go Dependencies...
echo ================================

go mod tidy
if %errorlevel% neq 0 (
    echo ❌ Error: Failed to install dependencies
    pause
    exit /b 1
)

echo ✅ Dependencies installed!

echo.
echo 🔨 Building GUI Version...
echo ========================

REM Enable CGO for GUI build
set CGO_ENABLED=1

go build -o sftp-client-gui.exe main.go app_icon.go
if %errorlevel% neq 0 (
    echo ❌ Error: GUI build failed
    echo.
    echo 🔍 Troubleshooting:
    echo    • Make sure your C compiler is in PATH
    echo    • Try restarting your command prompt
    echo    • Verify CGO_ENABLED=1 in your environment
    echo.
    echo Building CLI version as fallback...
    goto build_cli
)

echo ✅ GUI Version built successfully!
echo    Executable: sftp-client-gui.exe

echo.
echo 🎯 Launching GUI application...
start "" "sftp-client-gui.exe"

echo.
echo 🎉 Setup Complete!
echo ==================
echo.
echo 📋 What's been built:
if exist "sftp-client-gui.exe" (
    echo    ✅ GUI Version: sftp-client-gui.exe
)
if exist "sftp-client-cli.exe" (
    echo    ✅ CLI Version: sftp-client-cli.exe
)
echo.

:end
echo 💡 Usage Tips:
echo    • GUI: Double-click sftp-client-gui.exe or run .\sftp-client-gui.exe
echo    • CLI: Run .\sftp-client-cli.exe and type 'help' for commands
echo.
echo 📚 For more information, see README.md
echo.

if exist "sftp-client-gui.exe" (
    echo 🚀 GUI application should be running now!
    echo    If not, try running: .\sftp-client-gui.exe
) else if exist "sftp-client-cli.exe" (
    echo 💻 CLI version is ready to use!
    echo    Run: .\sftp-client-cli.exe
)

echo.
pause
