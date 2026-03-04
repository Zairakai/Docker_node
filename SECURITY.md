# Security Policy

## 🔒 Reporting Vulnerabilities

**Preferred channels** (in order):

1. **GitLab Issues** (for non-sensitive issues): [Open Issue][issues]
2. **GitLab Service Desk**: `contact-project+zairakai-dockers-node-79965561-issue-@incoming.gitlab.com`
3. **Email**: `security@the-white-rabbits.fr`

**Include in your report:**

- Vulnerability description
- Reproduction steps
- Potential impact
- Affected versions
- Suggested fix (if available)

---

## 🛡️ Security Features

### Runtime Security

- ✅ **Non-root execution** - Runs as non-privileged user
- ✅ **Alpine Linux** - Minimal attack surface
- ✅ **No unnecessary packages** - Production image is minimal
- ✅ **Healthchecks** - Validates environment on startup
- ✅ **Read-only compatible** - Works with read-only root filesystem

### Build Security

- ✅ **Multi-stage builds** - Optimized layers, minimal final image
- ✅ **Official base images** - Trusted sources only
- ✅ **No hardcoded secrets** - All credentials via environment variables
- ✅ **Vulnerability scanning** - Automated on every build

---

## 🔍 CI/CD Security Scanning

Every commit is automatically scanned for:

- **SAST** - Static Application Security Testing
- **Dependency Scanning** - Package vulnerabilities
- **Secret Detection** - Exposed credentials, API keys
- **ShellCheck** - Shell script security (100% compliance)

### Security Gates

| Severity | Action |
| -------- | ------ |
| **CRITICAL** | ❌ Pipeline fails |
| **HIGH** | ⚠️ Manual review required |
| **MEDIUM/LOW** | ℹ️ Warning only |

---

## ⏱️ Response Timeline

| Severity | Acknowledgment | Fix Target |
| -------- | -------------- | ---------- |
| **CRITICAL** | 24h | 24-48h |
| **HIGH** | 48h | 7 days |
| **MEDIUM** | 7 days | 30 days |
| **LOW** | 14 days | 90 days |

---

## 🔧 Security Best Practices

### Using Securely

```bash
# Pin to specific version (reproducible builds)
docker pull zairakai/node:x.y.z

# Run with read-only filesystem
docker run --read-only zairakai/node:x.y.z

# Drop all capabilities
docker run --cap-drop=ALL zairakai/node:x.y.z
```

### Docker Compose Security

```yaml
services:
  app:
    image: zairakai/node:x.y.z  # Pinned version
    read_only: true  # Read-only filesystem
    cap_drop:
      - ALL  # Drop all capabilities
    security_opt:
      - no-new-privileges:true  # Prevent privilege escalation
```

---

## 📋 Compliance Standards

- **OWASP Top 10** - Vulnerability prevention
- **CIS Docker Benchmark** - Container security
- **GitLab Security Best Practices** - CI/CD security
- **NIST Cybersecurity Framework** - Security principles

---

## 🔄 Security Updates

- **Vulnerability Database**: Auto-updated by GitLab scanners
- **Security Policies**: Reviewed quarterly
- **Base Images**: Updated with new LTS releases
- **Dependencies**: Reviewed and updated monthly

---

## 📚 Links

- [Contributing][contributing]
- [Releases][releases]

## Getting Help

[![License][license-badge]][license]
[![Security Policy][security-badge]][security]
[![Issues][issues-badge]][issues]
[![Discord][discord-badge]][discord]

---

**Made with ❤️ by [Zairakai][ecosystem]**

<!-- Reference Links -->
[license-badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license]: ./LICENSE
[contributing]: ./CONTRIBUTING.md

[issues-badge]: https://img.shields.io/gitlab/issues/open/zairakai%2Fdockers%2Fnode?logo=gitlab&logoColor=white&label=Issues
[issues]: https://gitlab.com/zairakai/dockers/node/-/issues

[discord-badge]: https://img.shields.io/discord/1260000352699289621?logo=discord&logoColor=white&label=Discord&color=5865F2
[discord]: https://discord.gg/MAmD5SG8Zu

[security-badge]: https://img.shields.io/badge/security-scanned-green.svg
[security]: ./SECURITY.md

[releases]: https://gitlab.com/zairakai/dockers/node/-/releases
[ecosystem]: https://gitlab.com/zairakai/dockers
