# Docker Scout CI/CD Integration Guide

## 🔒 Overview

This guide documents the Docker Scout security scanning integration for the Zammad deployment, providing continuous security monitoring and vulnerability management through automated CI/CD pipelines.

## 📋 Table of Contents

- [Quick Start](#quick-start)
- [Security Analysis Results](#security-analysis-results)
- [GitHub Actions Workflow](#github-actions-workflow)
- [Manual Commands](#manual-commands)
- [Security Best Practices](#security-best-practices)
- [Troubleshooting](#troubleshooting)

## 🚀 Quick Start

### Prerequisites

1. **Docker Scout Organization**: `vantagepointconsult` (✅ Configured)
2. **Docker Hub Account**: Required for accessing Docker Scout features
3. **GitHub Secrets**: Configure the following in your repository settings:
   - `DOCKER_USERNAME`: Your Docker Hub username
   - `DOCKER_PASSWORD`: Your Docker Hub access token

### Automated Security Scanning

The GitHub Actions workflow (`.github/workflows/docker-scout.yaml`) automatically:
- Scans for vulnerabilities on every push and pull request
- Runs weekly security audits (every Monday at 9 AM)
- Generates Software Bill of Materials (SBOM)
- Evaluates policy compliance
- Provides remediation recommendations

## 📊 Security Analysis Results

### Current Vulnerability Status (Zammad 6.5.1)

Based on our Docker Scout analysis:

```
Total Vulnerabilities: 111
├── Critical: 0
├── High: 3
├── Medium: 6
├── Low: 98
└── Unspecified: 4
```

### High Priority Issues

1. **CVE-2025-5994** (HIGH) - unbound 1.17.1
2. **CVE-2025-24293** (HIGH) - activestorage 7.2.2.1
3. **CVE-2025-6020** (HIGH) - pam 1.5.2

### Recommended Base Image Updates

Docker Scout recommends updating to one of these base images to reduce vulnerabilities:

| Base Image | Vulnerabilities Reduced | Benefits |
|------------|------------------------|----------|
| `ruby:3.2.9-slim-bookworm` | -2 vulnerabilities | Patch runtime update, most compatible |
| `ruby:3.4.5-slim-bookworm` | -2 vulnerabilities | Minor version update, latest features |
| `ruby:3.3.9-slim-bookworm` | -2 vulnerabilities | Stable minor version |

## 🔧 GitHub Actions Workflow

### Workflow Features

The workflow includes 5 main jobs:

1. **scout-analysis**: CVE scanning and vulnerability detection
2. **build-and-scan-custom**: Build and scan custom images (if Dockerfile exists)
3. **policy-evaluation**: Check compliance with organization policies
4. **sbom-generation**: Generate Software Bill of Materials
5. **security-summary**: Consolidated security report

### Triggering the Workflow

#### Automatic Triggers
- Push to `main`, `master`, or `develop` branches
- Pull requests to protected branches
- Weekly schedule (Mondays at 9 AM UTC)

#### Manual Trigger
```bash
# Trigger via GitHub CLI
gh workflow run docker-scout.yaml --ref main

# With custom image tag
gh workflow run docker-scout.yaml --ref main -f image_tag=6.5.2
```

## 💻 Manual Commands

### Local Security Scanning

```bash
# Scan for all vulnerabilities
docker scout cves ghcr.io/zammad/zammad:6.5.1

# Scan for critical and high severity only
docker scout cves ghcr.io/zammad/zammad:6.5.1 --only-severity critical,high

# Get remediation recommendations
docker scout recommendations ghcr.io/zammad/zammad:6.5.1

# Compare versions
docker scout compare ghcr.io/zammad/zammad:6.5.1 --to ghcr.io/zammad/zammad:latest

# Generate SBOM
docker scout sbom --format spdx --output zammad-sbom.json ghcr.io/zammad/zammad:6.5.1
```

### Organization Management

```bash
# View organization status
docker scout config organization

# List enabled repositories
docker scout repo list --org vantagepointconsult

# Push image to Scout for analysis
docker scout push ghcr.io/zammad/zammad:6.5.1 --org vantagepointconsult
```

## 🛡️ Security Best Practices

### 1. Regular Updates
- **Weekly Scans**: Automated via GitHub Actions
- **Base Image Updates**: Review recommendations monthly
- **Patch Management**: Apply security patches within 30 days for HIGH/CRITICAL

### 2. Vulnerability Response Plan

#### Critical (CVSS 9.0-10.0)
- **Response Time**: Within 24 hours
- **Action**: Immediate patching or mitigation

#### High (CVSS 7.0-8.9)
- **Response Time**: Within 7 days
- **Action**: Schedule patching in next release

#### Medium (CVSS 4.0-6.9)
- **Response Time**: Within 30 days
- **Action**: Include in regular update cycle

#### Low (CVSS 0.1-3.9)
- **Response Time**: Within 90 days
- **Action**: Bundle with other updates

### 3. Container Security Checklist

- [ ] Run containers as non-root user
- [ ] Use minimal base images (slim variants)
- [ ] Implement resource limits
- [ ] Enable security scanning in CI/CD
- [ ] Maintain SBOM for compliance
- [ ] Regular security audits
- [ ] Monitor Docker Scout Dashboard

## 🔍 Monitoring & Dashboards

### Docker Scout Dashboard
Access at: https://scout.docker.com/org/vantagepointconsult

Features:
- Real-time vulnerability tracking
- Policy compliance status
- Historical security trends
- Remediation recommendations

### GitHub Security Tab
View security alerts and dependency updates in your repository's Security tab.

## 🐛 Troubleshooting

### Common Issues

#### 1. Authentication Errors
```bash
# Re-authenticate with Docker Hub
docker login

# Verify organization
docker scout config organization vantagepointconsult
```

#### 2. Workflow Failures
- Check GitHub Secrets are configured correctly
- Ensure Docker Hub account has Scout access
- Verify organization enrollment status

#### 3. Image Not Found
```bash
# Pull image first
docker pull ghcr.io/zammad/zammad:6.5.1

# Then scan
docker scout cves ghcr.io/zammad/zammad:6.5.1
```

### Getting Help

- **Docker Scout Documentation**: https://docs.docker.com/scout/
- **GitHub Issues**: Report workflow issues in the repository
- **Docker Scout Support**: https://github.com/docker/scout-cli/issues

## 📈 Metrics & KPIs

Track these metrics for security posture:

1. **Mean Time to Remediation (MTTR)**
   - Target: < 7 days for HIGH/CRITICAL

2. **Vulnerability Density**
   - Current: 111 vulnerabilities / 714 packages = 15.5%
   - Target: < 10%

3. **Policy Compliance Rate**
   - Monitor via Docker Scout Dashboard

4. **SBOM Coverage**
   - Target: 100% of production images

## 🔄 Continuous Improvement

### Monthly Review Checklist
- [ ] Review vulnerability trends
- [ ] Update base images if recommended
- [ ] Audit policy compliance
- [ ] Update security documentation
- [ ] Review and update response times

### Quarterly Security Audit
- [ ] Full security assessment
- [ ] Update security policies
- [ ] Review access controls
- [ ] Penetration testing (if applicable)
- [ ] Update incident response plan

## 📝 Appendix

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DOCKER_ORG` | Docker organization | vantagepointconsult |
| `IMAGE_NAME` | Image to scan | ghcr.io/zammad/zammad |
| `VERSION` | Zammad version | 6.5.1 |

### Useful Links

- [Docker Scout CLI Reference](https://docs.docker.com/engine/reference/commandline/scout/)
- [Zammad Docker Compose](https://github.com/zammad/zammad-docker-compose)
- [CVE Database](https://cve.mitre.org/)
- [CVSS Calculator](https://www.first.org/cvss/calculator/3.1)

---

**Last Updated**: 2025-08-15
**Maintained By**: VantagePoint Consult DevOps Team
**Version**: 1.0.0
