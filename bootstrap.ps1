# Claude Code Installer Bootstrap
# Downloads and runs install.ps1 with correct encoding
#
# Usage (copy the entire command):
#   powershell -ExecutionPolicy Bypass -Command "& { $policy = Get-ExecutionPolicy -Scope CurrentUser; if ($policy -eq 'Restricted' -or $policy -eq 'AllSigned' -or $policy -eq 'Undefined') { Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force }; $r = Invoke-WebRequest -Uri 'https://ghproxy.net/https://raw.githubusercontent.com/taliove/easy-install-claude/main/install.ps1' -UseBasicParsing; $s = [System.Text.Encoding]::UTF8.GetString($r.Content); $b = [ScriptBlock]::Create($s); & $b }"

$ErrorActionPreference = "Stop"

# ============================================================================
# Step 1: Check and configure PowerShell Execution Policy
# ============================================================================

$policy = Get-ExecutionPolicy -Scope CurrentUser

if ($policy -eq 'Restricted' -or $policy -eq 'AllSigned' -or $policy -eq 'Undefined') {
    Write-Host "[i] Configuring PowerShell execution policy..." -ForegroundColor Cyan
    try {
        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
        Write-Host "[+] Execution policy set to RemoteSigned" -ForegroundColor Green
    }
    catch {
        Write-Host "[x] Failed to set execution policy: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please run this command manually and retry:" -ForegroundColor Yellow
        Write-Host "  Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned" -ForegroundColor Cyan
        exit 1
    }
}

# ============================================================================
# Step 2: Set console to UTF-8 encoding
# ============================================================================

try {
    $null = cmd /c chcp 65001 2>$null
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::InputEncoding = [System.Text.Encoding]::UTF8
}
catch { }

# ============================================================================
# Step 3: Show banner and download installer
# ============================================================================

Write-Host ""
Write-Host "+----------------------------------------------+" -ForegroundColor Cyan
Write-Host "|  Claude Code Installer                       |" -ForegroundColor Cyan
Write-Host "|  Easy Install Claude                         |" -ForegroundColor Cyan
Write-Host "+----------------------------------------------+" -ForegroundColor Cyan
Write-Host ""
Write-Host "[i] Downloading installer..." -ForegroundColor Cyan

$DirectUrl = "https://raw.githubusercontent.com/taliove/easy-install-claude/main/install.ps1"
$MirrorUrls = @(
    "https://ghproxy.net/$DirectUrl"
    "https://mirror.ghproxy.com/$DirectUrl"
    "https://gh-proxy.com/$DirectUrl"
)

$scriptContent = $null
$downloadSuccess = $false

$useMirror = $true
try {
    $null = Invoke-WebRequest -Uri "https://github.com" -TimeoutSec 3 -UseBasicParsing
    $useMirror = $false
}
catch {
    $useMirror = $true
}

$urlList = if ($useMirror) { $MirrorUrls + $DirectUrl } else { @($DirectUrl) + $MirrorUrls }

foreach ($url in $urlList) {
    try {
        Write-Host "[i] Trying: $url" -ForegroundColor DarkGray
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 30
        $bytes = $response.Content
        if ($bytes -is [byte[]]) {
            $scriptContent = [System.Text.Encoding]::UTF8.GetString($bytes)
        }
        else {
            $scriptContent = $bytes
        }
        $downloadSuccess = $true
        Write-Host "[+] Download successful" -ForegroundColor Green
        break
    }
    catch {
        Write-Host "[!] Failed: $url" -ForegroundColor Yellow
        continue
    }
}

if (-not $downloadSuccess -or [string]::IsNullOrEmpty($scriptContent)) {
    Write-Host "[x] Failed to download installer" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please try manual download:" -ForegroundColor Yellow
    Write-Host "  1. Visit: https://github.com/taliove/easy-install-claude" -ForegroundColor White
    Write-Host "  2. Download install.ps1" -ForegroundColor White
    Write-Host "  3. Run: .\install.ps1" -ForegroundColor White
    exit 1
}

# ============================================================================
# Step 4: Execute the installer
# ============================================================================

Write-Host "[i] Running installer..." -ForegroundColor Cyan
Write-Host ""

$scriptBlock = [ScriptBlock]::Create($scriptContent)
& $scriptBlock
