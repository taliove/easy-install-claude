# Claude Code 一键安装工具

[![Go Version](https://img.shields.io/badge/Go-1.21+-00ADD8?style=flat-square&logo=go)](https://go.dev/)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20macOS-blue?style=flat-square)](https://github.com/taliove/go-install-claude)
[![Release](https://img.shields.io/github/v/release/taliove/go-install-claude?style=flat-square)](https://github.com/taliove/go-install-claude/releases/latest)

专为国内用户设计的 Claude Code 一键安装工具，预配置万界数据代理，只需输入 API Key 即可完成安装。

```
  ╔════════════════════════════════════════════╗
  ║  Claude Code 一键安装工具                  ║
  ║  ⚡ 万界数据 ⚡                            ║
  ╚════════════════════════════════════════════╝
```

## ✨ 特性

- 🎨 **精美 TUI 界面** - 参考 OpenCode/Claude Code 的专业视觉设计
- 🚀 **一键安装** - 自动配置 NPM 镜像、安装 Claude Code
- 🔧 **预设万界代理** - 无需手动配置代理地址
- 📦 **多模型支持** - 支持选择 Claude Sonnet/Opus/Haiku 系列
- 🔄 **模型切换** - 已安装用户可随时切换模型
- 💻 **跨平台支持** - Windows、Linux、macOS 全平台覆盖
- 🔑 **安全配置** - API Key 自动写入 `~/.claude/settings.json`
- 🎯 **多主题支持** - 内置 OpenCode、Catppuccin、Tokyo Night 主题
- 📦 **UPX 压缩** - Linux/Windows 二进制文件使用 UPX 压缩，体积更小

## 📥 一键安装

### 国内用户（推荐，使用加速镜像）

#### Linux / macOS

```bash
curl -fsSL https://ghproxy.net/https://raw.githubusercontent.com/taliove/go-install-claude/main/install.sh | bash
```

#### Windows (PowerShell)

```powershell
iwr -useb https://ghproxy.net/https://raw.githubusercontent.com/taliove/go-install-claude/main/install.ps1 | iex
```

### 海外用户（直连 GitHub）

#### Linux / macOS

```bash
curl -fsSL https://raw.githubusercontent.com/taliove/go-install-claude/main/install.sh | bash
```

#### Windows (PowerShell)

```powershell
iwr -useb https://raw.githubusercontent.com/taliove/go-install-claude/main/install.ps1 | iex
```

### 环境变量控制

```bash
# 强制使用国内镜像加速
USE_MIRROR=true curl -fsSL <URL> | bash

# 强制直连 GitHub（海外用户）
USE_MIRROR=false curl -fsSL <URL> | bash

# 自动检测（默认）
curl -fsSL <URL> | bash
```

### 手动下载

从 [Releases](https://github.com/taliove/go-install-claude/releases/latest) 页面下载对应平台的二进制文件：

| 平台 | 文件 | 压缩 |
|------|------|------|
| Windows x64 | `claude-installer-windows-amd64.exe` | ✅ UPX |
| Linux x64 | `claude-installer-linux-amd64` | ✅ UPX |
| macOS Intel | `claude-installer-darwin-amd64` | ❌ |
| macOS Apple Silicon | `claude-installer-darwin-arm64` | ❌ |

> macOS 二进制文件未使用 UPX 压缩，因为 UPX 对 macOS/ARM64 的兼容性有限。

## 📋 前置要求

- **Node.js 18+** - [下载地址](https://nodejs.org/)
- **万界数据 API Key** - [获取地址](https://www.wanjiedata.com)

## 🔧 支持的模型

| 模型 ID | 名称 | 说明 |
|---------|------|------|
| `claude-sonnet-4-20250514` | Claude Sonnet 4 | 性价比之选，推荐日常使用 ⭐ |
| `claude-sonnet-4-5-20250929` | Claude Sonnet 4.5 | 增强版 Sonnet，更强推理能力 |
| `claude-haiku-4-5-20251001` | Claude Haiku 4.5 | 快速响应，适合简单任务 |
| `claude-opus-4-1-20250805` | Claude Opus 4.1 | 强大性能，适合复杂任务 |
| `claude-opus-4-5-20251101` | Claude Opus 4.5 | 旗舰模型，最强性能 |

## 🎮 命令行选项

```bash
# 完整安装向导（默认）
claude-installer

# 交互式切换模型（已安装用户）
claude-installer --switch-model

# 查看当前配置
claude-installer --config

# 列出所有支持的模型
claude-installer --list-models

# 显示版本信息
claude-installer --version
```

### 模型切换

已安装 Claude Code 的用户可以随时切换模型：

```bash
claude-installer --switch-model
```

这会：
1. 读取现有的 API Key 配置
2. 进入交互式模型选择界面
3. 更新模型配置（保留其他设置）

## 🎨 界面预览

安装向导包含以下步骤：

1. **环境检测** - 自动检测 Node.js、npm、网络连接
2. **输入 API Key** - 安全输入万界数据 API Key
3. **选择模型** - 从支持的模型列表中选择
4. **确认配置** - 预览并确认安装配置
5. **安装** - 自动安装 Claude Code CLI
6. **完成** - 显示安装成功信息

## 📁 配置文件

安装完成后，配置将写入 `~/.claude/settings.json`：

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://maas-openapi.wanjiedata.com/api/anthropic",
    "ANTHROPIC_API_KEY": "your-api-key",
    "ANTHROPIC_MODEL": "claude-sonnet-4-20250514"
  }
}
```

## 🎯 使用方法

安装完成后，在终端中运行：

```bash
claude
```

开始使用 Claude Code 进行 AI 编程！

## 🏗️ 自行构建

### 前置条件

- Go 1.21+

### 构建命令

```bash
# 克隆仓库
git clone https://github.com/taliove/go-install-claude.git
cd go-install-claude

# 下载依赖
go mod tidy

# 构建所有平台
# Windows PowerShell
.\build.ps1

# Linux/macOS
chmod +x build.sh && ./build.sh

# 仅构建当前平台
go build -o claude-installer ./cmd/installer
```

### 构建输出

```
dist/
├── claude-installer-windows-amd64.exe  # Windows 64位
├── claude-installer-linux-amd64        # Linux 64位
├── claude-installer-darwin-amd64       # macOS Intel
└── claude-installer-darwin-arm64       # macOS Apple Silicon
```

## 🔄 版本发布

项目使用 GitHub Actions 自动发布。发布新版本只需：

```bash
# 创建版本标签
git tag v1.1.0
git push origin v1.1.0
```

GitHub Actions 将自动：
1. 运行代码检查 (golangci-lint)
2. 运行测试
3. 构建所有平台二进制文件
4. 使用 UPX 压缩 Linux/Windows 二进制文件
5. 创建 GitHub Release 并上传文件

## ❓ 常见问题

### Q: 提示 "未检测到 Node.js"

请先安装 Node.js 18 或更高版本：https://nodejs.org/

### Q: 安装失败，显示网络错误

1. 检查网络连接
2. 程序会自动使用淘宝 NPM 镜像
3. 如果仍失败，请尝试手动安装：
   ```bash
   npm config set registry https://registry.npmmirror.com
   npm install -g @anthropic-ai/claude-code
   ```

### Q: 如何修改配置？

直接编辑 `~/.claude/settings.json` 文件，或使用：
```bash
claude-installer --switch-model
```

### Q: 如何切换模型？

运行以下命令进入交互式模型选择：
```bash
claude-installer --switch-model
```

### Q: 如何查看当前配置？

```bash
claude-installer --config
```

### Q: 如何切换主题？

当前版本默认使用 OpenCode 主题。后续版本将支持主题切换功能。

## 📏 代码规范

项目遵循 Go 最佳实践，使用以下工具确保代码质量：

```bash
# 安装开发工具
make tools

# 格式化代码
make fmt

# 代码检查
make lint

# 运行测试
make test
```

配置文件：
- [.golangci.yml](.golangci.yml) - 代码检查规则
- [.editorconfig](.editorconfig) - 编辑器配置

## 📄 开源协议

MIT License

## 🙏 致谢

- [Anthropic](https://anthropic.com) - Claude AI
- [万界数据](https://www.wanjiedata.com) - API 代理服务
- [Charm](https://charm.sh) - Bubble Tea TUI 框架
- [OpenCode](https://github.com/opencode-ai/opencode) - TUI 设计灵感
