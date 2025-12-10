//go:build cli
// +build cli

package main

import (
	"bufio"
	"fmt"
	"io"
	"log"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/pkg/sftp"
	"golang.org/x/crypto/ssh"
)

type SFTPClient struct {
	sshClient  *ssh.Client
	sftpClient *sftp.Client
	connected  bool
}

func NewSFTPClient() *SFTPClient {
	return &SFTPClient{
		connected: false,
	}
}

func (c *SFTPClient) Connect(host, username, password string, port int) error {
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

func (c *SFTPClient) ConnectWithKey(host, username, keyPath string, port int) error {
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

func (c *SFTPClient) Disconnect() error {
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

func (c *SFTPClient) IsConnected() bool {
	return c.connected
}

func (c *SFTPClient) ListDirectory(remotePath string) error {
	if !c.connected {
		return fmt.Errorf("not connected to server")
	}

	files, err := c.sftpClient.ReadDir(remotePath)
	if err != nil {
		return fmt.Errorf("failed to list directory: %v", err)
	}

	fmt.Printf("\nListing directory: %s\n", remotePath)
	fmt.Println("Type\tSize\t\tModified\t\tName")
	fmt.Println("----\t----\t\t--------\t\t----")

	for _, file := range files {
		fileType := "FILE"
		if file.IsDir() {
			fileType = "DIR "
		}

		fmt.Printf("%s\t%-10d\t%s\t%s\n",
			fileType,
			file.Size(),
			file.ModTime().Format("2006-01-02 15:04:05"),
			file.Name())
	}

	return nil
}

func (c *SFTPClient) UploadFile(localPath, remotePath string) error {
	if !c.connected {
		return fmt.Errorf("not connected to server")
	}

	localFile, err := os.Open(localPath)
	if err != nil {
		return fmt.Errorf("failed to open local file: %v", err)
	}
	defer localFile.Close()

	remoteFile, err := c.sftpClient.Create(remotePath)
	if err != nil {
		return fmt.Errorf("failed to create remote file: %v", err)
	}
	defer remoteFile.Close()

	_, err = io.Copy(remoteFile, localFile)
	if err != nil {
		return fmt.Errorf("failed to upload file: %v", err)
	}

	fmt.Printf("Successfully uploaded %s to %s\n", localPath, remotePath)
	return nil
}

func (c *SFTPClient) DownloadFile(remotePath, localPath string) error {
	if !c.connected {
		return fmt.Errorf("not connected to server")
	}

	remoteFile, err := c.sftpClient.Open(remotePath)
	if err != nil {
		return fmt.Errorf("failed to open remote file: %v", err)
	}
	defer remoteFile.Close()

	localFile, err := os.Create(localPath)
	if err != nil {
		return fmt.Errorf("failed to create local file: %v", err)
	}
	defer localFile.Close()

	_, err = io.Copy(localFile, remoteFile)
	if err != nil {
		return fmt.Errorf("failed to download file: %v", err)
	}

	fmt.Printf("Successfully downloaded %s to %s\n", remotePath, localPath)
	return nil
}

func (c *SFTPClient) DeleteFile(remotePath string) error {
	if !c.connected {
		return fmt.Errorf("not connected to server")
	}

	err := c.sftpClient.Remove(remotePath)
	if err != nil {
		return fmt.Errorf("failed to delete file: %v", err)
	}

	fmt.Printf("Successfully deleted %s\n", remotePath)
	return nil
}

func (c *SFTPClient) MakeDirectory(remotePath string) error {
	if !c.connected {
		return fmt.Errorf("not connected to server")
	}

	err := c.sftpClient.Mkdir(remotePath)
	if err != nil {
		return fmt.Errorf("failed to create directory: %v", err)
	}

	fmt.Printf("Successfully created directory %s\n", remotePath)
	return nil
}

func (c *SFTPClient) RemoveDirectory(remotePath string) error {
	if !c.connected {
		return fmt.Errorf("not connected to server")
	}

	err := c.sftpClient.RemoveDirectory(remotePath)
	if err != nil {
		return fmt.Errorf("failed to remove directory: %v", err)
	}

	fmt.Printf("Successfully removed directory %s\n", remotePath)
	return nil
}

func (c *SFTPClient) GetWorkingDirectory() (string, error) {
	if !c.connected {
		return "", fmt.Errorf("not connected to server")
	}

	wd, err := c.sftpClient.Getwd()
	if err != nil {
		return "", fmt.Errorf("failed to get working directory: %v", err)
	}

	return wd, nil
}

func printHelp() {
	fmt.Println("\nAvailable commands:")
	fmt.Println("  connect <host> <username> <password> [port] - Connect using password authentication")
	fmt.Println("  connectkey <host> <username> <keypath> [port] - Connect using SSH key authentication")
	fmt.Println("  disconnect - Disconnect from server")
	fmt.Println("  ls [path] - List directory contents")
	fmt.Println("  pwd - Print working directory")
	fmt.Println("  upload <local_file> <remote_file> - Upload file to server")
	fmt.Println("  download <remote_file> <local_file> - Download file from server")
	fmt.Println("  delete <remote_file> - Delete file on server")
	fmt.Println("  mkdir <remote_directory> - Create directory on server")
	fmt.Println("  rmdir <remote_directory> - Remove directory on server")
	fmt.Println("  help - Show this help message")
	fmt.Println("  quit - Exit the application")
}

func main() {
	client := NewSFTPClient()
	defer client.Disconnect()

	scanner := bufio.NewScanner(os.Stdin)

	fmt.Println("SFTP Client v1.0")
	fmt.Println("Type 'help' for available commands")

	for {
		if client.IsConnected() {
			wd, _ := client.GetWorkingDirectory()
			fmt.Printf("sftp:%s> ", wd)
		} else {
			fmt.Print("sftp> ")
		}

		if !scanner.Scan() {
			break
		}

		input := strings.TrimSpace(scanner.Text())
		if input == "" {
			continue
		}

		parts := strings.Fields(input)
		command := strings.ToLower(parts[0])

		switch command {
		case "help":
			printHelp()

		case "connect":
			if len(parts) < 4 {
				fmt.Println("Usage: connect <host> <username> <password> [port]")
				continue
			}

			host := parts[1]
			username := parts[2]
			password := parts[3]
			port := 22

			if len(parts) > 4 {
				if p, err := strconv.Atoi(parts[4]); err == nil {
					port = p
				} else {
					fmt.Printf("Invalid port number: %s\n", parts[4])
					continue
				}
			}

			err := client.Connect(host, username, password, port)
			if err != nil {
				fmt.Printf("Connection failed: %v\n", err)
			} else {
				fmt.Printf("Connected to %s:%d\n", host, port)
			}

		case "connectkey":
			if len(parts) < 4 {
				fmt.Println("Usage: connectkey <host> <username> <keypath> [port]")
				continue
			}

			host := parts[1]
			username := parts[2]
			keyPath := parts[3]
			port := 22

			if len(parts) > 4 {
				if p, err := strconv.Atoi(parts[4]); err == nil {
					port = p
				} else {
					fmt.Printf("Invalid port number: %s\n", parts[4])
					continue
				}
			}

			err := client.ConnectWithKey(host, username, keyPath, port)
			if err != nil {
				fmt.Printf("Connection failed: %v\n", err)
			} else {
				fmt.Printf("Connected to %s:%d using key authentication\n", host, port)
			}

		case "disconnect":
			err := client.Disconnect()
			if err != nil {
				fmt.Printf("Disconnect failed: %v\n", err)
			} else {
				fmt.Println("Disconnected from server")
			}

		case "ls":
			if !client.IsConnected() {
				fmt.Println("Not connected to server")
				continue
			}

			path := "."
			if len(parts) > 1 {
				path = parts[1]
			}

			err := client.ListDirectory(path)
			if err != nil {
				fmt.Printf("List directory failed: %v\n", err)
			}

		case "pwd":
			if !client.IsConnected() {
				fmt.Println("Not connected to server")
				continue
			}

			wd, err := client.GetWorkingDirectory()
			if err != nil {
				fmt.Printf("Get working directory failed: %v\n", err)
			} else {
				fmt.Println(wd)
			}

		case "upload":
			if len(parts) < 3 {
				fmt.Println("Usage: upload <local_file> <remote_file>")
				continue
			}

			localFile := parts[1]
			remoteFile := parts[2]

			err := client.UploadFile(localFile, remoteFile)
			if err != nil {
				fmt.Printf("Upload failed: %v\n", err)
			}

		case "download":
			if len(parts) < 3 {
				fmt.Println("Usage: download <remote_file> <local_file>")
				continue
			}

			remoteFile := parts[1]
			localFile := parts[2]

			err := client.DownloadFile(remoteFile, localFile)
			if err != nil {
				fmt.Printf("Download failed: %v\n", err)
			}

		case "delete":
			if len(parts) < 2 {
				fmt.Println("Usage: delete <remote_file>")
				continue
			}

			remoteFile := parts[1]
			err := client.DeleteFile(remoteFile)
			if err != nil {
				fmt.Printf("Delete failed: %v\n", err)
			}

		case "mkdir":
			if len(parts) < 2 {
				fmt.Println("Usage: mkdir <remote_directory>")
				continue
			}

			remoteDir := parts[1]
			err := client.MakeDirectory(remoteDir)
			if err != nil {
				fmt.Printf("Make directory failed: %v\n", err)
			}

		case "rmdir":
			if len(parts) < 2 {
				fmt.Println("Usage: rmdir <remote_directory>")
				continue
			}

			remoteDir := parts[1]
			err := client.RemoveDirectory(remoteDir)
			if err != nil {
				fmt.Printf("Remove directory failed: %v\n", err)
			}

		case "quit", "exit":
			fmt.Println("Goodbye!")
			return

		default:
			fmt.Printf("Unknown command: %s\n", command)
			fmt.Println("Type 'help' for available commands")
		}
	}

	if err := scanner.Err(); err != nil {
		log.Fatalf("Error reading input: %v", err)
	}
}
