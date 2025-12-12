# Windows Setup Guide for Go SFTP GUI Client

This guide helps you set up the build environment for the Go SFTP GUI Client on Windows.

## Quick Start (TL;DR)

If you just want to use the application immediately:

1. **CLI Version (No setup required):**
   ```cmd
   go build -o sftp-client-cli.exe cli-main.go
   .\sftp-client-cli.exe
   ```

2. **GUI Version (Requires C compiler):**
   - Install TDM-GCC from https://jmeubank.github.io/tdm-gcc/
   - Run `setup-windows.bat`

## The Problem

The GUI version uses the Fyne framework which requires:
- **CGO (C bindings)** - Currently disabled on your system
- **C Compiler** - Not installed on your system
- **OpenGL libraries** - Provided by the C compiler toolchain

Without these, you'll see this error:
```
build constraints exclude all Go files in github.com/go-gl/gl@v0.0.0-20211210172815-726fda9656d6/v2.1/gl
```

## Solutions

### Option 1: Use CLI Version (Immediate Solution)

The CLI version works perfectly without any additional setup:

```cmd
# Build CLI version
go build -o sftp-client-cli.exe cli-main.go

# Run it
.\sftp-client-cli.exe
```

**CLI Commands:**
```
help                                    - Show available commands
connect <host> <port> <user> <pass>    - Connect to SFTP server
connect-key <host> <port> <user> <key> - Connect using SSH key
ls [path]                              - List remote directory
lls [path]                             - List local directory
cd <path>                              - Change remote directory
lcd <path>                             - Change local directory
pwd                                    - Show remote working directory
lpwd                                   - Show local working directory
get <remote> [local]                   - Download file
put <local> [remote]                   - Upload file
mkdir <path>                           - Create remote directory
rm <path>                              - Remove remote file
quit                                   - Exit
```

### Option 2: Install TDM-GCC (Recommended for GUI)

TDM-GCC is the easiest way to get a working C compiler on Windows:

1. **Download TDM-GCC:**
   - Go to: https://jmeubank.github.io/tdm-gcc/
   - Download the latest version (usually `tdm64-gcc-X.X.X-2.exe`)

2. **Install TDM-GCC:**
   - Run the installer as Administrator
   - Choose "Create" for new installation
   - **Important:** Make sure "Add to PATH" is checked
   - Use default installation directory (`C:\TDM-GCC-64\`)
   - Complete the installation

3. **Verify Installation:**
   ```cmd
   # Restart your command prompt first!
   gcc --version
   ```
   You should see something like:
   ```
   gcc (tdm64-1) 10.3.0
   ```

4. **Build GUI Version:**
   ```cmd
   set CGO_ENABLED=1
   go build -o sftp-client-gui.exe main.go app_icon.go
   ```

### Option 3: Install MinGW-w64

Alternative C compiler option:

1. **Download MinGW-w64:**
   - Go to: https://www.mingw-w64.org/downloads/
   - Choose "MingW-W64-builds" or "w64devkit"

2. **Install and Configure:**
   - Extract to `C:\mingw64\`
   - Add `C:\mingw64\bin` to your PATH environment variable
   - Restart command prompt

3. **Verify and Build:**
   ```cmd
   gcc --version
   set CGO_ENABLED=1
   go build -o sftp-client-gui.exe main.go app_icon.go
   ```

### Option 4: Visual Studio Build Tools

For those who prefer Microsoft tools:

1. **Download Visual Studio Installer:**
   - Go to: https://visualstudio.microsoft.com/downloads/
   - Download "Build Tools for Visual Studio"

2. **Install C++ Build Tools:**
   - Run the installer
   - Select "C++ build tools" workload
   - Make sure "Windows 10 SDK" is included

3. **Use Developer Command Prompt:**
   - Open "Developer Command Prompt for VS"
   - Navigate to your project directory
   - Build as usual

## Automated Setup Scripts

We've created automated scripts to help with the setup:

### setup-windows.bat
Comprehensive setup script that:
- Checks for Go installation
- Detects C compiler availability
- Provides installation guidance
- Builds appropriate version (GUI or CLI)
- Tests the built application

```cmd
.\setup-windows.bat
```

### run.bat (Updated)
Enhanced launcher that:
- Automatically detects missing dependencies
- Falls back to CLI version if GUI can't build
- Provides helpful error messages and solutions

```cmd
.\run.bat
```

## Environment Variables

After installing a C compiler, make sure these are set:

```cmd
# Check current settings
go env CGO_ENABLED
go env CC

# Set for current session
set CGO_ENABLED=1

# Set permanently (optional)
setx CGO_ENABLED 1
```

## Troubleshooting

### "gcc: command not found"
- C compiler not installed or not in PATH
- Solution: Install TDM-GCC or MinGW-w64 and restart command prompt

### "build constraints exclude all Go files"
- CGO is disabled or C compiler not working
- Solution: `set CGO_ENABLED=1` and ensure gcc works

### "cannot find -lOpenGL32"
- OpenGL libraries missing
- Solution: Install complete C compiler toolchain (TDM-GCC recommended)

### GUI application won't start
- Missing Windows runtime libraries
- Solution: Install Visual C++ Redistributables or use static linking:
  ```cmd
  go build -ldflags "-s -w -extldflags=-static" -o sftp-client-gui.exe main.go app_icon.go
  ```

### Permission denied errors
- Windows antivirus blocking execution
- Solution: Add build directory to antivirus exclusions

## Building for Distribution

To create a distributable executable that works on machines without Go:

```cmd
# Enable CGO and build with static linking
set CGO_ENABLED=1
set GOOS=windows
set GOARCH=amd64

# Build with optimizations
go build -ldflags "-s -w" -o sftp-client-gui.exe main.go app_icon.go

# Or build both versions
go build -ldflags "-s -w" -o sftp-client-gui.exe main.go app_icon.go
go build -ldflags "-s -w" -o sftp-client-cli.exe cli-main.go
```

## Alternative: Cross-compilation from Linux/macOS

If you have access to a Linux or macOS system, you can cross-compile for Windows:

```bash
# Install mingw-w64 cross-compiler
# Ubuntu/Debian: sudo apt install gcc-mingw-w64
# macOS: brew install mingw-w64

# Cross-compile for Windows
env GOOS=windows GOARCH=amd64 CGO_ENABLED=1 CC=x86_64-w64-mingw32-gcc \
  go build -o sftp-client-gui.exe main.go app_icon.go
```

## Performance Notes

- **GUI Version:** Full-featured with modern interface, requires ~50MB
- **CLI Version:** Lightweight, requires ~15MB, same SFTP functionality
- Both versions have identical SFTP capabilities
- CLI version is often preferred for servers and automation

## Next Steps

1. **Choose your approach:** CLI (immediate) or GUI (after setup)
2. **Install C compiler** if you want GUI support
3. **Run setup-windows.bat** for automated setup
4. **Test with your SFTP servers**

## Getting Help

If you encounter issues:

1. **Check this guide** for common solutions
2. **Run setup-windows.bat** for automated diagnosis
3. **Use CLI version** as a working fallback
4. **Check GitHub issues** for similar problems

The CLI version provides full SFTP functionality and is often the preferred choice for Windows environments where GUI setup is complex.