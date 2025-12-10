//go:build example
// +build example

package main

import (
	"fmt"
	"log"
	"os"
	"time"
)

// This is a standalone example showing how to use the SFTP client programmatically
// To run this example, rename it to main.go or create a separate module

func main() {
	// Check if we have command line arguments for connection
	if len(os.Args) < 4 {
		fmt.Println("Usage: go run example.go <host> <username> <password> [port]")
		fmt.Println("Example: go run example.go example.com myuser mypassword 22")
		os.Exit(1)
	}

	host := os.Args[1]
	username := os.Args[2]
	password := os.Args[3]
	port := 22

	if len(os.Args) > 4 {
		fmt.Sscanf(os.Args[4], "%d", &port)
	}

	// Create a new SFTP client
	client := NewSFTPClient()
	defer func() {
		if err := client.Disconnect(); err != nil {
			log.Printf("Error disconnecting: %v", err)
		}
	}()

	// Connect to the server
	fmt.Printf("Connecting to %s:%d...\n", host, port)
	err := client.Connect(host, username, password, port)
	if err != nil {
		log.Fatalf("Failed to connect: %v", err)
	}

	fmt.Println("✓ Connected successfully!")

	// Example 1: Get current working directory
	fmt.Println("\n=== Current Working Directory ===")
	wd, err := client.GetWorkingDirectory()
	if err != nil {
		log.Printf("Failed to get working directory: %v", err)
	} else {
		fmt.Printf("Current directory: %s\n", wd)
	}

	// Example 2: List current directory
	fmt.Println("\n=== Directory Listing ===")
	err = client.ListDirectory(".")
	if err != nil {
		log.Printf("Failed to list directory: %v", err)
	}

	// Example 3: Create a test directory
	fmt.Println("\n=== Creating Test Directory ===")
	testDir := "sftp_test_" + time.Now().Format("20060102_150405")
	err = client.MakeDirectory(testDir)
	if err != nil {
		log.Printf("Failed to create directory: %v", err)
	} else {
		fmt.Printf("✓ Created directory: %s\n", testDir)
	}

	// Example 4: Create a local test file and upload it
	fmt.Println("\n=== Creating and Uploading Test File ===")
	localTestFile := "test_upload.txt"
	remoteTestFile := testDir + "/uploaded_file.txt"

	// Create local test file
	err = createTestFile(localTestFile)
	if err != nil {
		log.Printf("Failed to create test file: %v", err)
	} else {
		fmt.Printf("✓ Created local test file: %s\n", localTestFile)

		// Upload the file
		err = client.UploadFile(localTestFile, remoteTestFile)
		if err != nil {
			log.Printf("Failed to upload file: %v", err)
		} else {
			fmt.Printf("✓ Uploaded file to: %s\n", remoteTestFile)
		}

		// Clean up local file
		os.Remove(localTestFile)
	}

	// Example 5: List the test directory to verify upload
	fmt.Println("\n=== Verifying Upload ===")
	err = client.ListDirectory(testDir)
	if err != nil {
		log.Printf("Failed to list test directory: %v", err)
	}

	// Example 6: Download the file back
	fmt.Println("\n=== Downloading File ===")
	localDownloadFile := "downloaded_file.txt"
	err = client.DownloadFile(remoteTestFile, localDownloadFile)
	if err != nil {
		log.Printf("Failed to download file: %v", err)
	} else {
		fmt.Printf("✓ Downloaded file to: %s\n", localDownloadFile)

		// Verify downloaded content
		content, err := os.ReadFile(localDownloadFile)
		if err == nil {
			fmt.Printf("Downloaded file content: %s", string(content))
		}

		// Clean up downloaded file
		os.Remove(localDownloadFile)
	}

	// Example 7: Clean up - delete the uploaded file and directory
	fmt.Println("\n=== Cleanup ===")
	err = client.DeleteFile(remoteTestFile)
	if err != nil {
		log.Printf("Failed to delete remote file: %v", err)
	} else {
		fmt.Printf("✓ Deleted remote file: %s\n", remoteTestFile)
	}

	err = client.RemoveDirectory(testDir)
	if err != nil {
		log.Printf("Failed to remove test directory: %v", err)
	} else {
		fmt.Printf("✓ Removed test directory: %s\n", testDir)
	}

	fmt.Println("\n=== Example completed successfully! ===")
}

// createTestFile creates a simple test file with sample content
func createTestFile(filename string) error {
	content := fmt.Sprintf("This is a test file created at %s\n", time.Now().Format(time.RFC3339))
	content += "This file demonstrates SFTP upload functionality.\n"
	content += "Line 3: Hello from Go SFTP Client!\n"

	return os.WriteFile(filename, []byte(content), 0644)
}

// Example function showing batch operations
func exampleBatchOperations(client *SFTPClient) error {
	fmt.Println("\n=== Batch Operations Example ===")

	// Create multiple test files locally
	testFiles := []string{"batch1.txt", "batch2.txt", "batch3.txt"}
	remoteDir := "batch_test"

	// Create remote directory
	err := client.MakeDirectory(remoteDir)
	if err != nil {
		return fmt.Errorf("failed to create batch directory: %v", err)
	}

	// Create and upload multiple files
	for i, file := range testFiles {
		content := fmt.Sprintf("Batch file %d created at %s\n", i+1, time.Now().Format(time.RFC3339))
		err := os.WriteFile(file, []byte(content), 0644)
		if err != nil {
			log.Printf("Failed to create %s: %v", file, err)
			continue
		}

		remoteFile := remoteDir + "/" + file
		err = client.UploadFile(file, remoteFile)
		if err != nil {
			log.Printf("Failed to upload %s: %v", file, err)
		} else {
			fmt.Printf("✓ Uploaded: %s\n", file)
		}

		// Clean up local file
		os.Remove(file)
	}

	// List the batch directory
	fmt.Println("\nBatch directory contents:")
	err = client.ListDirectory(remoteDir)
	if err != nil {
		log.Printf("Failed to list batch directory: %v", err)
	}

	// Clean up batch files and directory
	for _, file := range testFiles {
		remoteFile := remoteDir + "/" + file
		err := client.DeleteFile(remoteFile)
		if err != nil {
			log.Printf("Failed to delete %s: %v", remoteFile, err)
		}
	}

	err = client.RemoveDirectory(remoteDir)
	if err != nil {
		log.Printf("Failed to remove batch directory: %v", err)
	} else {
		fmt.Printf("✓ Cleaned up batch directory\n")
	}

	return nil
}
