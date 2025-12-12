@echo off
REM Quick Fix Script for "not valid for this OS" errors
REM Addresses common Windows runtime issues with Go GUI applications

setlocal enabledelayedexpansion

echo 🔧 Quick Fix for Windows Runtime Issues
echo ======================================

REM Check if we're in the right directory
if not exist "main.go" (
    echo ❌ Error: main.go not found in current directory
    echo    Please run this script from the golang-ftpClient directory
    pause
    exit /b 1
)

echo 📋 System Information:
systeminfo | findstr "System Type"
echo.

echo 🔍 Diagnosing issue...

REM Check if executable exists
if not exist "sftp-client-gui.exe" (
    echo ⚠️  GUI executable not found. Building first...
    goto rebuild
)

REM Try to get file info
echo 📁 Checking executable properties...
dir sftp-client-gui.exe | findstr sftp-client-gui.exe
echo.

echo 🚀 Testing execution methods...

REM Method 1: Try direct execution
echo Method 1: Direct execution...
start /wait "" "sftp-client-gui.exe" 2>nul
if %errorlevel% equ 0 (
    echo ✅ Direct execution successful!
    goto success
)

echo ❌ Direct execution failed

REM Method 2: Try with compatibility
echo Method 2: Compatibility mode...
start /wait "" cmd /c "sftp-client-gui.exe" 2>nul
if %errorlevel% equ 0 (
    echo ✅ Compatibility mode successful!
    goto success
)

echo ❌ Compatibility mode failed

REM Method 3: Check for Windows Defender blocking
echo Method 3: Checking Windows Defender...
powershell -Command "try { Add-MpPreference -ExclusionPath (Get-Location).Path -ErrorAction Stop; Write-Host 'Added Windows Defender exclusion' } catch { Write-Host 'Could not add exclusion (may need admin)' }"
echo.

:rebuild
echo 🔨 Rebuilding with different options...

REM Option 1: Static linking
echo Building with static linking...
set CGO_ENABLED=1
go build -ldflags "-s -w -extldflags=-static" -o sftp-client-gui-static.exe main.go app_icon.go
if %errorlevel% equ 0 (
    if exist "sftp-client-gui-static.exe" (
        echo ✅ Static build created: sftp-client-gui-static.exe
        echo Testing static build...
        start /wait "" "sftp-client-gui-static.exe" 2>nul
        if !errorlevel! equ 0 (
            echo ✅ Static build works! Use: sftp-client-gui-static.exe
            goto success
        )
    )
)

REM Option 2: Minimal build
echo Building minimal version...
go build -ldflags "-s -w" -o sftp-client-gui-minimal.exe main.go app_icon.go
if %errorlevel% equ 0 (
    if exist "sftp-client-gui-minimal.exe" (
        echo ✅ Minimal build created: sftp-client-gui-minimal.exe
        echo Testing minimal build...
        start /wait "" "sftp-client-gui-minimal.exe" 2>nul
        if !errorlevel! equ 0 (
            echo ✅ Minimal build works! Use: sftp-client-gui-minimal.exe
            goto success
        )
    )
)

REM Option 3: CLI fallback
echo Building CLI fallback...
go build -o sftp-client-cli.exe cli-main.go
if %errorlevel% equ 0 (
    if exist "sftp-client-cli.exe" (
        echo ✅ CLI version available as backup
    )
)

REM Manual fixes section
echo.
echo 🔧 Manual Fix Options:
echo ======================
echo.
echo 1. Windows Defender Issue:
echo    - Open Windows Security ^> Virus ^& threat protection
echo    - Click "Manage settings" under Real-time protection
echo    - Add exclusion for this folder: %CD%
echo    - Or temporarily disable real-time protection
echo.
echo 2. Missing Visual C++ Runtime:
echo    - Download from: https://aka.ms/vs/17/release/vc_redist.x64.exe
echo    - Install the latest Visual C++ Redistributable
echo.
echo 3. Run as Administrator:
echo    - Right-click Command Prompt ^> "Run as administrator"
echo    - Navigate to this folder and try again
echo.
echo 4. Use CLI Version ^(Always Works^):
echo    - Run: sftp-client-cli.exe
echo    - Full SFTP functionality without GUI issues
echo.
echo 5. Alternative Build Methods:
if exist "sftp-client-gui-static.exe" (
    echo    - Try: sftp-client-gui-static.exe
)
if exist "sftp-client-gui-minimal.exe" (
    echo    - Try: sftp-client-gui-minimal.exe
)
echo    - Or use the CLI version: sftp-client-cli.exe
echo.

goto end

:success
echo.
echo 🎉 Success! The application should now be working.
echo.
echo 💡 If the GUI window doesn't appear:
echo    - Check your taskbar for the application icon
echo    - Try Alt+Tab to switch to it
echo    - Some GUI apps start minimized or in background
echo.

:end
echo 📦 Available Executables:
for %%f in (sftp-client*.exe) do (
    echo    - %%f
)
echo.

echo 🚀 To test your working versions:
if exist "sftp-client-gui.exe" (
    echo    GUI ^(original^): sftp-client-gui.exe
)
if exist "sftp-client-gui-static.exe" (
    echo    GUI ^(static^):   sftp-client-gui-static.exe
)
if exist "sftp-client-gui-minimal.exe" (
    echo    GUI ^(minimal^):  sftp-client-gui-minimal.exe
)
if exist "sftp-client-cli.exe" (
    echo    CLI ^(reliable^): sftp-client-cli.exe
)

echo.
echo 💡 Pro Tip: The CLI version often works better on Windows
echo    and provides the same SFTP functionality as the GUI.
echo.

pause
