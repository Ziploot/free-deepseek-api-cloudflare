#!/bin/bash
# ZipLoot Linux/macOS 1-Click Serverless DeepSeek API Setup
echo "=============================================="
echo "⚡ ZipLoot - Linux/macOS Auto-Installer ⚡"
echo "=============================================="

# --- COLLECT ALL INPUTS UPFRONT ---

API_KEY=""
while [ -z "$API_KEY" ]; do
    read -p "[INPUT] Create a custom API Key to secure your API (e.g. 'my-secret-key'): " API_KEY
done

SUBDOMAIN=""
while [ -z "$SUBDOMAIN" ]; do
    read -p "[INPUT] Enter your Cloudflare workers.dev subdomain (e.g. 'ziploot'): " SUBDOMAIN_INPUT
    SUBDOMAIN=$(echo "$SUBDOMAIN_INPUT" | sed 's/\.workers\.dev//g' | xargs)
done

echo -e "
[INFO] All inputs collected! Starting automatic setup, please wait...
"

# 1. Check Node.js
if ! command -v node &> /dev/null; then
    echo "⚠️ Node.js not detected. Attempting to install Node.js..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y nodejs npm
    elif command -v brew &> /dev/null; then
        brew install node
    elif command -v yum &> /dev/null; then
        sudo yum install -y nodejs npm
    else
        echo "❌ Unsupported package manager. Please install Node.js manually."
        exit 1
    fi
    echo "✅ Node.js successfully installed!"
else
    echo "✅ Node.js is already installed."
fi

# Create project folder locally
PROJECT_DIR="$(pwd)/free-deepseek-api-project"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Download files from repository
echo "📥 Fetching files..."
curl -sL "https://raw.githubusercontent.com/Ziploot/free-deepseek-api-cloudflare/main/index.js" -o index.js
curl -sL "https://raw.githubusercontent.com/Ziploot/free-deepseek-api-cloudflare/main/wrangler.json" -o wrangler.json
curl -sL "https://raw.githubusercontent.com/Ziploot/free-deepseek-api-cloudflare/main/package.json" -o package.json

echo "📦 Installing dependencies locally..."
npm install

echo "🔑 Logging in to Cloudflare..."
npx wrangler login

echo "🔒 Saving API Key securely in Cloudflare..."
echo "$API_KEY" | npx wrangler secret put API_KEY

echo "🚀 Deploying worker to Cloudflare..."
npx wrangler deploy

API_URL="https://free-deepseek-api.${SUBDOMAIN}.workers.dev"
echo -e "
🎉 Congratulations! Your Private DeepSeek API is live!"
echo "--------------------------------------------------------"
echo "🔗 API Endpoint (Base URL): $API_URL"
echo "🔑 API Key: $API_KEY"
echo "🤖 Model Name: @cf/deepseek-ai/deepseek-r1-distill-qwen-32b"
echo "--------------------------------------------------------"
