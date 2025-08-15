# 🔒 Security Update Package for Zammad

## Overview
This security update addresses 3 HIGH severity vulnerabilities identified by Docker Scout in the Zammad 6.5.1 deployment.

## Vulnerabilities Addressed

| CVE | Severity | Component | CVSS | Status |
|-----|----------|-----------|------|--------|
| CVE-2025-24293 | HIGH | activestorage 7.2.2.1 | 8.2 | ✅ Patched |
| CVE-2025-5994 | HIGH | unbound 1.17.1 | N/A | ✅ Removed |
| CVE-2025-6020 | HIGH | pam 1.5.2 | N/A | ✅ Updated |

## Files Added

1. **`setup-github-secrets.sh`** - Automated GitHub secrets configuration
2. **`Dockerfile.security-patched`** - Custom Dockerfile with security patches
3. **`docker-compose.security.yml`** - Security-enhanced compose configuration
4. **`apply-security-patches.sh`** - Runtime patch application script
5. **`.github/workflows/docker-scout.yaml`** - CI/CD security scanning workflow
6. **`DOCKER_SCOUT_GUIDE.md`** - Complete Docker Scout documentation

## Quick Start Guide

### Step 1: Configure GitHub Secrets
```bash
# Run the automated setup script
./setup-github-secrets.sh

# Or manually add secrets in GitHub:
# Settings > Secrets > Actions > New repository secret
# - DOCKER_USERNAME: Your Docker Hub username
# - DOCKER_PASSWORD: Your Docker Hub access token
```

### Step 2: Apply Security Patches

#### Option A: Use Pre-built Official Image (Recommended for Testing)
```bash
# Apply patches to running containers
docker compose up -d
./apply-security-patches.sh
docker compose restart
```

#### Option B: Build Custom Security-Patched Image
```bash
# Build the patched image
docker build -f Dockerfile.security-patched -t vantagepointconsult/zammad-patched:6.5.1-security .

# Use the security-enhanced compose file
docker compose -f docker-compose.yml -f docker-compose.security.yml up -d
```

### Step 3: Verify Security Improvements
```bash
# Scan the patched image
docker scout cves vantagepointconsult/zammad-patched:6.5.1-security

# Compare with original
docker scout compare ghcr.io/zammad/zammad:6.5.1 --to vantagepointconsult/zammad-patched:6.5.1-security
```

## CI/CD Integration

The GitHub Actions workflow will automatically:
- 🔍 Scan for vulnerabilities on every push
- 📅 Run weekly security audits (Mondays 9 AM)
- 📦 Generate SBOM for compliance
- ✅ Check policy compliance
- 📊 Provide security reports

### Manual Workflow Trigger
```bash
# Using GitHub CLI
gh workflow run docker-scout.yaml --ref main

# With custom image tag
gh workflow run docker-scout.yaml --ref main -f image_tag=6.5.2
```

## Security Improvements Summary

### Base Image Update
- **From**: `ruby:3.2.8-slim-bookworm`
- **To**: `ruby:3.2.9-slim-bookworm`
- **Result**: -2 vulnerabilities

### Package Updates
- ✅ activestorage → 7.2.2.2
- ✅ activerecord → 7.2.2.2
- ✅ resolv → 0.2.3
- ✅ net-imap → 0.3.9

### Security Hardening
- 🔒 Non-root user execution
- 🔒 Read-only filesystems where possible
- 🔒 Security capabilities restrictions
- 🔒 Resource limits applied
- 🔒 Core dumps disabled
- 🔒 PAM security enhanced

## Monitoring & Maintenance

### Dashboard Access
- **Docker Scout**: https://scout.docker.com/org/vantagepointconsult
- **Repository Settings**: https://scout.docker.com/org/vantagepointconsult/settings/repos

### Regular Tasks
- [ ] Weekly: Review vulnerability reports
- [ ] Monthly: Update base images
- [ ] Quarterly: Full security audit

## Important Notes

⚠️ **Temporary vs Permanent Fixes**:
- The `apply-security-patches.sh` script provides temporary fixes
- For permanent solutions, rebuild using `Dockerfile.security-patched`
- Push patched images to your registry for production use

⚠️ **Production Deployment**:
1. Test patches in staging environment first
2. Build and tag custom image
3. Push to your private registry
4. Update production compose files
5. Deploy with zero-downtime strategy

## Support & Resources

- 📚 [Docker Scout Documentation](https://docs.docker.com/scout/)
- 🐛 [Report Issues](https://github.com/docker/scout-cli/issues)
- 📖 [Zammad Security](https://docs.zammad.org/en/latest/admin/security.html)
- 🔍 [CVE Database](https://cve.mitre.org/)

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-08-15 | Initial security update package |

---

**Maintained by**: VantagePoint Consult DevOps Team
**Last Updated**: 2025-08-15
