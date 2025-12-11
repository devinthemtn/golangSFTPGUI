#!/bin/bash

# SFTP Client GUI - Bookmarks Demo Script
# This script demonstrates the bookmarks feature of the SFTP Client

echo "🚀 SFTP Client GUI - Bookmarks Feature Demo"
echo "=========================================="
echo ""

# Check if the GUI application exists
if [ ! -f "./sftp-client-gui" ]; then
    echo "❌ GUI application not found. Building it now..."
    make build-gui
    if [ $? -ne 0 ]; then
        echo "❌ Failed to build the application"
        exit 1
    fi
fi

echo "📚 Creating sample bookmarks..."

# Create sample bookmarks file in new location
mkdir -p ~/.config/KAT-ftp
cat > ~/.config/KAT-ftp/bookmarks.json << 'EOF'
[
  {
    "name": "Local Test Server",
    "host": "localhost",
    "port": "22",
    "username": "testuser",
    "use_ssh_key": false,
    "key_path": ""
  },
  {
    "name": "Production Server",
    "host": "prod.example.com",
    "port": "22",
    "username": "admin",
    "use_ssh_key": true,
    "key_path": "/Users/$USER/.ssh/id_rsa"
  },
  {
    "name": "Development Server",
    "host": "dev.example.com",
    "port": "2222",
    "username": "developer",
    "use_ssh_key": false,
    "key_path": ""
  },
  {
    "name": "Staging Server",
    "host": "staging.example.com",
    "port": "22",
    "username": "deploy",
    "use_ssh_key": true,
    "key_path": "/Users/$USER/.ssh/staging_key"
  }
]
EOF

echo "✅ Sample bookmarks created at: ~/.config/KAT-ftp/bookmarks.json"
echo ""

echo "📖 Bookmarks Feature Overview:"
echo "------------------------------"
echo "1. 📋 Bookmark Dropdown - Select from saved connections"
echo "2. ⚡ Quick Connect - One-click connection from bookmark"
echo "3. 💾 Save Button - Store current connection as bookmark"
echo "4. 🗑️  Delete Button - Remove selected bookmark"
echo "5. 🔄 Auto-collapse - Connection panel minimizes when connected"
echo ""

echo "🎯 Demo Instructions:"
echo "--------------------"
echo "1. Launch the application: ./sftp-client-gui"
echo "2. Click the bookmarks dropdown to see pre-loaded connections"
echo "3. Select 'Local Test Server' from the dropdown"
echo "4. Notice how the form fields auto-populate"
echo "5. Try the 'Quick Connect' button for instant connection"
echo "6. Create new bookmarks by filling the form and clicking 'Save'"
echo "7. Watch the connection panel collapse when connected"
echo ""

echo "💡 Tips:"
echo "-------"
echo "• Passwords are NOT saved in bookmarks for security"
echo "• SSH key paths are validated when loading bookmarks"
echo "• Bookmarks are automatically saved to ~/.config/KAT-ftp/bookmarks.json"
echo "• Connection panel auto-expands when disconnected"
echo "• Use meaningful names for your bookmarks (e.g., 'Production DB Server')"
echo ""

echo "🔧 Current bookmarks:"
echo "-------------------"
if [ -f ~/.config/KAT-ftp/bookmarks.json ]; then
    cat ~/.config/KAT-ftp/bookmarks.json | python3 -m json.tool 2>/dev/null || cat ~/.config/KAT-ftp/bookmarks.json
else
    echo "No bookmarks file found."
fi

echo ""
echo "🚀 Starting SFTP Client GUI..."
echo "   Close the application window to return to this terminal."
echo ""

# Launch the GUI application
./sftp-client-gui

echo ""
echo "📊 Demo completed!"
echo "Current bookmarks file location: ~/.config/KAT-ftp/bookmarks.json"
echo "File size: $(du -h ~/.config/KAT-ftp/bookmarks.json 2>/dev/null | cut -f1 || echo 'N/A')"
echo ""
echo "🎉 Thanks for trying the SFTP Client GUI bookmarks feature!"
