#!/bin/bash

# SFTP Client GUI Launcher Script
# This script builds and runs the SFTP GUI client

set -e

echo "🚀 SFTP Client GUI Launcher"
echo "=========================="

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo "❌ Error: Go is not installed or not in PATH"
    echo "   Please install Go from https://golang.org/downloads/"
    exit 1
fi

# Check Go version
GO_VERSION=$(go version | cut -d' ' -f3 | sed 's/go//')
REQUIRED_VERSION="1.21"

if [[ "$(printf '%s\n' "$REQUIRED_VERSION" "$GO_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]]; then
    echo "❌ Error: Go version $REQUIRED_VERSION or higher is required"
    echo "   Current version: $GO_VERSION"
    exit 1
fi

echo "✅ Go version: $GO_VERSION"

# Change to script directory
cd "$(dirname "$0")"

# Check if we're in the right directory
if [[ ! -f "main.go" ]]; then
    echo "❌ Error: main.go not found in current directory"
    echo "   Please run this script from the golang-ftpClient directory"
    exit 1
fi

echo "📦 Installing dependencies..."
if ! go mod tidy; then
    echo "❌ Error: Failed to install dependencies"
    exit 1
fi

echo "🔨 Building SFTP Client GUI..."
if ! go build -o sftp-client-gui main.go app_icon.go; then
    echo "❌ Error: Build failed"
    exit 1
fi

echo "✅ Build successful!"

# Check if binary was created
if [[ ! -f "sftp-client-gui" ]]; then
    echo "❌ Error: Binary not found after build"
    exit 1
fi

echo "🎯 Launching SFTP Client GUI..."
echo ""

# Launch the application
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    open ./sftp-client-gui
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    ./sftp-client-gui &
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    # Windows (Git Bash/Cygwin)
    ./sftp-client-gui.exe &
else
    # Unknown OS, try direct execution
    ./sftp-client-gui &
fi

echo "🎉 SFTP Client GUI is now running!"
echo ""
echo "💡 Tips:"
echo "   • Fill in the connection details in the top panel"
echo "   • Choose between password or SSH key authentication"
echo "   • Use the file browsers to navigate and transfer files"
echo "   • Check the activity log for operation status"
echo ""
echo "📚 For help and documentation, see README.md"
