#!/bin/bash
# Claude Code 一键安装脚本 - Easy Install Claude
#
# 国内用户（推荐，使用加速镜像）:
#   curl -fsSL https://ghproxy.net/https://raw.githubusercontent.com/taliove/easy-install-claude/main/install.sh | bash
#
# 海外用户（直连 GitHub）:
#   curl -fsSL https://raw.githubusercontent.com/taliove/easy-install-claude/main/install.sh | bash
#
# 重新配置:
#   curl -fsSL <url> | bash -s -- --config
#
# 环境变量:
#   USE_MIRROR=true   强制使用国内镜像加速
#   USE_MIRROR=false  强制直连 GitHub（海外用户）
#   USE_MIRROR=auto   自动检测（默认）
#   PROVIDER=1-4      预设服务商（1=MiniMax, 2=豆包, 3=智谱, 4=万界）
#   ANTHROPIC_API_KEY 预设 API Key
#   ANTHROPIC_MODEL   预设模型

set -e

# ============================================================================
# 颜色定义
# ============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ============================================================================
# 配置
# ============================================================================
NVM_DIR="${HOME}/.nvm"
CLAUDE_DIR="${HOME}/.claude"
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"
NODE_MIN_VERSION=18

# npm 淘宝镜像
NPM_MIRROR="https://registry.npmmirror.com"
# Node.js 淘宝镜像（nvm 使用）
NODE_MIRROR="https://npmmirror.com/mirrors/node"

# GitHub 加速镜像列表
GITHUB_MIRRORS=(
    "https://ghproxy.net"
    "https://mirror.ghproxy.com"
    "https://gh-proxy.com"
)

# nvm 安装脚本地址
NVM_INSTALL_URL="https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh"

# 是否使用镜像加速（默认自动检测）
USE_MIRROR="${USE_MIRROR:-auto}"
MIRROR_MODE=false
ACTIVE_MIRROR=""

# 非交互式模式（用于自动化测试）
NONINTERACTIVE="${NONINTERACTIVE:-false}"

# ============================================================================
# 服务商配置
# ============================================================================

# 服务商列表
declare -a PROVIDER_NAMES=(
    "MiniMax"
    "豆包 (火山引擎)"
    "智谱 AI"
    "万界数据"
)

declare -a PROVIDER_URLS=(
    "https://api.minimaxi.com/anthropic"
    "https://ark.cn-beijing.volces.com/api/coding"
    "https://open.bigmodel.cn/api/anthropic"
    "https://maas-openapi.wanjiedata.com/api/anthropic"
)

declare -a PROVIDER_KEY_URLS=(
    "https://platform.minimaxi.com"
    "https://console.volcengine.com/ark"
    "https://open.bigmodel.cn"
    "https://data.wanjiehuyu.com"
)

# MiniMax 模型
declare -a MINIMAX_MODEL_IDS=(
    "M2.1-flash"
    "M2.1-standard"
)
declare -a MINIMAX_MODEL_NAMES=(
    "M2.1-flash"
    "M2.1-standard"
)
declare -a MINIMAX_MODEL_DESCS=(
    "[推荐] 免费使用"
    "标准版"
)

# 豆包模型（支持自定义）
declare -a DOUBAO_MODEL_IDS=(
    "ark-code-latest"
    "__custom__"
)
declare -a DOUBAO_MODEL_NAMES=(
    "ark-code-latest"
    "自定义模型"
)
declare -a DOUBAO_MODEL_DESCS=(
    "[默认] 最新代码模型"
    "输入自定义模型名称"
)

# 智谱模型
declare -a ZHIPU_MODEL_IDS=(
    "GLM-4.7"
    "GLM-4.5-Air"
)
declare -a ZHIPU_MODEL_NAMES=(
    "GLM-4.7"
    "GLM-4.5-Air"
)
declare -a ZHIPU_MODEL_DESCS=(
    "[推荐] 最强性能"
    "快速响应"
)

# 万界数据模型（Claude 系列）
declare -a WANJIE_MODEL_IDS=(
    "claude-sonnet-4-20250514"
    "claude-sonnet-4-5-20250929"
    "claude-haiku-4-5-20251001"
    "claude-opus-4-1-20250805"
    "claude-opus-4-5-20251101"
)
declare -a WANJIE_MODEL_NAMES=(
    "Claude Sonnet 4"
    "Claude Sonnet 4.5"
    "Claude Haiku 4.5"
    "Claude Opus 4.1"
    "Claude Opus 4.5"
)
declare -a WANJIE_MODEL_DESCS=(
    "[推荐] 性价比之选，日常使用"
    "增强版，更强推理能力"
    "快速响应，适合简单任务"
    "强大性能，适合复杂任务"
    "旗舰模型，最强性能"
)

# 当前选择的服务商和模型
SELECTED_PROVIDER=""
SELECTED_PROVIDER_INDEX=0
SELECTED_BASE_URL=""
SELECTED_MODEL=""
API_KEY=""

# ============================================================================
# 工具函数
# ============================================================================
info() { echo -e "${CYAN}ℹ ${NC}$1"; }
success() { echo -e "${GREEN}✓ ${NC}$1"; }
warn() { echo -e "${YELLOW}⚠ ${NC}$1"; }
error() { echo -e "${RED}✖ ${NC}$1"; }
step() { echo -e "${BLUE}▶ ${NC}${BOLD}$1${NC}"; }

# 打印分隔线
divider() {
    echo -e "${DIM}────────────────────────────────────────────────${NC}"
}

# 检测是否需要使用镜像
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
    
    # 自动检测：尝试快速访问 GitHub
    info "检测网络环境..."
    
    if curl -fsSL --connect-timeout 3 --max-time 5 "https://github.com" -o /dev/null 2>/dev/null; then
        if curl -fsSL --connect-timeout 3 --max-time 5 "https://raw.githubusercontent.com" -o /dev/null 2>/dev/null; then
            MIRROR_MODE=false
            success "可以直连 GitHub"
            return
        fi
    fi
    
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

# 通用下载函数
do_download() {
    local url="$1"
    local final_url
    
    final_url=$(get_url "$url")
    
    if command -v curl &> /dev/null; then
        curl -fsSL "$final_url"
        return $?
    elif command -v wget &> /dev/null; then
        wget -qO- "$final_url"
        return $?
    else
        error "需要 curl 或 wget"
        exit 1
    fi
}

# ============================================================================
# 检测函数
# ============================================================================

# 检测 Xcode Command Line Tools (macOS only)
check_xcode_clt() {
    if [ "$(uname)" != "Darwin" ]; then
        return 0
    fi
    
    if command -v git &> /dev/null; then
        return 0
    fi
    
    if xcode-select -p &> /dev/null 2>&1; then
        return 0
    fi
    
    return 1
}

# 检测用户 shell
detect_shell() {
    SHELL_NAME=$(basename "$SHELL")
    case "$SHELL_NAME" in
        zsh)
            RC_FILE="$HOME/.zshrc"
            ;;
        bash)
            if [ -f "$HOME/.bash_profile" ] && [ "$(uname)" = "Darwin" ]; then
                RC_FILE="$HOME/.bash_profile"
            else
                RC_FILE="$HOME/.bashrc"
            fi
            ;;
        fish)
            RC_FILE="$HOME/.config/fish/config.fish"
            ;;
        *)
            RC_FILE="$HOME/.profile"
            ;;
    esac
}

# 检测 Node.js 版本
check_node_version() {
    if command -v node &> /dev/null; then
        local version
        version=$(node -v 2>/dev/null | sed 's/v//' | cut -d. -f1)
        if [ -n "$version" ] && [ "$version" -ge "$NODE_MIN_VERSION" ]; then
            return 0
        fi
    fi
    return 1
}

# 检测 nvm
check_nvm() {
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        return 0
    fi
    return 1
}

# 加载 nvm
load_nvm() {
    export NVM_DIR="$HOME/.nvm"
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        # shellcheck source=/dev/null
        . "$NVM_DIR/nvm.sh"
        return 0
    fi
    return 1
}

# ============================================================================
# 安装函数
# ============================================================================

# 安装 Xcode Command Line Tools (macOS only)
install_xcode_clt() {
    step "安装 Xcode Command Line Tools..."
    info "这是 macOS 上使用 git 的必要依赖"
    echo ""
    
    xcode-select --install 2>/dev/null || true
    
    echo ""
    warn "请在弹出的窗口中点击「安装」按钮"
    info "安装完成后按 Enter 继续..."
    read -r
    
    if ! command -v git &> /dev/null; then
        error "Xcode Command Line Tools 安装似乎未完成"
        error "请手动运行: xcode-select --install"
        error "安装完成后重新运行此脚本"
        exit 1
    fi
    
    success "Xcode Command Line Tools 安装完成"
}

# 清理 nvm 残留目录（用于重试前）
cleanup_nvm_dir() {
    if [ -d "$NVM_DIR" ]; then
        rm -rf "$NVM_DIR"
    fi
}

# 尝试使用指定镜像安装 nvm
try_install_nvm_with_mirror() {
    local mirror="$1"
    local install_script
    local nvm_source
    
    if [ -n "$mirror" ]; then
        install_script="${mirror}/${NVM_INSTALL_URL}"
        nvm_source="${mirror}/https://github.com/nvm-sh/nvm.git"
        info "尝试镜像: ${mirror}"
    else
        install_script="$NVM_INSTALL_URL"
        unset NVM_SOURCE
        info "尝试直连 GitHub..."
    fi
    
    # 清理残留目录
    cleanup_nvm_dir
    
    # 设置 git 超时（防止长时间等待）
    export GIT_HTTP_CONNECT_TIMEOUT=10
    export GIT_HTTP_LOW_SPEED_LIMIT=1000
    export GIT_HTTP_LOW_SPEED_TIME=15
    
    # 设置 NVM_SOURCE
    if [ -n "$mirror" ]; then
        export NVM_SOURCE="$nvm_source"
    fi
    
    # 下载并执行安装脚本（带超时）
    if curl -fsSL --connect-timeout 10 --max-time 60 "$install_script" 2>/dev/null | bash 2>&1; then
        return 0
    fi
    
    return 1
}

# 安装 nvm
install_nvm() {
    step "安装 nvm (Node Version Manager)..."
    
    local installed=false
    
    # 镜像模式：逐个尝试所有镜像
    if [ "$MIRROR_MODE" = true ]; then
        info "将依次尝试所有可用镜像..."
        
        for mirror in "${GITHUB_MIRRORS[@]}"; do
            if try_install_nvm_with_mirror "$mirror"; then
                installed=true
                success "使用镜像 ${mirror} 安装成功"
                break
            else
                warn "镜像 ${mirror} 失败，尝试下一个..."
            fi
        done
        
        # 所有镜像都失败，尝试直连
        if [ "$installed" = false ]; then
            warn "所有镜像均失败，尝试直连 GitHub..."
            if try_install_nvm_with_mirror ""; then
                installed=true
                success "直连 GitHub 安装成功"
            fi
        fi
    else
        # 直连模式
        if try_install_nvm_with_mirror ""; then
            installed=true
        fi
    fi
    
    # 检查是否安装成功
    if [ "$installed" = false ]; then
        error "nvm 安装失败"
        echo ""
        echo -e "  ${YELLOW}手动安装方法:${NC}"
        echo -e "  1. 访问 https://github.com/nvm-sh/nvm"
        echo -e "  2. 下载并解压到 ~/.nvm"
        echo -e "  3. 重新运行此脚本"
        echo ""
        exit 1
    fi
    
    # 清理 git 超时环境变量
    unset GIT_HTTP_CONNECT_TIMEOUT
    unset GIT_HTTP_LOW_SPEED_LIMIT
    unset GIT_HTTP_LOW_SPEED_TIME
    unset NVM_SOURCE
    
    # 加载 nvm
    if ! load_nvm; then
        error "无法加载 nvm"
        exit 1
    fi
    
    success "nvm 安装完成"
}

# 安装 Node.js
install_nodejs() {
    step "安装 Node.js (v${NODE_MIN_VERSION}+)..."
    
    # 设置 Node.js 镜像
    export NVM_NODEJS_ORG_MIRROR="$NODE_MIRROR"
    info "使用镜像: $NODE_MIRROR"
    
    # 安装 LTS 版本
    if ! nvm install --lts; then
        error "Node.js 安装失败"
        exit 1
    fi
    
    # 设为默认
    nvm alias default node
    
    success "Node.js $(node -v) 安装完成"
}

# 配置 npm 镜像
configure_npm_mirror() {
    step "配置 npm 镜像..."
    npm config set registry "$NPM_MIRROR"
    success "npm 镜像已配置: $NPM_MIRROR"
}

# 安装 Claude Code
install_claude_code() {
    step "安装 Claude Code..."
    
    if ! npm install -g @anthropic-ai/claude-code; then
        error "Claude Code 安装失败"
        exit 1
    fi
    
    success "Claude Code 安装完成"
}

# ============================================================================
# 服务商与模型选择
# ============================================================================

# 选择服务商
select_provider() {
    # 非交互式模式：使用环境变量
    if [ "$NONINTERACTIVE" = "true" ] && [ -n "${PROVIDER:-}" ]; then
        if [[ "$PROVIDER" =~ ^[1-4]$ ]]; then
            SELECTED_PROVIDER_INDEX=$((PROVIDER - 1))
            SELECTED_PROVIDER="${PROVIDER_NAMES[$SELECTED_PROVIDER_INDEX]}"
            SELECTED_BASE_URL="${PROVIDER_URLS[$SELECTED_PROVIDER_INDEX]}"
            success "服务商已从环境变量设置: $SELECTED_PROVIDER"
            return
        fi
    fi
    
    echo ""
    step "选择服务商"
    echo ""
    
    for i in "${!PROVIDER_NAMES[@]}"; do
        local num=$((i + 1))
        local name="${PROVIDER_NAMES[$i]}"
        local key_url="${PROVIDER_KEY_URLS[$i]}"
        
        if [ "$i" -eq 0 ]; then
            echo -e "  ${GREEN}${num}.${NC} ${BOLD}${name}${NC}  ${YELLOW}[默认]${NC}"
        else
            echo -e "  ${num}. ${name}"
        fi
        echo -e "     ${DIM}API Key 获取: ${key_url}${NC}"
    done
    
    echo ""
    while true; do
        read -rp "  请选择服务商 [1-4，默认 1]: " choice
        choice="${choice:-1}"
        
        if [[ "$choice" =~ ^[1-4]$ ]]; then
            SELECTED_PROVIDER_INDEX=$((choice - 1))
            SELECTED_PROVIDER="${PROVIDER_NAMES[$SELECTED_PROVIDER_INDEX]}"
            SELECTED_BASE_URL="${PROVIDER_URLS[$SELECTED_PROVIDER_INDEX]}"
            success "已选择: ${SELECTED_PROVIDER}"
            break
        else
            error "请输入 1-4 之间的数字"
        fi
    done
}

# 选择模型（根据服务商）
select_model() {
    # 非交互式模式：使用环境变量
    if [ "$NONINTERACTIVE" = "true" ] && [ -n "${ANTHROPIC_MODEL:-}" ]; then
        SELECTED_MODEL="$ANTHROPIC_MODEL"
        success "模型已从环境变量设置: $SELECTED_MODEL"
        return
    fi
    
    echo ""
    step "选择模型 (${SELECTED_PROVIDER})"
    echo ""
    
    local -a model_ids
    local -a model_names
    local -a model_descs
    local model_count
    local supports_custom=false
    
    case $SELECTED_PROVIDER_INDEX in
        0)  # MiniMax
            model_ids=("${MINIMAX_MODEL_IDS[@]}")
            model_names=("${MINIMAX_MODEL_NAMES[@]}")
            model_descs=("${MINIMAX_MODEL_DESCS[@]}")
            ;;
        1)  # 豆包
            model_ids=("${DOUBAO_MODEL_IDS[@]}")
            model_names=("${DOUBAO_MODEL_NAMES[@]}")
            model_descs=("${DOUBAO_MODEL_DESCS[@]}")
            supports_custom=true
            ;;
        2)  # 智谱
            model_ids=("${ZHIPU_MODEL_IDS[@]}")
            model_names=("${ZHIPU_MODEL_NAMES[@]}")
            model_descs=("${ZHIPU_MODEL_DESCS[@]}")
            ;;
        3)  # 万界
            model_ids=("${WANJIE_MODEL_IDS[@]}")
            model_names=("${WANJIE_MODEL_NAMES[@]}")
            model_descs=("${WANJIE_MODEL_DESCS[@]}")
            ;;
    esac
    
    model_count=${#model_ids[@]}
    
    for i in "${!model_ids[@]}"; do
        local num=$((i + 1))
        local name="${model_names[$i]}"
        local desc="${model_descs[$i]}"
        local id="${model_ids[$i]}"
        
        if [ "$i" -eq 0 ]; then
            echo -e "  ${GREEN}${num}.${NC} ${BOLD}${name}${NC}  ${YELLOW}${desc}${NC}"
        else
            echo -e "  ${num}. ${name}  ${DIM}${desc}${NC}"
        fi
        
        # 不显示 __custom__ 作为 ID
        if [ "$id" != "__custom__" ]; then
            echo -e "     ${DIM}(${id})${NC}"
        fi
    done
    
    echo ""
    while true; do
        read -rp "  请选择 [1-${model_count}，默认 1]: " choice
        choice="${choice:-1}"
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$model_count" ]; then
            local idx=$((choice - 1))
            local selected_id="${model_ids[$idx]}"
            
            # 处理自定义模型输入
            if [ "$selected_id" = "__custom__" ]; then
                echo ""
                read -rp "  请输入自定义模型名称 [默认 ark-code-latest]: " custom_model
                SELECTED_MODEL="${custom_model:-ark-code-latest}"
            else
                SELECTED_MODEL="$selected_id"
            fi
            
            success "已选择模型: ${SELECTED_MODEL}"
            break
        else
            error "请输入 1-${model_count} 之间的数字"
        fi
    done
}

# 输入 API Key
input_api_key() {
    # 非交互式模式：使用环境变量
    if [ "$NONINTERACTIVE" = "true" ] && [ -n "${ANTHROPIC_API_KEY:-}" ]; then
        API_KEY="$ANTHROPIC_API_KEY"
        success "API Key 已从环境变量设置"
        return
    fi
    
    local key_url="${PROVIDER_KEY_URLS[$SELECTED_PROVIDER_INDEX]}"
    
    echo ""
    step "配置 API Key"
    echo ""
    echo -e "  请输入 ${BOLD}${SELECTED_PROVIDER}${NC} API Key"
    echo -e "  ${DIM}获取地址: ${key_url}${NC}"
    echo ""
    
    while true; do
        read -rp "  API Key: " API_KEY
        if [ -n "$API_KEY" ]; then
            success "API Key 已设置"
            break
        else
            error "API Key 不能为空"
        fi
    done
}

# 计算模型映射
calculate_model_mappings() {
    case $SELECTED_PROVIDER_INDEX in
        0)  # MiniMax - 无需映射
            DEFAULT_HAIKU=""
            DEFAULT_SONNET=""
            DEFAULT_OPUS=""
            ;;
        1)  # 豆包 - 全部使用用户选择的模型
            DEFAULT_HAIKU="$SELECTED_MODEL"
            DEFAULT_SONNET="$SELECTED_MODEL"
            DEFAULT_OPUS="$SELECTED_MODEL"
            ;;
        2)  # 智谱 - Haiku=GLM-4.5-Air, Sonnet/Opus=GLM-4.7
            DEFAULT_HAIKU="GLM-4.5-Air"
            DEFAULT_SONNET="GLM-4.7"
            DEFAULT_OPUS="GLM-4.7"
            ;;
        3)  # 万界 - 保持原有逻辑
            DEFAULT_HAIKU="claude-haiku-4-5-20251001"
            
            if [ "$SELECTED_MODEL" = "claude-sonnet-4-5-20250929" ]; then
                DEFAULT_SONNET="claude-sonnet-4-5-20250929"
            else
                DEFAULT_SONNET="claude-sonnet-4-20250514"
            fi
            
            if [ "$SELECTED_MODEL" = "claude-opus-4-5-20251101" ]; then
                DEFAULT_OPUS="claude-opus-4-5-20251101"
            else
                DEFAULT_OPUS="claude-opus-4-1-20250805"
            fi
            ;;
    esac
}

# 写入配置文件
write_settings() {
    step "写入配置文件..."
    
    # 创建配置目录
    mkdir -p "$CLAUDE_DIR"
    
    # 计算模型映射
    calculate_model_mappings
    
    # 生成 JSON 配置
    # MiniMax 不需要 Haiku/Sonnet/Opus 映射
    if [ "$SELECTED_PROVIDER_INDEX" -eq 0 ]; then
        cat > "$SETTINGS_FILE" << EOF
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
    "ANTHROPIC_AUTH_TOKEN": "${API_KEY}",
    "ANTHROPIC_BASE_URL": "${SELECTED_BASE_URL}",
    "ANTHROPIC_MODEL": "${SELECTED_MODEL}",
    "API_TIMEOUT_MS": "3000000",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": 1
  }
}
EOF
    else
        cat > "$SETTINGS_FILE" << EOF
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
    "ANTHROPIC_AUTH_TOKEN": "${API_KEY}",
    "ANTHROPIC_BASE_URL": "${SELECTED_BASE_URL}",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "${DEFAULT_HAIKU}",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "${DEFAULT_OPUS}",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "${DEFAULT_SONNET}",
    "ANTHROPIC_MODEL": "${SELECTED_MODEL}",
    "API_TIMEOUT_MS": "3000000",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": 1
  }
}
EOF
    fi
    
    success "配置已写入: $SETTINGS_FILE"
}

# ============================================================================
# PATH 配置
# ============================================================================

configure_path() {
    step "配置环境变量..."
    
    detect_shell
    
    local npm_bin
    npm_bin="$(npm config get prefix)/bin"
    local nvm_init='export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"'
    
    if ! grep -q 'NVM_DIR' "$RC_FILE" 2>/dev/null; then
        echo "" >> "$RC_FILE"
        echo "# nvm" >> "$RC_FILE"
        echo "$nvm_init" >> "$RC_FILE"
        info "已添加 nvm 初始化到 $RC_FILE"
    fi
    
    if ! grep -q "$npm_bin" "$RC_FILE" 2>/dev/null; then
        echo "" >> "$RC_FILE"
        echo "# npm global bin" >> "$RC_FILE"
        echo "export PATH=\"\$PATH:$npm_bin\"" >> "$RC_FILE"
        info "已添加 npm bin 到 PATH"
    fi
    
    export PATH="$PATH:$npm_bin"
    
    success "环境变量配置完成"
}

# ============================================================================
# 主流程
# ============================================================================

show_help() {
    echo ""
    echo -e "${BOLD}Easy Install Claude - 一键安装脚本${NC}"
    echo ""
    echo "用法:"
    echo "  bash install.sh           完整安装流程"
    echo "  bash install.sh --config  仅重新配置（服务商 + API Key + 模型选择）"
    echo "  bash install.sh --help    显示此帮助"
    echo ""
    echo "支持的服务商:"
    echo "  1. MiniMax         https://platform.minimaxi.com"
    echo "  2. 豆包 (火山引擎)  https://console.volcengine.com/ark"
    echo "  3. 智谱 AI         https://open.bigmodel.cn"
    echo "  4. 万界数据        https://data.wanjiehuyu.com"
    echo ""
    echo "在线安装:"
    echo "  国内: curl -fsSL https://ghproxy.net/https://raw.githubusercontent.com/taliove/easy-install-claude/main/install.sh | bash"
    echo "  海外: curl -fsSL https://raw.githubusercontent.com/taliove/easy-install-claude/main/install.sh | bash"
    echo ""
    echo "环境变量:"
    echo "  USE_MIRROR=true/false/auto  镜像模式（默认 auto）"
    echo "  PROVIDER=1-4                预设服务商"
    echo "  ANTHROPIC_API_KEY=xxx       预设 API Key"
    echo "  ANTHROPIC_MODEL=xxx         预设模型"
    echo ""
}

show_banner() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  ${BOLD}Claude Code 一键安装${NC}${CYAN}                          ║${NC}"
    echo -e "${CYAN}║  ${YELLOW}Easy Install Claude${NC}${CYAN}                            ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════╝${NC}"
    echo ""
}

# 仅配置模式
config_only() {
    show_banner
    step "重新配置 Claude Code"
    divider
    
    if ! command -v claude &> /dev/null; then
        error "Claude Code 未安装，请先运行完整安装"
        exit 1
    fi
    
    select_provider
    select_model
    input_api_key
    write_settings
    
    divider
    echo ""
    success "配置完成！"
    echo ""
    echo -e "  服务商: ${BOLD}${SELECTED_PROVIDER}${NC}"
    echo -e "  模型:   ${BOLD}${SELECTED_MODEL}${NC}"
    echo ""
    echo -e "  运行 ${CYAN}claude${NC} 开始使用"
    echo ""
}

# 完整安装流程
full_install() {
    show_banner
    
    # 检测网络环境
    detect_mirror_need
    
    if [ "$MIRROR_MODE" = true ]; then
        if ! find_working_mirror; then
            warn "将尝试直连..."
            MIRROR_MODE=false
        fi
    fi
    
    divider
    
    # Step 1: 检测/安装 Node.js
    step "Step 1: 检查 Node.js 环境"
    
    if check_node_version; then
        success "Node.js $(node -v) 已安装"
    else
        info "需要安装 Node.js ${NODE_MIN_VERSION}+"
        
        if ! check_xcode_clt; then
            install_xcode_clt
        fi
        
        if check_nvm; then
            info "nvm 已安装"
            load_nvm
        else
            install_nvm
        fi
        
        install_nodejs
    fi
    
    divider
    
    # Step 2: 配置 npm 镜像
    step "Step 2: 配置 npm"
    configure_npm_mirror
    
    divider
    
    # Step 3: 安装 Claude Code
    step "Step 3: 安装 Claude Code"
    install_claude_code
    
    divider
    
    # Step 4: 选择服务商和配置
    step "Step 4: 配置 Claude Code"
    select_provider
    select_model
    input_api_key
    write_settings
    
    divider
    
    # Step 5: 配置 PATH
    step "Step 5: 配置环境变量"
    configure_path
    
    divider
    
    # 完成
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ${BOLD}安装完成！${NC}${GREEN}                                    ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  服务商: ${BOLD}${SELECTED_PROVIDER}${NC}"
    echo -e "  模型:   ${BOLD}${SELECTED_MODEL}${NC}"
    echo ""
    echo -e "  请运行以下命令使配置生效:"
    echo ""
    echo -e "    ${CYAN}source $RC_FILE${NC}"
    echo ""
    echo -e "  然后运行 ${CYAN}claude${NC} 开始使用"
    echo ""
    echo -e "  ${DIM}如需重新配置，运行:${NC}"
    echo -e "    ${CYAN}curl -fsSL <url> | bash -s -- --config${NC}"
    echo ""
}

# 主函数
main() {
    case "${1:-}" in
        --help|-h)
            show_help
            exit 0
            ;;
        --config)
            config_only
            exit 0
            ;;
        "")
            full_install
            ;;
        *)
            error "未知参数: $1"
            show_help
            exit 1
            ;;
    esac
}

# 运行
main "$@"
