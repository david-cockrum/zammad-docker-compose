#!/bin/bash

# Docker Hub Setup Helper Script
# This script helps you log into Docker Hub and push the secure image

set -e

echo "🐳 Docker Hub Setup for Zammad Secure Image"
echo "==========================================="
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker Desktop first."
    exit 1
fi

echo "📝 Docker Hub Login Instructions:"
echo ""
echo "1. If you don't have a Docker Hub account:"
echo "   Visit: https://hub.docker.com/signup"
echo ""
echo "2. Create an access token (recommended over password):"
echo "   - Go to: https://hub.docker.com/settings/security"
echo "   - Click 'New Access Token'"
echo "   - Description: 'Zammad Secure Deployment'"
echo "   - Access permissions: 'Read, Write, Delete'"
echo "   - Copy the generated token"
echo ""

# Check current login status
echo "🔍 Checking Docker Hub login status..."
if docker info 2>/dev/null | grep -q "Username"; then
    CURRENT_USER=$(docker info 2>/dev/null | grep "Username" | awk '{print $2}')
    echo "✅ Already logged in as: $CURRENT_USER"
    echo ""
    read -p "Do you want to continue with this account? (y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        docker logout
        echo "Logged out. Please log in with your desired account."
    else
        DOCKER_USERNAME=$CURRENT_USER
    fi
else
    echo "📝 Not logged in to Docker Hub"
fi

# Login if needed
if [ -z "$DOCKER_USERNAME" ]; then
    echo ""
    echo "🔑 Docker Hub Login"
    echo "-------------------"
    read -p "Enter your Docker Hub username: " DOCKER_USERNAME
    
    echo ""
    echo "Enter your Docker Hub password or access token:"
    echo "(Token is recommended for security)"
    docker login -u "$DOCKER_USERNAME"
    
    if [ $? -ne 0 ]; then
        echo "❌ Login failed. Please check your credentials."
        exit 1
    fi
fi

echo ""
echo "✅ Docker Hub login successful!"
echo ""

# Ask if user wants to push the image
echo "📦 Ready to push security-patched image"
echo "----------------------------------------"
echo "Image to push: vantagepointconsult/zammad:6.5.1-secure"
echo ""
read -p "Do you want to push this image to Docker Hub now? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "🚀 Pushing image to Docker Hub..."
    echo "This may take a few minutes depending on your internet connection..."
    
    # Tag the image for the user's Docker Hub account
    docker tag vantagepointconsult/zammad:6.5.1-secure "$DOCKER_USERNAME/zammad:6.5.1-secure"
    docker tag vantagepointconsult/zammad:6.5.1-secure "$DOCKER_USERNAME/zammad:latest-secure"
    
    # Push both tags
    docker push "$DOCKER_USERNAME/zammad:6.5.1-secure"
    docker push "$DOCKER_USERNAME/zammad:latest-secure"
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ Image successfully pushed to Docker Hub!"
        echo ""
        echo "📍 Your images are now available at:"
        echo "   - docker.io/$DOCKER_USERNAME/zammad:6.5.1-secure"
        echo "   - docker.io/$DOCKER_USERNAME/zammad:latest-secure"
        echo ""
        echo "🔗 View on Docker Hub:"
        echo "   https://hub.docker.com/r/$DOCKER_USERNAME/zammad"
    else
        echo "❌ Failed to push image. Please check your connection and permissions."
        exit 1
    fi
else
    echo ""
    echo "⏭️  Skipping image push. You can run this script again later to push."
fi

echo ""
echo "📋 Next Steps:"
echo "-------------"
echo "1. Set up GitHub Secrets for CI/CD:"
echo "   ./setup-github-secrets.sh"
echo ""
echo "2. Update docker-compose.yml to use your image:"
echo "   Replace: ghcr.io/zammad/zammad:6.5.1"
echo "   With: $DOCKER_USERNAME/zammad:6.5.1-secure"
echo ""
echo "3. Deploy with enhanced security:"
echo "   docker compose -f docker-compose.yml -f docker-compose.security.yml up -d"
echo ""
echo "✨ Docker Hub setup complete!"
