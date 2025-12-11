package main

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"time"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/app"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/data/binding"
	"fyne.io/fyne/v2/dialog"
	"fyne.io/fyne/v2/layout"
	"fyne.io/fyne/v2/theme"
	"fyne.io/fyne/v2/widget"
	"github.com/pkg/sftp"
	"golang.org/x/crypto/ssh"
)

// SFTPGUIClient wraps the SFTP functionality for GUI use
// Bookmark represents a saved connection configuration
type Bookmark struct {
	Name      string `json:"name"`
	Host      string `json:"host"`
	Port      string `json:"port"`
	Username  string `json:"username"`
	UseSSHKey bool   `json:"use_ssh_key"`
	KeyPath   string `json:"key_path,omitempty"`
}

type SFTPGUIClient struct {
	sshClient  *ssh.Client
	sftpClient *sftp.Client
	connected  bool
}

// SFTPApp represents the main application
type SFTPApp struct {
	app    fyne.App
	window fyne.Window
	client *SFTPGUIClient

	// Connection widgets
	hostEntry         *widget.Entry
	portEntry         *widget.Entry
	userEntry         *widget.Entry
	passEntry         *widget.Entry
	keyEntry          *widget.Entry
	useKeyCheck       *widget.Check
	connectBtn        *widget.Button
	disconnectBtn     *widget.Button
	statusLabel       *widget.Label
	connectionPanel   *fyne.Container
	connectionContent *fyne.Container
	collapseBtn       *widget.Button
	isCollapsed       bool

	// Bookmark widgets
	bookmarkSelect    *widget.Select
	saveBookmarkBtn   *widget.Button
	deleteBookmarkBtn *widget.Button
	quickConnectBtn   *widget.Button
	bookmarks         []Bookmark
	bookmarksFile     string

	// File browser widgets
	remoteList *widget.List
	localList  *widget.List
	remotePath *widget.Entry
	localPath  *widget.Entry

	// Operation buttons
	uploadBtn   *widget.Button
	downloadBtn *widget.Button
	deleteBtn   *widget.Button
	mkdirBtn    *widget.Button
	refreshBtn  *widget.Button

	// Status and progress
	progressBar *widget.ProgressBar
	logArea     *widget.Entry

	// Activity log collapse
	logPanel       *fyne.Container
	logContent     *fyne.Container
	logCollapseBtn *widget.Button
	isLogCollapsed bool

	// Footer widgets
	footerPanel      *fyne.Container
	connectionStatus *widget.Label
	footerDisconnect *widget.Button

	// Data bindings
	remoteFiles    binding.StringList
	localFiles     binding.StringList
	currentRemote  string
	currentLocal   string
	selectedRemote string
	selectedLocal  string
}

// NewSFTPGUIClient creates a new SFTP client
func NewSFTPGUIClient() *SFTPGUIClient {
	return &SFTPGUIClient{
		connected: false,
	}
}

// Connect establishes connection with password authentication
func (c *SFTPGUIClient) Connect(host, username, password string, port int) error {
	config := &ssh.ClientConfig{
		User: username,
		Auth: []ssh.AuthMethod{
			ssh.Password(password),
		},
		HostKeyCallback: ssh.InsecureIgnoreHostKey(),
		Timeout:         30 * time.Second,
	}

	addr := fmt.Sprintf("%s:%d", host, port)
	sshClient, err := ssh.Dial("tcp", addr, config)
	if err != nil {
		return fmt.Errorf("failed to connect to SSH server: %v", err)
	}

	sftpClient, err := sftp.NewClient(sshClient)
	if err != nil {
		sshClient.Close()
		return fmt.Errorf("failed to create SFTP client: %v", err)
	}

	c.sshClient = sshClient
	c.sftpClient = sftpClient
	c.connected = true

	return nil
}

// ConnectWithKey establishes connection with key authentication
func (c *SFTPGUIClient) ConnectWithKey(host, username, keyPath string, port int) error {
	key, err := os.ReadFile(keyPath)
	if err != nil {
		return fmt.Errorf("unable to read private key: %v", err)
	}

	signer, err := ssh.ParsePrivateKey(key)
	if err != nil {
		return fmt.Errorf("unable to parse private key: %v", err)
	}

	config := &ssh.ClientConfig{
		User: username,
		Auth: []ssh.AuthMethod{
			ssh.PublicKeys(signer),
		},
		HostKeyCallback: ssh.InsecureIgnoreHostKey(),
		Timeout:         30 * time.Second,
	}

	addr := fmt.Sprintf("%s:%d", host, port)
	sshClient, err := ssh.Dial("tcp", addr, config)
	if err != nil {
		return fmt.Errorf("failed to connect to SSH server: %v", err)
	}

	sftpClient, err := sftp.NewClient(sshClient)
	if err != nil {
		sshClient.Close()
		return fmt.Errorf("failed to create SFTP client: %v", err)
	}

	c.sshClient = sshClient
	c.sftpClient = sftpClient
	c.connected = true

	return nil
}

// Disconnect closes the connection
func (c *SFTPGUIClient) Disconnect() error {
	if !c.connected {
		return nil
	}

	if c.sftpClient != nil {
		c.sftpClient.Close()
	}
	if c.sshClient != nil {
		c.sshClient.Close()
	}

	c.connected = false
	return nil
}

// IsConnected returns connection status
func (c *SFTPGUIClient) IsConnected() bool {
	return c.connected
}

// GetFiles returns files in the specified directory
func (c *SFTPGUIClient) GetFiles(path string) ([]string, error) {
	if !c.connected {
		return nil, fmt.Errorf("not connected")
	}

	files, err := c.sftpClient.ReadDir(path)
	if err != nil {
		return nil, err
	}

	var fileList []string
	for _, file := range files {
		prefix := "📄 "
		if file.IsDir() {
			prefix = "📁 "
		}
		fileList = append(fileList, prefix+file.Name())
	}

	return fileList, nil
}

// NewSFTPApp creates a new SFTP GUI application
func NewSFTPApp() *SFTPApp {
	myApp := app.New()
	// Commenting out icon to avoid corruption error
	// myApp.SetIcon(AppIcon())

	window := myApp.NewWindow("SFTP Client")
	window.Resize(fyne.NewSize(1200, 800))

	// Get application config directory
	configDir, err := getConfigDir()
	if err != nil {
		fmt.Printf("Warning: Could not create config directory: %v\n", err)
		// Fallback to home directory
		homeDir, _ := os.UserHomeDir()
		configDir = homeDir
	}

	bookmarksFile := filepath.Join(configDir, "bookmarks.json")

	// Migrate existing bookmarks from old location if they exist
	homeDir, _ := os.UserHomeDir()
	oldBookmarksFile := filepath.Join(homeDir, ".sftp-client-bookmarks.json")
	migrateOldBookmarks(oldBookmarksFile, bookmarksFile)

	sftpApp := &SFTPApp{
		app:           myApp,
		window:        window,
		client:        NewSFTPGUIClient(),
		bookmarksFile: bookmarksFile,
	}

	// Load bookmarks before setting up UI
	sftpApp.loadBookmarks()
	sftpApp.setupUI()
	return sftpApp
}

// getConfigDir returns the application's configuration directory
func getConfigDir() (string, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return "", err
	}
	configDir := filepath.Join(homeDir, ".config", "KAT-ftp")

	// Create config directory if it doesn't exist
	err = os.MkdirAll(configDir, 0755)
	if err != nil {
		return "", err
	}

	return configDir, nil
}

// migrateOldBookmarks migrates bookmarks from the old location to new location
func migrateOldBookmarks(oldPath, newPath string) {
	if _, err := os.Stat(oldPath); err == nil {
		// Old bookmarks file exists, check if new one doesn't
		if _, err := os.Stat(newPath); os.IsNotExist(err) {
			// Copy old bookmarks to new location
			if data, err := os.ReadFile(oldPath); err == nil {
				os.WriteFile(newPath, data, 0600)
				fmt.Printf("Migrated bookmarks from %s to %s\n", oldPath, newPath)
				// Optionally remove old file after successful migration
				// os.Remove(oldPath)
			}
		}
	}
}

// setupUI creates and configures the user interface
func (app *SFTPApp) setupUI() {
	// Initialize data bindings
	app.remoteFiles = binding.NewStringList()
	app.localFiles = binding.NewStringList()

	// Create connection panel
	connectionPanel := app.createConnectionPanel()

	// Create file browser panel
	browserPanel := app.createBrowserPanel()

	// Create control panel
	controlPanel := app.createControlPanel()

	// Create status panel
	statusPanel := app.createStatusPanel()

	// Create footer panel
	footerPanel := app.createFooterPanel()

	// Create main layout with proper separation
	mainContent := container.New(layout.NewBorderLayout(nil, statusPanel, nil, nil),
		statusPanel,
		browserPanel,
	)

	content := container.New(layout.NewBorderLayout(connectionPanel, footerPanel, nil, controlPanel),
		connectionPanel,
		footerPanel,
		controlPanel,
		mainContent,
	)

	app.window.SetContent(content)

	// Initialize local directory
	app.updateLocalFiles()
}

// createConnectionPanel creates the connection configuration panel
func (app *SFTPApp) createConnectionPanel() fyne.CanvasObject {
	app.hostEntry = widget.NewEntry()
	app.hostEntry.SetPlaceHolder("Host (e.g., example.com)")

	app.portEntry = widget.NewEntry()
	app.portEntry.SetText("22")
	app.portEntry.SetPlaceHolder("Port")

	app.userEntry = widget.NewEntry()
	app.userEntry.SetPlaceHolder("Username")

	app.passEntry = widget.NewPasswordEntry()
	app.passEntry.SetPlaceHolder("Password")

	app.keyEntry = widget.NewEntry()
	app.keyEntry.SetPlaceHolder("SSH Key Path")
	app.keyEntry.Disable()

	app.useKeyCheck = widget.NewCheck("Use SSH Key", func(checked bool) {
		if checked {
			app.passEntry.Disable()
			app.keyEntry.Enable()
		} else {
			app.passEntry.Enable()
			app.keyEntry.Disable()
		}
	})

	keyBrowseBtn := widget.NewButton("Browse", func() {
		dialog.ShowFileOpen(func(reader fyne.URIReadCloser, err error) {
			if err == nil && reader != nil {
				app.keyEntry.SetText(reader.URI().Path())
				reader.Close()
			}
		}, app.window)
	})

	app.connectBtn = widget.NewButtonWithIcon("Connect", theme.ConfirmIcon(), app.onConnect)
	app.disconnectBtn = widget.NewButtonWithIcon("Disconnect", theme.CancelIcon(), app.onDisconnect)
	app.disconnectBtn.Disable()

	app.statusLabel = widget.NewLabel("Disconnected")
	app.statusLabel.TextStyle.Bold = true

	// Layout connection form
	form := container.NewGridWithColumns(2,
		widget.NewLabel("Host:"), app.hostEntry,
		widget.NewLabel("Port:"), app.portEntry,
		widget.NewLabel("Username:"), app.userEntry,
		widget.NewLabel("Password:"), app.passEntry,
		widget.NewLabel("SSH Key:"), container.NewBorder(nil, nil, nil, keyBrowseBtn, app.keyEntry),
	)

	authPanel := container.NewHBox(app.useKeyCheck)
	buttonPanel := container.NewHBox(app.connectBtn, app.disconnectBtn, layout.NewSpacer(), app.statusLabel)

	// Create bookmark widgets
	app.bookmarkSelect = widget.NewSelect(app.getBookmarkNames(), func(selected string) {
		app.loadBookmarkByName(selected)
	})
	// Note: Fyne Select widget doesn't have SetPlaceHolder in v2.4.3
	app.bookmarkSelect.PlaceHolder = "Select a bookmark..."

	app.saveBookmarkBtn = widget.NewButtonWithIcon("Save", theme.DocumentSaveIcon(), func() {
		app.showSaveBookmarkDialog()
	})

	app.deleteBookmarkBtn = widget.NewButtonWithIcon("Delete", theme.DeleteIcon(), func() {
		app.deleteSelectedBookmark()
	})
	app.deleteBookmarkBtn.Disable()

	app.quickConnectBtn = widget.NewButtonWithIcon("Quick Connect", theme.MailForwardIcon(), func() {
		app.quickConnectFromBookmark()
	})
	app.quickConnectBtn.Disable()

	// Create bookmark panel
	bookmarkPanel := container.NewHBox(
		widget.NewLabel("Bookmarks:"),
		app.bookmarkSelect,
		app.quickConnectBtn,
		app.saveBookmarkBtn,
		app.deleteBookmarkBtn,
	)

	// Create the connection details content
	app.connectionContent = container.NewVBox(bookmarkPanel, form, authPanel, buttonPanel)

	// Create collapse/expand button
	app.collapseBtn = widget.NewButtonWithIcon("", theme.MenuDropDownIcon(), func() {
		app.toggleConnectionPanel()
	})
	app.collapseBtn.Resize(fyne.NewSize(30, 30))

	// Create header with collapse button
	headerPanel := container.NewBorder(nil, nil, nil, app.collapseBtn,
		widget.NewLabelWithStyle("Connection", fyne.TextAlignLeading, fyne.TextStyle{Bold: true}))

	// Create main connection panel
	app.connectionPanel = container.NewVBox(
		headerPanel,
		app.connectionContent,
	)

	app.isCollapsed = false
	return app.connectionPanel
}

// createBrowserPanel creates the file browser panel
func (app *SFTPApp) createBrowserPanel() fyne.CanvasObject {
	// Local file browser
	app.localPath = widget.NewEntry()
	app.localPath.SetText(".")
	app.localPath.OnSubmitted = func(path string) {
		app.currentLocal = path
		app.updateLocalFiles()
	}

	localBrowseBtn := widget.NewButton("Browse", func() {
		dialog.ShowFolderOpen(func(uri fyne.ListableURI, err error) {
			if err == nil && uri != nil {
				app.localPath.SetText(uri.Path())
				app.currentLocal = uri.Path()
				app.updateLocalFiles()
			}
		}, app.window)
	})

	app.localList = widget.NewListWithData(app.localFiles,
		func() fyne.CanvasObject {
			return widget.NewLabel("template")
		},
		func(item binding.DataItem, obj fyne.CanvasObject) {
			label := obj.(*widget.Label)
			strItem := item.(binding.String)
			val, _ := strItem.Get()
			label.SetText(val)
		},
	)
	app.localList.OnSelected = func(id widget.ListItemID) {
		if val, err := app.localFiles.GetValue(id); err == nil {
			app.selectedLocal = strings.TrimPrefix(val, "📄 ")
			app.selectedLocal = strings.TrimPrefix(app.selectedLocal, "📁 ")
		}
	}

	// Remote file browser
	app.remotePath = widget.NewEntry()
	app.remotePath.SetPlaceHolder("Remote path")
	app.remotePath.OnSubmitted = func(path string) {
		if app.client.IsConnected() {
			app.currentRemote = path
			app.updateRemoteFiles()
		}
	}

	app.remoteList = widget.NewListWithData(app.remoteFiles,
		func() fyne.CanvasObject {
			return widget.NewLabel("template")
		},
		func(item binding.DataItem, obj fyne.CanvasObject) {
			label := obj.(*widget.Label)
			strItem := item.(binding.String)
			val, _ := strItem.Get()
			label.SetText(val)
		},
	)
	app.remoteList.OnSelected = func(id widget.ListItemID) {
		if val, err := app.remoteFiles.GetValue(id); err == nil {
			app.selectedRemote = strings.TrimPrefix(val, "📄 ")
			app.selectedRemote = strings.TrimPrefix(app.selectedRemote, "📁 ")
		}
	}

	localPanel := container.NewBorder(
		container.NewBorder(nil, nil, widget.NewLabel("Local Path:"), localBrowseBtn, app.localPath),
		nil, nil, nil,
		container.NewScroll(app.localList),
	)

	remotePanel := container.NewBorder(
		container.NewBorder(nil, nil, widget.NewLabel("Remote Path:"), nil, app.remotePath),
		nil, nil, nil,
		container.NewScroll(app.remoteList),
	)

	return container.NewHSplit(
		widget.NewCard("Local Files", "", localPanel),
		widget.NewCard("Remote Files", "", remotePanel),
	)
}

// createControlPanel creates the control buttons panel
func (app *SFTPApp) createControlPanel() fyne.CanvasObject {
	app.uploadBtn = widget.NewButtonWithIcon("Upload", theme.UploadIcon(), app.onUpload)
	app.uploadBtn.Disable()

	app.downloadBtn = widget.NewButtonWithIcon("Download", theme.DownloadIcon(), app.onDownload)
	app.downloadBtn.Disable()

	app.deleteBtn = widget.NewButtonWithIcon("Delete", theme.DeleteIcon(), app.onDelete)
	app.deleteBtn.Disable()

	app.mkdirBtn = widget.NewButtonWithIcon("New Folder", theme.FolderNewIcon(), app.onMkdir)
	app.mkdirBtn.Disable()

	app.refreshBtn = widget.NewButtonWithIcon("Refresh", theme.ViewRefreshIcon(), app.onRefresh)
	app.refreshBtn.Disable()

	return container.NewVBox(
		widget.NewCard("Operations", "",
			container.NewVBox(
				app.uploadBtn,
				app.downloadBtn,
				widget.NewSeparator(),
				app.deleteBtn,
				app.mkdirBtn,
				widget.NewSeparator(),
				app.refreshBtn,
			),
		),
	)
}

// createStatusPanel creates the status and progress panel
func (app *SFTPApp) createStatusPanel() fyne.CanvasObject {
	app.progressBar = widget.NewProgressBar()
	app.progressBar.Hide()

	app.logArea = widget.NewMultiLineEntry()
	app.logArea.SetPlaceHolder("Activity log will appear here...")
	app.logArea.Wrapping = fyne.TextWrapWord

	logScroll := container.NewScroll(app.logArea)
	logScroll.SetMinSize(fyne.NewSize(0, 150))

	// Create the log content
	app.logContent = container.NewVBox(logScroll)

	// Create collapse/expand button for log
	app.logCollapseBtn = widget.NewButtonWithIcon("", theme.MenuDropDownIcon(), func() {
		app.toggleLogPanel()
	})
	app.logCollapseBtn.Resize(fyne.NewSize(30, 30))

	// Create header with collapse button
	logHeaderPanel := container.NewBorder(nil, nil, nil, app.logCollapseBtn,
		widget.NewLabelWithStyle("Activity Log", fyne.TextAlignLeading, fyne.TextStyle{Bold: true}))

	// Create main log panel
	app.logPanel = container.NewVBox(
		logHeaderPanel,
		app.logContent,
	)

	app.isLogCollapsed = false

	return container.NewVBox(
		app.progressBar,
		app.logPanel,
	)
}

// Event handlers
func (app *SFTPApp) onConnect() {
	host := app.hostEntry.Text
	port := 22
	if portText := app.portEntry.Text; portText != "" {
		fmt.Sscanf(portText, "%d", &port)
	}
	username := app.userEntry.Text

	if host == "" || username == "" {
		app.showError("Please enter host and username")
		return
	}

	app.showProgress("Connecting...")

	var err error
	if app.useKeyCheck.Checked {
		keyPath := app.keyEntry.Text
		if keyPath == "" {
			app.showError("Please select SSH key file")
			app.hideProgress()
			return
		}
		err = app.client.ConnectWithKey(host, username, keyPath, port)
	} else {
		password := app.passEntry.Text
		if password == "" {
			app.showError("Please enter password")
			app.hideProgress()
			return
		}
		err = app.client.Connect(host, username, password, port)
	}

	app.hideProgress()

	if err != nil {
		app.showError(fmt.Sprintf("Connection failed: %v", err))
		return
	}

	app.onConnected()
}

// createFooterPanel creates the footer with connection status and disconnect button
func (app *SFTPApp) createFooterPanel() fyne.CanvasObject {
	// Create connection status label (no redundant icon needed)
	app.connectionStatus = widget.NewLabel("🔴 Disconnected")
	app.connectionStatus.TextStyle.Bold = true

	// Create footer disconnect button
	app.footerDisconnect = widget.NewButtonWithIcon("Disconnect", theme.CancelIcon(), app.onDisconnect)
	app.footerDisconnect.Disable()

	// Create footer panel with clean design
	app.footerPanel = container.NewBorder(
		nil, nil,
		app.connectionStatus,
		app.footerDisconnect,
		widget.NewSeparator(),
	)

	return app.footerPanel
}

func (app *SFTPApp) onDisconnect() {
	app.client.Disconnect()
	app.onDisconnected()
}

func (app *SFTPApp) onConnected() {
	app.statusLabel.SetText("Connected")
	app.connectBtn.Disable()
	app.disconnectBtn.Enable()

	// Enable operation buttons
	app.uploadBtn.Enable()
	app.downloadBtn.Enable()
	app.deleteBtn.Enable()
	app.mkdirBtn.Enable()
	app.refreshBtn.Enable()

	app.logMessage("Connected successfully")

	// Set initial remote path and load files
	app.remotePath.SetText(".")
	app.currentRemote = "."
	app.updateRemoteFiles()

	// Collapse the connection panel to save space
	if !app.isCollapsed {
		app.toggleConnectionPanel()
	}

	// Update footer status
	app.connectionStatus.SetText("🔵 Connected")
	app.footerDisconnect.Enable()

	// Collapse the activity log to save space
	if !app.isLogCollapsed {
		app.toggleLogPanel()
	}
}

func (app *SFTPApp) onDisconnected() {
	app.statusLabel.SetText("Disconnected")
	app.connectBtn.Enable()
	app.disconnectBtn.Disable()

	// Disable operation buttons
	app.uploadBtn.Disable()
	app.downloadBtn.Disable()
	app.deleteBtn.Disable()
	app.mkdirBtn.Disable()
	app.refreshBtn.Disable()

	// Clear remote files
	app.remoteFiles.Set([]string{})

	app.logMessage("Disconnected")

	// Expand the connection panel when disconnected
	if app.isCollapsed {
		app.toggleConnectionPanel()
	}

	// Update bookmark selection state
	app.bookmarkSelect.ClearSelected()
	app.deleteBookmarkBtn.Disable()
	app.quickConnectBtn.Disable()

	// Update footer status
	app.connectionStatus.SetText("🔴 Disconnected")
	app.footerDisconnect.Disable()

	// Expand the activity log when disconnected
	if app.isLogCollapsed {
		app.toggleLogPanel()
	}
}

func (app *SFTPApp) onUpload() {
	if app.selectedLocal == "" {
		app.showError("Please select a local file to upload")
		return
	}

	localFile := filepath.Join(app.currentLocal, app.selectedLocal)
	remoteFile := app.currentRemote + "/" + app.selectedLocal

	app.showProgress("Uploading...")

	go func() {
		err := app.uploadFile(localFile, remoteFile)
		app.hideProgress()

		if err != nil {
			app.showError(fmt.Sprintf("Upload failed: %v", err))
		} else {
			app.logMessage(fmt.Sprintf("Uploaded: %s", app.selectedLocal))
			app.updateRemoteFiles()
		}
	}()
}

func (app *SFTPApp) onDownload() {
	if app.selectedRemote == "" {
		app.showError("Please select a remote file to download")
		return
	}

	remoteFile := app.currentRemote + "/" + app.selectedRemote
	localFile := filepath.Join(app.currentLocal, app.selectedRemote)

	app.showProgress("Downloading...")

	go func() {
		err := app.downloadFile(remoteFile, localFile)
		app.hideProgress()

		if err != nil {
			app.showError(fmt.Sprintf("Download failed: %v", err))
		} else {
			app.logMessage(fmt.Sprintf("Downloaded: %s", app.selectedRemote))
			app.updateLocalFiles()
		}
	}()
}

func (app *SFTPApp) onDelete() {
	if app.selectedRemote == "" {
		app.showError("Please select a remote file to delete")
		return
	}

	dialog.ShowConfirm("Confirm Delete",
		fmt.Sprintf("Are you sure you want to delete '%s'?", app.selectedRemote),
		func(confirmed bool) {
			if confirmed {
				remoteFile := app.currentRemote + "/" + app.selectedRemote
				err := app.client.sftpClient.Remove(remoteFile)
				if err != nil {
					app.showError(fmt.Sprintf("Delete failed: %v", err))
				} else {
					app.logMessage(fmt.Sprintf("Deleted: %s", app.selectedRemote))
					app.updateRemoteFiles()
				}
			}
		}, app.window)
}

func (app *SFTPApp) onMkdir() {
	entry := widget.NewEntry()
	entry.SetPlaceHolder("Enter directory name")

	dialog.ShowForm("Create Directory", "Create", "Cancel",
		[]*widget.FormItem{
			widget.NewFormItem("Directory Name", entry),
		},
		func(confirmed bool) {
			if confirmed && entry.Text != "" {
				remotePath := app.currentRemote + "/" + entry.Text
				err := app.client.sftpClient.Mkdir(remotePath)
				if err != nil {
					app.showError(fmt.Sprintf("Create directory failed: %v", err))
				} else {
					app.logMessage(fmt.Sprintf("Created directory: %s", entry.Text))
					app.updateRemoteFiles()
				}
			}
		}, app.window)
}

func (app *SFTPApp) onRefresh() {
	app.updateRemoteFiles()
	app.updateLocalFiles()
}

// Helper methods
func (app *SFTPApp) updateLocalFiles() {
	files, err := app.getLocalFiles(app.currentLocal)
	if err != nil {
		app.logMessage(fmt.Sprintf("Error reading local directory: %v", err))
		return
	}
	app.localFiles.Set(files)
}

func (app *SFTPApp) updateRemoteFiles() {
	if !app.client.IsConnected() {
		return
	}

	files, err := app.client.GetFiles(app.currentRemote)
	if err != nil {
		app.logMessage(fmt.Sprintf("Error reading remote directory: %v", err))
		return
	}
	app.remoteFiles.Set(files)
}

func (app *SFTPApp) getLocalFiles(path string) ([]string, error) {
	files, err := os.ReadDir(path)
	if err != nil {
		return nil, err
	}

	var fileList []string
	for _, file := range files {
		prefix := "📄 "
		if file.IsDir() {
			prefix = "📁 "
		}
		fileList = append(fileList, prefix+file.Name())
	}

	return fileList, nil
}

func (app *SFTPApp) uploadFile(localPath, remotePath string) error {
	localFile, err := os.Open(localPath)
	if err != nil {
		return err
	}
	defer localFile.Close()

	remoteFile, err := app.client.sftpClient.Create(remotePath)
	if err != nil {
		return err
	}
	defer remoteFile.Close()

	_, err = io.Copy(remoteFile, localFile)
	return err
}

func (app *SFTPApp) downloadFile(remotePath, localPath string) error {
	remoteFile, err := app.client.sftpClient.Open(remotePath)
	if err != nil {
		return err
	}
	defer remoteFile.Close()

	localFile, err := os.Create(localPath)
	if err != nil {
		return err
	}
	defer localFile.Close()

	_, err = io.Copy(localFile, remoteFile)
	return err
}

func (app *SFTPApp) showProgress(message string) {
	app.progressBar.Show()
	app.logMessage(message)
}

func (app *SFTPApp) hideProgress() {
	app.progressBar.Hide()
}

func (app *SFTPApp) logMessage(message string) {
	timestamp := time.Now().Format("15:04:05")
	logEntry := fmt.Sprintf("[%s] %s\n", timestamp, message)
	app.logArea.SetText(app.logArea.Text + logEntry)
}

func (app *SFTPApp) showError(message string) {
	dialog.ShowError(fmt.Errorf(message), app.window)
	app.logMessage("ERROR: " + message)
}

// Run starts the application
func (app *SFTPApp) Run() {
	app.window.ShowAndRun()
}

func (app *SFTPApp) toggleConnectionPanel() {
	if app.isCollapsed {
		// Expand
		app.connectionPanel.Objects = []fyne.CanvasObject{
			app.connectionPanel.Objects[0], // header
			app.connectionContent,
		}
		app.collapseBtn.SetIcon(theme.MenuDropDownIcon())
		app.isCollapsed = false
	} else {
		// Collapse
		app.connectionPanel.Objects = []fyne.CanvasObject{
			app.connectionPanel.Objects[0], // header only
		}
		app.collapseBtn.SetIcon(theme.MenuDropUpIcon())
		app.isCollapsed = true
	}
	app.connectionPanel.Refresh()
}

func (app *SFTPApp) toggleLogPanel() {
	if app.isLogCollapsed {
		// Expand
		app.logPanel.Objects = []fyne.CanvasObject{
			app.logPanel.Objects[0], // header
			app.logContent,
		}
		app.logCollapseBtn.SetIcon(theme.MenuDropDownIcon())
		app.isLogCollapsed = false
	} else {
		// Collapse
		app.logPanel.Objects = []fyne.CanvasObject{
			app.logPanel.Objects[0], // header only
		}
		app.logCollapseBtn.SetIcon(theme.MenuDropUpIcon())
		app.isLogCollapsed = true
	}
	app.logPanel.Refresh()
}

// Bookmark management functions
func (app *SFTPApp) loadBookmarks() {
	data, err := os.ReadFile(app.bookmarksFile)
	if err != nil {
		// File doesn't exist or can't be read, start with empty bookmarks
		app.bookmarks = []Bookmark{}
		return
	}

	err = json.Unmarshal(data, &app.bookmarks)
	if err != nil {
		// Don't use logMessage here as UI isn't initialized yet
		fmt.Printf("Warning: Error loading bookmarks: %v\n", err)
		app.bookmarks = []Bookmark{}
	}
}

func (app *SFTPApp) saveBookmarks() {
	data, err := json.MarshalIndent(app.bookmarks, "", "  ")
	if err != nil {
		app.showError("Error saving bookmarks: " + err.Error())
		return
	}

	err = os.WriteFile(app.bookmarksFile, data, 0600)
	if err != nil {
		app.showError("Error writing bookmarks file: " + err.Error())
	}
}

func (app *SFTPApp) getBookmarkNames() []string {
	names := make([]string, len(app.bookmarks))
	for i, bookmark := range app.bookmarks {
		names[i] = bookmark.Name
	}
	return names
}

func (app *SFTPApp) loadBookmarkByName(name string) {
	for _, bookmark := range app.bookmarks {
		if bookmark.Name == name {
			app.loadBookmark(bookmark)
			app.deleteBookmarkBtn.Enable()
			app.quickConnectBtn.Enable()
			return
		}
	}
}

func (app *SFTPApp) loadBookmark(bookmark Bookmark) {
	app.hostEntry.SetText(bookmark.Host)
	app.portEntry.SetText(bookmark.Port)
	app.userEntry.SetText(bookmark.Username)
	app.useKeyCheck.SetChecked(bookmark.UseSSHKey)

	if bookmark.UseSSHKey {
		app.passEntry.Disable()
		app.keyEntry.Enable()
		app.keyEntry.SetText(bookmark.KeyPath)
		// Validate SSH key path if provided
		if bookmark.KeyPath != "" {
			if _, err := os.Stat(bookmark.KeyPath); os.IsNotExist(err) {
				app.logMessage("Warning: SSH key file not found: " + bookmark.KeyPath)
			}
		}
	} else {
		app.passEntry.Enable()
		app.keyEntry.Disable()
		app.keyEntry.SetText("")
	}
}

func (app *SFTPApp) showSaveBookmarkDialog() {
	// Validate before showing dialog
	if app.hostEntry.Text == "" {
		app.showError("Please enter a host before saving bookmark")
		return
	}
	if app.userEntry.Text == "" {
		app.showError("Please enter a username before saving bookmark")
		return
	}

	nameEntry := widget.NewEntry()
	nameEntry.SetPlaceHolder("Bookmark name")

	// Pre-fill with host if available
	if app.hostEntry.Text != "" {
		nameEntry.SetText(app.hostEntry.Text)
	}

	dialog := dialog.NewForm("Save Bookmark", "Save", "Cancel",
		[]*widget.FormItem{
			widget.NewFormItem("Name", nameEntry),
		}, func(ok bool) {
			if !ok || nameEntry.Text == "" {
				return
			}
			app.saveCurrentAsBookmark(nameEntry.Text)
		}, app.window)

	dialog.Show()
}

func (app *SFTPApp) saveCurrentAsBookmark(name string) {
	// Validate required fields
	if app.hostEntry.Text == "" {
		app.showError("Host is required to save a bookmark")
		return
	}
	if app.userEntry.Text == "" {
		app.showError("Username is required to save a bookmark")
		return
	}
	if app.portEntry.Text == "" {
		app.portEntry.SetText("22") // Default SSH port
	}

	bookmark := Bookmark{
		Name:      name,
		Host:      app.hostEntry.Text,
		Port:      app.portEntry.Text,
		Username:  app.userEntry.Text,
		UseSSHKey: app.useKeyCheck.Checked,
		KeyPath:   app.keyEntry.Text,
	}

	// Additional validation for SSH key
	if bookmark.UseSSHKey && bookmark.KeyPath != "" {
		if _, err := os.Stat(bookmark.KeyPath); os.IsNotExist(err) {
			app.showError("SSH key file does not exist: " + bookmark.KeyPath)
			return
		}
	}

	// Check if bookmark with same name exists and replace it
	found := false
	for i, existing := range app.bookmarks {
		if existing.Name == name {
			app.bookmarks[i] = bookmark
			found = true
			break
		}
	}

	// If not found, add as new bookmark
	if !found {
		app.bookmarks = append(app.bookmarks, bookmark)
	}

	app.saveBookmarks()
	app.updateBookmarkSelect()
	app.logMessage("Bookmark saved: " + name)
}

func (app *SFTPApp) deleteSelectedBookmark() {
	selected := app.bookmarkSelect.Selected
	if selected == "" {
		return
	}

	dialog := dialog.NewConfirm("Delete Bookmark",
		"Are you sure you want to delete the bookmark '"+selected+"'?",
		func(ok bool) {
			if ok {
				app.deleteBookmark(selected)
			}
		}, app.window)

	dialog.Show()
}

func (app *SFTPApp) deleteBookmark(name string) {
	for i, bookmark := range app.bookmarks {
		if bookmark.Name == name {
			app.bookmarks = append(app.bookmarks[:i], app.bookmarks[i+1:]...)
			break
		}
	}

	app.saveBookmarks()
	app.updateBookmarkSelect()
	app.bookmarkSelect.ClearSelected()
	app.deleteBookmarkBtn.Disable()
	app.logMessage("Bookmark deleted: " + name)
}

func (app *SFTPApp) updateBookmarkSelect() {
	app.bookmarkSelect.Options = app.getBookmarkNames()
	app.bookmarkSelect.Refresh()
}

func (app *SFTPApp) quickConnectFromBookmark() {
	selected := app.bookmarkSelect.Selected
	if selected == "" {
		return
	}

	// Load the bookmark data into form fields
	app.loadBookmarkByName(selected)

	// Trigger the connection
	app.onConnect()
}

func main() {
	app := NewSFTPApp()
	app.Run()
}
