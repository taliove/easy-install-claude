# AGENTS.md - AI Coding Agent Guidelines

This document provides guidelines for AI coding agents working on the `go-install-claude` project.

## Project Overview

A Go-based TUI installer tool for Claude Code with pre-configured Wanjie Data proxy (万界数据).
Built with Bubble Tea (Charm) framework for terminal UI.

- **Language**: Go 1.21+
- **Module**: `github.com/taliove/go-install-claude`
- **TUI Framework**: Bubble Tea (`github.com/charmbracelet/bubbletea`)
- **Platforms**: Windows, Linux, macOS (amd64/arm64)

## Build, Lint, and Test Commands

### Quick Reference

```bash
# Build current platform
make build
go build -o dist/claude-installer.exe ./cmd/installer

# Build all platforms
make build-all

# Run linter (REQUIRED before push)
make lint
golangci-lint run

# Run all tests
make test
go test -v -race -cover ./...

# Run a single test
go test -v -run TestFunctionName ./internal/config/...
go test -v -run TestFunctionName ./path/to/package

# Format code
make fmt
go fmt ./...
goimports -w .

# Run development version
make run
go run ./cmd/installer

# Install dev tools
make tools
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
go install golang.org/x/tools/cmd/goimports@latest
```

### Pre-Push Checklist

**ALWAYS run before pushing:**
```bash
golangci-lint run          # Must pass with no errors
go test -v -race ./...     # Must pass all tests
go build ./cmd/installer   # Must compile successfully
```

## Code Style Guidelines

### Import Organization

Imports MUST be organized in three groups with blank lines between them:

```go
import (
    // 1. Standard library
    "fmt"
    "strings"

    // 2. Third-party packages
    "github.com/charmbracelet/bubbletea"
    "github.com/charmbracelet/lipgloss"

    // 3. Local packages (github.com/taliove/go-install-claude/...)
    "github.com/taliove/go-install-claude/internal/config"
    "github.com/taliove/go-install-claude/internal/tui/theme"
)
```

### File Permissions (Octal Literals)

Use the new Go 1.13+ octal literal style:
```go
// Good
os.MkdirAll(dir, 0o755)
os.WriteFile(path, data, 0o600)

// Bad
os.MkdirAll(dir, 0755)
os.WriteFile(path, data, 0600)
```

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Package | lowercase, single word | `config`, `detector`, `tui` |
| Public functions | PascalCase | `NewModel()`, `GetDefaultModel()` |
| Private functions | camelCase | `doDetect()`, `handleEnter()` |
| Constants | PascalCase (public) or camelCase (private) | `WanjieBaseURL`, `logoArt` |
| Structs | PascalCase | `InstallConfig`, `Model` |
| Interfaces | PascalCase, often -er suffix | `Installer`, `Renderer` |
| Errors | Err prefix | `ErrConfigNotFound`, `ErrAPIKeyNotFound` |

### Control Flow

Use switch statements instead of if-else chains (3+ conditions):
```go
// Good
switch {
case i < index:
    s.steps[i].Status = StepCompleted
case i == index:
    s.steps[i].Status = StepCurrent
default:
    s.steps[i].Status = StepPending
}

// Bad
if i < index {
    s.steps[i].Status = StepCompleted
} else if i == index {
    s.steps[i].Status = StepCurrent
} else {
    s.steps[i].Status = StepPending
}
```

### Function Parameters

Combine parameters of the same type:
```go
// Good
func newModel(mode AppMode, claudeDir, currentModel string) Model

// Bad
func newModel(mode AppMode, claudeDir string, currentModel string) Model
```

### Error Handling

- Always check and handle errors
- Return errors to caller, don't panic
- Use custom error variables for common errors:

```go
var ErrConfigNotFound = errors.New("配置文件不存在")

func ReadSettings() (*Config, error) {
    if !exists {
        return nil, ErrConfigNotFound
    }
    // ...
}
```

### Comments

- Package comments are optional (disabled in linter)
- Exported items comments are optional (disabled in linter)
- Use Chinese comments for Chinese users where appropriate
- Doc comments should explain "why", not "what"

## Project Structure

```
go-install-claude/
├── cmd/installer/main.go      # Entry point, CLI flags
├── internal/
│   ├── config/                # Configuration management
│   │   ├── config.go          # Core config types and functions
│   │   └── reader.go          # Read existing settings
│   ├── detector/              # System environment detection
│   │   └── detector.go        # Detect Node.js, npm, paths
│   ├── installer/             # Installation executor
│   │   └── installer.go       # npm install logic
│   ├── version/               # Version info (injected at build)
│   │   └── version.go
│   └── tui/                   # Terminal UI
│       ├── app.go             # Main Bubble Tea model
│       ├── components/        # Reusable UI components
│       │   ├── core/          # Logo, StatusBar
│       │   ├── dialog/        # Dialog, HelpDialog
│       │   └── wizard/        # Steps, Selector, ConfigCard
│       ├── layout/            # Container, Overlay
│       ├── styles/            # Style helpers, Icons
│       └── theme/             # Theme system (OpenCode, Catppuccin, etc.)
├── .github/workflows/         # CI/CD (ci.yml, release.yml)
├── .golangci.yml              # Linter configuration
├── Makefile                   # Build commands
├── install.sh                 # Linux/macOS install script
└── install.ps1                # Windows install script
```

## Enabled Linters

The project uses these golangci-lint checks (see `.golangci.yml`):

- **errcheck**: Check unhandled errors
- **gosimple**: Simplify code suggestions
- **govet**: Go vet checks
- **staticcheck**: Static analysis
- **unused**: Unused variables/functions
- **gofmt**: Code formatting
- **goimports**: Import sorting (local-prefixes: github.com/taliove/go-install-claude)
- **misspell**: Spelling check
- **revive**: Code style
- **unconvert**: Unnecessary type conversions
- **unparam**: Unused parameters
- **gocritic**: Code optimization (octalLiteral, ifElseChain, paramTypeCombine)

## TUI Development Guidelines

### Bubble Tea Pattern

Follow the Elm architecture:
```go
type Model struct { ... }
func (m Model) Init() tea.Cmd { ... }
func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) { ... }
func (m Model) View() string { ... }
```

### Theme Usage

Always use theme colors, never hardcode:
```go
t := theme.Current()
style := lipgloss.NewStyle().Foreground(t.Primary())
```

### Icons

Use icons from `styles/icons.go`:
```go
styles.IconCheck   // ✓
styles.IconCross   // ✗
styles.IconArrow   // →
styles.IconRocket  // 🚀
```

## CI/CD Pipeline

- **Push to main**: Runs lint, test, build (ci.yml)
- **Push tag v***: Creates GitHub release with binaries (release.yml)

## Release Process

### Semantic Versioning

This project follows [Semantic Versioning](https://semver.org/):
- **MAJOR** (v2.0.0): Breaking changes
- **MINOR** (v1.1.0): New features, backward compatible
- **PATCH** (v1.0.1): Bug fixes, backward compatible

### Pre-Release Checklist

**ALWAYS run before creating a release:**
```bash
# 1. Ensure working directory is clean
git status

# 2. Run all checks
golangci-lint run          # Must pass with no errors
go test -v ./...           # Must pass all tests  
go build ./cmd/installer   # Must compile successfully

# 3. Verify you're on main branch and up to date
git checkout main
git pull origin main
```

### Creating a Release

```bash
# 1. Determine version number based on changes
#    - Breaking changes: bump MAJOR
#    - New features: bump MINOR  
#    - Bug fixes: bump PATCH

# 2. Create annotated tag with changelog
git tag -a v1.2.0 -m "v1.2.0: Brief description

Changes:
- feat: new feature description
- fix: bug fix description
- docs: documentation updates"

# 3. Push tag to trigger GitHub Actions release
git push origin v1.2.0

# 4. Verify release on GitHub Actions
#    https://github.com/taliove/go-install-claude/actions
```

### Release Workflow (Automated)

When a tag matching `v*` is pushed, GitHub Actions will:
1. Build binaries for all platforms (Windows, Linux, macOS)
2. Compress with UPX (Linux/Windows only)
3. Generate SHA256 checksums
4. Create GitHub Release with binaries attached

### Hotfix Process

For urgent fixes to a released version:
```bash
# 1. Create hotfix from the release tag
git checkout -b hotfix/v1.2.1 v1.2.0

# 2. Make fixes and commit
git add .
git commit -m "fix: critical bug description"

# 3. Run all checks
golangci-lint run && go test -v ./... && go build ./cmd/installer

# 4. Merge to main
git checkout main
git merge hotfix/v1.2.1

# 5. Tag and release
git tag -a v1.2.1 -m "v1.2.1: Hotfix description"
git push origin main v1.2.1

# 6. Clean up
git branch -d hotfix/v1.2.1
```

## Common Tasks

### Adding a New Model

Edit `internal/config/config.go`:
```go
var SupportedModels = []ModelInfo{
    {ID: "claude-new-model", Name: "Claude New", Description: "描述"},
    // ...
}
```

### Creating a New TUI Component

1. Create file in appropriate `internal/tui/components/` subdirectory
2. Use theme colors via `theme.Current()`
3. Return string from `Render()` method
4. Follow existing component patterns

## China Network Acceleration (国内网络加速)

This project is designed to work smoothly in mainland China. Here are the acceleration strategies used:

### Network Sources Overview

| Component | URL | China-Friendly |
|-----------|-----|----------------|
| Claude API | `https://maas-openapi.wanjiedata.com/api/anthropic` | ✅ 万界数据代理 |
| NPM Registry | `https://registry.npmmirror.com` | ✅ 淘宝镜像 |
| GitHub Releases | `https://github.com/...` | ⚠️ 需要镜像加速 |
| GitHub Raw | `https://raw.githubusercontent.com/...` | ⚠️ 需要镜像加速 |
| GitHub API | `https://api.github.com/...` | ⚠️ 可能不稳定 |

### GitHub Mirror Strategy

The install scripts (`install.sh`, `install.ps1`) implement automatic GitHub acceleration:

1. **Auto-detection**: Scripts detect if GitHub is accessible
2. **Mirror fallback**: If blocked, try mirrors in order:
   - `https://ghproxy.net`
   - `https://mirror.ghproxy.com`
   - `https://gh-proxy.com`
3. **Direct fallback**: If all mirrors fail, attempt direct connection

### Environment Variables

Users can control mirror behavior:

```bash
# Force use mirror (China users)
USE_MIRROR=true curl -fsSL ... | bash

# Force direct connection (overseas users)
USE_MIRROR=false curl -fsSL ... | bash

# Auto-detect (default)
curl -fsSL ... | bash
```

### One-Line Install Commands

**For China users (recommended):**
```bash
# Linux/macOS
curl -fsSL https://ghproxy.net/https://raw.githubusercontent.com/taliove/go-install-claude/main/install.sh | bash

# Windows PowerShell
iwr -useb https://ghproxy.net/https://raw.githubusercontent.com/taliove/go-install-claude/main/install.ps1 | iex
```

**For overseas users:**
```bash
# Linux/macOS
curl -fsSL https://raw.githubusercontent.com/taliove/go-install-claude/main/install.sh | bash

# Windows PowerShell
iwr -useb https://raw.githubusercontent.com/taliove/go-install-claude/main/install.ps1 | iex
```

### Adding New Mirrors

To add a new GitHub mirror, update both scripts:

**install.sh:**
```bash
GITHUB_MIRRORS=(
    "https://ghproxy.net"
    "https://mirror.ghproxy.com"
    "https://gh-proxy.com"
    "https://new-mirror.example.com"  # Add new mirror here
)
```

**install.ps1:**
```powershell
$GitHubMirrors = @(
    "https://ghproxy.net"
    "https://mirror.ghproxy.com"
    "https://gh-proxy.com"
    "https://new-mirror.example.com"  # Add new mirror here
)
```

### NPM Mirror Configuration

The installer automatically configures NPM to use the China mirror:

```go
// internal/installer/installer.go
cmd := exec.Command("npm", "config", "set", "registry", "https://registry.npmmirror.com")
```

This is enabled by default (`UseNPMMirror: true`) and runs before `npm install`.
