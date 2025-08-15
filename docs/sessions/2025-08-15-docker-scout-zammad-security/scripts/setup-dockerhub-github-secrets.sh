#!/bin/bash

# Automated Docker Hub Credentials Setup for GitHub Secrets
# This script sets up Docker Hub credentials in GitHub Secrets for full CI/CD functionality

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}     Docker Hub → GitHub Secrets Configuration Tool${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}📋 Checking prerequisites...${NC}"

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI (gh) is not installed.${NC}"
    echo "Please install it first:"
    echo "  brew install gh"
    exit 1
fi

# Check if authenticated with GitHub
if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}🔑 Authenticating with GitHub...${NC}"
    gh auth login
fi

echo -e "${GREEN}✅ GitHub CLI is ready${NC}"

# Get repository information
REPO_OWNER=$(git remote get-url origin | sed -n 's/.*github.com[:/]\([^/]*\).*/\1/p')
REPO_NAME=$(git remote get-url origin | sed -n 's/.*github.com[:/][^/]*\/\([^.]*\).*/\1/p')

echo -e "${GREEN}✅ Repository: ${REPO_OWNER}/${REPO_NAME}${NC}"
echo ""

# Docker Hub Account Setup
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                 Docker Hub Account Setup${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}📝 Docker Hub Account Information${NC}"
echo ""
echo "If you don't have a Docker Hub account yet:"
echo "  1. Visit: https://hub.docker.com/signup"
echo "  2. Create a free account"
echo "  3. Verify your email"
echo ""

read -p "Do you have a Docker Hub account? (y/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Please create a Docker Hub account first, then run this script again.${NC}"
    echo "Visit: https://hub.docker.com/signup"
    exit 0
fi

# Get Docker Hub username
echo ""
echo -e "${YELLOW}Enter your Docker Hub username:${NC}"
read -r DOCKER_USERNAME

if [ -z "$DOCKER_USERNAME" ]; then
    echo -e "${RED}❌ Username cannot be empty${NC}"
    exit 1
fi

# Docker Hub Token Creation
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}              Docker Hub Access Token Creation${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}🔐 Creating Docker Hub Access Token${NC}"
echo ""
echo "Please follow these steps to create an access token:"
echo ""
echo -e "${GREEN}1. Click this link to open Docker Hub Security Settings:${NC}"
echo "   https://hub.docker.com/settings/security"
echo ""
echo -e "${GREEN}2. Click 'New Access Token'${NC}"
echo ""
echo -e "${GREEN}3. Use these settings:${NC}"
echo "   • Description: GitHub Actions - ${REPO_NAME}"
echo "   • Access permissions: Read, Write, Delete"
echo ""
echo -e "${GREEN}4. Click 'Generate'${NC}"
echo ""
echo -e "${GREEN}5. IMPORTANT: Copy the token immediately (you won't see it again!)${NC}"
echo ""

read -p "Press Enter when you're ready to continue..."

# Get Docker Hub token
echo ""
echo -e "${YELLOW}Paste your Docker Hub access token:${NC}"
echo "(It will be hidden for security)"
read -rs DOCKER_PASSWORD

if [ -z "$DOCKER_PASSWORD" ]; then
    echo -e "${RED}❌ Token cannot be empty${NC}"
    exit 1
fi

echo ""
echo ""

# Validate Docker Hub credentials
echo -e "${YELLOW}🔍 Validating Docker Hub credentials...${NC}"

# Test login
echo "$DOCKER_PASSWORD" | docker login --username "$DOCKER_USERNAME" --password-stdin &> /dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Docker Hub credentials are valid${NC}"
    docker logout &> /dev/null
else
    echo -e "${RED}❌ Invalid Docker Hub credentials. Please check and try again.${NC}"
    exit 1
fi

# Add secrets to GitHub
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                Setting up GitHub Secrets${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}🚀 Adding secrets to GitHub repository...${NC}"

# Function to set a secret
set_secret() {
    local secret_name=$1
    local secret_value=$2
    
    echo -e "${YELLOW}Setting ${secret_name}...${NC}"
    echo "$secret_value" | gh secret set "$secret_name" --repo "$REPO_OWNER/$REPO_NAME" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ ${secret_name} configured successfully${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed to set ${secret_name}${NC}"
        return 1
    fi
}

# Set the secrets
SUCCESS=true
set_secret "DOCKER_USERNAME" "$DOCKER_USERNAME" || SUCCESS=false
set_secret "DOCKER_PASSWORD" "$DOCKER_PASSWORD" || SUCCESS=false

if [ "$SUCCESS" = false ]; then
    echo -e "${RED}❌ Some secrets failed to set. Please try again.${NC}"
    exit 1
fi

# Clear sensitive variables
unset DOCKER_PASSWORD

echo ""
echo -e "${GREEN}✨ GitHub Secrets configured successfully!${NC}"
echo ""

# Trigger workflow to test
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                  Testing CI/CD Pipeline${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

read -p "Would you like to trigger the CI/CD workflow now to test? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}🔄 Triggering Docker Scout Security Analysis workflow...${NC}"
    
    gh workflow run "Docker Scout Security Analysis" --repo "$REPO_OWNER/$REPO_NAME" --ref master
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Workflow triggered successfully${NC}"
        echo ""
        echo "View the workflow run at:"
        echo "https://github.com/$REPO_OWNER/$REPO_NAME/actions"
        
        # Wait a moment for the workflow to start
        sleep 3
        
        # Show the latest run
        echo ""
        echo -e "${YELLOW}Latest workflow run:${NC}"
        gh run list --workflow="docker-scout.yaml" --repo "$REPO_OWNER/$REPO_NAME" --limit 1
    else
        echo -e "${YELLOW}⚠️  Could not trigger workflow automatically${NC}"
        echo "You can trigger it manually at:"
        echo "https://github.com/$REPO_OWNER/$REPO_NAME/actions"
    fi
fi

# Summary
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                    Setup Complete! 🎉${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${GREEN}✅ What's been configured:${NC}"
echo "  • Docker Hub username: $DOCKER_USERNAME"
echo "  • GitHub Secrets: DOCKER_USERNAME, DOCKER_PASSWORD"
echo "  • Repository: $REPO_OWNER/$REPO_NAME"
echo ""

echo -e "${GREEN}📊 Your CI/CD pipeline can now:${NC}"
echo "  • Generate SBOM (Software Bill of Materials)"
echo "  • Push images to Docker Hub automatically"
echo "  • Run full security scans with Docker Scout"
echo "  • Create security reports and attestations"
echo ""

echo -e "${GREEN}🔗 Useful links:${NC}"
echo "  • GitHub Actions: https://github.com/$REPO_OWNER/$REPO_NAME/actions"
echo "  • Docker Hub: https://hub.docker.com/r/$DOCKER_USERNAME"
echo "  • Secrets Settings: https://github.com/$REPO_OWNER/$REPO_NAME/settings/secrets/actions"
echo ""

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}           Full CI/CD functionality is now enabled!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
