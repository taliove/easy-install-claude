# Claude Code 一键安装工具 - Makefile
# Go 项目标准构建命令

.PHONY: all build build-all clean test lint fmt run help tools

# 版本信息
VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
COMMIT  ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_TIME ?= $(shell date -u +%Y-%m-%dT%H:%M:%SZ)

# 编译参数
LDFLAGS := -s -w \
	-X github.com/taliove/go-install-claude/internal/version.Version=$(VERSION) \
	-X github.com/taliove/go-install-claude/internal/version.GitCommit=$(COMMIT) \
	-X github.com/taliove/go-install-claude/internal/version.BuildTime=$(BUILD_TIME)

# 默认目标
all: lint test build

# 帮助信息
help:
	@echo "Claude Code 安装工具 - 可用命令:"
	@echo ""
	@echo "  make build     - 构建当前平台"
	@echo "  make build-all - 构建所有平台"
	@echo "  make test      - 运行测试"
	@echo "  make lint      - 代码检查"
	@echo "  make fmt       - 格式化代码"
	@echo "  make clean     - 清理构建"
	@echo "  make run       - 运行开发版"
	@echo "  make tools     - 安装开发工具"
	@echo ""

# 格式化代码
fmt:
	@echo "格式化代码..."
	go fmt ./...

# 代码检查
lint:
	@echo "代码检查..."
	@if command -v golangci-lint >/dev/null 2>&1; then \
		golangci-lint run ./...; \
	else \
		echo "golangci-lint 未安装，跳过检查"; \
	fi

# 运行测试
test:
	@echo "运行测试..."
	go test -v -race -cover ./...

# 构建当前平台
build:
	@echo "构建中..."
	@mkdir -p dist
	go build -ldflags="$(LDFLAGS)" -o dist/claude-installer ./cmd/installer
	@echo "构建完成: dist/claude-installer"

# 构建所有平台
build-all: clean
	@echo "构建所有平台..."
	@mkdir -p dist
	GOOS=windows GOARCH=amd64 go build -ldflags="$(LDFLAGS)" -o dist/claude-installer-windows-amd64.exe ./cmd/installer
	GOOS=linux GOARCH=amd64 go build -ldflags="$(LDFLAGS)" -o dist/claude-installer-linux-amd64 ./cmd/installer
	GOOS=darwin GOARCH=amd64 go build -ldflags="$(LDFLAGS)" -o dist/claude-installer-darwin-amd64 ./cmd/installer
	GOOS=darwin GOARCH=arm64 go build -ldflags="$(LDFLAGS)" -o dist/claude-installer-darwin-arm64 ./cmd/installer
	@echo "所有平台构建完成!"

# 运行开发版
run:
	go run ./cmd/installer

# 清理
clean:
	@echo "清理..."
	rm -rf dist/

# 安装开发工具
tools:
	@echo "安装开发工具..."
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	@echo "工具安装完成"
