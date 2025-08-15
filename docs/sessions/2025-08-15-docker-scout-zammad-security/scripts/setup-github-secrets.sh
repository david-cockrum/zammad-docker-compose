#!/bin/bash

# GitHub Secrets Setup Script for Docker Scout CI/CD
# This script helps you configure the required GitHub secrets

set -e

echo "🔐 GitHub Secrets Setup for Docker Scout CI/CD"
echo "=============================================="
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed."
    echo "Please install it first:"
    echo "  brew install gh"
    echo "Or visit: https://cli.github.com/"
    exit 1
fi

# Check if authenticated with GitHub
if ! gh auth status &> /dev/null; then
    echo "🔑 You need to authenticate with GitHub first."
    echo "Running: gh auth login"
    gh auth login
fi

echo "✅ GitHub CLI is ready"
echo ""

# Get repository information
REPO_OWNER=$(git remote get-url origin | sed -n 's/.*github.com[:/]\([^/]*\).*/\1/p')
REPO_NAME=$(git remote get-url origin | sed -n 's/.*github.com[:/][^/]*\/\([^.]*\).*/\1/p')

if [ -z "$REPO_OWNER" ] || [ -z "$REPO_NAME" ]; then
    echo "❌ Could not determine repository information."
    echo "Please ensure you're in a Git repository with a GitHub remote."
    exit 1
fi

echo "📦 Repository: $REPO_OWNER/$REPO_NAME"
echo ""

# Function to set a secret
set_secret() {
    local secret_name=$1
    local secret_value=$2
    
    echo "Setting secret: $secret_name"
    echo "$secret_value" | gh secret set "$secret_name" --repo "$REPO_OWNER/$REPO_NAME"
    
    if [ $? -eq 0 ]; then
        echo "✅ $secret_name configured successfully"
    else
        echo "❌ Failed to set $secret_name"
        return 1
    fi
}

# Docker Hub Username
echo "📝 Enter your Docker Hub username:"
read -r DOCKER_USERNAME

if [ -z "$DOCKER_USERNAME" ]; then
    echo "❌ Docker Hub username cannot be empty"
    exit 1
fi

# Docker Hub Access Token
echo ""
echo "🔑 Now, let's set up your Docker Hub access token."
echo ""
echo "To create a Docker Hub access token:"
echo "1. Go to: https://hub.docker.com/settings/security"
echo "2. Click 'New Access Token'"
echo "3. Description: 'GitHub Actions for Zammad'"
echo "4. Access permissions: 'Read' (or 'Read & Write' if pushing images)"
echo "5. Click 'Generate'"
echo "6. Copy the token (you won't see it again!)"
echo ""
echo "📝 Enter your Docker Hub access token:"
read -rs DOCKER_PASSWORD

if [ -z "$DOCKER_PASSWORD" ]; then
    echo "❌ Docker Hub access token cannot be empty"
    exit 1
fi

echo ""
echo ""
echo "🚀 Setting up GitHub secrets..."
echo ""

# Set the secrets
set_secret "DOCKER_USERNAME" "$DOCKER_USERNAME"
set_secret "DOCKER_PASSWORD" "$DOCKER_PASSWORD"

echo ""
echo "✨ GitHub secrets configuration complete!"
echo ""
echo "You can verify the secrets at:"
echo "https://github.com/$REPO_OWNER/$REPO_NAME/settings/secrets/actions"
echo ""
echo "The following secrets have been configured:"
echo "  ✅ DOCKER_USERNAME"
echo "  ✅ DOCKER_PASSWORD"
echo ""
echo "🎯 Next steps:"
echo "1. The GitHub Actions workflow is ready to use"
echo "2. Push changes to trigger the workflow"
echo "3. Monitor security scans in the Actions tab"
echo ""
