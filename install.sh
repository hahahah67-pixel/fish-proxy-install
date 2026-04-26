#!/bin/bash
# ============================================================
#  Fish Proxy — One-Command Installer
#  Supports: Ubuntu 20.04+ / Debian 11+
#  Usage: curl -fsSL <raw github url>/install.sh | bash
# ============================================================

set -e

# ── Colors ──────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Banner ───────────────────────────────────────────────────
echo ""
echo -e "${CYAN}${BOLD}"
echo "  ███████╗██╗███████╗██╗  ██╗    ██████╗ ██████╗  ██████╗ ██╗  ██╗██╗   ██╗"
echo "  ██╔════╝██║██╔════╝██║  ██║    ██╔══██╗██╔══██╗██╔═══██╗╚██╗██╔╝╚██╗ ██╔╝"
echo "  █████╗  ██║███████╗███████║    ██████╔╝██████╔╝██║   ██║ ╚███╔╝  ╚████╔╝ "
echo "  ██╔══╝  ██║╚════██║██╔══██║    ██╔═══╝ ██╔══██╗██║   ██║ ██╔██╗   ╚██╔╝  "
echo "  ██║     ██║███████║██║  ██║    ██║     ██║  ██║╚██████╔╝██╔╝ ██╗   ██║   "
echo "  ╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝    ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝  "
echo -e "${RESET}"
echo -e "${BOLD}  Fish Proxy Installer${RESET} — github.com/hahahah67-pixel/Ultraviolet-App"
echo ""

# ── Helpers ──────────────────────────────────────────────────
info()    { echo -e "${BLUE}[info]${RESET}  $1"; }
success() { echo -e "${GREEN}[done]${RESET}  $1"; }
warn()    { echo -e "${YELLOW}[warn]${RESET}  $1"; }
error()   { echo -e "${RED}[error]${RESET} $1"; exit 1; }
step()    { echo -e "\n${BOLD}${CYAN}── $1${RESET}"; }

# ── Check OS ─────────────────────────────────────────────────
step "Checking system"

if [ ! -f /etc/os-release ]; then
  error "Cannot detect OS. This installer supports Ubuntu/Debian only."
fi

. /etc/os-release
if [[ "$ID" != "ubuntu" && "$ID" != "debian" ]]; then
  error "Unsupported OS: $ID. Please use Ubuntu 20.04+ or Debian 11+."
fi

info "OS: $PRETTY_NAME ✓"

# ── Update apt ────────────────────────────────────────────────
step "Updating package lists"
sudo apt-get update -qq
success "Package lists updated"

# ── Install git ───────────────────────────────────────────────
step "Checking Git"
if ! command -v git &>/dev/null; then
  info "Installing Git..."
  sudo apt-get install -y -qq git
  success "Git installed"
else
  success "Git already installed ($(git --version))"
fi

# ── Install curl ──────────────────────────────────────────────
if ! command -v curl &>/dev/null; then
  info "Installing curl..."
  sudo apt-get install -y -qq curl
fi

# ── Install Node.js 22 ────────────────────────────────────────
step "Checking Node.js"
REQUIRED_NODE=22
INSTALL_NODE=false

if command -v node &>/dev/null; then
  NODE_VER=$(node -e "process.stdout.write(String(process.versions.node.split('.')[0]))")
  if [ "$NODE_VER" -ge "$REQUIRED_NODE" ]; then
    success "Node.js v$(node --version) already installed ✓"
  else
    warn "Node.js v$(node --version) is too old (need v${REQUIRED_NODE}+). Upgrading..."
    INSTALL_NODE=true
  fi
else
  info "Node.js not found. Installing v${REQUIRED_NODE}..."
  INSTALL_NODE=true
fi

if [ "$INSTALL_NODE" = true ]; then
  curl -fsSL https://deb.nodesource.com/setup_${REQUIRED_NODE}.x | sudo -E bash - &>/dev/null
  sudo apt-get install -y -qq nodejs
  success "Node.js $(node --version) installed"
fi

# ── Install pnpm ──────────────────────────────────────────────
step "Checking pnpm"
if ! command -v pnpm &>/dev/null; then
  info "Installing pnpm..."
  sudo npm install -g pnpm --quiet
  success "pnpm installed"
else
  success "pnpm already installed ($(pnpm --version))"
fi

# ── Install PM2 ───────────────────────────────────────────────
step "Checking PM2"
if ! command -v pm2 &>/dev/null; then
  info "Installing PM2 (process manager)..."
  sudo npm install -g pm2 --quiet
  success "PM2 installed"
else
  success "PM2 already installed"
fi

# ── Clone repo ────────────────────────────────────────────────
step "Cloning Fish Proxy"

REPO_URL="https://github.com/hahahah67-pixel/Ultraviolet-App.git"
INSTALL_DIR="$HOME/fish-proxy"

if [ -d "$INSTALL_DIR" ]; then
  warn "Directory $INSTALL_DIR already exists."
  read -p "  Overwrite it? (y/n): " OVERWRITE
  if [[ "$OVERWRITE" =~ ^[Yy]$ ]]; then
    rm -rf "$INSTALL_DIR"
    info "Removed old install."
  else
    info "Keeping existing directory. Pulling latest changes..."
    cd "$INSTALL_DIR"
    git pull --quiet
    success "Repo updated"
  fi
fi

if [ ! -d "$INSTALL_DIR" ]; then
  git clone --quiet "$REPO_URL" "$INSTALL_DIR"
  success "Repo cloned to $INSTALL_DIR"
fi

cd "$INSTALL_DIR"

# ── Install dependencies ──────────────────────────────────────
step "Installing dependencies"
pnpm install --silent
success "Dependencies installed"

# ── Configure port ────────────────────────────────────────────
step "Port configuration"
DEFAULT_PORT=8080
read -p "  What port should Fish Proxy run on? [default: $DEFAULT_PORT]: " PORT_INPUT
PORT=${PORT_INPUT:-$DEFAULT_PORT}

# Check port is not in use
if lsof -Pi :$PORT -sTCP:LISTEN -t &>/dev/null 2>&1; then
  warn "Port $PORT is already in use. Trying $((PORT+1))..."
  PORT=$((PORT+1))
fi

# ── Start with PM2 ────────────────────────────────────────────
step "Starting Fish Proxy"

# Stop old instance if running
pm2 delete fish-proxy &>/dev/null || true

PORT=$PORT pm2 start src/index.js \
  --name fish-proxy \
  --env production \
  --restart-delay 3000 \
  --max-restarts 10 \
  --quiet

# Save PM2 config so it restarts on reboot
pm2 save --quiet

# Setup PM2 startup (auto-start on reboot)
PM2_STARTUP=$(pm2 startup | grep "sudo" | tail -1)
if [ -n "$PM2_STARTUP" ]; then
  eval "$PM2_STARTUP" &>/dev/null || true
fi

success "Fish Proxy is running with PM2"

# ── Get IP ────────────────────────────────────────────────────
step "Getting server address"
PUBLIC_IP=$(curl -s --max-time 5 https://api.ipify.org 2>/dev/null || echo "unknown")
LOCAL_IP=$(hostname -I | awk '{print $1}')

# ── Done ──────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}╔════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}${BOLD}║       Fish Proxy installed successfully!    ║${RESET}"
echo -e "${GREEN}${BOLD}╚════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${BOLD}Local URL:${RESET}   http://$LOCAL_IP:$PORT"
echo -e "  ${BOLD}Public URL:${RESET}  http://$PUBLIC_IP:$PORT"
echo ""
echo -e "  ${BOLD}Useful commands:${RESET}"
echo -e "  ${CYAN}pm2 status${RESET}          — check if Fish Proxy is running"
echo -e "  ${CYAN}pm2 logs fish-proxy${RESET} — view live server logs"
echo -e "  ${CYAN}pm2 restart fish-proxy${RESET} — restart the server"
echo -e "  ${CYAN}pm2 stop fish-proxy${RESET} — stop the server"
echo ""
echo -e "  ${YELLOW}Note:${RESET} To use your own domain, point it to $PUBLIC_IP"
echo -e "  ${YELLOW}Note:${RESET} Make sure port $PORT is open in your firewall/security group"
echo ""
