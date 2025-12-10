# Go SFTP Client Makefile

# Variables
BINARY_NAME=sftp-client
BINARY_UNIX=$(BINARY_NAME)_unix
BINARY_WINDOWS=$(BINARY_NAME).exe
BINARY_DARWIN=$(BINARY_NAME)_darwin
BINARY_GUI=sftp-client-gui

# Default target
.PHONY: all
all: build

# Build the application
.PHONY: build
build: build-gui

# Build the GUI application (default)
.PHONY: build-gui
build-gui: clean
	@echo "Building GUI application..."
	go build -o $(BINARY_GUI) main.go app_icon.go

# Build the CLI application
.PHONY: build-cli
build-cli: clean
	@echo "Building CLI application..."
	go build -tags cli -o $(BINARY_NAME) cli-main.go

# Build for multiple platforms
.PHONY: build-all
build-all: build-gui-all build-cli-all

# Build GUI for multiple platforms
.PHONY: build-gui-all
build-gui-all: build-gui-linux build-gui-windows build-gui-darwin

# Build CLI for multiple platforms
.PHONY: build-cli-all
build-cli-all: build-cli-linux build-cli-windows build-cli-darwin

.PHONY: build-gui-linux
build-gui-linux:
	@echo "Building GUI for Linux..."
	GOOS=linux GOARCH=amd64 go build -o $(BINARY_GUI)_linux main.go app_icon.go

.PHONY: build-gui-windows
build-gui-windows:
	@echo "Building GUI for Windows..."
	GOOS=windows GOARCH=amd64 go build -o $(BINARY_GUI)_windows.exe main.go app_icon.go

.PHONY: build-gui-darwin
build-gui-darwin:
	@echo "Building GUI for macOS..."
	GOOS=darwin GOARCH=amd64 go build -o $(BINARY_GUI)_darwin main.go app_icon.go

.PHONY: build-cli-linux
build-cli-linux:
	@echo "Building CLI for Linux..."
	GOOS=linux GOARCH=amd64 go build -tags cli -o $(BINARY_UNIX) cli-main.go

.PHONY: build-cli-windows
build-cli-windows:
	@echo "Building CLI for Windows..."
	GOOS=windows GOARCH=amd64 go build -tags cli -o $(BINARY_WINDOWS) cli-main.go

.PHONY: build-cli-darwin
build-cli-darwin:
	@echo "Building CLI for macOS..."
	GOOS=darwin GOARCH=amd64 go build -tags cli -o $(BINARY_DARWIN) cli-main.go

# Run the GUI application
.PHONY: run
run: run-gui

# Run the GUI application
.PHONY: run-gui
run-gui: build-gui
	@echo "Running GUI application..."
	./$(BINARY_GUI)

# Run the CLI application
.PHONY: run-cli
run-cli: build-cli
	@echo "Running CLI application..."
	./$(BINARY_NAME)

# Test the application
.PHONY: test
test:
	@echo "Running tests..."
	go test -short -v .

# Test with coverage
.PHONY: test-coverage
test-coverage:
	@echo "Running tests with coverage..."
	go test -v -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report generated: coverage.html"

# Benchmark tests
.PHONY: benchmark
benchmark:
	@echo "Running benchmarks..."
	go test -bench=. -benchmem ./...

# Format code
.PHONY: fmt
fmt:
	@echo "Formatting code..."
	go fmt ./...

# Lint code
.PHONY: lint
lint:
	@echo "Running linter..."
	golangci-lint run

# Vet code
.PHONY: vet
vet:
	@echo "Running go vet..."
	go vet ./...

# Install dependencies
.PHONY: deps
deps:
	@echo "Installing dependencies..."
	go mod download
	go mod tidy

# Update dependencies
.PHONY: update-deps
update-deps:
	@echo "Updating dependencies..."
	go get -u ./...
	go mod tidy

# Clean build artifacts
.PHONY: clean
clean:
	@echo "Cleaning build artifacts..."
	rm -f $(BINARY_NAME)
	rm -f $(BINARY_GUI)
	rm -f $(BINARY_UNIX)
	rm -f $(BINARY_WINDOWS)
	rm -f $(BINARY_DARWIN)
	rm -f $(BINARY_GUI)_linux
	rm -f $(BINARY_GUI)_windows.exe
	rm -f $(BINARY_GUI)_darwin
	rm -f coverage.out
	rm -f coverage.html

# Install the binary to GOPATH/bin
.PHONY: install
install:
	@echo "Installing $(BINARY_NAME)..."
	go install

# Check for security vulnerabilities
.PHONY: security
security:
	@echo "Checking for security vulnerabilities..."
	gosec ./...

# Generate documentation
.PHONY: doc
doc:
	@echo "Generating documentation..."
	godoc -http=:6060

# Pre-commit checks
.PHONY: pre-commit
pre-commit: fmt vet test lint

# Docker build (if needed in the future)
.PHONY: docker-build
docker-build:
	@echo "Building Docker image..."
	docker build -t sftp-client .

# Help
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  build          - Build the GUI application (default)"
	@echo "  build-gui      - Build the GUI application"
	@echo "  build-cli      - Build the CLI application"
	@echo "  build-all      - Build both GUI and CLI for all platforms"
	@echo "  build-gui-all  - Build GUI for all platforms (Linux, Windows, macOS)"
	@echo "  build-cli-all  - Build CLI for all platforms (Linux, Windows, macOS)"
	@echo "  build-gui-linux    - Build GUI for Linux"
	@echo "  build-gui-windows  - Build GUI for Windows"
	@echo "  build-gui-darwin   - Build GUI for macOS"
	@echo "  build-cli-linux    - Build CLI for Linux"
	@echo "  build-cli-windows  - Build CLI for Windows"
	@echo "  build-cli-darwin   - Build CLI for macOS"
	@echo "  run            - Build and run the GUI application"
	@echo "  run-gui        - Build and run the GUI application"
	@echo "  run-cli        - Build and run the CLI application"
	@echo "  test           - Run tests"
	@echo "  test-coverage  - Run tests with coverage report"
	@echo "  benchmark      - Run benchmark tests"
	@echo "  fmt            - Format code"
	@echo "  lint           - Run linter (requires golangci-lint)"
	@echo "  vet            - Run go vet"
	@echo "  deps           - Install dependencies"
	@echo "  update-deps    - Update dependencies"
	@echo "  clean          - Clean build artifacts"
	@echo "  install        - Install binary to GOPATH/bin"
	@echo "  security       - Check for security vulnerabilities (requires gosec)"
	@echo "  doc            - Start documentation server"
	@echo "  pre-commit     - Run pre-commit checks (fmt, vet, test, lint)"
	@echo "  docker-build   - Build Docker image"
	@echo "  help           - Show this help message"
