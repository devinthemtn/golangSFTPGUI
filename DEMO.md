# SFTP Client GUI - Demo Guide

Welcome to the SFTP Client GUI demo! This guide will walk you through all the features of the graphical SFTP client built with Go and Fyne.

## 🚀 Quick Start

### 1. Launch the Application

```bash
# Method 1: Use the launcher script (recommended)
./run.sh

# Method 2: Build and run manually
make build-gui
./sftp-client-gui

# Method 3: Windows users
run.bat
```

### 2. First Look at the Interface

When you launch the application, you'll see a modern GUI with four main sections:

```
┌─────────────────────────────────────────────────────────────────┐
│                    Connection Panel                             │
│  [Host] [Port] [Username] [Password/Key] [Connect] [Status]     │
├─────────────────────────┬───────────────────────────────────────┤
│     Local Files         │        Remote Files                   │
│   📁 Documents          │      📁 home                          │
│   📁 Downloads          │      📁 var                           │
│   📄 file1.txt          │      📄 config.txt                    │
│   📄 file2.txt          │      📄 server.log                    │
│                         │                                       │
├─────────────────────────┼─────────────────────────────────────┬─┤
│                         │                                     │O│
│                         │                                     │p│
│                         │                                     │e│
│                         │                                     │r│
│                         │                                     │a│
│                         │                                     │t│
│                         │                                     │i│
│                         │                                     │o│
│                         │                                     │n│
│                         │                                     │s│
├─────────────────────────┴─────────────────────────────────────┴─┤
│                    Activity Log                                 │
│  [10:30:15] Connected successfully                              │
│  [10:30:16] Listed directory: /home/user                       │
│  [10:30:20] Uploaded file: document.txt                        │
└──────────────────────────────────────────────────────────────────┘
```

## 📋 Demo Scenarios

### Scenario 1: Password Authentication

**Setup a test connection:**

1. **Fill in connection details:**
   - Host: `demo.wftpserver.com` (free test server)
   - Port: `2222`
   - Username: `demo-user`
   - Password: `demo-user`

2. **Click "Connect"**
   - Status should change to "Connected"
   - Remote files panel will populate with server files
   - Operation buttons will become enabled

3. **Explore the interface:**
   - Browse through remote directories by double-clicking folders
   - Use the path entry to navigate directly: `/home/demo-user`
   - Notice file icons: 📁 for directories, 📄 for files

### Scenario 2: SSH Key Authentication

**If you have SSH key access:**

1. **Enable key authentication:**
   - Check the "Use SSH Key" checkbox
   - Password field will disable, key field will enable

2. **Select your private key:**
   - Click "Browse" button next to SSH Key field
   - Navigate to your private key (e.g., `~/.ssh/id_rsa`)
   - Select the key file

3. **Connect:**
   - Fill in host, port, and username
   - Click "Connect"

### Scenario 3: File Operations Demo

**Upload files:**

1. **Select a local file:**
   - In the left panel, click on any file you want to upload
   - The file will be highlighted

2. **Upload the file:**
   - Click the "Upload" button in the operations panel
   - Watch the activity log for progress
   - The file should appear in the remote panel

3. **Create a remote directory:**
   - Click "New Folder" button
   - Enter a directory name (e.g., "test_uploads")
   - Click "Create"
   - New folder appears in remote panel

**Download files:**

1. **Select a remote file:**
   - In the right panel, click on a file to download
   - File will be highlighted

2. **Download the file:**
   - Click the "Download" button
   - File will be saved to your current local directory
   - Check the activity log for confirmation

**File management:**

1. **Delete remote files:**
   - Select a remote file
   - Click "Delete" button
   - Confirm in the dialog that appears
   - File is removed from server

2. **Navigate directories:**
   - Double-click on folders to enter them
   - Use the path entry box to type paths directly
   - Use parent directory references (`..`) to go up

### Scenario 4: Advanced Features Demo

**Batch operations:**

1. **Multiple uploads:**
   - Select different local files one by one
   - Upload each by clicking "Upload"
   - Monitor progress in activity log

2. **Directory synchronization:**
   - Create matching folder structures
   - Upload files to maintain organization

**Error handling:**

1. **Test connection errors:**
   - Try connecting with wrong credentials
   - Observe error dialog and log messages

2. **Test file operation errors:**
   - Try uploading to read-only directory
   - Attempt to delete protected files
   - Notice detailed error messages

## 🎯 Feature Walkthrough

### Connection Management

**Visual indicators:**
- 🔴 Red status: "Disconnected"
- 🟢 Green status: "Connected"
- Buttons enable/disable based on connection state

**Authentication options:**
- Password: Traditional username/password
- SSH Key: More secure key-based authentication
- Auto-detection of key format (RSA, ED25519, etc.)

### File Browser Features

**Local browser (left panel):**
- Shows your local file system
- Navigate with path entry or clicking
- Icons distinguish files and folders
- Browse button for quick folder selection

**Remote browser (right panel):**
- Shows server file system (when connected)
- Same navigation as local browser
- Updates automatically after operations
- Path entry shows current remote directory

### Operation Controls

**File transfer buttons:**
- 📤 Upload: Local → Remote
- 📥 Download: Remote → Local
- Progress indication during transfers

**File management:**
- 🗑️ Delete: Remove remote files (with confirmation)
- 📁 New Folder: Create remote directories
- 🔄 Refresh: Update both file lists

### Activity Monitoring

**Real-time logging:**
- Timestamps for all operations
- Success and error messages
- Connection status changes
- File transfer confirmations

**Progress feedback:**
- Visual progress bar for long operations
- Status messages during transfers
- Error dialogs for immediate attention

## 🔧 Troubleshooting Demo

### Common Issues and Solutions

**Connection problems:**
```
Error: Connection failed: dial tcp: no such host
Solution: Check hostname and internet connection
```

**Authentication failures:**
```
Error: Connection failed: ssh: handshake failed
Solution: Verify username, password, or SSH key
```

**File transfer issues:**
```
Error: Upload failed: permission denied
Solution: Check file permissions and target directory
```

**SSH key problems:**
```
Error: Unable to parse private key
Solution: Ensure key is in correct format (not encrypted)
```

### Testing Connection Issues

1. **Invalid hostname:**
   - Enter: `invalid-server-name.com`
   - Observe timeout error and message

2. **Wrong port:**
   - Try port `22` on server that uses `2222`
   - See connection refused error

3. **Bad credentials:**
   - Use wrong password
   - Notice authentication failure

## 📊 Performance Features

### Efficient Operations

**Asynchronous transfers:**
- UI remains responsive during file operations
- Can perform other tasks while transferring
- Cancel operations if needed (future feature)

**Smart caching:**
- Directory listings are cached
- Reduces server requests
- Refresh button forces cache update

**Memory management:**
- Large files handled efficiently
- Proper cleanup of network connections
- No memory leaks during extended use

### Monitoring Performance

**File transfer speeds:**
- Watch activity log for transfer completion times
- Compare different file sizes
- Network conditions affect performance

**Connection stability:**
- Long-running connections maintained
- Automatic reconnection (future feature)
- Timeout handling for slow networks

## 🎨 UI/UX Features

### Visual Design

**Modern interface:**
- Clean, professional appearance
- Consistent iconography throughout
- Native look on each platform (Windows, macOS, Linux)

**Responsive layout:**
- Resizable window with proper scaling
- Panels adjust to content
- Minimum size constraints for usability

**Accessibility:**
- Keyboard navigation support
- Screen reader friendly labels
- High contrast mode compatibility

### User Experience

**Intuitive workflow:**
1. Connect to server
2. Browse files visually
3. Select and transfer with single clicks
4. Monitor progress in real-time
5. Manage files easily

**Error prevention:**
- Input validation on connection fields
- Confirmation dialogs for destructive operations
- Clear status indicators

**Helpful feedback:**
- Tooltips for buttons (future feature)
- Status bar information
- Comprehensive activity logging

## 🔮 Future Enhancements

### Planned Features

**Advanced transfers:**
- Drag and drop support
- Multi-file selection
- Transfer queue with pause/resume
- Progress bars with speed indicators

**Enhanced navigation:**
- Breadcrumb navigation
- Bookmark favorite locations
- Recent connections history
- Tabbed interface for multiple connections

**Security improvements:**
- Host key verification
- Connection profiles with encryption settings
- Secure credential storage
- Two-factor authentication support

**Productivity features:**
- File synchronization
- Scheduled transfers
- File comparison tools
- Search functionality

### Customization Options

**Interface themes:**
- Dark/light mode toggle
- Custom color schemes
- Font size adjustments
- Layout preferences

**Behavior settings:**
- Default directories
- Transfer confirmation settings
- Log verbosity levels
- Auto-refresh intervals

## 📚 Additional Resources

### Documentation
- `README.md` - Installation and basic usage
- `cli-main.go` - Command-line version for scripting
- Source code comments - Detailed implementation notes

### Test Servers
- **demo.wftpserver.com:2222** (demo-user/demo-user)
- **test.rebex.net:22** (demo/password)
- Local development: Use Docker SFTP containers

### Development
- Built with Go 1.21+ and Fyne v2.4+
- Cross-platform: Windows, macOS, Linux
- Easy to extend and customize
- Well-structured, maintainable code

---

**Happy file transferring! 🎉**

For questions, issues, or feature requests, please check the GitHub repository or create an issue.