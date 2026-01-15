# Easy Install Claude

[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20macOS-blue?style=flat-square)](https://github.com/taliove/easy-install-claude)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

专为国内用户设计的 Claude Code 一键安装工具，支持多个 AI 服务商，一行命令完成所有安装配置。

```
  ╔════════════════════════════════════════════╗
  ║  Easy Install Claude                       ║
  ║  多服务商 | 一键安装 | 国内加速            ║
  ╚════════════════════════════════════════════╝
```

## ✨ 特性

- 🚀 **一键安装** - 自动安装 Node.js、配置 NPM 镜像、安装 Claude Code
- 🔌 **多服务商** - 支持 MiniMax、豆包、智谱 AI、万界数据
- 📦 **多模型支持** - 每个服务商提供多种模型选择
- 🔄 **随时重配** - 使用 `--config` 参数重新配置服务商、API Key 和模型
- 💻 **跨平台支持** - Windows、Linux、macOS 全平台覆盖
- 🔑 **安全配置** - API Key 自动写入 `~/.claude/settings.json`
- 🌐 **网络加速** - 自动检测并使用国内镜像加速

## 🔌 支持的服务商

| 服务商 | Base URL | 模型 | 获取 API Key |
|--------|----------|------|--------------|
| **MiniMax** ⭐ | `api.minimaxi.com` | M2.1-flash (免费), M2.1-standard | [platform.minimaxi.com](https://platform.minimaxi.com) |
| **豆包 (火山引擎)** | `ark.cn-beijing.volces.com` | ark-code-latest, 自定义 | [console.volcengine.com/ark](https://console.volcengine.com/ark) |
| **智谱 AI** | `open.bigmodel.cn` | GLM-4.7, GLM-4.5-Air | [open.bigmodel.cn](https://open.bigmodel.cn) |
| **万界数据** | `maas-openapi.wanjiedata.com` | Claude 全系列 | [data.wanjiehuyu.com](https://data.wanjiehuyu.com) |

## 📥 一键安装

### 国内用户（推荐，使用加速镜像）

#### Linux / macOS

```bash
curl -fsSL https://ghproxy.net/https://raw.githubusercontent.com/taliove/easy-install-claude/main/install.sh | bash
```

#### Windows (PowerShell)

```powershell
irm https://ghproxy.net/https://raw.githubusercontent.com/taliove/easy-install-claude/main/install.ps1 | iex
```

### 海外用户（直连 GitHub）

#### Linux / macOS

```bash
curl -fsSL https://raw.githubusercontent.com/taliove/easy-install-claude/main/install.sh | bash
```

#### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/taliove/easy-install-claude/main/install.ps1 | iex
```

## 🔄 重新配置

已安装用户可随时重新配置服务商、API Key 和模型：

#### Linux / macOS

```bash
curl -fsSL https://ghproxy.net/https://raw.githubusercontent.com/taliove/easy-install-claude/main/install.sh | bash -s -- --config
```

#### Windows (PowerShell)

```powershell
irm https://ghproxy.net/https://raw.githubusercontent.com/taliove/easy-install-claude/main/install.ps1 -OutFile install.ps1; .\install.ps1 -Config
```

## 🔧 各服务商模型列表

### MiniMax（推荐）

| 模型 ID | 名称 | 说明 |
|---------|------|------|
| `M2.1-flash` | M2.1 Flash | 免费模型，推荐日常使用 ⭐ |
| `M2.1-standard` | M2.1 Standard | 标准模型，更强性能 |

### 豆包 (火山引擎)

| 模型 ID | 名称 | 说明 |
|---------|------|------|
| `ark-code-latest` | Ark Code Latest | 默认模型 ⭐ |
| 自定义 | - | 支持输入任意模型 ID |

### 智谱 AI

| 模型 ID | 名称 | 说明 |
|---------|------|------|
| `GLM-4.7` | GLM-4.7 | 推荐使用 ⭐ |
| `GLM-4.5-Air` | GLM-4.5 Air | 快速响应 |

### 万界数据 (Claude 原生)

| 模型 ID | 名称 | 说明 |
|---------|------|------|
| `claude-sonnet-4-20250514` | Claude Sonnet 4 | 性价比之选 ⭐ |
| `claude-sonnet-4-5-20250929` | Claude Sonnet 4.5 | 增强版 Sonnet |
| `claude-haiku-4-5-20251001` | Claude Haiku 4.5 | 快速响应 |
| `claude-opus-4-1-20250805` | Claude Opus 4.1 | 复杂任务 |
| `claude-opus-4-5-20251101` | Claude Opus 4.5 | 旗舰模型 |

## 🎮 命令行选项

### install.sh (Linux/macOS)

```bash
# 完整安装（默认）
curl -fsSL <URL> | bash

# 仅重新配置
curl -fsSL <URL> | bash -s -- --config

# 显示帮助
curl -fsSL <URL> | bash -s -- --help
```

### install.ps1 (Windows)

```powershell
# 完整安装（默认）
.\install.ps1

# 仅重新配置
.\install.ps1 -Config

# 显示帮助
.\install.ps1 -Help
```

## 🌐 环境变量控制

```bash
# 强制使用国内镜像加速
USE_MIRROR=true curl -fsSL <URL> | bash

# 强制直连 GitHub（海外用户）
USE_MIRROR=false curl -fsSL <URL> | bash

# 非交互式安装（用于自动化）
NONINTERACTIVE=true PROVIDER=1 ANTHROPIC_API_KEY=your-key ANTHROPIC_MODEL=M2.1-flash curl -fsSL <URL> | bash
```

### 环境变量说明

| 变量 | 说明 | 示例值 |
|------|------|--------|
| `USE_MIRROR` | 强制镜像模式 | `true`, `false`, `auto` |
| `NONINTERACTIVE` | 非交互式模式 | `true` |
| `PROVIDER` | 服务商选择 | `1`=MiniMax, `2`=豆包, `3`=智谱, `4`=万界 |
| `ANTHROPIC_API_KEY` | API Key | `sk-xxx` |
| `ANTHROPIC_MODEL` | 模型 ID | `M2.1-flash`, `GLM-4.7`, 等 |

## 📁 配置文件

安装完成后，配置将写入 `~/.claude/settings.json`：

```json
{
  "enabledPlugins": {
    "commit-commands@claude-plugins-official": true,
    "context7@claude-plugins-official": true,
    "frontend-design@claude-plugins-official": true,
    "github@claude-plugins-official": true,
    "planning-with-files@planning-with-files": true,
    "superpowers@superpowers-marketplace": true
  },
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "your-api-key",
    "ANTHROPIC_BASE_URL": "https://api.minimaxi.com/anthropic",
    "ANTHROPIC_MODEL": "M2.1-flash",
    "API_TIMEOUT_MS": "3000000",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": 1
  }
}
```

## 🎯 使用方法

安装完成后，在终端中运行：

```bash
claude
```

开始使用 Claude Code 进行 AI 编程！

## ❓ 常见问题

### Q: 安装过程自动做了什么？

1. 检测/安装 Node.js 18+（使用 nvm/winget）
2. 配置 npm 使用淘宝镜像
3. 安装 Claude Code CLI
4. 交互式选择服务商
5. 输入 API Key 和选择模型
6. 写入配置到 `~/.claude/settings.json`
7. 配置 PATH 环境变量

### Q: 如何切换服务商？

重新运行配置命令：
```bash
curl -fsSL <URL> | bash -s -- --config
```

### Q: Node.js 安装失败

**Linux/macOS**: 脚本使用 nvm 安装 Node.js，如果失败请手动安装：
```bash
# 安装 nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

# 安装 Node.js
nvm install 18
```

**Windows**: 脚本使用 winget 安装，如果失败请从 https://nodejs.org/ 下载安装。

### Q: Claude Code 安装失败

检查网络连接，然后手动安装：
```bash
npm config set registry https://registry.npmmirror.com
npm install -g @anthropic-ai/claude-code
```

### Q: 如何修改配置？

方式一：重新运行配置脚本
```bash
curl -fsSL <URL> | bash -s -- --config
```

方式二：直接编辑配置文件
```bash
vim ~/.claude/settings.json
```

## 📄 开源协议

MIT License

## 🙏 致谢

- [Anthropic](https://anthropic.com) - Claude AI
- [MiniMax](https://platform.minimaxi.com) - M2.1 系列模型
- [火山引擎](https://www.volcengine.com) - 豆包大模型
- [智谱 AI](https://open.bigmodel.cn) - GLM 系列模型
- [万界数据](https://www.wanjiedata.com) - Claude API 代理
- [nvm](https://github.com/nvm-sh/nvm) - Node Version Manager
