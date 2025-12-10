package main

import (
	"testing"
)

func TestNewSFTPGUIClient(t *testing.T) {
	client := NewSFTPGUIClient()
	if client == nil {
		t.Fatal("NewSFTPGUIClient() returned nil")
	}

	if client.IsConnected() {
		t.Error("New client should not be connected")
	}
}

func TestSFTPGUIClient_IsConnected(t *testing.T) {
	client := NewSFTPGUIClient()

	// Should not be connected initially
	if client.IsConnected() {
		t.Error("Client should not be connected initially")
	}

	// Should still not be connected after calling Disconnect on unconnected client
	err := client.Disconnect()
	if err != nil {
		t.Errorf("Disconnect on unconnected client should not return error, got: %v", err)
	}

	if client.IsConnected() {
		t.Error("Client should still not be connected after disconnect")
	}
}

func TestSFTPGUIClient_ConnectInvalidHost(t *testing.T) {
	client := NewSFTPGUIClient()

	// Test connection to invalid host
	err := client.Connect("invalid.host.example", "testuser", "testpass", 22)
	if err == nil {
		t.Error("Connection to invalid host should fail")
	}

	if client.IsConnected() {
		t.Error("Client should not be connected after failed connection")
	}
}

func TestSFTPGUIClient_ConnectWithKeyInvalidKey(t *testing.T) {
	client := NewSFTPGUIClient()

	// Test connection with non-existent key file
	err := client.ConnectWithKey("example.com", "testuser", "/nonexistent/key", 22)
	if err == nil {
		t.Error("Connection with non-existent key should fail")
	}

	if client.IsConnected() {
		t.Error("Client should not be connected after failed key connection")
	}
}

func TestSFTPGUIClient_GetFilesWhenNotConnected(t *testing.T) {
	client := NewSFTPGUIClient()

	_, err := client.GetFiles(".")
	if err == nil {
		t.Error("GetFiles should fail when not connected")
	}

	expectedMsg := "not connected"
	if err.Error() != expectedMsg {
		t.Errorf("Expected error message '%s', got '%s'", expectedMsg, err.Error())
	}
}

func TestNewSFTPApp(t *testing.T) {
	// Skip this test in headless environments
	if testing.Short() {
		t.Skip("Skipping GUI test in short mode")
	}

	app := NewSFTPApp()
	if app == nil {
		t.Fatal("NewSFTPApp() returned nil")
	}

	if app.client == nil {
		t.Error("SFTPApp should have a client")
	}

	if app.client.IsConnected() {
		t.Error("New app client should not be connected")
	}
}

// Benchmark tests
func BenchmarkNewSFTPGUIClient(b *testing.B) {
	for i := 0; i < b.N; i++ {
		client := NewSFTPGUIClient()
		_ = client
	}
}

func BenchmarkSFTPGUIClient_IsConnected(b *testing.B) {
	client := NewSFTPGUIClient()
	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		_ = client.IsConnected()
	}
}

// Example test demonstrating usage
func ExampleSFTPGUIClient_basic() {
	client := NewSFTPGUIClient()
	defer client.Disconnect()

	// This would normally connect to a real server
	// err := client.Connect("example.com", "user", "pass", 22)
	// if err != nil {
	//     log.Fatal(err)
	// }

	connected := client.IsConnected()
	_ = connected
	// Output:
}
