#!/bin/bash
# Claude Code 一键安装脚本
#
# 国内用户（推荐，使用加速镜像）:
#   curl -fsSL https://ghproxy.net/https://raw.githubusercontent.com/taliove/go-install-claude/main/install.sh | bash
#
# 海外用户（直连 GitHub）:
#   curl -fsSL https://raw.githubusercontent.com/taliove/go-install-claude/main/install.sh | bash
#
# 带参数安装指定版本:
#   curl -fsSL <上述URL> | bash -s -- --version v1.0.0
#
# 环境变量:
#   USE_MIRROR=true   强制使用国内镜像加速
#   USE_MIRROR=false  强制直连 GitHub（海外用户）
#   USE_MIRROR=auto   自动检测（默认）

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# 配置
REPO="taliove/go-install-claude"
BINARY_NAME="claude-installer"
INSTALL_DIR="${HOME}/.local/bin"
VERSION="${1:-latest}"

# GitHub 加速镜像列表（国内用户优先尝试）
GITHUB_MIRRORS=(
    "https://ghproxy.net"
    "https://mirror.ghproxy.com"
    "https://gh-proxy.com"
)
# 是否使用镜像加速（默认自动检测）
USE_MIRROR="${USE_MIRROR:-auto}"

# 打印带颜色的消息
info() { echo -e "${CYAN}ℹ ${NC}$1"; }
success() { echo -e "${GREEN}✓ ${NC}$1"; }
warn() { echo -e "${YELLOW}⚠ ${NC}$1"; }
error() { echo -e "${RED}✖ ${NC}$1"; }

# 检测是否需要使用镜像（检测能否快速访问 GitHub）
detect_mirror_need() {
    if [ "$USE_MIRROR" = "true" ]; then
        MIRROR_MODE=true
        info "强制使用镜像模式"
        return
    elif [ "$USE_MIRROR" = "false" ]; then
        MIRROR_MODE=false
        info "强制使用直连模式"
        return
    fi
    
    # 自动检测：尝试快速访问 GitHub（严格超时）
    # 不只检测 API，还要检测实际下载域名
    info "检测网络环境..."
    
    # 测试 github.com 的响应速度（3秒连接超时，5秒总超时）
    # 使用 github.com 而非 api.github.com，因为下载走的是 github.com
    if curl -fsSL --connect-timeout 3 --max-time 5 "https://github.com" -o /dev/null 2>/dev/null; then
        # 额外测试：尝试访问 raw.githubusercontent.com（Release 下载需要）
        if curl -fsSL --connect-timeout 3 --max-time 5 "https://raw.githubusercontent.com" -o /dev/null 2>/dev/null; then
            MIRROR_MODE=false
            success "可以直连 GitHub"
            return
        fi
    fi
    
    # 任一测试失败或超时，使用镜像
    MIRROR_MODE=true
    warn "GitHub 访问较慢或不可用，将使用国内镜像加速"
}

# 查找可用的镜像
find_working_mirror() {
    for mirror in "${GITHUB_MIRRORS[@]}"; do
        if curl -fsSL --connect-timeout 5 "${mirror}" &> /dev/null; then
            ACTIVE_MIRROR="$mirror"
            success "使用镜像: ${BOLD}${mirror}${NC}"
            return 0
        fi
    done
    error "所有镜像均不可用"
    return 1
}

# 获取带镜像前缀的 URL
get_url() {
    local url="$1"
    if [ "$MIRROR_MODE" = true ] && [ -n "$ACTIVE_MIRROR" ]; then
        echo "${ACTIVE_MIRROR}/${url}"
    else
        echo "$url"
    fi
}

# 通用下载函数（支持镜像重试）
do_download() {
    local url="$1"
    local output="$2"
    local final_url
    
    final_url=$(get_url "$url")
    
    if command -v curl &> /dev/null; then
        if curl -fsSL "$final_url" -o "$output"; then
            return 0
        fi
    elif command -v wget &> /dev/null; then
        if wget -q "$final_url" -O "$output"; then
            return 0
        fi
    else
        error "需要 curl 或 wget"
        exit 1
    fi
    
    # 如果使用镜像失败，尝试直连
    if [ "$MIRROR_MODE" = true ]; then
        warn "镜像下载失败，尝试直连..."
        if command -v curl &> /dev/null; then
            curl -fsSL "$url" -o "$output" && return 0
        else
            wget -q "$url" -O "$output" && return 0
        fi
    fi
    
    return 1
}

# 检测操作系统和架构
detect_platform() {
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    
    case "$OS" in
        linux*)
            OS="linux"
            ;;
        darwin*)
            OS="darwin"
            ;;
        mingw*|msys*|cygwin*)
            OS="windows"
            ;;
        *)
            error "不支持的操作系统: $OS"
            exit 1
            ;;
    esac
    
    case "$ARCH" in
        x86_64|amd64)
            ARCH="amd64"
            ;;
        arm64|aarch64)
            ARCH="arm64"
            ;;
        *)
            error "不支持的架构: $ARCH"
            exit 1
            ;;
    esac
    
    PLATFORM="${OS}-${ARCH}"
    
    # 构建文件名
    if [ "$OS" = "windows" ]; then
        BINARY="${BINARY_NAME}-${PLATFORM}.exe"
    else
        BINARY="${BINARY_NAME}-${PLATFORM}"
    fi
    
    info "检测到平台: ${BOLD}${PLATFORM}${NC}"
}

# 获取最新版本
get_latest_version() {
    if [ "$VERSION" = "latest" ]; then
        info "获取最新版本信息..."
        local api_url="https://api.github.com/repos/${REPO}/releases/latest"
        local response
        
        # GitHub API 不需要镜像，但可能需要多次重试
        if [ "$MIRROR_MODE" = true ]; then
            # 国内环境，尝试多次
            for i in 1 2 3; do
                response=$(curl -fsSL --connect-timeout 10 "$api_url" 2>/dev/null) && break
                sleep 1
            done
        else
            response=$(curl -fsSL "$api_url")
        fi
        
        VERSION=$(echo "$response" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        if [ -z "$VERSION" ]; then
            error "无法获取最新版本，请指定版本号或检查网络"
            error "例如: bash -s -- --version v1.0.0"
            exit 1
        fi
    fi
    success "版本: ${BOLD}${VERSION}${NC}"
}

# 下载安装程序
download() {
    DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${VERSION}/${BINARY}"
    
    info "下载安装程序..."
    
    # 创建临时目录
    TMP_DIR=$(mktemp -d)
    TMP_FILE="${TMP_DIR}/${BINARY}"
    
    # 使用镜像加速下载
    if [ "$MIRROR_MODE" = true ]; then
        local mirror_url="${ACTIVE_MIRROR}/${DOWNLOAD_URL}"
        info "URL: ${mirror_url}"
    else
        info "URL: ${DOWNLOAD_URL}"
    fi
    
    # 下载（使用通用下载函数）
    if ! do_download "$DOWNLOAD_URL" "$TMP_FILE"; then
        error "下载失败"
        exit 1
    fi
    
    if [ ! -f "$TMP_FILE" ]; then
        error "下载失败"
        exit 1
    fi
    
    success "下载完成"
}

# 安装
install() {
    # 设置执行权限
    chmod +x "$TMP_FILE"
    
    # 创建安装目录
    mkdir -p "$INSTALL_DIR"
    
    # 移动到安装目录
    mv "$TMP_FILE" "${INSTALL_DIR}/${BINARY_NAME}"
    
    success "安装到: ${BOLD}${INSTALL_DIR}/${BINARY_NAME}${NC}"
    
    # 清理
    rm -rf "$TMP_DIR"
}

# 检查 PATH
check_path() {
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        warn "请将以下路径添加到你的 PATH:"
        echo ""
        echo -e "  ${CYAN}export PATH=\"\$PATH:${INSTALL_DIR}\"${NC}"
        echo ""
        
        # 提示添加到 shell 配置文件
        SHELL_NAME=$(basename "$SHELL")
        case "$SHELL_NAME" in
            bash)
                RC_FILE="$HOME/.bashrc"
                ;;
            zsh)
                RC_FILE="$HOME/.zshrc"
                ;;
            fish)
                RC_FILE="$HOME/.config/fish/config.fish"
                warn "Fish shell 请使用: set -gx PATH \$PATH ${INSTALL_DIR}"
                return
                ;;
            *)
                RC_FILE="$HOME/.profile"
                ;;
        esac
        
        echo -e "  可以运行以下命令自动添加:"
        echo -e "  ${CYAN}echo 'export PATH=\"\$PATH:${INSTALL_DIR}\"' >> ${RC_FILE}${NC}"
        echo ""
    fi
}

# 运行安装程序
run_installer() {
    echo ""
    info "启动 Claude Code 安装向导..."
    echo ""
    
    "${INSTALL_DIR}/${BINARY_NAME}"
}

# 主函数
main() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  ${BOLD}Claude Code 一键安装工具${NC}${CYAN}                  ║${NC}"
    echo -e "${CYAN}║  ${YELLOW}⚡ 万界数据 ⚡${NC}${CYAN}                            ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo ""
    
    detect_platform
    detect_mirror_need
    
    # 如果需要使用镜像，查找可用的镜像
    if [ "$MIRROR_MODE" = true ]; then
        if ! find_working_mirror; then
            warn "将尝试直连 GitHub..."
            MIRROR_MODE=false
        fi
    fi
    
    get_latest_version
    download
    install
    check_path
    
    echo ""
    success "安装完成！"
    echo ""
    
    # 询问是否立即运行
    read -p "是否立即运行安装向导? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        run_installer
    else
        echo ""
        info "稍后可以运行以下命令启动安装向导:"
        echo -e "  ${CYAN}${BINARY_NAME}${NC}"
        echo ""
    fi
}

# 运行
main "$@"
