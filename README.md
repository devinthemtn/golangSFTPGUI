# Go SFTP Client (GUI)

A modern graphical SFTP (SSH File Transfer Protocol) client written in Go using the Fyne UI framework. This application provides an intuitive GUI for connecting to and managing files on remote servers.

## Features

- **Modern GUI Interface** - Built with Fyne for cross-platform compatibility
- **Dual-pane File Browser** - Side-by-side local and remote file browsing
- **Multiple Authentication Methods** - Password and SSH key authentication
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
- **Host/Port/Username**: Server connection details
- **Authentication**: Choose password or SSH key authentication
- **Connect/Disconnect**: Manage server connection
- **Status**: Shows current connection state

#### File Browser (Center)
- **Left Panel**: Local file system browser
- **Right Panel**: Remote server file browser
- **Path Entries**: Navigate by typing paths directly
- **File Lists**: Click to select files and folders

#### Operations Panel (Right)
- **Upload**: Transfer selected local file to remote server
- **Download**: Transfer selected remote file to local system
- **Delete**: Remove selected remote file (with confirmation)
- **New Folder**: Create new directory on remote server
- **Refresh**: Update both file lists

#### Activity Log (Bottom)
- **Real-time Logging**: All operations are logged with timestamps
- **Error Messages**: Failed operations show detailed error information
- **Progress Feedback**: Visual indication of ongoing operations

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

#### 2. SSH Key Authentication
1. Enter server details in connection panel
2. Check "Use SSH Key" checkbox
3. Click "Browse" to select your private key file
4. Click "Connect"

#### 3. File Transfer
1. **Upload**: Select file in left panel → Click "Upload"
2. **Download**: Select file in right panel → Click "Download"
3. **Batch Operations**: Repeat for multiple files

#### 4. Directory Management
1. **Navigate**: Double-click folders or type path in path entry
2. **Create Folder**: Click "New Folder" and enter name
3. **Delete**: Select item and click "Delete" (with confirmation)

## Security Notes

- **Host Key Verification**: Currently uses `ssh.InsecureIgnoreHostKey()` for development ease
- **Production Use**: Implement proper host key verification for production environments
- **SSH Key Storage**: Store private keys securely with appropriate permissions (600)
- **Password Security**: Passwords are handled securely in memory but not persisted
- **Network Security**: All communications use encrypted SSH protocol

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