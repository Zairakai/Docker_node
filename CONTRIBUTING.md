# Contributing to node

Thanks for contributing!

## 🚀 Quick Start

```bash
# 1. Fork & clone
git clone https://gitlab.com/zairakai/dockers/node.git
cd node

# 2. Add upstream
git remote add upstream https://gitlab.com/zairakai/dockers/node.git

# 3. Create branch
git checkout -b feature/your-feature

# 4. Make changes & test
make ci-full

# 5. Commit (Conventional Commits)
git commit -m "feat: add amazing feature"

# 6. Push & open MR
git push origin feature/your-feature
```

---

## ✅ Requirements

### Shell Scripts

- **ShellCheck 100%** compliance (ZERO warnings)
- **Shebang**: `#!/usr/bin/env bash`
- **Error handling**: `set -euo pipefail`
- **Clear logging**: Use emojis and structured output

### Tests

- **Add BATS tests** for new features
- **All tests must pass**: `make bats`
- **Coverage**: Unit + integration tests

### Documentation

- **Markdownlint** compliance
- **Clear examples** with code blocks
- **Update docs** for new features

---

## 🧪 Adding Tests

```bash
# tests/unit/05-my-feature.bats

@test "my-feature: should work correctly" {
    run bash scripts/my-script.sh
    assert_success
    assert_output --partial "expected output"
}

@test "my-feature: should handle errors" {
    run bash scripts/my-script.sh invalid-arg
    assert_failure
}
```

Run: `bats tests/unit/05-my-feature.bats`

---

## 📜 Shell Script Template

```bash
#!/usr/bin/env bash
#
# Script description
# Usage: script-name.sh <arg1> <arg2>
#
set -euo pipefail

echo "━━━━━━━━━━━━━━━━"
echo "🎯 Script Title"
echo "━━━━━━━━━━━━━━━━"
echo ""

echo "→ Doing something..."
# Implementation
echo "  ✅ Done"
echo ""

echo "✅ Script completed successfully"
```

**Validate**: `shellcheck scripts/my-script.sh`

---

## 🔍 Validation

```bash
make quality    # ShellCheck + Markdownlint + Hadolint
make bats       # All tests
make ci-full    # Complete validation
```

---

## 📝 Commit Format

We use [Conventional Commits](https://conventionalcommits.org/):

```bash
feat: new feature
fix: bug fix
docs: documentation update
test: add tests
ci: CI/CD changes
chore: maintenance tasks
```

**Examples:**

```bash
feat(browser): add Firefox support
fix(healthcheck): correct timeout handling
docs: update installation guide
test(unit): add BATS tests for run-tests.sh
ci: optimize Kaniko cache strategy
chore(deps): update dependencies
```

---

## 🔄 Review Process

1. **Automated Checks** - GitLab CI validates code
2. **Manual Review** - Maintainer reviews changes
3. **Testing** - Changes tested in CI environment
4. **Approval** - Maintainer approves MR
5. **Merge** - Changes merged to main

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
