# Claude Code 一键安装脚本 (PowerShell)
#
# 国内用户（推荐，使用加速镜像）:
#   iwr -useb https://ghproxy.net/https://raw.githubusercontent.com/taliove/go-install-claude/main/install.ps1 | iex
#
# 海外用户（直连 GitHub）:
#   iwr -useb https://raw.githubusercontent.com/taliove/go-install-claude/main/install.ps1 | iex
#
# 保存后运行（可指定版本）:
#   .\install.ps1 -Version v1.0.0
#
# 环境变量:
#   $env:USE_MIRROR="true"   强制使用国内镜像加速
#   $env:USE_MIRROR="false"  强制直连 GitHub（海外用户）
#   不设置则自动检测

param(
    [string]$Version = "latest"
)

$ErrorActionPreference = "Stop"

# 配置
$Repo = "taliove/go-install-claude"
$BinaryName = "claude-installer"
$InstallDir = "$env:LOCALAPPDATA\Programs\claude-installer"

# GitHub 加速镜像列表（国内用户优先尝试）
$GitHubMirrors = @(
    "https://ghproxy.net"
    "https://mirror.ghproxy.com"
    "https://gh-proxy.com"
)

# 全局变量
$script:MirrorMode = $false
$script:ActiveMirror = ""

# 颜色输出函数
function Write-Info { Write-Host "ℹ " -ForegroundColor Cyan -NoNewline; Write-Host $args[0] }
function Write-Success { Write-Host "✓ " -ForegroundColor Green -NoNewline; Write-Host $args[0] }
function Write-Warn { Write-Host "⚠ " -ForegroundColor Yellow -NoNewline; Write-Host $args[0] }
function Write-Err { Write-Host "✖ " -ForegroundColor Red -NoNewline; Write-Host $args[0] }

# 检测是否需要使用镜像
function Test-MirrorNeed {
    $useMirror = $env:USE_MIRROR
    
    if ($useMirror -eq "true") {
        $script:MirrorMode = $true
        return
    }
    elseif ($useMirror -eq "false") {
        $script:MirrorMode = $false
        return
    }
    
    # 自动检测：尝试连接 GitHub API
    Write-Info "检测网络环境..."
    try {
        $null = Invoke-WebRequest -Uri "https://api.github.com" -TimeoutSec 5 -UseBasicParsing
        $script:MirrorMode = $false
        Write-Success "可以直连 GitHub"
    }
    catch {
        $script:MirrorMode = $true
        Write-Warn "无法直连 GitHub，将使用国内镜像加速"
    }
}

# 查找可用的镜像
function Find-WorkingMirror {
    foreach ($mirror in $GitHubMirrors) {
        try {
            $null = Invoke-WebRequest -Uri $mirror -TimeoutSec 5 -UseBasicParsing
            $script:ActiveMirror = $mirror
            Write-Success "使用镜像: $mirror"
            return $true
        }
        catch {
            continue
        }
    }
    Write-Err "所有镜像均不可用"
    return $false
}

# 获取带镜像前缀的 URL
function Get-MirrorUrl {
    param([string]$Url)
    
    if ($script:MirrorMode -and $script:ActiveMirror) {
        return "$($script:ActiveMirror)/$Url"
    }
    return $Url
}

# 通用下载函数（支持镜像重试）
function Invoke-Download {
    param(
        [string]$Url,
        [string]$OutFile
    )
    
    $finalUrl = Get-MirrorUrl -Url $Url
    
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $finalUrl -OutFile $OutFile -UseBasicParsing
        return $true
    }
    catch {
        # 如果使用镜像失败，尝试直连
        if ($script:MirrorMode) {
            Write-Warn "镜像下载失败，尝试直连..."
            try {
                Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing
                return $true
            }
            catch {
                return $false
            }
        }
        return $false
    }
}

# Banner
function Show-Banner {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  " -ForegroundColor Cyan -NoNewline
    Write-Host "Claude Code 一键安装工具" -ForegroundColor White -NoNewline
    Write-Host "                  ║" -ForegroundColor Cyan
    Write-Host "║  " -ForegroundColor Cyan -NoNewline
    Write-Host "⚡ 万界数据 ⚡" -ForegroundColor Yellow -NoNewline
    Write-Host "                            ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

# 检测架构
function Get-Platform {
    $arch = [System.Environment]::Is64BitOperatingSystem
    if (-not $arch) {
        Write-Err "需要 64 位 Windows"
        exit 1
    }
    
    $script:Platform = "windows-amd64"
    $script:Binary = "$BinaryName-$Platform.exe"
    
    Write-Info "检测到平台: $Platform"
}

# 获取最新版本
function Get-LatestVersion {
    if ($Version -eq "latest") {
        Write-Info "获取最新版本信息..."
        $apiUrl = "https://api.github.com/repos/$Repo/releases/latest"
        
        # GitHub API，国内可能需要重试
        $maxRetries = if ($script:MirrorMode) { 3 } else { 1 }
        $success = $false
        
        for ($i = 1; $i -le $maxRetries; $i++) {
            try {
                $release = Invoke-RestMethod -Uri $apiUrl -TimeoutSec 10
                $script:Version = $release.tag_name
                $success = $true
                break
            }
            catch {
                if ($i -lt $maxRetries) {
                    Start-Sleep -Seconds 1
                }
            }
        }
        
        if (-not $success) {
            Write-Err "无法获取最新版本，请指定版本号或检查网络"
            Write-Err "例如: .\install.ps1 -Version v1.0.0"
            exit 1
        }
    }
    Write-Success "版本: $Version"
}

# 下载
function Download-Binary {
    $downloadUrl = "https://github.com/$Repo/releases/download/$Version/$Binary"
    
    Write-Info "下载安装程序..."
    
    # 显示实际使用的 URL
    if ($script:MirrorMode -and $script:ActiveMirror) {
        Write-Info "URL: $($script:ActiveMirror)/$downloadUrl"
    }
    else {
        Write-Info "URL: $downloadUrl"
    }
    
    # 创建临时文件
    $tmpFile = [System.IO.Path]::GetTempFileName() + ".exe"
    
    if (-not (Invoke-Download -Url $downloadUrl -OutFile $tmpFile)) {
        Write-Err "下载失败"
        exit 1
    }
    
    if (-not (Test-Path $tmpFile)) {
        Write-Err "下载失败"
        exit 1
    }
    
    $script:TmpFile = $tmpFile
    Write-Success "下载完成"
}

# 安装
function Install-Binary {
    # 创建安装目录
    if (-not (Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    }
    
    # 目标路径
    $targetPath = Join-Path $InstallDir "$BinaryName.exe"
    
    # 移动文件
    Move-Item -Path $TmpFile -Destination $targetPath -Force
    
    Write-Success "安装到: $targetPath"
    
    $script:TargetPath = $targetPath
}

# 添加到 PATH
function Add-ToPath {
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    
    if ($currentPath -notlike "*$InstallDir*") {
        Write-Info "添加到 PATH..."
        
        $newPath = "$currentPath;$InstallDir"
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        
        # 更新当前会话
        $env:Path = "$env:Path;$InstallDir"
        
        Write-Success "已添加到 PATH (需要重新打开终端生效)"
    }
}

# 运行安装程序
function Run-Installer {
    Write-Host ""
    Write-Info "启动 Claude Code 安装向导..."
    Write-Host ""
    
    & $TargetPath
}

# 主函数
function Main {
    Show-Banner
    Get-Platform
    Test-MirrorNeed
    
    # 如果需要使用镜像，查找可用的镜像
    if ($script:MirrorMode) {
        if (-not (Find-WorkingMirror)) {
            Write-Warn "将尝试直连 GitHub..."
            $script:MirrorMode = $false
        }
    }
    
    Get-LatestVersion
    Download-Binary
    Install-Binary
    Add-ToPath
    
    Write-Host ""
    Write-Success "安装完成！"
    Write-Host ""
    
    # 询问是否立即运行
    $response = Read-Host "是否立即运行安装向导? [Y/n]"
    if ($response -eq "" -or $response -match "^[Yy]") {
        Run-Installer
    }
    else {
        Write-Host ""
        Write-Info "稍后可以运行以下命令启动安装向导:"
        Write-Host "  $BinaryName" -ForegroundColor Cyan
        Write-Host ""
    }
}

# 运行
Main
