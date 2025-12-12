# Windows Setup Script for Go SFTP GUI Client
# PowerShell version with better error handling

Write-Host "🛠️  Go SFTP GUI Client - Windows Setup" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Check if Go is installed
try {
    $goVersion = go version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Go is installed: $goVersion" -ForegroundColor Green
    } else {
        throw "Go not found"
    }
} catch {
    Write-Host "❌ Error: Go is not installed or not in PATH" -ForegroundColor Red
    Write-Host "   Please install Go from https://golang.org/downloads/" -ForegroundColor Yellow
    Write-Host "   Make sure to restart PowerShell after installation" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Check CGO status
$cgoEnabled = go env CGO_ENABLED
Write-Host "🔧 CGO Status: $cgoEnabled" -ForegroundColor Yellow

# Check for C compiler
$gccFound = $false
try {
    $gccVersion = gcc --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        $gccFound = $true
        Write-Host "✅ C Compiler found: $($gccVersion[0])" -ForegroundColor Green
    }
} catch {
    $gccFound = $false
}

if (-not $gccFound) {
    Write-Host ""
    Write-Host "⚠️  WARNING: No C compiler found!" -ForegroundColor Yellow
    Write-Host "   The GUI version requires CGO and a C compiler." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "📋 To install build tools, choose one option:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "🔹 Option 1: TDM-GCC (Recommended - Easiest)" -ForegroundColor White
    Write-Host "   1. Download from: https://jmeubank.github.io/tdm-gcc/" -ForegroundColor Gray
    Write-Host "   2. Install with default settings" -ForegroundColor Gray
    Write-Host "   3. Make sure 'Add to PATH' is checked" -ForegroundColor Gray
    Write-Host "   4. Restart PowerShell and run this script again" -ForegroundColor Gray
    Write-Host ""
    Write-Host "🔹 Option 2: MinGW-w64" -ForegroundColor White
    Write-Host "   1. Download from: https://www.mingw-w64.org/downloads/" -ForegroundColor Gray
    Write-Host "   2. Install to C:\mingw64" -ForegroundColor Gray
    Write-Host "   3. Add C:\mingw64\bin to your PATH" -ForegroundColor Gray
    Write-Host "   4. Restart PowerShell and run this script again" -ForegroundColor Gray
    Write-Host ""
    Write-Host "🔹 Option 3: Visual Studio Build Tools" -ForegroundColor White
    Write-Host "   1. Download Visual Studio Installer" -ForegroundColor Gray
    Write-Host "   2. Install 'C++ build tools' workload" -ForegroundColor Gray
    Write-Host "   3. Restart PowerShell and run this script again" -ForegroundColor Gray
    Write-Host ""
    Write-Host "🔸 Alternative: Use CLI version (works without C compiler)" -ForegroundColor Magenta
    Write-Host "   The CLI version is fully functional and doesn't require CGO." -ForegroundColor Magenta
    Write-Host ""

    $choice = Read-Host "Do you want to try building the CLI version now? (y/n)"
    if ($choice -eq "y" -or $choice -eq "Y") {
        $buildCli = $true
    } else {
        Write-Host ""
        Write-Host "Please install a C compiler and run this script again for GUI support." -ForegroundColor Yellow
        Read-Host "Press Enter to exit"
        exit 0
    }
} else {
    $buildCli = $false
}

function Build-CLI {
    Write-Host ""
    Write-Host "📦 Building CLI Version..." -ForegroundColor Cyan
    Write-Host "========================" -ForegroundColor Cyan

    try {
        go build -o sftp-client-cli.exe cli-main.go
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ CLI Version built successfully!" -ForegroundColor Green
            Write-Host "   Executable: sftp-client-cli.exe" -ForegroundColor Gray

            # Test the CLI version
            Write-Host ""
            Write-Host "🎯 Testing CLI version..." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "💡 CLI Version Usage:" -ForegroundColor Cyan
            Write-Host "   • Run: .\sftp-client-cli.exe" -ForegroundColor Gray
            Write-Host "   • Type 'help' for available commands" -ForegroundColor Gray
            Write-Host "   • Type 'connect host port username password' to connect" -ForegroundColor Gray
            Write-Host "   • Type 'quit' to exit" -ForegroundColor Gray
            Write-Host ""

            $testChoice = Read-Host "Would you like to test the CLI version now? (y/n)"
            if ($testChoice -eq "y" -or $testChoice -eq "Y") {
                Write-Host "Starting CLI client (type 'quit' to exit)..."
                .\sftp-client-cli.exe
            }

            return $true
        } else {
            throw "Build failed"
        }
    } catch {
        Write-Host "❌ Error: CLI build failed" -ForegroundColor Red
        return $false
    }
}

function Build-GUI {
    Write-Host ""
    Write-Host "📦 Installing Go Dependencies..." -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan

    try {
        go mod tidy
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to install dependencies"
        }
        Write-Host "✅ Dependencies installed!" -ForegroundColor Green
    } catch {
        Write-Host "❌ Error: Failed to install dependencies" -ForegroundColor Red
        return $false
    }

    Write-Host ""
    Write-Host "🔨 Building GUI Version..." -ForegroundColor Cyan
    Write-Host "========================" -ForegroundColor Cyan

    # Enable CGO for GUI build
    $env:CGO_ENABLED = "1"

    try {
        go build -o sftp-client-gui.exe main.go app_icon.go
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ GUI Version built successfully!" -ForegroundColor Green
            Write-Host "   Executable: sftp-client-gui.exe" -ForegroundColor Gray

            Write-Host ""
            Write-Host "🎯 Launching GUI application..." -ForegroundColor Yellow
            Start-Process ".\sftp-client-gui.exe"

            return $true
        } else {
            throw "Build failed"
        }
    } catch {
        Write-Host "❌ Error: GUI build failed" -ForegroundColor Red
        Write-Host ""
        Write-Host "🔍 Troubleshooting:" -ForegroundColor Yellow
        Write-Host "   • Make sure your C compiler is in PATH" -ForegroundColor Gray
        Write-Host "   • Try restarting PowerShell" -ForegroundColor Gray
        Write-Host "   • Verify CGO_ENABLED=1 in your environment" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Building CLI version as fallback..." -ForegroundColor Yellow
        return Build-CLI
    }
}

# Main execution
if ($buildCli) {
    $success = Build-CLI
} else {
    $success = Build-GUI
    if (-not $success) {
        $success = Build-CLI
    }
}

Write-Host ""
Write-Host "🎉 Setup Complete!" -ForegroundColor Green
Write-Host "=================" -ForegroundColor Green
Write-Host ""
Write-Host "📋 What's been built:" -ForegroundColor Cyan

if (Test-Path "sftp-client-gui.exe") {
    Write-Host "   ✅ GUI Version: sftp-client-gui.exe" -ForegroundColor Green
}
if (Test-Path "sftp-client-cli.exe") {
    Write-Host "   ✅ CLI Version: sftp-client-cli.exe" -ForegroundColor Green
}

Write-Host ""
Write-Host "💡 Usage Tips:" -ForegroundColor Cyan
Write-Host "   • GUI: Double-click sftp-client-gui.exe or run .\sftp-client-gui.exe" -ForegroundColor Gray
Write-Host "   • CLI: Run .\sftp-client-cli.exe and type 'help' for commands" -ForegroundColor Gray
Write-Host ""
Write-Host "📚 For more information, see README.md or WINDOWS-SETUP.md" -ForegroundColor Gray
Write-Host ""

if (Test-Path "sftp-client-gui.exe") {
    Write-Host "🚀 GUI application should be running now!" -ForegroundColor Green
    Write-Host "   If not, try running: .\sftp-client-gui.exe" -ForegroundColor Gray
} elseif (Test-Path "sftp-client-cli.exe") {
    Write-Host "💻 CLI version is ready to use!" -ForegroundColor Green
    Write-Host "   Run: .\sftp-client-cli.exe" -ForegroundColor Gray
}

Write-Host ""
Read-Host "Press Enter to exit"
