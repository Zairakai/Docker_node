#!/bin/bash
set -euo pipefail

# Development environment setup script
# Configures Node.js development environment with tools and preferences

readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

log_info()  { echo -e "${GREEN}[DEV-SETUP]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"; }
log_warn()  { echo -e "${YELLOW}[DEV-SETUP]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2; }
log_error() { echo -e "${RED}[DEV-SETUP]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2; }
log_step()  { echo -e "${BLUE}[DEV-SETUP]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"; }

setup_git_config() {
  log_step "Setting up Git configuration..."

  mkdir -p ~/.gitconfig.d

  cat > ~/.gitconfig << 'EOF'
[user]
  name = Docker Developer
  email = dev@example.com

[core]
  editor = nano
  autocrlf = input
  safecrlf = warn
  excludesfile = ~/.gitignore_global

[init]
  defaultBranch = main

[pull]
  rebase = false

[push]
  default = simple

[alias]
  st = status
  ci = commit
  co = checkout
  br = branch
  last = log -1 HEAD
  lg = log --oneline --graph --decorate --all

[color]
  ui = auto
EOF

  cat > ~/.gitignore_global << 'EOF'
.DS_Store
._*
.vscode/
.idea/
*.swp
*.swo
node_modules/
npm-debug.log*
.npm
.env
.env.local
logs
*.log
coverage/
.nyc_output
.eslintcache
EOF

  log_info "Git configuration completed"
}

setup_npm_config() {
  log_step "Setting up npm configuration..."

  cat > ~/.npmrc << 'EOF'
registry=https://registry.npmjs.org/
cache=/home/node/.npm
cache-min=10
save=true
save-exact=false
save-prefix=^
package-lock=true
progress=true
loglevel=info
unicode=true
maxsockets=50
fetch-retries=3
fund=true
audit-level=moderate
optional=true
EOF

  log_info "npm configuration completed"
}

setup_shell_environment() {
  log_step "Setting up shell environment..."

  cat > ~/.bashrc << 'EOF'
export TERM=xterm-256color
export NODE_ENV=development
export NODE_OPTIONS="--max-old-space-size=1024 --inspect=0.0.0.0:9229"
export EDITOR=nano
export PATH="$HOME/.local/bin:$PATH"
export PATH="./node_modules/.bin:$PATH"
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoredups:erasedups

alias ll='ls -alF'
alias la='ls -A'
alias grep='grep --color=auto'
alias ni='npm install'
alias ns='npm start'
alias nt='npm test'
alias nb='npm run build'
alias nd='npm run dev'
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gd='git diff'

shopt -s histappend

echo "Node.js: $(node --version 2>/dev/null || echo 'not found')"
echo "npm: $(npm --version 2>/dev/null || echo 'not found')"
EOF

  ln -sf ~/.bashrc ~/.profile

  log_info "Shell environment completed"
}

setup_debugging_config() {
  log_step "Setting up debugging configuration..."

  mkdir -p ~/.config/debug

  cat > ~/.config/debug/inspector.json << 'EOF'
{
  "inspector": {
    "host": "0.0.0.0",
    "port": 9229,
    "break": false
  },
  "source_maps": {
    "enabled": true,
    "inline": true
  }
}
EOF

  log_info "Debugging configuration completed"
}

setup_development_tools() {
  log_step "Setting up development tools..."

  mkdir -p ~/.local/bin
  mkdir -p ~/.cache

  log_info "Development tools setup completed"
}

verify_setup() {
  log_step "Verifying development setup..."

  local errors=0
  local tools=("node" "npm" "git" "tsc" "nodemon")
  for tool in "${tools[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
      log_info "  $tool available"
    else
      log_error "  $tool not found"
      errors=$((errors + 1))
    fi
  done

  if [ "$errors" -eq 0 ]; then
    log_info "All required tools are available"
    return 0
  else
    log_warn "$errors tool(s) missing — verify image build"
    return 1
  fi
}

main() {
  log_info "Starting development environment setup..."
  log_info "User: $(whoami)"
  log_info "Home: $HOME"

  setup_git_config
  setup_npm_config
  setup_shell_environment
  setup_debugging_config
  setup_development_tools

  if verify_setup; then
    log_info "Development environment setup completed"
  else
    log_warn "Setup completed with warnings"
  fi
}

main "$@"
