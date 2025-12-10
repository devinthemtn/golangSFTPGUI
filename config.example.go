//go:build example
// +build example

package main

import (
	"fmt"
	"log"
)

// Example configuration struct for programmatic usage
type SFTPConfig struct {
	Host     string
	Port     int
	Username string
	Password string
	KeyPath  string
	UseKey   bool
}

// ExampleProgrammaticUsage demonstrates how to use the SFTP client programmatically
func ExampleProgrammaticUsage() {
	// Example 1: Using password authentication
	config := SFTPConfig{
		Host:     "example.com",
		Port:     22,
		Username: "myuser",
		Password: "mypassword",
		UseKey:   false,
	}

	client := NewSFTPClient()
	defer client.Disconnect()

	// Connect using password
	if !config.UseKey {
		err := client.Connect(config.Host, config.Username, config.Password, config.Port)
		if err != nil {
			log.Fatalf("Failed to connect: %v", err)
		}
	} else {
		err := client.ConnectWithKey(config.Host, config.Username, config.KeyPath, config.Port)
		if err != nil {
			log.Fatalf("Failed to connect with key: %v", err)
		}
	}

	fmt.Printf("Connected to %s:%d\n", config.Host, config.Port)

	// Example operations

	// List current directory
	err := client.ListDirectory(".")
	if err != nil {
		log.Printf("Failed to list directory: %v", err)
	}

	// Get working directory
	wd, err := client.GetWorkingDirectory()
	if err != nil {
		log.Printf("Failed to get working directory: %v", err)
	} else {
		fmt.Printf("Current directory: %s\n", wd)
	}

	// Upload a file
	err = client.UploadFile("./local-file.txt", "/remote/path/file.txt")
	if err != nil {
		log.Printf("Failed to upload file: %v", err)
	}

	// Download a file
	err = client.DownloadFile("/remote/path/file.txt", "./downloaded-file.txt")
	if err != nil {
		log.Printf("Failed to download file: %v", err)
	}

	// Create directory
	err = client.MakeDirectory("/remote/path/new-directory")
	if err != nil {
		log.Printf("Failed to create directory: %v", err)
	}

	// Delete file
	err = client.DeleteFile("/remote/path/file-to-delete.txt")
	if err != nil {
		log.Printf("Failed to delete file: %v", err)
	}

	fmt.Println("Example operations completed")
}

// ExampleSSHKeyUsage demonstrates SSH key authentication
func ExampleSSHKeyUsage() {
	config := SFTPConfig{
		Host:     "example.com",
		Port:     22,
		Username: "myuser",
		KeyPath:  "~/.ssh/id_rsa", // Path to your private key
		UseKey:   true,
	}

	client := NewSFTPClient()
	defer client.Disconnect()

	err := client.ConnectWithKey(config.Host, config.Username, config.KeyPath, config.Port)
	if err != nil {
		log.Fatalf("Failed to connect with SSH key: %v", err)
	}

	fmt.Println("Connected using SSH key authentication")

	// Perform operations...
	err = client.ListDirectory("/home/user")
	if err != nil {
		log.Printf("Failed to list directory: %v", err)
	}
}

// BatchOperations demonstrates batch file operations
func BatchOperations() {
	client := NewSFTPClient()
	defer client.Disconnect()

	// Connect (replace with your credentials)
	err := client.Connect("example.com", "username", "password", 22)
	if err != nil {
		log.Fatalf("Failed to connect: %v", err)
	}

	// List of files to upload
	filesToUpload := []struct {
		local  string
		remote string
	}{
		{"./file1.txt", "/remote/file1.txt"},
		{"./file2.txt", "/remote/file2.txt"},
		{"./file3.txt", "/remote/file3.txt"},
	}

	// Upload multiple files
	for _, file := range filesToUpload {
		err := client.UploadFile(file.local, file.remote)
		if err != nil {
			log.Printf("Failed to upload %s: %v", file.local, err)
		} else {
			fmt.Printf("Successfully uploaded %s\n", file.local)
		}
	}

	// Create multiple directories
	directories := []string{
		"/remote/dir1",
		"/remote/dir2",
		"/remote/dir3",
	}

	for _, dir := range directories {
		err := client.MakeDirectory(dir)
		if err != nil {
			log.Printf("Failed to create directory %s: %v", dir, err)
		} else {
			fmt.Printf("Successfully created directory %s\n", dir)
		}
	}
}

// This file serves as an example and is not meant to be executed directly.
// Copy the relevant functions to your main application or create a separate
// program that imports the SFTP client functionality.
