# Zairakai Node.js 22 Docker Image

[![Main][pipeline-main-badge]][pipeline-main-link]
[![Security][security-badge]][security]

[![License][license-badge]][license]
[![Node][node-badge]][node]
[![Release][release-badge]][release]

[![Docker Pulls][docker-pulls-badge]][dockerhub]
[![Prod Image Size][docker-prod-size-badge]][dockerhub]
[![Dev Image Size][docker-dev-size-badge]][dockerhub]
[![Test Image Size][docker-test-size-badge]][dockerhub]

Lightweight, secure, and optimized Node.js 22 LTS images built on Alpine Linux.

Production-ready Node.js 22 images with multi-stage builds for production, development, and testing.

## Features

### Production Stage (`prod`)

- Node.js 22 LTS on Alpine Linux
- Minimal runtime, non-root user (`node:node`)
- Hardened npm config for production
- Health check and graceful shutdown entrypoint

### Development Stage (`dev`)

- All production features
- TypeScript toolchain (`tsc`, `ts-node`)
- Hot reload with `nodemon`
- Process manager with `pm2`
- Build tools: git, make, g++, python3, curl
- Debug port `9229` exposed

### Test Stage (`test`)

- All development features
- Vitest + coverage tooling
- Pre-created `~/test-results/` and `~/coverage/` directories

## Quick Start

```bash
# Pull and run
docker run -d --name node-app -p 3000:3000 zairakai/node:latest node server.js
```

## Available Tags

| Version | Production | Development | Test |
| --- | --- | --- | --- |
| **Major** | `zairakai/node:22-prod` | `zairakai/node:22-dev` | `zairakai/node:22-test` |
| **Latest** | `zairakai/node:latest` | `zairakai/node:latest-dev` | `zairakai/node:latest-test` |

## Usage

### Production

```yaml
# docker-compose.yml
services:
  node:
    image: zairakai/node:latest
    volumes:
      - ./dist:/app/dist
    environment:
      - NODE_ENV=production
```

### Development

```yaml
services:
  node:
    image: zairakai/node:latest-dev
    volumes:
      - ./app:/app
    ports:
      - "3000:3000"
      - "9229:9229"
    environment:
      - NODE_ENV=development
    command: npm run dev
```

### Docker Compose with Laravel Backend

```yaml
services:
  frontend:
    image: zairakai/node:22-dev
    working_dir: /app
    volumes:
      - ./frontend:/app
    ports:
      - "3000:3000"
      - "9229:9229"
    command: npm run dev

  backend:
    image: zairakai/php:latest-dev
    volumes:
      - ./backend:/var/www/html
```

## Configuration

### Environment Variables

| Variable | Default | Description |
| -------- | ------- | ----------- |
| `NODE_ENV` | `production` | Node environment |
| `NODE_OPTIONS` | `--max-old-space-size=512` | V8 heap options |
| `NPM_CONFIG_CACHE` | `/tmp/.npm` | npm cache location |

## Health Check

The image includes a health check for the Node process:

```bash
docker inspect --format='{{.State.Health.Status}}' <container-id>
```

---

## Development

### Prerequisites

- Git
- Docker
- GNU Make (optional, for running tests)

### Clone the Repository

This repository uses Git submodules for shared tooling. Clone with:

```bash
# Clone with submodules in one command
git clone --recurse-submodules https://gitlab.com/zairakai/dockers/node.git

# OR if already cloned without submodules
git clone https://gitlab.com/zairakai/dockers/node.git
cd node
git submodule update --init --recursive
```

### Update Submodules

To update the `tooling` submodule to the latest version:

```bash
git submodule update --remote --merge
```

### Build Images Locally

```bash
# Build production image
docker build --target prod -t zairakai/node:local .

# Build development image
docker build --target dev -t zairakai/node:local-dev .

# Build test image
docker build --target test -t zairakai/node:local-test .
```

### Run Tests

```bash
# Run BATS tests (requires submodules)
make bats

# Or manually
bats tests/
```

### CI/CD Pipeline

The project uses GitLab CI/CD with the following stages:

1. **Security** - Secret detection
2. **Validate** - Dockerfile linting (Hadolint), Markdown linting, Shellcheck
3. **Test** - BATS test suite
4. **Build** - Multi-stage Docker builds (prod/dev/test)
5. **Release** - Automated releases with changelog

---

## Security

- Non-root user (`node:node`, UID/GID 1000)
- Alpine Linux minimal attack surface
- Trivy vulnerability scanning on every release
- GitLab Secret Detection in CI

See [SECURITY.md](SECURITY.md) for the security policy.

## Getting Help

[![License][license-badge]][license]
[![Security Policy][security-badge]][security]
[![Issues][issues-badge]][issues]

---

**Made with ❤️ by [Zairakai][dockers]**

<!-- Reference Links -->
[pipeline-main-badge]: https://gitlab.com/zairakai/dockers/node/badges/main/pipeline.svg?ignore_skipped=true&key_text=Main
[pipeline-main-link]: https://gitlab.com/zairakai/dockers/node/-/commits/main
[license-badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license]: ./LICENSE
[node-badge]: https://img.shields.io/badge/node-22-blue.svg
[node]: https://nodejs.org/
[release-badge]: https://img.shields.io/gitlab/v/release/zairakai%2Fdockers%2Fnode?logo=gitlab
[release]: https://gitlab.com/zairakai/dockers/node/-/releases
[issues-badge]: https://img.shields.io/gitlab/issues/open-raw/zairakai%2Fdockers%2Fnode?logo=gitlab&label=Issues
[issues]: https://gitlab.com/zairakai/dockers/node/-/issues
[security-badge]: https://img.shields.io/badge/security-scanned-green.svg
[security]: ./SECURITY.md
[docker-pulls-badge]: https://img.shields.io/docker/pulls/zairakai/node?logo=docker
[dockerhub]: https://hub.docker.com/r/zairakai/node
[docker-prod-size-badge]: https://img.shields.io/docker/image-size/zairakai/node/latest?logo=docker&label=prod
[docker-dev-size-badge]: https://img.shields.io/docker/image-size/zairakai/node/latest-dev?logo=docker&label=dev
[docker-test-size-badge]: https://img.shields.io/docker/image-size/zairakai/node/latest-test?logo=docker&label=test
[dockers]: https://gitlab.com/zairakai/dockers
