#!/bin/bash
# ============================================================
#  Fish Proxy — One-Command Installer
#  Supports: Ubuntu/Debian Linux, macOS
#  Usage: curl -fsSL https://raw.githubusercontent.com/hahahah67-pixel/fish-proxy-install/main/install.sh | bash
# ============================================================

set -e

# ── Colors ───────────────────────────────────────────────────
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
info()    { echo -e "  ${BLUE}[info]${RESET}  $1"; }
success() { echo -e "  ${GREEN}[done]${RESET}  $1"; }
warn()    { echo -e "  ${YELLOW}[warn]${RESET}  $1"; }
error()   { echo -e "  ${RED}[error]${RESET} $1"; exit 1; }
step()    { echo -e "\n${BOLD}${CYAN}── $1${RESET}"; }

# ── Detect OS ────────────────────────────────────────────────
step "Detecting system"

OS=""
if [[ "$OSTYPE" == "darwin"* ]]; then
  OS="macos"
  info "macOS detected ✓"
elif [ -f /etc/os-release ]; then
  . /etc/os-release
  if [[ "$ID" == "ubuntu" || "$ID" == "debian" || "$ID_LIKE" == *"debian"* ]]; then
    OS="debian"
    info "OS: $PRETTY_NAME ✓"
  else
    error "Unsupported Linux distro: $ID. This installer supports Ubuntu/Debian only."
  fi
else
  error "Cannot detect OS. Supported: Ubuntu, Debian, macOS."
fi

# ── Server warning + app install question ────────────────────
echo ""
echo -e "  ${YELLOW}${BOLD}⚠  READ THIS BEFORE CONTINUING${RESET}"
echo ""
echo -e "  ${YELLOW}If you are deploying Fish Proxy to a SERVER or VM (AWS, DigitalOcean, etc.)${RESET}"
echo -e "  ${YELLOW}do NOT install it as a desktop app — just install it to the server.${RESET}"
echo -e "  ${YELLOW}Installing as a desktop app on a server can cause unexpected issues.${RESET}"
echo ""

INSTALL_APP=false

if [[ "$OS" == "macos" ]]; then
  echo -e "  ${BOLD}Would you like to install Fish Proxy as a macOS app?${RESET}"
  echo -e "  This lets you launch Fish Proxy directly from your Mac without a terminal."
  echo -e "  ${BLUE}Only choose yes if you are on a personal Mac, not a server.${RESET}"
  echo ""
  read -p "  Install as macOS app? (y/n): " APP_CHOICE
else
  echo -e "  ${BOLD}Would you like to install Fish Proxy as a Linux desktop app?${RESET}"
  echo -e "  This creates a .deb package you can launch from your app menu."
  echo -e "  ${BLUE}Only choose yes if you are on a personal Linux desktop, not a server.${RESET}"
  echo ""
  read -p "  Install as Linux desktop app? (y/n): " APP_CHOICE
fi

if [[ "$APP_CHOICE" =~ ^[Yy]$ ]]; then
  INSTALL_APP=true
  info "Desktop app install selected."
else
  info "Server/standard install selected."
fi

# ── Auto-update question ──────────────────────────────────────
echo ""
echo -e "  ${BOLD}Would you like Fish Proxy to check for and deploy updates${RESET}"
echo -e "  ${BOLD}automatically every time the server starts?${RESET}"
echo -e "  ${BLUE}If yes: git pull + pnpm install runs on every startup.${RESET}"
echo -e "  ${BLUE}If no:  update manually whenever you want.${RESET}"
echo ""
read -p "  Enable auto-updates on startup? (y/n): " UPDATE_CHOICE
AUTO_UPDATE=false
if [[ "$UPDATE_CHOICE" =~ ^[Yy]$ ]]; then
  AUTO_UPDATE=true
  info "Auto-updates enabled."
else
  info "Auto-updates disabled."
fi

# ── Install dependencies: macOS ──────────────────────────────
if [[ "$OS" == "macos" ]]; then

  step "Checking Homebrew"
  if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    success "Homebrew installed"
  else
    success "Homebrew already installed"
  fi

  step "Checking Git"
  if ! command -v git &>/dev/null; then
    info "Installing Git..."
    brew install git --quiet
    success "Git installed"
  else
    success "Git already installed ($(git --version))"
  fi

  step "Checking Node.js"
  REQUIRED_NODE=22
  if command -v node &>/dev/null; then
    NODE_VER=$(node -e "process.stdout.write(String(process.versions.node.split('.')[0]))")
    if [ "$NODE_VER" -ge "$REQUIRED_NODE" ]; then
      success "Node.js v$(node --version) already installed ✓"
    else
      warn "Node.js v$(node --version) is too old. Upgrading..."
      brew install node@${REQUIRED_NODE} --quiet
      brew link --overwrite node@${REQUIRED_NODE} --quiet
      success "Node.js upgraded"
    fi
  else
    info "Installing Node.js ${REQUIRED_NODE}..."
    brew install node@${REQUIRED_NODE} --quiet
    brew link --overwrite node@${REQUIRED_NODE} --quiet
    success "Node.js $(node --version) installed"
  fi

# ── Install dependencies: Linux ──────────────────────────────
else

  step "Updating package lists"
  sudo apt-get update -qq
  success "Package lists updated"

  step "Checking Git"
  if ! command -v git &>/dev/null; then
    info "Installing Git..."
    sudo apt-get install -y -qq git
    success "Git installed"
  else
    success "Git already installed ($(git --version))"
  fi

  if ! command -v curl &>/dev/null; then
    sudo apt-get install -y -qq curl
  fi

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

fi

# ── pnpm (both OS) ───────────────────────────────────────────
step "Checking pnpm"
if ! command -v pnpm &>/dev/null; then
  info "Installing pnpm..."
  sudo npm install -g pnpm --quiet
  success "pnpm installed"
else
  success "pnpm already installed ($(pnpm --version))"
fi

# ── PM2 (both OS) ────────────────────────────────────────────
step "Checking PM2"
if ! command -v pm2 &>/dev/null; then
  info "Installing PM2..."
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

# ── Desktop app install ───────────────────────────────────────
if [ "$INSTALL_APP" = true ]; then

  if [[ "$OS" == "macos" ]]; then
    step "Creating macOS app"

    APP_DIR="/Applications/Fish Proxy.app/Contents/MacOS"
    mkdir -p "$APP_DIR"

    cat > "$APP_DIR/Fish Proxy" << APPEOF
#!/bin/bash
cd "$INSTALL_DIR"
PORT=8080 node src/index.js &
SERVER_PID=\$!
sleep 2
open "http://localhost:8080/index.html"
wait \$SERVER_PID
APPEOF
    chmod +x "$APP_DIR/Fish Proxy"

    # Info.plist
    mkdir -p "/Applications/Fish Proxy.app/Contents"
    cat > "/Applications/Fish Proxy.app/Contents/Info.plist" << PLISTEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Fish Proxy</string>
  <key>CFBundleExecutable</key><string>Fish Proxy</string>
  <key>CFBundleIdentifier</key><string>com.fishproxy.app</string>
  <key>CFBundleVersion</key><string>1.0</string>
  <key>CFBundlePackageType</key><string>APPL</string>
</dict>
</plist>
PLISTEOF

    success "Fish Proxy.app created in /Applications"
    info "You can now launch Fish Proxy from your Applications folder."

  else
    step "Creating Linux desktop app (.deb)"

    DEB_DIR="/tmp/fish-proxy-deb"
    mkdir -p "$DEB_DIR/DEBIAN"
    mkdir -p "$DEB_DIR/usr/bin"
    mkdir -p "$DEB_DIR/usr/share/applications"

    # Launcher script
    cat > "$DEB_DIR/usr/bin/fish-proxy" << LAUNCHEOF
#!/bin/bash
cd "$INSTALL_DIR"
PORT=8080 node src/index.js &
sleep 2
xdg-open "http://localhost:8080/index.html" 2>/dev/null || \
  sensible-browser "http://localhost:8080/index.html" 2>/dev/null
LAUNCHEOF
    chmod +x "$DEB_DIR/usr/bin/fish-proxy"

    # .desktop entry
    cat > "$DEB_DIR/usr/share/applications/fish-proxy.desktop" << DESKEOF
[Desktop Entry]
Name=Fish Proxy
Comment=Fast free web proxy
Exec=fish-proxy
Icon=network-proxy
Terminal=false
Type=Application
Categories=Network;
DESKEOF

    # Control file
    cat > "$DEB_DIR/DEBIAN/control" << CTRLEOF
Package: fish-proxy
Version: 1.0.0
Section: net
Priority: optional
Architecture: all
Maintainer: Fish Proxy
Description: Fish Proxy - Fast free web proxy powered by UV and Scramjet
CTRLEOF

    dpkg-deb --build "$DEB_DIR" /tmp/fish-proxy.deb &>/dev/null
    sudo dpkg -i /tmp/fish-proxy.deb &>/dev/null
    rm -rf "$DEB_DIR" /tmp/fish-proxy.deb

    success "Fish Proxy installed as a desktop app"
    info "Launch it from your app menu or by running: fish-proxy"
  fi

fi

# ── Configure port ────────────────────────────────────────────
step "Port configuration"
DEFAULT_PORT=8080
read -p "  What port should Fish Proxy run on? [default: $DEFAULT_PORT]: " PORT_INPUT
PORT=${PORT_INPUT:-$DEFAULT_PORT}

if lsof -Pi :$PORT -sTCP:LISTEN -t &>/dev/null 2>&1; then
  warn "Port $PORT is already in use. Trying $((PORT+1))..."
  PORT=$((PORT+1))
fi

# ── Start with PM2 ────────────────────────────────────────────
step "Starting Fish Proxy"

pm2 delete fish-proxy &>/dev/null || true

if [ "$AUTO_UPDATE" = true ]; then
  cat > "$INSTALL_DIR/start-with-update.sh" << 'WRAPEOF'
#!/bin/bash
cd INSTALL_DIR_PLACEHOLDER
echo "[Fish Proxy] Checking for updates..."
git pull --quiet && pnpm install --silent && echo "[Fish Proxy] Up to date." || echo "[Fish Proxy] Update check failed, starting anyway."
exec node src/index.js
WRAPEOF
  sed -i "s|INSTALL_DIR_PLACEHOLDER|$INSTALL_DIR|g" "$INSTALL_DIR/start-with-update.sh"
  chmod +x "$INSTALL_DIR/start-with-update.sh"
  PORT=$PORT pm2 start "$INSTALL_DIR/start-with-update.sh" \
    --name fish-proxy \
    --restart-delay 3000 \
    --max-restarts 10 \
    --quiet
  info "Auto-updates ON — Fish Proxy pulls latest on every restart."
else
  PORT=$PORT pm2 start src/index.js \
    --name fish-proxy \
    --restart-delay 3000 \
    --max-restarts 10 \
    --quiet
fi

pm2 save --quiet

PM2_STARTUP=$(pm2 startup 2>/dev/null | grep "sudo" | tail -1)
if [ -n "$PM2_STARTUP" ]; then
  eval "$PM2_STARTUP" &>/dev/null || true
fi

success "Fish Proxy is running with PM2"

# ── Get IP ────────────────────────────────────────────────────
step "Getting server address"
PUBLIC_IP=$(curl -s --max-time 5 https://api.ipify.org 2>/dev/null || echo "unknown")
if [[ "$OS" == "macos" ]]; then
  LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || echo "localhost")
else
  LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "localhost")
fi

# ── Done ──────────────────────────────────────────────────────
echo ""
echo -e "  ${GREEN}${BOLD}╔════════════════════════════════════════════╗${RESET}"
echo -e "  ${GREEN}${BOLD}║    Fish Proxy installed successfully!       ║${RESET}"
echo -e "  ${GREEN}${BOLD}╚════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${BOLD}Local URL:${RESET}   http://$LOCAL_IP:$PORT"
echo -e "  ${BOLD}Public URL:${RESET}  http://$PUBLIC_IP:$PORT"
echo ""
echo -e "  ${BOLD}Useful commands:${RESET}"
echo -e "  ${CYAN}pm2 status${RESET}             — check if Fish Proxy is running"
echo -e "  ${CYAN}pm2 logs fish-proxy${RESET}    — view live server logs"
echo -e "  ${CYAN}pm2 restart fish-proxy${RESET} — restart the server"
echo -e "  ${CYAN}pm2 stop fish-proxy${RESET}    — stop the server"
echo ""
echo -e "  ${YELLOW}Note:${RESET} Make sure port $PORT is open in your firewall/security group"
if [ "$AUTO_UPDATE" = true ]; then
  echo -e "  ${GREEN}Auto-updates: ON${RESET}  — Fish Proxy pulls latest code on every restart"
else
  echo -e "  ${YELLOW}Auto-updates: OFF${RESET} — to update manually: cd ~/fish-proxy && git pull && pnpm install && pm2 restart fish-proxy"
fi
if [ "$INSTALL_APP" = true ]; then
  echo -e "  ${YELLOW}Note:${RESET} Desktop app launches Fish Proxy on port 8080"
fi
echo ""
