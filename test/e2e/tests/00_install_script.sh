#!/bin/bash
# 测试 00: 安装脚本语法和功能测试
# 验证 install.sh 的语法正确性和关键功能

set -e

echo "=== Test: Install Script Validation ==="

# 脚本路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
INSTALL_SH="${REPO_ROOT}/install.sh"

# 测试计数
TESTS_RUN=0
TESTS_PASSED=0

# 测试函数
assert_contains() {
    local content="$1"
    local expected="$2"
    local test_name="$3"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if echo "$content" | grep -q "$expected"; then
        echo "  [PASS] ${test_name}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo "  [FAIL] ${test_name}"
        echo "    Expected to contain: ${expected}"
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local test_name="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [ -f "$file" ]; then
        echo "  [PASS] ${test_name}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo "  [FAIL] ${test_name} - file not found: ${file}"
        return 1
    fi
}

# ========================================
# 测试 1: 脚本文件存在
# ========================================
echo ""
echo "Test 1: Install scripts exist"

assert_file_exists "$INSTALL_SH" "install.sh exists"
assert_file_exists "${REPO_ROOT}/install.ps1" "install.ps1 exists"

# ========================================
# 测试 2: Bash 语法检查
# ========================================
echo ""
echo "Test 2: Bash syntax validation"

TESTS_RUN=$((TESTS_RUN + 1))
if bash -n "$INSTALL_SH" 2>&1; then
    echo "  [PASS] install.sh has valid syntax"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "  [FAIL] install.sh has syntax errors"
    exit 1
fi

# ========================================
# 测试 3: 镜像配置存在
# ========================================
echo ""
echo "Test 3: Mirror configuration"

SCRIPT_CONTENT=$(cat "$INSTALL_SH")

assert_contains "$SCRIPT_CONTENT" "GITHUB_MIRRORS" "GITHUB_MIRRORS array defined"
assert_contains "$SCRIPT_CONTENT" "ghproxy.net" "ghproxy.net mirror configured"
assert_contains "$SCRIPT_CONTENT" "mirror.ghproxy.com" "mirror.ghproxy.com configured"
assert_contains "$SCRIPT_CONTENT" "gh-proxy.com" "gh-proxy.com configured"

# ========================================
# 测试 4: USE_MIRROR 环境变量支持
# ========================================
echo ""
echo "Test 4: USE_MIRROR environment variable support"

assert_contains "$SCRIPT_CONTENT" "USE_MIRROR" "USE_MIRROR variable defined"
assert_contains "$SCRIPT_CONTENT" 'USE_MIRROR:-auto' "USE_MIRROR defaults to auto"

# ========================================
# 测试 5: 网络检测函数存在
# ========================================
echo ""
echo "Test 5: Network detection functions"

assert_contains "$SCRIPT_CONTENT" "detect_mirror_need" "detect_mirror_need function exists"
assert_contains "$SCRIPT_CONTENT" "find_working_mirror" "find_working_mirror function exists"
assert_contains "$SCRIPT_CONTENT" "do_download" "do_download function exists"
assert_contains "$SCRIPT_CONTENT" "get_url" "get_url function exists"

# ========================================
# 测试 6: 镜像回退逻辑
# ========================================
echo ""
echo "Test 6: Mirror fallback logic"

assert_contains "$SCRIPT_CONTENT" "镜像下载失败，尝试直连" "Fallback to direct connection message"
assert_contains "$SCRIPT_CONTENT" "MIRROR_MODE=false" "Mirror mode can be disabled"

# ========================================
# 测试 7: 国内用户说明
# ========================================
echo ""
echo "Test 7: China user documentation in script comments"

assert_contains "$SCRIPT_CONTENT" "国内用户" "China user instructions"
assert_contains "$SCRIPT_CONTENT" "海外用户" "Overseas user instructions"

# ========================================
# 测试 8: PowerShell 脚本检查
# ========================================
echo ""
echo "Test 8: PowerShell script validation"

PS1_CONTENT=$(cat "${REPO_ROOT}/install.ps1")

assert_contains "$PS1_CONTENT" "GitHubMirrors" "PowerShell: GitHubMirrors array defined"
assert_contains "$PS1_CONTENT" "ghproxy.net" "PowerShell: ghproxy.net configured"
assert_contains "$PS1_CONTENT" "Test-MirrorNeed" "PowerShell: Test-MirrorNeed function exists"
assert_contains "$PS1_CONTENT" "Find-WorkingMirror" "PowerShell: Find-WorkingMirror function exists"
assert_contains "$PS1_CONTENT" "国内用户" "PowerShell: China user instructions"

# ========================================
# 汇总
# ========================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Install Script Tests: ${TESTS_PASSED}/${TESTS_RUN} passed"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$TESTS_PASSED" -eq "$TESTS_RUN" ]; then
    echo "SUCCESS: All install script tests passed"
    exit 0
else
    echo "FAILURE: Some install script tests failed"
    exit 1
fi
