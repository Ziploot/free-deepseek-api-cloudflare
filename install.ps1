# ZipLoot Windows 1-Click Serverless DeepSeek API Setup
try {
    Write-Host "==============================================" -ForegroundColor Green
    Write-Host "[ZipLoot] DeepSeek API Installer" -ForegroundColor Green
    Write-Host "==============================================" -ForegroundColor Green

    $ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

    # --- COLLECT ALL INPUTS UPFRONT ---
    
    $apiKey = ""
    while ([string]::IsNullOrWhiteSpace($apiKey)) {
        $apiKey = Read-Host "[INPUT] Create a custom API Key to secure your API (e.g. 'my-secret-key')"
    }

    $subdomain = ""
    while ([string]::IsNullOrWhiteSpace($subdomain)) {
        $subdomainInput = Read-Host "[INPUT] Enter your Cloudflare workers.dev subdomain (e.g. 'ziploot')"
        if (-not [string]::IsNullOrWhiteSpace($subdomainInput)) {
            $subdomain = $subdomainInput.Replace(".workers.dev", "").Trim()
        }
    }

    Write-Host "`n[INFO] All inputs collected! Starting automatic setup, please wait...`n" -ForegroundColor Green

    # 1. Check Node.js
    $nodeInstalled = Get-Command node -ErrorAction SilentlyContinue
    if (-not $nodeInstalled) {
        Write-Host "[WARN] Node.js not detected. Installing Node.js silently via winget..." -ForegroundColor Yellow
        winget install OpenJS.NodeJS --silent --accept-package-agreements --accept-source-agreements
        
        # Update PATH env in current session so npx works immediately
        $env:Path += ";$env:ProgramFiles\\nodejs"
        
        # Verify installation
        $nodeVerify = Get-Command node -ErrorAction SilentlyContinue
        if (-not $nodeVerify) {
            Write-Host "[ERROR] Silent Node.js installation failed. Please install Node.js manually." -ForegroundColor Red
            Read-Host "Press Enter to exit..."
            Exit
        }
        Write-Host "[SUCCESS] Node.js successfully installed!" -ForegroundColor Green
    } else {
        Write-Host "[SUCCESS] Node.js is already installed." -ForegroundColor Green
    }

    # Create project folder locally in the user's CURRENT directory
    $projectFolder = Join-Path $pwd "free-deepseek-api-project"
    if (Test-Path $projectFolder) {
        Write-Host "[WARN] Folder 'free-deepseek-api-project' already exists." -ForegroundColor Yellow
    } else {
        New-Item -ItemType Directory -Path $projectFolder -ErrorAction SilentlyContinue | Out-Null
    }

    # Copy files already packaged in the ZIP
    Copy-Item -Path "$scriptDir\\index.js" -Destination "$projectFolder\\index.js" -Force
    Copy-Item -Path "$scriptDir\\wrangler.json" -Destination "$projectFolder\\wrangler.json" -Force
    Copy-Item -Path "$scriptDir\\package.json" -Destination "$projectFolder\\package.json" -Force

    Set-Location $projectFolder

    Write-Host "[INSTALL] Installing dependencies locally..." -ForegroundColor Cyan
    cmd.exe /c "npm install"

    Write-Host "[LOGIN] Logging in to Cloudflare..." -ForegroundColor Cyan
    cmd.exe /c "npx wrangler login"

    Write-Host "[SECURE] Saving API Key securely in Cloudflare..." -ForegroundColor Cyan
    cmd.exe /c "echo $apiKey | npx wrangler secret put API_KEY"

    Write-Host "[DEPLOY] Deploying worker to Cloudflare..." -ForegroundColor Cyan
    cmd.exe /c "npx wrangler deploy"

    $apiUrl = "https://free-deepseek-api.$subdomain.workers.dev"
    Write-Host "`n[SUCCESS] Congratulations! Your Private DeepSeek API is live!" -ForegroundColor Green
    Write-Host "--------------------------------------------------------" -ForegroundColor Green
    Write-Host "🔗 API Endpoint (Base URL): $apiUrl" -ForegroundColor Cyan
    Write-Host "🔑 API Key: $apiKey" -ForegroundColor Cyan
    Write-Host "🤖 Model Name: @cf/deepseek-ai/deepseek-r1-distill-qwen-32b" -ForegroundColor Cyan
    Write-Host "--------------------------------------------------------" -ForegroundColor Green
    Write-Host "`n📁 Project Folder created at: $projectFolder" -ForegroundColor Yellow
    Write-Host "You can integrate this endpoint directly in Cursor or VS Code (via Continue.dev extension)." -ForegroundColor Yellow
    Read-Host "`nSetup completed. Press Enter to exit..."
} catch {
    Write-Host "[ERROR] An unexpected error occurred: $_" -ForegroundColor Red
    Read-Host "Press Enter to exit..."
}
