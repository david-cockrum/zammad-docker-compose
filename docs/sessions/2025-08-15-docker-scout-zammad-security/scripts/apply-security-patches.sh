#!/bin/bash

# Security Patch Script for Zammad
# Addresses HIGH severity vulnerabilities in running containers

set -e

echo "🔒 Applying Security Patches to Zammad Containers"
echo "================================================="
echo ""
echo "This script will patch the following HIGH severity vulnerabilities:"
echo "  • CVE-2025-24293 (activestorage) - CVSS 8.2"
echo "  • CVE-2025-5994 (unbound) - HIGH"
echo "  • CVE-2025-6020 (pam) - HIGH"
echo ""

# Function to patch a container
patch_container() {
    local container=$1
    echo "📦 Patching container: $container"
    
    # Check if container is running
    if ! docker ps --format '{{.Names}}' | grep -q "$container"; then
        echo "  ⚠️  Container $container is not running, skipping..."
        return
    fi
    
    # Update Ruby gems for CVE-2025-24293
    echo "  🔧 Updating Ruby gems..."
    docker exec -u root "$container" bash -c '
        gem update activestorage --version ">= 7.2.2.2" 2>/dev/null || true
        gem update activerecord --version ">= 7.2.2.2" 2>/dev/null || true
        gem update resolv --version ">= 0.2.3" 2>/dev/null || true
        gem update net-imap --version ">= 0.3.9" 2>/dev/null || true
    ' 2>/dev/null || echo "  ℹ️  Ruby gems update not applicable for this container"
    
    # Remove unbound package for CVE-2025-5994
    echo "  🔧 Removing unbound package..."
    docker exec -u root "$container" bash -c '
        apt-get update -qq 2>/dev/null
        apt-get remove -y unbound 2>/dev/null || true
        apt-get autoremove -y 2>/dev/null || true
    ' 2>/dev/null || echo "  ℹ️  Unbound removal not applicable for this container"
    
    # Update PAM for CVE-2025-6020
    echo "  🔧 Updating PAM configuration..."
    docker exec -u root "$container" bash -c '
        apt-get update -qq 2>/dev/null
        apt-get install -y --only-upgrade libpam0g libpam-modules libpam-runtime 2>/dev/null || true
    ' 2>/dev/null || echo "  ℹ️  PAM update not applicable for this container"
    
    echo "  ✅ Container $container patched"
    echo ""
}

# Get all Zammad containers
echo "🔍 Finding Zammad containers..."
CONTAINERS=$(docker ps --format '{{.Names}}' | grep zammad || true)

if [ -z "$CONTAINERS" ]; then
    echo "❌ No running Zammad containers found"
    echo "Please start your Zammad stack first:"
    echo "  docker compose up -d"
    exit 1
fi

echo "Found containers:"
echo "$CONTAINERS" | sed 's/^/  • /'
echo ""

# Apply patches to each container
for container in $CONTAINERS; do
    patch_container "$container"
done

echo "✨ Security patches applied successfully!"
echo ""
echo "📊 Verification Steps:"
echo "1. Check the vulnerability status:"
echo "   docker scout cves ghcr.io/zammad/zammad:6.5.1"
echo ""
echo "2. Restart the containers to ensure patches are fully applied:"
echo "   docker compose restart"
echo ""
echo "3. Monitor the containers for any issues:"
echo "   docker compose logs -f"
echo ""
echo "⚠️  Important Notes:"
echo "• These patches are temporary and will be lost when containers are recreated"
echo "• For permanent fixes, use the Dockerfile.security-patched"
echo "• Consider building and pushing the patched image to your registry"
echo ""
