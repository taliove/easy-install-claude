# Claude Code Installer for Windows
# Usage: irm https://ghproxy.net/https://raw.githubusercontent.com/taliove/easy-install-claude/main/install.ps1 | iex

& {
    param([switch]$Config, [switch]$Help)

    $ErrorActionPreference = "Stop"

    # ============================================================================
    # Configuration
    # ============================================================================

    $script:NpmRegistry = "https://registry.npmmirror.com"
    $script:ClaudePackage = "@anthropic-ai/claude-code"
    $script:ClaudeDir = "$env:USERPROFILE\.claude"
    $script:SettingsFile = "$script:ClaudeDir\settings.json"

    $script:GitHubMirrors = @(
        "https://ghproxy.net"
        "https://mirror.ghproxy.com"
        "https://gh-proxy.com"
    )

    # ============================================================================
    # Providers Configuration
    # ============================================================================

    $script:Providers = @(
        @{
            ID          = "minimax"
            Name        = "MiniMax"
            Tag         = "[Recommended]"
            Description = "Free quota, fast response"
            BaseUrl     = "https://api.minimaxi.com/anthropic"
            ApiKeyUrl   = "https://platform.minimaxi.com"
            Models      = @(
                @{ ID = "M2.1-flash"; Name = "M2.1-flash"; Tag = "[Recommended]"; Description = "Free, fast response" },
                @{ ID = "M2.1-standard"; Name = "M2.1-standard"; Tag = ""; Description = "Standard, more powerful" }
            )
            CustomModel = $false
        },
        @{
            ID          = "doubao"
            Name        = "Doubao (Volcengine)"
            Tag         = ""
            Description = "ByteDance, stable and reliable"
            BaseUrl     = "https://ark.cn-beijing.volces.com/api/coding"
            ApiKeyUrl   = "https://console.volcengine.com/ark"
            Models      = @(
                @{ ID = "ark-code-latest"; Name = "ark-code-latest"; Tag = "[Default]"; Description = "Latest coding model" }
            )
            CustomModel = $true
        },
        @{
            ID          = "zhipu"
            Name        = "Zhipu AI"
            Tag         = ""
            Description = "Chinese LLM, cost-effective"
            BaseUrl     = "https://open.bigmodel.cn/api/anthropic"
            ApiKeyUrl   = "https://open.bigmodel.cn"
            Models      = @(
                @{ ID = "GLM-4.7"; Name = "GLM-4.7"; Tag = "[Recommended]"; Description = "Latest, powerful" },
                @{ ID = "GLM-4.5-Air"; Name = "GLM-4.5-Air"; Tag = ""; Description = "Fast response" }
            )
            CustomModel = $false
        },
        @{
            ID          = "wanjie"
            Name        = "Wanjie Data"
            Tag         = ""
            Description = "Claude native models proxy"
            BaseUrl     = "https://maas-openapi.wanjiedata.com/api/anthropic"
            ApiKeyUrl   = "https://data.wanjiehuyu.com"
            Models      = @(
                @{ ID = "claude-sonnet-4-20250514"; Name = "Claude Sonnet 4"; Tag = "[Recommended]"; Description = "Best value"; Family = "sonnet" },
                @{ ID = "claude-sonnet-4-5-20250929"; Name = "Claude Sonnet 4.5"; Tag = ""; Description = "Enhanced Sonnet"; Family = "sonnet" },
                @{ ID = "claude-haiku-4-5-20251001"; Name = "Claude Haiku 4.5"; Tag = ""; Description = "Fast response"; Family = "haiku" },
                @{ ID = "claude-opus-4-1-20250805"; Name = "Claude Opus 4.1"; Tag = ""; Description = "Complex tasks"; Family = "opus" },
                @{ ID = "claude-opus-4-5-20251101"; Name = "Claude Opus 4.5"; Tag = ""; Description = "Flagship model"; Family = "opus" }
            )
            CustomModel = $false
        }
    )

    $script:MirrorMode = $false
    $script:ActiveMirror = ""

    # ============================================================================
    # Output Functions
    # ============================================================================

    function Write-Info { Write-Host "[i] " -ForegroundColor Cyan -NoNewline; Write-Host $args[0] }
    function Write-Success { Write-Host "[+] " -ForegroundColor Green -NoNewline; Write-Host $args[0] }
    function Write-Warn { Write-Host "[!] " -ForegroundColor Yellow -NoNewline; Write-Host $args[0] }
    function Write-Err { Write-Host "[x] " -ForegroundColor Red -NoNewline; Write-Host $args[0] }

    function Write-Step {
        param([int]$Step, [int]$Total, [string]$Message)
        Write-Host ""
        Write-Host "[$Step/$Total] " -ForegroundColor Magenta -NoNewline
        Write-Host $Message -ForegroundColor White
        Write-Host ("-" * 50) -ForegroundColor DarkGray
    }

    # ============================================================================
    # Banner
    # ============================================================================

    function Show-Banner {
        Write-Host ""
        Write-Host "+----------------------------------------------+" -ForegroundColor Cyan
        Write-Host "|  " -ForegroundColor Cyan -NoNewline
        Write-Host "Claude Code Installer" -ForegroundColor White -NoNewline
        Write-Host "                       |" -ForegroundColor Cyan
        Write-Host "|  " -ForegroundColor Cyan -NoNewline
        Write-Host "Easy Install Claude" -ForegroundColor Yellow -NoNewline
        Write-Host "                       |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor Cyan
        Write-Host ""
    }

    # ============================================================================
    # Help
    # ============================================================================

    function Show-Help {
        Show-Banner
        Write-Host "Usage: install.ps1 [Options]" -ForegroundColor White
        Write-Host ""
        Write-Host "Options:" -ForegroundColor Yellow
        Write-Host "  -Config    Run configuration wizard only (skip installation)"
        Write-Host "  -Help      Show this help message"
        Write-Host ""
        Write-Host "Examples:" -ForegroundColor Yellow
        Write-Host "  # Full installation"
        Write-Host "  irm <url> | iex"
        Write-Host ""
        Write-Host "  # Reconfigure API Key and model"
        Write-Host "  .\install.ps1 -Config"
        Write-Host ""
        Write-Host "Supported Providers:" -ForegroundColor Yellow
        Write-Host "  1. MiniMax       - Free quota, fast response"
        Write-Host "  2. Doubao        - ByteDance, stable"
        Write-Host "  3. Zhipu AI      - Chinese LLM, cost-effective"
        Write-Host "  4. Wanjie Data   - Claude native models proxy"
        Write-Host ""
    }

    # ============================================================================
    # Execution Policy
    # ============================================================================

    function Set-SafeExecutionPolicy {
        $policy = Get-ExecutionPolicy -Scope CurrentUser
        if ($policy -eq 'Restricted' -or $policy -eq 'AllSigned' -or $policy -eq 'Undefined') {
            Write-Info "Configuring PowerShell execution policy..."
            try {
                Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
                Write-Success "Execution policy set to RemoteSigned"
            }
            catch {
                Write-Warn "Could not set execution policy: $_"
            }
        }
    }

    # ============================================================================
    # Console Encoding
    # ============================================================================

    function Set-ConsoleEncoding {
        try {
            $null = cmd /c chcp 65001 2>$null
            [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
            [Console]::InputEncoding = [System.Text.Encoding]::UTF8
        }
        catch { }
    }

    # ============================================================================
    # Network Detection
    # ============================================================================

    function Test-MirrorNeed {
        $useMirror = $env:USE_MIRROR
        if ($useMirror -eq "true") {
            $script:MirrorMode = $true
            Write-Info "Forced mirror mode"
            return
        }
        elseif ($useMirror -eq "false") {
            $script:MirrorMode = $false
            Write-Info "Forced direct mode"
            return
        }
        Write-Info "Detecting network environment..."
        try {
            $null = Invoke-WebRequest -Uri "https://github.com" -TimeoutSec 3 -UseBasicParsing
            $script:MirrorMode = $false
            Write-Success "GitHub is accessible"
        }
        catch {
            $script:MirrorMode = $true
            Write-Warn "GitHub is slow, will use mirror"
        }
    }

    function Find-WorkingMirror {
        foreach ($mirror in $script:GitHubMirrors) {
            try {
                $null = Invoke-WebRequest -Uri $mirror -TimeoutSec 5 -UseBasicParsing
                $script:ActiveMirror = $mirror
                Write-Success "Using mirror: $mirror"
                return $true
            }
            catch { continue }
        }
        Write-Warn "All mirrors unavailable, trying direct connection"
        return $false
    }

    # ============================================================================
    # Node.js Detection and Installation
    # ============================================================================

    function Test-NodeJS {
        try {
            $nodeVersion = & node --version 2>$null
            if ($nodeVersion) {
                $major = [int]($nodeVersion -replace '^v(\d+)\..*', '$1')
                if ($major -ge 18) {
                    Write-Success "Node.js installed: $nodeVersion"
                    return $true
                }
                else {
                    Write-Warn "Node.js version too old: $nodeVersion (need v18+)"
                    return $false
                }
            }
        }
        catch { }
        return $false
    }

    function Test-Winget {
        try {
            $null = & winget --version 2>$null
            return $true
        }
        catch { return $false }
    }

    function Test-Fnm {
        try {
            $fnmVersion = & fnm --version 2>$null
            if ($fnmVersion) {
                Write-Success "fnm installed: $fnmVersion"
                return $true
            }
        }
        catch { }
        # Check common installation paths
        $fnmPaths = @(
            "$env:USERPROFILE\.fnm\fnm.exe"
            "$env:LOCALAPPDATA\fnm\fnm.exe"
            "$env:ProgramFiles\fnm\fnm.exe"
        )
        foreach ($fnmPath in $fnmPaths) {
            if (Test-Path $fnmPath) {
                $parentDir = Split-Path $fnmPath -Parent
                if ($env:Path -notlike "*$parentDir*") {
                    $env:Path = "$env:Path;$parentDir"
                }
                Write-Success "fnm found: $fnmPath"
                return $true
            }
        }
        return $false
    }

    function Get-FnmDownloadUrl {
        $baseUrl = "https://github.com/Schniz/fnm/releases/latest/download/fnm-windows.zip"
        if ($script:MirrorMode -and $script:ActiveMirror) {
            return "$($script:ActiveMirror)/$baseUrl"
        }
        return $baseUrl
    }

    function Install-Fnm {
        Write-Info "Installing fnm (Fast Node Manager)..."
        $fnmDir = "$env:USERPROFILE\.fnm"
        $fnmZip = "$env:TEMP\fnm-windows.zip"
        $downloadUrl = Get-FnmDownloadUrl
        
        try {
            # Create fnm directory
            if (-not (Test-Path $fnmDir)) {
                New-Item -ItemType Directory -Path $fnmDir -Force | Out-Null
            }
            
            # Download fnm
            Write-Info "Downloading fnm from: $downloadUrl"
            try {
                Invoke-WebRequest -Uri $downloadUrl -OutFile $fnmZip -UseBasicParsing -TimeoutSec 60
            }
            catch {
                # Try direct URL if mirror fails
                if ($script:MirrorMode) {
                    Write-Warn "Mirror download failed, trying direct..."
                    $directUrl = "https://github.com/Schniz/fnm/releases/latest/download/fnm-windows.zip"
                    Invoke-WebRequest -Uri $directUrl -OutFile $fnmZip -UseBasicParsing -TimeoutSec 60
                }
                else {
                    throw $_
                }
            }
            
            # Extract fnm
            Write-Info "Extracting fnm..."
            Expand-Archive -Path $fnmZip -DestinationPath $fnmDir -Force
            
            # Add to PATH
            if ($env:Path -notlike "*$fnmDir*") {
                $env:Path = "$env:Path;$fnmDir"
            }
            
            # Update user PATH permanently
            $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
            if ($userPath -notlike "*$fnmDir*") {
                $newPath = "$userPath;$fnmDir"
                [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
            }
            
            # Cleanup
            Remove-Item $fnmZip -Force -ErrorAction SilentlyContinue
            
            Write-Success "fnm installed successfully"
            return $true
        }
        catch {
            Write-Err "fnm installation failed: $_"
            return $false
        }
    }

    function Install-NodeJSViaFnm {
        Write-Info "Installing Node.js LTS via fnm..."
        
        # Set China mirror for Node.js download
        $env:FNM_NODE_DIST_MIRROR = "https://npmmirror.com/mirrors/node"
        Write-Info "Using Node.js mirror: $($env:FNM_NODE_DIST_MIRROR)"
        
        try {
            # Install LTS version
            $installResult = & fnm install --lts 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Err "fnm install failed: $installResult"
                return $false
            }
            Write-Success "Node.js LTS installed"
            
            # Set default version
            & fnm default lts-latest 2>$null
            
            # Use the installed version
            & fnm use lts-latest 2>$null
            
            # Setup fnm environment for current session
            $fnmEnv = & fnm env --shell powershell 2>$null
            if ($fnmEnv) {
                $fnmEnv | ForEach-Object {
                    if ($_ -match '^\$env:(\w+)\s*=\s*"(.+)"') {
                        [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
                    }
                }
            }
            
            # Add fnm shims to PATH
            $fnmDir = "$env:USERPROFILE\.fnm"
            $aliasesDir = "$fnmDir\aliases\default"
            if ((Test-Path $aliasesDir) -and ($env:Path -notlike "*$aliasesDir*")) {
                $env:Path = "$aliasesDir;$env:Path"
            }
            
            # Find and add node path
            $nodeVersionDirs = Get-ChildItem -Path "$fnmDir\node-versions" -Directory -ErrorAction SilentlyContinue
            if ($nodeVersionDirs) {
                $latestVersion = $nodeVersionDirs | Sort-Object Name -Descending | Select-Object -First 1
                $nodeBinPath = "$($latestVersion.FullName)\installation"
                if ((Test-Path $nodeBinPath) -and ($env:Path -notlike "*$nodeBinPath*")) {
                    $env:Path = "$nodeBinPath;$env:Path"
                }
            }
            
            return $true
        }
        catch {
            Write-Err "Node.js installation via fnm failed: $_"
            return $false
        }
    }

    function Install-NodeJS {
        Write-Info "Installing Node.js LTS..."
        
        # Method 1: Try winget first
        if (Test-Winget) {
            Write-Info "Using winget to install..."
            try {
                & winget install OpenJS.NodeJS.LTS --silent --accept-package-agreements --accept-source-agreements
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "Node.js installed successfully"
                    Update-PathEnvironment
                    return $true
                }
            }
            catch {
                Write-Warn "winget installation failed: $_"
            }
        }
        else {
            Write-Warn "winget not available"
        }
        
        # Method 2: Try fnm as fallback
        Write-Info "Trying fnm (Fast Node Manager) as fallback..."
        
        # Check if fnm is already installed
        if (-not (Test-Fnm)) {
            # Install fnm first
            if (-not (Install-Fnm)) {
                Write-Err "fnm installation failed"
                Show-ManualInstallInstructions
                return $false
            }
        }
        
        # Use fnm to install Node.js
        if (Install-NodeJSViaFnm) {
            return $true
        }
        
        # All methods failed
        Show-ManualInstallInstructions
        return $false
    }

    function Show-ManualInstallInstructions {
        Write-Host ""
        Write-Err "Cannot install Node.js automatically"
        Write-Host ""
        Write-Host "Please install Node.js manually:" -ForegroundColor Yellow
        Write-Host "  1. Visit https://nodejs.org" -ForegroundColor White
        Write-Host "  2. Download LTS version (v20 or v22)" -ForegroundColor White
        Write-Host "  3. Run the installer" -ForegroundColor White
        Write-Host "  4. Reopen terminal and run this script again" -ForegroundColor White
        Write-Host ""
    }

    function Update-PathEnvironment {
        $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
        $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
        $env:Path = "$machinePath;$userPath"
        $nodePaths = @(
            "$env:ProgramFiles\nodejs"
            "${env:ProgramFiles(x86)}\nodejs"
            "$env:LOCALAPPDATA\Programs\nodejs"
        )
        foreach ($nodePath in $nodePaths) {
            if ((Test-Path $nodePath) -and ($env:Path -notlike "*$nodePath*")) {
                $env:Path = "$env:Path;$nodePath"
            }
        }
    }

    # ============================================================================
    # npm Configuration
    # ============================================================================

    function Set-NpmRegistry {
        Write-Info "Configuring npm registry (China mirror)..."
        try {
            & npm config set registry $script:NpmRegistry 2>$null
            Write-Success "npm registry configured: $script:NpmRegistry"
            return $true
        }
        catch {
            Write-Warn "npm registry configuration failed: $_"
            return $false
        }
    }

    # ============================================================================
    # Claude Code Installation
    # ============================================================================

    function Test-ClaudeCode {
        try {
            $version = & claude --version 2>$null
            if ($version) {
                Write-Success "Claude Code installed: $version"
                return $true
            }
        }
        catch { }
        return $false
    }

    function Install-ClaudeCodePackage {
        Write-Info "Installing Claude Code..."
        Write-Info "This may take a few minutes, please wait..."
        try {
            $process = Start-Process -FilePath "npm" -ArgumentList "install", "-g", $script:ClaudePackage -NoNewWindow -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Update-PathEnvironment
                $npmGlobalDir = & npm config get prefix 2>$null
                if ($npmGlobalDir -and (Test-Path $npmGlobalDir)) {
                    if ($env:Path -notlike "*$npmGlobalDir*") {
                        $env:Path = "$env:Path;$npmGlobalDir"
                    }
                }
                Write-Success "Claude Code installed successfully"
                return $true
            }
            else {
                Write-Err "npm install failed, exit code: $($process.ExitCode)"
                return $false
            }
        }
        catch {
            Write-Err "Installation failed: $_"
            return $false
        }
    }

    # ============================================================================
    # Configuration Wizard
    # ============================================================================

    function Select-Provider {
        Write-Host ""
        Write-Host "Select API Provider:" -ForegroundColor Yellow
        Write-Host ""
        for ($i = 0; $i -lt $script:Providers.Count; $i++) {
            $provider = $script:Providers[$i]
            $num = $i + 1
            $tag = if ($provider.Tag) { " $($provider.Tag)" } else { "" }
            Write-Host "  $num. " -ForegroundColor Cyan -NoNewline
            Write-Host "$($provider.Name)" -ForegroundColor White -NoNewline
            Write-Host "$tag " -ForegroundColor Green -NoNewline
            Write-Host "- $($provider.Description)" -ForegroundColor DarkGray
        }
        Write-Host ""
        $choice = Read-Host "Enter number [1-$($script:Providers.Count)], default 1"
        if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "1" }
        $index = 0
        if (-not [int]::TryParse($choice, [ref]$index) -or $index -lt 1 -or $index -gt $script:Providers.Count) {
            Write-Warn "Invalid choice, using default provider"
            $index = 1
        }
        $selected = $script:Providers[$index - 1]
        Write-Success "Selected: $($selected.Name)"
        return $selected
    }

    function Read-ApiKey {
        param($Provider)
        Write-Host ""
        Write-Host "Enter your API Key:" -ForegroundColor Yellow
        Write-Host "(Get from $($Provider.Name): $($Provider.ApiKeyUrl))" -ForegroundColor DarkGray
        Write-Host ""
        $existingKey = ""
        if (Test-Path $script:SettingsFile) {
            try {
                $settings = Get-Content $script:SettingsFile -Raw | ConvertFrom-Json
                $existingKey = $settings.env.ANTHROPIC_AUTH_TOKEN
                if ($existingKey) {
                    $masked = $existingKey.Substring(0, [Math]::Min(8, $existingKey.Length)) + "..."
                    Write-Host "Current Key: $masked" -ForegroundColor DarkGray
                }
            }
            catch { }
        }
        $key = Read-Host "API Key"
        if ([string]::IsNullOrWhiteSpace($key) -and $existingKey) {
            Write-Info "Keeping existing API Key"
            return $existingKey
        }
        if ([string]::IsNullOrWhiteSpace($key)) {
            Write-Err "API Key cannot be empty"
            return Read-ApiKey -Provider $Provider
        }
        return $key.Trim()
    }

    function Select-Model {
        param($Provider)
        Write-Host ""
        Write-Host "Select default model:" -ForegroundColor Yellow
        Write-Host ""
        $models = $Provider.Models
        for ($i = 0; $i -lt $models.Count; $i++) {
            $model = $models[$i]
            $num = $i + 1
            $tag = if ($model.Tag) { " $($model.Tag)" } else { "" }
            Write-Host "  $num. " -ForegroundColor Cyan -NoNewline
            Write-Host "$($model.Name)" -ForegroundColor White -NoNewline
            Write-Host "$tag " -ForegroundColor Green -NoNewline
            Write-Host "- $($model.Description)" -ForegroundColor DarkGray
        }
        if ($Provider.CustomModel) {
            $customNum = $models.Count + 1
            Write-Host "  $customNum. " -ForegroundColor Cyan -NoNewline
            Write-Host "[Custom Input]" -ForegroundColor Yellow -NoNewline
            Write-Host " - Enter custom model ID" -ForegroundColor DarkGray
        }
        Write-Host ""
        $maxChoice = if ($Provider.CustomModel) { $models.Count + 1 } else { $models.Count }
        $choice = Read-Host "Enter number [1-$maxChoice], default 1"
        if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "1" }
        $index = 0
        if (-not [int]::TryParse($choice, [ref]$index) -or $index -lt 1 -or $index -gt $maxChoice) {
            Write-Warn "Invalid choice, using default model"
            $index = 1
        }
        if ($Provider.CustomModel -and $index -eq $maxChoice) {
            Write-Host ""
            $customModelId = Read-Host "Enter model ID (default: $($models[0].ID))"
            if ([string]::IsNullOrWhiteSpace($customModelId)) { $customModelId = $models[0].ID }
            $selectedModel = @{ ID = $customModelId.Trim(); Name = $customModelId.Trim(); Tag = ""; Description = "Custom model" }
            Write-Success "Selected custom model: $($selectedModel.ID)"
            return $selectedModel
        }
        $selected = $models[$index - 1]
        Write-Success "Selected: $($selected.Name)"
        return $selected
    }

    function Get-ModelMappings {
        param($Provider, $SelectedModel)
        switch ($Provider.ID) {
            "minimax" { return @{ Haiku = ""; Sonnet = ""; Opus = "" } }
            "doubao" { return @{ Haiku = $SelectedModel.ID; Sonnet = $SelectedModel.ID; Opus = $SelectedModel.ID } }
            "zhipu" { return @{ Haiku = "GLM-4.5-Air"; Sonnet = "GLM-4.7"; Opus = "GLM-4.7" } }
            "wanjie" {
                $haikuModel = "claude-haiku-4-5-20251001"
                $sonnetModel = "claude-sonnet-4-20250514"
                $opusModel = "claude-opus-4-1-20250805"
                if ($SelectedModel.Family -eq "sonnet" -and $SelectedModel.ID -like "*4-5*") { $sonnetModel = "claude-sonnet-4-5-20250929" }
                elseif ($SelectedModel.Family -eq "opus" -and $SelectedModel.ID -like "*4-5*") { $opusModel = "claude-opus-4-5-20251101" }
                return @{ Haiku = $haikuModel; Sonnet = $sonnetModel; Opus = $opusModel }
            }
            default { return @{ Haiku = ""; Sonnet = ""; Opus = "" } }
        }
    }

    function Write-SettingsFile {
        param([string]$ApiKey, $Provider, $Model)
        $mappings = Get-ModelMappings -Provider $Provider -SelectedModel $Model
        $settings = @{
            enabledPlugins = @{
                "commit-commands@claude-plugins-official"  = $true
                "context7@claude-plugins-official"         = $true
                "frontend-design@claude-plugins-official"  = $true
                "github@claude-plugins-official"           = $true
                "planning-with-files@planning-with-files"  = $true
                "superpowers@superpowers-marketplace"      = $true
            }
            env            = @{
                ANTHROPIC_AUTH_TOKEN                     = $ApiKey
                ANTHROPIC_BASE_URL                       = $Provider.BaseUrl
                ANTHROPIC_DEFAULT_HAIKU_MODEL            = $mappings.Haiku
                ANTHROPIC_DEFAULT_OPUS_MODEL             = $mappings.Opus
                ANTHROPIC_DEFAULT_SONNET_MODEL           = $mappings.Sonnet
                ANTHROPIC_MODEL                          = $Model.ID
                API_TIMEOUT_MS                           = "3000000"
                CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = 1
            }
        }
        if (-not (Test-Path $script:ClaudeDir)) {
            New-Item -ItemType Directory -Path $script:ClaudeDir -Force | Out-Null
        }
        $json = $settings | ConvertTo-Json -Depth 10
        Set-Content -Path $script:SettingsFile -Value $json -Encoding UTF8
        Write-Success "Configuration saved: $script:SettingsFile"
    }

    # ============================================================================
    # PATH Configuration
    # ============================================================================

    function Add-NpmToPath {
        try {
            $npmPrefix = & npm config get prefix 2>$null
            if (-not $npmPrefix) { return }
            $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
            if ($currentPath -notlike "*$npmPrefix*") {
                Write-Info "Adding npm global directory to PATH..."
                $newPath = "$currentPath;$npmPrefix"
                [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
                $env:Path = "$env:Path;$npmPrefix"
                Write-Success "PATH updated"
            }
        }
        catch {
            Write-Warn "Could not update PATH: $_"
        }
    }

    # ============================================================================
    # Completion
    # ============================================================================

    function Show-Completion {
        param($Provider)
        Write-Host ""
        Write-Host "+----------------------------------------------+" -ForegroundColor Green
        Write-Host "|  " -ForegroundColor Green -NoNewline
        Write-Host "Installation Complete!" -ForegroundColor White -NoNewline
        Write-Host "                      |" -ForegroundColor Green
        Write-Host "+----------------------------------------------+" -ForegroundColor Green
        Write-Host ""
        Write-Host "Provider: " -ForegroundColor Yellow -NoNewline
        Write-Host "$($Provider.Name)" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Getting Started:" -ForegroundColor Yellow
        Write-Host "  1. Open a new terminal window" -ForegroundColor White
        Write-Host "  2. Navigate to any project directory" -ForegroundColor White
        Write-Host "  3. Run " -ForegroundColor White -NoNewline
        Write-Host "claude" -ForegroundColor Cyan -NoNewline
        Write-Host " to start" -ForegroundColor White
        Write-Host ""
        Write-Host "Common Commands:" -ForegroundColor Yellow
        Write-Host "  claude              Start interactive mode" -ForegroundColor DarkGray
        Write-Host "  claude --help       Show help" -ForegroundColor DarkGray
        Write-Host "  claude --version    Show version" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "Reconfigure:" -ForegroundColor Yellow
        Write-Host "  .\install.ps1 -Config" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "Config file:" -ForegroundColor Yellow
        Write-Host "  $script:SettingsFile" -ForegroundColor DarkGray
        Write-Host ""
    }

    # ============================================================================
    # Config Only Mode
    # ============================================================================

    function Invoke-ConfigOnly {
        Show-Banner
        Write-Info "Configuration mode"
        Write-Host ""
        if (-not (Test-ClaudeCode)) {
            Write-Err "Claude Code is not installed"
            Write-Host "Please run full installation first: irm <url> | iex" -ForegroundColor Yellow
            return
        }
        Write-Step -Step 1 -Total 3 -Message "Select Provider"
        $provider = Select-Provider
        Write-Step -Step 2 -Total 3 -Message "Enter API Key"
        $apiKey = Read-ApiKey -Provider $provider
        Write-Step -Step 3 -Total 3 -Message "Select Model"
        $model = Select-Model -Provider $provider
        Write-SettingsFile -ApiKey $apiKey -Provider $provider -Model $model
        Write-Host ""
        Write-Success "Configuration complete!"
        Write-Host ""
    }

    # ============================================================================
    # Full Installation
    # ============================================================================

    function Invoke-FullInstall {
        Show-Banner
        $totalSteps = 6
        $currentStep = 0

        $currentStep++
        Write-Step -Step $currentStep -Total $totalSteps -Message "Detecting network environment"
        Test-MirrorNeed
        if ($script:MirrorMode) { Find-WorkingMirror | Out-Null }

        $currentStep++
        Write-Step -Step $currentStep -Total $totalSteps -Message "Checking Node.js"
        if (-not (Test-NodeJS)) {
            if (-not (Install-NodeJS)) { return }
            Start-Sleep -Seconds 2
            Update-PathEnvironment
            if (-not (Test-NodeJS)) {
                Write-Err "Node.js still not detected after installation"
                Write-Host "Please reopen terminal and run this script again" -ForegroundColor Yellow
                return
            }
        }
        Set-NpmRegistry

        $currentStep++
        Write-Step -Step $currentStep -Total $totalSteps -Message "Installing Claude Code"
        if (-not (Test-ClaudeCode)) {
            if (-not (Install-ClaudeCodePackage)) {
                Write-Err "Claude Code installation failed"
                return
            }
        }
        else {
            Write-Info "Skipping installation (already installed)"
        }

        $currentStep++
        Write-Step -Step $currentStep -Total $totalSteps -Message "Select Provider"
        $provider = Select-Provider

        $currentStep++
        Write-Step -Step $currentStep -Total $totalSteps -Message "Configure API Key"
        $apiKey = Read-ApiKey -Provider $provider

        $currentStep++
        Write-Step -Step $currentStep -Total $totalSteps -Message "Select Model"
        $model = Select-Model -Provider $provider

        Write-Info "Saving configuration..."
        Write-SettingsFile -ApiKey $apiKey -Provider $provider -Model $model
        Add-NpmToPath
        Show-Completion -Provider $provider
    }

    # ============================================================================
    # Main Entry
    # ============================================================================

    Set-SafeExecutionPolicy
    Set-ConsoleEncoding

    if ($Help) {
        Show-Help
        return
    }

    if ($Config) {
        Invoke-ConfigOnly
        return
    }

    Invoke-FullInstall
}
