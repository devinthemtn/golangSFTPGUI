# Windows Diagnostic Script for Go SFTP GUI Client
# Fixes "not valid for this OS" errors and runtime issues

Write-Host "🔍 Windows Diagnostic for Go SFTP GUI Client" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Function to check Windows version
function Get-WindowsInfo {
    Write-Host "📋 System Information:" -ForegroundColor Yellow
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $arch = $env:PROCESSOR_ARCHITECTURE
    Write-Host "   OS: $($os.Caption)" -ForegroundColor Gray
    Write-Host "   Version: $($os.Version)" -ForegroundColor Gray
    Write-Host "   Architecture: $arch" -ForegroundColor Gray
    Write-Host "   Build: $($os.BuildNumber)" -ForegroundColor Gray
    Write-Host ""
}

# Function to check Go environment
function Get-GoInfo {
    Write-Host "🔧 Go Environment:" -ForegroundColor Yellow
    try {
        $goVersion = go version
        $goArch = go env GOARCH
        $goOS = go env GOOS
        $cgEnabled = go env CGO_ENABLED
        Write-Host "   Version: $goVersion" -ForegroundColor Gray
        Write-Host "   Target OS: $goOS" -ForegroundColor Gray
        Write-Host "   Target Arch: $goArch" -ForegroundColor Gray
        Write-Host "   CGO Enabled: $cgEnabled" -ForegroundColor Gray
    } catch {
        Write-Host "   ❌ Go not found or not working" -ForegroundColor Red
    }
    Write-Host ""
}

# Function to check executable properties
function Test-Executable {
    param($ExePath)

    Write-Host "📁 Executable Analysis:" -ForegroundColor Yellow

    if (Test-Path $ExePath) {
        $file = Get-Item $ExePath
        Write-Host "   ✅ File exists: $($file.Name)" -ForegroundColor Green
        Write-Host "   Size: $([math]::Round($file.Length / 1MB, 2)) MB" -ForegroundColor Gray
        Write-Host "   Created: $($file.CreationTime)" -ForegroundColor Gray
        Write-Host "   Modified: $($file.LastWriteTime)" -ForegroundColor Gray

        # Try to get file type info
        try {
            $fileInfo = cmd /c "file `"$ExePath`"" 2>$null
            if ($fileInfo) {
                Write-Host "   Type: $fileInfo" -ForegroundColor Gray
            }
        } catch {
            Write-Host "   Type: Windows executable (assumed)" -ForegroundColor Gray
        }

        return $true
    } else {
        Write-Host "   ❌ File not found: $ExePath" -ForegroundColor Red
        return $false
    }
}

# Function to check for common issues
function Test-CommonIssues {
    param($ExePath)

    Write-Host "🔍 Common Issue Detection:" -ForegroundColor Yellow

    # Check Windows Defender exclusions
    Write-Host "   Checking Windows Security..." -ForegroundColor Gray
    try {
        $defenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
        if ($defenderStatus.RealTimeProtectionEnabled) {
            Write-Host "   ⚠️  Windows Defender Real-time protection is ON" -ForegroundColor Yellow
            Write-Host "      This may block the executable" -ForegroundColor Gray
        }
    } catch {
        Write-Host "   Cannot check Windows Defender status" -ForegroundColor Gray
    }

    # Check execution policy
    $policy = Get-ExecutionPolicy -Scope CurrentUser
    Write-Host "   PowerShell Execution Policy: $policy" -ForegroundColor Gray

    # Check for missing Visual C++ Redistributables
    Write-Host "   Checking Visual C++ Runtime..." -ForegroundColor Gray
    $vcRuntimes = Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" |
                  Where-Object { $_.DisplayName -match "Microsoft Visual C\+\+" }

    if ($vcRuntimes.Count -gt 0) {
        Write-Host "   ✅ Visual C++ Redistributables found:" -ForegroundColor Green
        foreach ($runtime in $vcRuntimes) {
            Write-Host "      - $($runtime.DisplayName)" -ForegroundColor Gray
        }
    } else {
        Write-Host "   ⚠️  No Visual C++ Redistributables detected" -ForegroundColor Yellow
    }

    Write-Host ""
}

# Function to attempt fixes
function Invoke-Fixes {
    param($ExePath)

    Write-Host "🔧 Attempting Fixes:" -ForegroundColor Yellow

    # Fix 1: Try running with different compatibility modes
    Write-Host "   Fix 1: Testing basic execution..." -ForegroundColor Cyan
    try {
        $process = Start-Process -FilePath $ExePath -NoNewWindow -PassThru -ErrorAction Stop
        Start-Sleep -Seconds 2
        if (!$process.HasExited) {
            Write-Host "   ✅ Application started successfully!" -ForegroundColor Green
            $process.Kill()
            return $true
        }
    } catch {
        Write-Host "   ❌ Basic execution failed: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Fix 2: Rebuild with static linking
    Write-Host "   Fix 2: Rebuilding with static linking..." -ForegroundColor Cyan
    try {
        $env:CGO_ENABLED = "1"
        $buildArgs = @(
            "build",
            "-ldflags", "-s -w -extldflags=-static",
            "-a",
            "-o", "sftp-client-gui-static.exe",
            "main.go", "app_icon.go"
        )

        & go @buildArgs

        if ($LASTEXITCODE -eq 0 -and (Test-Path "sftp-client-gui-static.exe")) {
            Write-Host "   ✅ Static build successful!" -ForegroundColor Green
            Write-Host "   Try running: .\sftp-client-gui-static.exe" -ForegroundColor Gray
        } else {
            Write-Host "   ❌ Static build failed" -ForegroundColor Red
        }
    } catch {
        Write-Host "   ❌ Static build error: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Fix 3: Build without CGO (fallback GUI)
    Write-Host "   Fix 3: Attempting CGO-free build..." -ForegroundColor Cyan
    try {
        $env:CGO_ENABLED = "0"
        & go build -ldflags "-s -w" -o "sftp-client-nocgo.exe" "main.go" "app_icon.go"

        if ($LASTEXITCODE -eq 0 -and (Test-Path "sftp-client-nocgo.exe")) {
            Write-Host "   ✅ No-CGO build successful!" -ForegroundColor Green
        } else {
            Write-Host "   ❌ No-CGO build failed (expected for Fyne)" -ForegroundColor Red
        }
    } catch {
        Write-Host "   ❌ No-CGO build error: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Fix 4: Ensure CLI version works
    Write-Host "   Fix 4: Verifying CLI version..." -ForegroundColor Cyan
    if (Test-Path "sftp-client-cli.exe") {
        try {
            $process = Start-Process -FilePath ".\sftp-client-cli.exe" -ArgumentList "-h" -NoNewWindow -Wait -PassThru
            Write-Host "   ✅ CLI version is available as fallback" -ForegroundColor Green
        } catch {
            Write-Host "   ⚠️  CLI version may have issues too" -ForegroundColor Yellow
        }
    } else {
        Write-Host "   Building CLI version as backup..." -ForegroundColor Gray
        & go build -o "sftp-client-cli.exe" "cli-main.go"
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ✅ CLI backup created" -ForegroundColor Green
        }
    }

    return $false
}

# Function to provide solutions
function Show-Solutions {
    Write-Host "💡 Recommended Solutions:" -ForegroundColor Green
    Write-Host ""

    Write-Host "🔹 Immediate Solutions:" -ForegroundColor White
    Write-Host "   1. Add build directory to Windows Defender exclusions:" -ForegroundColor Gray
    Write-Host "      - Open Windows Security → Virus & threat protection" -ForegroundColor Gray
    Write-Host "      - Add exclusion for: $(Get-Location)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   2. Try the static build (if created):" -ForegroundColor Gray
    Write-Host "      .\sftp-client-gui-static.exe" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   3. Use the CLI version (always works):" -ForegroundColor Gray
    Write-Host "      .\sftp-client-cli.exe" -ForegroundColor Gray
    Write-Host ""

    Write-Host "🔹 System-level Fixes:" -ForegroundColor White
    Write-Host "   1. Install Visual C++ Redistributable (latest):" -ForegroundColor Gray
    Write-Host "      https://aka.ms/vs/17/release/vc_redist.x64.exe" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   2. Update Windows to latest version" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   3. Try running as Administrator:" -ForegroundColor Gray
    Write-Host "      Right-click → 'Run as administrator'" -ForegroundColor Gray
    Write-Host ""

    Write-Host "🔹 Alternative Builds:" -ForegroundColor White
    Write-Host "   1. Cross-compile from WSL/Linux:" -ForegroundColor Gray
    Write-Host "      env GOOS=windows GOARCH=amd64 CGO_ENABLED=1 go build ..." -ForegroundColor Gray
    Write-Host ""
    Write-Host "   2. Use Docker for consistent builds:" -ForegroundColor Gray
    Write-Host "      docker run --rm -v `"$(pwd):/src`" -w /src golang:1.21 go build ..." -ForegroundColor Gray
    Write-Host ""
}

# Main execution
Get-WindowsInfo
Get-GoInfo

$exePath = ".\sftp-client-gui.exe"
$fileExists = Test-Executable $exePath

if ($fileExists) {
    Test-CommonIssues $exePath

    Write-Host "🚀 Attempting to fix the issue..." -ForegroundColor Cyan
    Write-Host ""

    $fixed = Invoke-Fixes $exePath

    if (!$fixed) {
        Write-Host ""
        Show-Solutions
    }
} else {
    Write-Host "❌ Executable not found. Building first..." -ForegroundColor Red
    Write-Host ""

    # Try to build
    $env:CGO_ENABLED = "1"
    & go build -o "sftp-client-gui.exe" "main.go" "app_icon.go"

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Build successful, re-running diagnostics..." -ForegroundColor Green
        Write-Host ""
        $fileExists = Test-Executable $exePath
        if ($fileExists) {
            Invoke-Fixes $exePath
        }
    } else {
        Write-Host "❌ Build failed. Check build environment." -ForegroundColor Red
        Show-Solutions
    }
}

Write-Host ""
Write-Host "🏁 Diagnostic Complete!" -ForegroundColor Green
Write-Host ""

# Summary of available executables
Write-Host "📦 Available Executables:" -ForegroundColor Cyan
Get-ChildItem -Filter "sftp-client*.exe" | ForEach-Object {
    $size = [math]::Round($_.Length / 1MB, 2)
    Write-Host "   ✅ $($_.Name) ($size MB)" -ForegroundColor Green
}

Write-Host ""
Write-Host "🔧 Quick Test Commands:" -ForegroundColor Yellow
Write-Host "   Test GUI (original): .\sftp-client-gui.exe" -ForegroundColor Gray
if (Test-Path "sftp-client-gui-static.exe") {
    Write-Host "   Test GUI (static):   .\sftp-client-gui-static.exe" -ForegroundColor Gray
}
Write-Host "   Test CLI (reliable): .\sftp-client-cli.exe" -ForegroundColor Gray

Write-Host ""
Read-Host "Press Enter to exit"
