# Go SFTP Client (GUI)

A modern graphical SFTP (SSH File Transfer Protocol) client written in Go using the Fyne UI framework. This application provides an intuitive GUI for connecting to and managing files on remote servers.

## Features

- **Modern GUI Interface** - Built with Fyne for cross-platform compatibility
- **Dual-pane File Browser** - Side-by-side local and remote file browsing
- **Multiple Authentication Methods** - Password and SSH key authentication
- **Connection Bookmarks** - Save and manage frequently used server connections
- **Collapsible Connection Panel** - Automatically collapses when connected to save screen space
- **Collapsible Activity Log** - Activity log panel collapses when connected to maximize file browser space
- **Footer Status Bar** - Always-visible connection status with quick disconnect button
- **Open Local Files** - Open files with system default applications directly from the client
- **Quick Connect** - One-click connection from saved bookmarks
- **Drag-and-drop Operations** - Easy file upload and download
- **Visual File Management** - Create, delete, and navigate directories
- **Real-time Activity Log** - Monitor all operations with timestamps
- **Progress Indicators** - Visual feedback for file transfers
- **Cross-platform** - Works on Windows, macOS, and Linux

## Installation

### Prerequisites

- Go 1.21 or later
- Git

### Build from Source

1. Clone the repository:
```bash
git clone <repository-url>
cd golang-ftpClient
```

2. Install dependencies:
```bash
go mod tidy
```

3. Build the GUI application:
```bash
go build -o sftp-client-gui main.go
```

4. Run the GUI application:
```bash
./sftp-client-gui
```

### Alternative: CLI Version

A command-line version is also available in `cli-main.go`:
```bash
go build -o sftp-client-cli cli-main.go
./sftp-client-cli
```

## Usage

### Getting Started

1. **Launch the Application**
   ```bash
   ./sftp-client-gui
   ```

2. **Connect to Server**
   - Fill in the connection details:
     - Host: Your server hostname or IP
     - Port: SSH port (default: 22)
     - Username: Your SSH username
     - Password: Your password OR check "Use SSH Key" and browse for your private key

3. **Click Connect**
   - The status will show "Connected" when successful
   - Remote files will appear in the right panel
   - Local files are shown in the left panel

### Main Interface

#### Connection Panel (Top)
- **Bookmarks**: Save and manage frequently used server connections
  - **Select Bookmark**: Choose from saved connections
  - **Quick Connect**: One-click connection from selected bookmark
  - **Save**: Store current connection details as a new bookmark
  - **Delete**: Remove selected bookmark (with confirmation)
- **Host/Port/Username**: Server connection details
- **Authentication**: Choose password or SSH key authentication
- **Connect/Disconnect**: Manage server connection
- **Status**: Shows current connection state
- **Collapsible**: Panel automatically collapses when connected to save screen space

#### Activity Log Panel (Bottom Center)
- **Collapsible Log**: Activity log with expand/collapse functionality
- **Auto-collapse**: Automatically collapses when connected to maximize file browser space
- **Manual Toggle**: Click arrow button to manually expand/collapse anytime
- **Real-time Updates**: All operations logged with timestamps

#### Footer Status Bar (Bottom)
- **Connection Status**: Clean visual indicator with emoji (🔵 Connected / 🔴 Disconnected)
- **Quick Disconnect**: Always-accessible disconnect button
- **Always Visible**: Footer remains visible regardless of panel collapse states
- **Minimal Design**: Clean layout without redundant icons for better clarity

#### File Browser (Center)
- **Left Panel**: Local file system browser
- **Right Panel**: Remote server file browser
- **Path Entries**: Navigate by typing paths directly
- **File Lists**: Click to select files and folders

#### Operations Panel (Right)
- **Upload**: Transfer selected local file to remote server
- **Download**: Transfer selected remote file to local system
- **Open**: Open selected local file with system default application
- **Delete**: Remove selected remote file (with confirmation)
- **New Folder**: Create new directory on remote server
- **Refresh**: Update both file lists

#### Progress Indicators
- **Progress Bar**: Visual indication of ongoing file transfer operations
- **Status Messages**: Real-time feedback for all operations

## Screenshots and Examples

### Main Application Window
The GUI provides an intuitive dual-pane interface:
- Clean, modern design with Fyne UI components
- File icons distinguish between files (📄) and directories (📁)
- Integrated connection management at the top
- Real-time activity logging at the bottom

### Common Workflows

#### 1. Password Authentication
1. Enter server details in connection panel
2. Enter username and password
3. Click "Connect"

#### 2. Using Bookmarks
1. Fill in connection details for a server
2. Click "Save" to create a bookmark
3. Enter a name for the bookmark (e.g., "Production Server")
4. Select the bookmark from the dropdown for future connections
5. Use "Quick Connect" to connect immediately with bookmark settings
6. Use "Delete" to remove unwanted bookmarks

#### 3. Managing Screen Space
1. **Connection Panel**: Automatically collapses when connected
   - Click arrow button to manually toggle
   - Expands automatically when disconnected
2. **Activity Log**: Automatically collapses when connected
   - Click arrow button to manually toggle  
   - Expands automatically when disconnected
3. **Footer Status**: Always shows connection state
   - Clean status display: "🔵 Connected" or "🔴 Disconnected"
   - Quick disconnect button always available
   - Minimal design without redundant icons

#### 4. SSH Key Authentication
1. Enter server details in connection panel
2. Check "Use SSH Key" checkbox
3. Click "Browse" to select your private key file
4. Click "Connect"

#### 5. File Operations
1. **Upload**: Select file in left panel → Click "Upload"
2. **Download**: Select file in right panel → Click "Download"
3. **Open Local Files**: Select file in left panel → Click "Open" or double-click
4. **Batch Operations**: Repeat for multiple files

#### 6. Opening Local Files
1. **Button Method**: Select a local file → Click "Open" button
2. **Double-click Method**: Double-click any file in the local file list
3. **System Integration**: Files open with their default applications
4. **File Type Support**: Works with any file type (text, images, documents, etc.)
5. **Error Handling**: Shows helpful messages for directories or missing files

#### 7. Directory Management
1. **Navigate**: Double-click folders or type path in path entry
2. **Create Folder**: Click "New Folder" and enter name
3. **Delete**: Select item and click "Delete" (with confirmation)

## Security Notes

- **Host Key Verification**: Currently uses `ssh.InsecureIgnoreHostKey()` for development ease
- **Production Use**: Implement proper host key verification for production environments
- **SSH Key Storage**: Store private keys securely with appropriate permissions (600)
- **Password Security**: Passwords are handled securely in memory but not persisted
- **Network Security**: All communications use encrypted SSH protocol

## Accessibility Features

- **Color Blind Friendly**: Status indicators use blue (🔵) and red (🔴) colors instead of green/red to improve accessibility for color blind users
- **High Contrast**: Bold text and clear visual separators for better readability
- **Keyboard Navigation**: Full keyboard support for all UI elements
- **Screen Reader Friendly**: Proper labeling and semantic structure

## Dependencies

### Core Libraries
- `fyne.io/fyne/v2` - Cross-platform GUI framework
- `github.com/pkg/sftp` - SFTP client library  
- `golang.org/x/crypto/ssh` - SSH client implementation

### GUI Components
- Modern, native-looking interface on all platforms
- Responsive design that works on different screen sizes
- Keyboard shortcuts and accessibility features

## Advanced Features

### User Experience Improvements

#### Smart Interface Adaptation
The application automatically adapts its interface based on connection state:

- **Connected State**: 
  - Connection panel collapses to save space
  - Activity log collapses to maximize file browser area
  - Footer shows "🔵 Connected" status
  - Quick disconnect always available in footer

- **Disconnected State**:
  - Connection panel expands for easy reconnection
  - Activity log expands to show connection attempts
  - Footer shows "🔴 Disconnected" status
  - Connection controls prominently displayed

#### Space-Efficient Design
- **Collapsible Panels**: Both connection and activity log panels can be manually toggled
- **Intelligent Defaults**: Panels automatically collapse/expand based on workflow needs
- **Always-Accessible Controls**: Critical functions like disconnect remain visible
- **Visual Status Indicators**: Color-coded status (🔵/🔴) for instant connection state recognition

#### File Integration
- **System Default Applications**: Open any local file with its default application
- **Cross-Platform Support**: Works on Windows (`rundll32`), macOS (`open`), and Linux (`xdg-open`)
- **Double-Click Convenience**: Quick file opening without extra clicks
- **Smart File Detection**: Automatically prevents opening directories as files
- **Activity Logging**: All file open operations are logged for reference

### Bookmarks Management

#### Storage Location
Bookmarks are automatically saved to `~/.config/KAT-ftp/bookmarks.json` in your home directory's config folder.

#### Bookmark File Format
The bookmarks file uses JSON format:
```json
[
  {
    "name": "Production Server",
    "host": "prod.example.com",
    "port": "22",
    "username": "admin",
    "use_ssh_key": true,
    "key_path": "/home/user/.ssh/id_rsa"
  },
  {
    "name": "Development Server",
    "host": "dev.example.com",
    "port": "2222",
    "username": "developer",
    "use_ssh_key": false,
    "key_path": ""
  }
]
```

#### Security Considerations
- **Passwords are NOT stored** in bookmarks for security reasons
- Only connection details and SSH key paths are saved
- SSH key files should have proper permissions (600)
- Bookmark file is created with restricted permissions (600)

#### Manual Bookmark Management
You can manually edit the bookmarks file or copy it between machines:
```bash
# View current bookmarks
cat ~/.config/KAT-ftp/bookmarks.json

# Backup bookmarks
cp ~/.config/KAT-ftp/bookmarks.json ~/sftp-bookmarks-backup.json

# Copy bookmarks to another machine
scp ~/.config/KAT-ftp/bookmarks.json user@machine:~/

# Set more secure permissions
chmod 600 ~/.config/KAT-ftp/bookmarks.json
```

#### Cross-platform Locations
The config directory is automatically detected for your operating system:
- **macOS**: `/Users/yourusername/.config/KAT-ftp/bookmarks.json`
- **Linux**: `/home/yourusername/.config/KAT-ftp/bookmarks.json` 
- **Windows**: `C:\Users\yourusername\.config\KAT-ftp\bookmarks.json`

The app uses Go's `os.UserHomeDir()` function to automatically detect the correct home directory and creates the `.config/KAT-ftp/` subdirectory for storing all application configuration files.

#### Migration from Old Location
If you have existing bookmarks from a previous version stored at `~/.sftp-client-bookmarks.json`, they will be automatically migrated to the new location when you first run the updated app.

### Technical Implementation

#### Open File Functionality
The open file feature uses platform-specific commands to launch files with their default applications:

```go
func (app *SFTPApp) openWithSystemDefault(filepath string) error {
    var cmd *exec.Cmd

    switch runtime.GOOS {
    case "windows":
        cmd = exec.Command("rundll32", "url.dll,FileProtocolHandler", filepath)
    case "darwin":
        cmd = exec.Command("open", filepath)
    case "linux":
        cmd = exec.Command("xdg-open", filepath)
    default:
        return fmt.Errorf("unsupported operating system: %s", runtime.GOOS)
    }

    return cmd.Start()
}
```

**Platform Commands:**
- **Windows**: `rundll32 url.dll,FileProtocolHandler` - Uses Windows shell association
- **macOS**: `open` - Uses macOS Launch Services
- **Linux**: `xdg-open` - Uses XDG MIME type associations

**Double-Click Detection:**
- Tracks click timing and list item ID
- 500ms window for double-click detection
- Only opens files (not directories)
- Integrates seamlessly with existing file selection

### Build Options
```bash
# Build GUI version (default)
make build

# Build CLI version  
go build -o sftp-client-cli cli-main.go

# Build for multiple platforms
make build-all

# Run tests
make test

# Generate coverage report
make test-coverage
```

### Configuration
- Settings are managed through the GUI interface
- Connection history can be implemented as a future feature
- Customizable file transfer settings

### Error Handling

The GUI application provides user-friendly error handling:
- **Visual Dialogs**: Error messages appear in popup dialogs
- **Activity Logging**: All errors are logged in the activity panel
- **Connection Issues**: Clear feedback for authentication and network problems
- **File Operations**: Detailed error messages for transfer failures
- **Input Validation**: Real-time validation of user inputs

### Performance Features
- **Asynchronous Operations**: File transfers don't block the UI
- **Progress Indicators**: Visual feedback during long operations
- **Efficient File Listing**: Optimized directory browsing
- **Memory Management**: Proper cleanup of resources

## Platform Support

- **Windows**: Full support with native Windows look and feel
- **macOS**: Native macOS interface with proper menu integration
- **Linux**: GTK-based interface that integrates with desktop environments

## License

This project is open source. Please check the LICENSE file for details.

## Contributing

Contributions are welcome! Areas for improvement:
- Host key verification implementation
- Connection history/bookmarks
- File transfer progress bars with cancellation
- Keyboard shortcuts
- Drag-and-drop file operations
- Multi-file selection and batch operations

Please feel free to submit pull requests or open issues for bugs and feature requests.