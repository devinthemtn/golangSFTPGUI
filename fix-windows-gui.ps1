# Ultimate Windows GUI Fix Script for Go SFTP Client
# This script diagnoses and fixes "not valid for this OS" errors

param(
    [switch]$InstallTDM,
    [switch]$Force,
    [switch]$Verbose
)

$ErrorActionPreference = "Continue"

# Color functions for better output
function Write-Success { param($Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Error { param($Message) Write-Host "❌ $Message" -ForegroundColor Red }
function Write-Warning { param($Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }
function Write-Info { param($Message) Write-Host "ℹ️  $Message" -ForegroundColor Cyan }
function Write-Step { param($Message) Write-Host "🔧 $Message" -ForegroundColor Blue }

Clear-Host
Write-Host "🛠️  Windows GUI Fix Script for Go SFTP Client" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Cyan
Write-Host ""

# Step 1: System Diagnostics
Write-Step "Running system diagnostics..."

# Check Windows version
$os = Get-CimInstance -ClassName Win32_OperatingSystem
Write-Info "OS: $($os.Caption) (Build $($os.BuildNumber))"
Write-Info "Architecture: $($env:PROCESSOR_ARCHITECTURE)"

# Check Go installation
try {
    $goVersion = go version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Go installed: $goVersion"
        $goArch = go env GOARCH
        $goOS = go env GOOS
        $cgoEnabled = go env CGO_ENABLED

        Write-Info "Target: $goOS/$goArch"
        Write-Info "CGO: $cgoEnabled"
    } else {
        Write-Error "Go not found in PATH"
        Write-Host "Please install Go from https://golang.org/downloads/"
        exit 1
    }
} catch {
    Write-Error "Failed to check Go installation: $($_.Exception.Message)"
    exit 1
}

# Step 2: Check for C Compiler
Write-Step "Checking for C compiler..."

$compilerFound = $false
$compilerInfo = ""

# Check for GCC
try {
    $gccOutput = gcc --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        $compilerFound = $true
        $compilerInfo = ($gccOutput | Select-Object -First 1)
        Write-Success "GCC found: $compilerInfo"
    }
} catch { }

# Check for Visual Studio
if (-not $compilerFound) {
    try {
        $clOutput = cl 2>$null
        if ($LASTEXITCODE -eq 0 -or $clOutput -match "Microsoft") {
            $compilerFound = $true
            $compilerInfo = "Microsoft Visual C++"
            Write-Success "MSVC found: $compilerInfo"
        }
    } catch { }
}

# Check for Clang
if (-not $compilerFound) {
    try {
        $clangOutput = clang --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            $compilerFound = $true
            $compilerInfo = ($clangOutput | Select-Object -First 1)
            Write-Success "Clang found: $compilerInfo"
        }
    } catch { }
}

if (-not $compilerFound) {
    Write-Warning "No C compiler detected"
}

# Step 3: Check existing executables
Write-Step "Checking existing executables..."

$existingFiles = @()
Get-ChildItem -Filter "sftp-client*.exe" -ErrorAction SilentlyContinue | ForEach-Object {
    $size = [math]::Round($_.Length / 1MB, 2)
    Write-Info "Found: $($_.Name) ($size MB, Modified: $($_.LastWriteTime))"
    $existingFiles += $_.Name
}

if ($existingFiles.Count -eq 0) {
    Write-Warning "No existing executables found"
}

# Step 4: Test existing GUI executable if it exists
if (Test-Path "sftp-client-gui.exe") {
    Write-Step "Testing existing GUI executable..."

    try {
        # Try to get file info
        $exeInfo = Get-Item "sftp-client-gui.exe"
        Write-Info "File size: $([math]::Round($exeInfo.Length / 1MB, 2)) MB"

        # Try to start and quickly close
        $process = Start-Process -FilePath ".\sftp-client-gui.exe" -WindowStyle Hidden -PassThru -ErrorAction Stop
        Start-Sleep -Seconds 1

        if (!$process.HasExited) {
            Write-Success "GUI executable appears to work!"
            try { $process.Kill() } catch { }
            $needsRebuild = $false
        } else {
            Write-Warning "GUI executable exits immediately"
            $needsRebuild = $true
        }
    } catch {
        Write-Error "GUI executable failed to start: $($_.Exception.Message)"
        $needsRebuild = $true
    }
} else {
    $needsRebuild = $true
}

# Step 5: Handle missing C compiler
if (-not $compilerFound -and ($needsRebuild -or $Force)) {
    Write-Step "C compiler required for GUI build"
    Write-Host ""
    Write-Host "🔧 C Compiler Installation Options:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. TDM-GCC (Recommended - Easy installer)" -ForegroundColor White
    Write-Host "   • Download: https://jmeubank.github.io/tdm-gcc/" -ForegroundColor Gray
    Write-Host "   • Size: ~100 MB" -ForegroundColor Gray
    Write-Host "   • Automatic PATH setup" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. w64devkit (Portable)" -ForegroundColor White
    Write-Host "   • Download: https://github.com/skeeto/w64devkit/releases" -ForegroundColor Gray
    Write-Host "   • Size: ~80 MB" -ForegroundColor Gray
    Write-Host "   • Manual PATH setup required" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Visual Studio Build Tools" -ForegroundColor White
    Write-Host "   • Download: Visual Studio Installer" -ForegroundColor Gray
    Write-Host "   • Size: ~2 GB" -ForegroundColor Gray
    Write-Host "   • Professional development environment" -ForegroundColor Gray
    Write-Host ""

    if ($InstallTDM) {
        Write-Step "Attempting to download TDM-GCC..."
        try {
            $tdmUrl = "https://github.com/jmeubank/tdm-gcc/releases/download/v10.3.0-tdm64-2/tdm64-gcc-10.3.0-2.exe"
            $tdmPath = "$env:TEMP\tdm-gcc-installer.exe"

            Write-Info "Downloading TDM-GCC installer..."
            Invoke-WebRequest -Uri $tdmUrl -OutFile $tdmPath -ErrorAction Stop

            Write-Info "Starting TDM-GCC installer..."
            Write-Warning "IMPORTANT: Make sure to check 'Add to PATH' during installation!"
            Start-Process -FilePath $tdmPath -Wait

            Write-Info "Please restart PowerShell and run this script again after installation."
            exit 0
        } catch {
            Write-Error "Failed to download TDM-GCC: $($_.Exception.Message)"
            Write-Info "Please download manually from: https://jmeubank.github.io/tdm-gcc/"
        }
    } else {
        Write-Host "Options to proceed:" -ForegroundColor Cyan
        Write-Host "• Run with -InstallTDM to auto-download TDM-GCC" -ForegroundColor Gray
        Write-Host "• Install a C compiler manually and re-run this script" -ForegroundColor Gray
        Write-Host "• Use the CLI version (always works): .\sftp-client-cli.exe" -ForegroundColor Gray
        Write-Host ""

        $choice = Read-Host "Continue without C compiler? CLI version will be built (y/n)"
        if ($choice -ne "y" -and $choice -ne "Y") {
            Write-Info "Install a C compiler and run this script again for GUI support"
            exit 0
        }
    }
}

# Step 6: Ensure dependencies are up to date
Write-Step "Updating Go dependencies..."
try {
    go mod tidy
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Dependencies updated"
    } else {
        Write-Warning "Failed to update dependencies"
    }
} catch {
    Write-Error "Error updating dependencies: $($_.Exception.Message)"
}

# Step 7: Build CLI version (always works)
Write-Step "Building CLI version..."
try {
    go build -ldflags "-s -w" -o sftp-client-cli.exe cli-main.go
    if ($LASTEXITCODE -eq 0 -and (Test-Path "sftp-client-cli.exe")) {
        $cliSize = [math]::Round((Get-Item "sftp-client-cli.exe").Length / 1MB, 2)
        Write-Success "CLI version built successfully ($cliSize MB)"
        $cliWorks = $true
    } else {
        Write-Error "CLI build failed"
        $cliWorks = $false
    }
} catch {
    Write-Error "CLI build error: $($_.Exception.Message)"
    $cliWorks = $false
}

# Step 8: Build GUI version if C compiler is available
if ($compilerFound) {
    Write-Step "Building GUI version with C compiler support..."

    # Set CGO environment
    $env:CGO_ENABLED = "1"

    try {
        # Try standard build first
        Write-Info "Attempting standard GUI build..."
        go build -ldflags "-s -w" -o sftp-client-gui.exe main.go app_icon.go

        if ($LASTEXITCODE -eq 0 -and (Test-Path "sftp-client-gui.exe")) {
            $guiSize = [math]::Round((Get-Item "sftp-client-gui.exe").Length / 1MB, 2)
            Write-Success "GUI version built successfully ($guiSize MB)"

            # Test the GUI executable
            Write-Info "Testing GUI executable..."
            try {
                $testProcess = Start-Process -FilePath ".\sftp-client-gui.exe" -WindowStyle Hidden -PassThru -ErrorAction Stop
                Start-Sleep -Seconds 2

                if (!$testProcess.HasExited) {
                    Write-Success "GUI application started successfully!"
                    try { $testProcess.Kill() } catch { }
                    $guiWorks = $true
                } else {
                    Write-Warning "GUI application exits immediately"
                    $guiWorks = $false
                }
            } catch {
                Write-Warning "GUI test failed: $($_.Exception.Message)"
                $guiWorks = $false
            }
        } else {
            Write-Error "GUI build failed"
            $guiWorks = $false
        }

        # Try static build if standard build failed
        if (-not $guiWorks) {
            Write-Info "Attempting static GUI build..."
            go build -ldflags "-s -w -extldflags=-static" -o sftp-client-gui-static.exe main.go app_icon.go

            if ($LASTEXITCODE -eq 0 -and (Test-Path "sftp-client-gui-static.exe")) {
                $staticSize = [math]::Round((Get-Item "sftp-client-gui-static.exe").Length / 1MB, 2)
                Write-Success "Static GUI version built successfully ($staticSize MB)"
                $guiWorks = $true
            }
        }

    } catch {
        Write-Error "GUI build error: $($_.Exception.Message)"
        $guiWorks = $false
    }
} else {
    Write-Warning "Skipping GUI build - no C compiler available"
    $guiWorks = $false
}

# Step 9: Windows Defender check
Write-Step "Checking Windows Defender..."
try {
    $defenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
    if ($defenderStatus.RealTimeProtectionEnabled) {
        Write-Warning "Windows Defender real-time protection is enabled"
        Write-Info "If executables are blocked, add this folder to exclusions:"
        Write-Info "Windows Security → Virus & threat protection → Exclusions"
        Write-Info "Folder to exclude: $(Get-Location)"
    }
} catch {
    Write-Info "Could not check Windows Defender status"
}

# Step 10: Final summary and instructions
Write-Host ""
Write-Host "🎉 Build Summary" -ForegroundColor Green
Write-Host "=" * 30 -ForegroundColor Green

$availableExecutables = @()
Get-ChildItem -Filter "sftp-client*.exe" | ForEach-Object {
    $size = [math]::Round($_.Length / 1MB, 2)
    Write-Success "$($_.Name) - $size MB"
    $availableExecutables += $_.Name
}

Write-Host ""
Write-Host "🚀 Usage Instructions:" -ForegroundColor Cyan

if ($cliWorks) {
    Write-Host ""
    Write-Host "📱 CLI Version (Reliable):" -ForegroundColor White
    Write-Host "   .\sftp-client-cli.exe" -ForegroundColor Gray
    Write-Host "   • Type 'help' for commands" -ForegroundColor Gray
    Write-Host "   • connect server.com username password 22" -ForegroundColor Gray
    Write-Host "   • ls, get, put, mkdir, etc." -ForegroundColor Gray
}

if ($guiWorks) {
    Write-Host ""
    Write-Host "🖥️  GUI Version:" -ForegroundColor White
    if (Test-Path "sftp-client-gui.exe") {
        Write-Host "   .\sftp-client-gui.exe" -ForegroundColor Gray
    }
    if (Test-Path "sftp-client-gui-static.exe") {
        Write-Host "   .\sftp-client-gui-static.exe" -ForegroundColor Gray
    }
    Write-Host "   • Fill connection details in top panel" -ForegroundColor Gray
    Write-Host "   • Browse files in dual-pane interface" -ForegroundColor Gray
    Write-Host "   • Drag & drop for file transfers" -ForegroundColor Gray
}

Write-Host ""
Write-Host "💡 Troubleshooting:" -ForegroundColor Yellow
Write-Host "   • If GUI won't start: Use CLI version" -ForegroundColor Gray
Write-Host "   • If blocked by antivirus: Add folder to exclusions" -ForegroundColor Gray
Write-Host "   • If 'not valid for OS': C compiler issue - reinstall TDM-GCC" -ForegroundColor Gray

Write-Host ""
Write-Host "📚 Additional Resources:" -ForegroundColor Cyan
Write-Host "   • README.md - Full documentation" -ForegroundColor Gray
Write-Host "   • WINDOWS-SOLUTION.md - Detailed Windows guide" -ForegroundColor Gray
Write-Host "   • GitHub Issues - Report problems" -ForegroundColor Gray

# Step 11: Quick test option
if ($availableExecutables.Count -gt 0) {
    Write-Host ""
    $testChoice = Read-Host "Would you like to test an executable now? (cli/gui/n)"

    switch ($testChoice.ToLower()) {
        "cli" {
            if (Test-Path "sftp-client-cli.exe") {
                Write-Info "Starting CLI client..."
                Write-Host "Type 'help' for commands, 'quit' to exit" -ForegroundColor Gray
                .\sftp-client-cli.exe
            }
        }
        "gui" {
            $guiExe = $null
            if (Test-Path "sftp-client-gui.exe") { $guiExe = "sftp-client-gui.exe" }
            elseif (Test-Path "sftp-client-gui-static.exe") { $guiExe = "sftp-client-gui-static.exe" }

            if ($guiExe) {
                Write-Info "Starting GUI client: $guiExe"
                Start-Process -FilePath ".\$guiExe"
            } else {
                Write-Error "No GUI executable available"
            }
        }
        default {
            Write-Info "Setup complete! Use the executables when ready."
        }
    }
}

Write-Host ""
Write-Success "Windows GUI fix script completed!"
