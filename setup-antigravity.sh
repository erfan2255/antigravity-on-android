#!/bin/bash
#
# Google Antigravity 2.0 on Android - Masterclass Installer
# Supports: Tiny Container (APK) & Termux (PRoot Debian)
# Architecture: ARM64 & x86_64
#
set -e

# --- Color Definitions ---
C_BLUE='\033[1;34m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_CYAN='\033[1;36m'
C_RED='\033[1;31m'
C_RESET='\033[0m'

clear
echo -e "${C_CYAN}"
cat << "EOF"
    ___          __  _                         _ __         
   /   |  ____  / /_(_)___ __________ __   __(_) /___  __  
  / /| | / __ \/ __/ / __ `/ ___/ __ `/ | / / / __/ / / /  
 / ___ |/ / / / /_/ / /_/ / /  / /_/ /| |/ / / /_/ /_/ /   
/_/  |_/_/ /_/\__/_/\__, /_/   \__,_/ |___/_/\__/\__, /    
                   /____/                       /____/     
              Google Antigravity 2.0 on Android
EOF
echo -e "${C_RESET}"

# Check for root/sudo
if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
else
    SUDO=""
fi

# Detect Architecture
ARCH=$(uname -m)
echo -e "Detected Architecture: ${C_YELLOW}$ARCH${C_RESET}"
if [ "$ARCH" != "aarch64" ] && [ "$ARCH" != "arm64" ] && [ "$ARCH" != "x86_64" ]; then
    echo -e "${C_RED}Error: Architecture $ARCH is not supported. Required: ARM64 or x86_64.${C_RESET}"
    exit 1
fi

# Detect Environment
IS_TINY_CONTAINER=false
if [ -d "/mnt/sdcard" ] || [ -f "/etc/tiny_container" ]; then
    IS_TINY_CONTAINER=true
    echo -e "Environment: ${C_GREEN}Tiny Container (Native All-in-One Linux)${C_RESET}"
    STORAGE_DIR="/mnt/sdcard"
else
    echo -e "Environment: ${C_GREEN}Debian Linux / Termux PRoot${C_RESET}"
    STORAGE_DIR="/sdcard"
fi

# --- [1/4] Install Prerequisites ---
echo -e "\n${C_BLUE}>>> [1/4] Installing Required System Libraries...${C_RESET}"
$SUDO mkdir -p /etc/dpkg/dpkg.cfg.d /etc/apt/apt.conf.d
$SUDO bash -c "echo 'force-unsafe-io' > /etc/dpkg/dpkg.cfg.d/02apt-speedup" 2>/dev/null || true
$SUDO bash -c "echo 'Acquire::Languages \"none\";' > /etc/apt/apt.conf.d/99speedup" 2>/dev/null || true

$SUDO apt-get update
$SUDO apt-get install -y curl wget tar jq zenity file xdg-utils libnss3 libsecret-1-0 libx11-xcb1 libgbm1 libasound2t64 libasound2 fonts-noto-core fonts-vazirmatn || true

# --- [2/4] Download & Extract Antigravity 2.0 ---
echo -e "\n${C_BLUE}>>> [2/4] Downloading Google Antigravity 2.0...${C_RESET}"
$SUDO mkdir -p /opt/antigravity

if [ "$ARCH" == "aarch64" ] || [ "$ARCH" == "arm64" ]; then
    DOWNLOAD_URL="https://storage.googleapis.com/antigravity-public/antigravity-hub/2.8.1-6512087774658560/linux-arm/Antigravity.tar.gz"
else
    DOWNLOAD_URL="https://storage.googleapis.com/antigravity-public/antigravity-hub/2.8.1-6512087774658560/linux-x64/Antigravity.tar.gz"
fi

echo "Fetching archive from: $DOWNLOAD_URL"
curl -fsSL "$DOWNLOAD_URL" | $SUDO tar -xz -C /opt/antigravity --strip-components=1

# Create CLI / terminal wrapper
cat << 'EOF' | $SUDO tee /usr/local/bin/antigravity > /dev/null
#!/bin/bash
export ELECTRON_DISABLE_SECURITY_WARNINGS=true
exec /opt/antigravity/antigravity --no-sandbox "$@"
EOF
$SUDO chmod +x /usr/local/bin/antigravity

# --- [3/4] Desktop Launcher & System Integration ---
echo -e "\n${C_BLUE}>>> [3/4] Creating Desktop & Menu Shortcuts...${C_RESET}"
$SUDO mkdir -p /usr/share/applications

cat << 'EOF' | $SUDO tee /usr/share/applications/antigravity.desktop > /dev/null
[Desktop Entry]
Version=1.0
Type=Application
Name=Google Antigravity 2.0
Comment=AI-Powered Agentic IDE
Exec=/usr/local/bin/antigravity %F
Icon=/opt/antigravity/resources/app/resources/linux/code.png
Terminal=false
Categories=Development;IDE;
StartupNotify=true
EOF
$SUDO chmod +x /usr/share/applications/antigravity.desktop

# Place on current user Desktop
USER_DESKTOP="$HOME/Desktop"
if [ -d "$USER_DESKTOP" ]; then
    cp /usr/share/applications/antigravity.desktop "$USER_DESKTOP/Antigravity_2.0.desktop" 2>/dev/null || true
    chmod +x "$USER_DESKTOP/Antigravity_2.0.desktop" 2>/dev/null || true
fi

# Also place on /home/* user desktops if running as root
for udir in /home/*; do
    if [ -d "$udir/Desktop" ]; then
        cp /usr/share/applications/antigravity.desktop "$udir/Desktop/Antigravity_2.0.desktop" 2>/dev/null || true
        chmod +x "$udir/Desktop/Antigravity_2.0.desktop" 2>/dev/null || true
        chown $(stat -c '%U:%G' "$udir") "$udir/Desktop/Antigravity_2.0.desktop" 2>/dev/null || true
    fi
done

# --- [4/4] Optional AI Add-ons & Conversation Sync Helper ---
echo -e "\n${C_BLUE}>>> [4/4] Setting Up Conversation Sync Helper & CLI Tools...${C_RESET}"

# Conversation Sync Helper
cat << EOF | $SUDO tee /usr/local/bin/sync-antigravity > /dev/null
#!/bin/bash
echo "=== Antigravity Conversation Sync Helper ==="
if [ -d "$STORAGE_DIR/Download/.gemini" ]; then
    echo "Found .gemini folder in Android Downloads! Syncing..."
    mkdir -p \$HOME/.gemini
    cp -rf "$STORAGE_DIR/Download/.gemini/"* \$HOME/.gemini/
    echo "SUCCESS: Conversations and history imported successfully!"
elif [ -d "$STORAGE_DIR/Download/brain" ]; then
    echo "Found brain folder in Android Downloads! Syncing..."
    mkdir -p \$HOME/.gemini/antigravity/brain
    cp -rf "$STORAGE_DIR/Download/brain/"* \$HOME/.gemini/antigravity/brain/
    echo "SUCCESS: Conversations imported successfully!"
else
    echo "No .gemini or brain folder found in $STORAGE_DIR/Download."
    echo "To sync: Copy your PC's C:\\Users\\<User>\\.gemini folder to your phone's Download folder, then re-run 'sync-antigravity'."
fi
EOF
$SUDO chmod +x /usr/local/bin/sync-antigravity

# Install Antigravity CLI (agy)
echo "Installing Node.js & Antigravity CLI (agy)..."
$SUDO apt-get install -y nodejs npm python3 python3-pip python3-venv > /dev/null 2>&1 || true
$SUDO npm install -g @google/antigravity-cli > /dev/null 2>&1 || $SUDO npm install -g antigravity > /dev/null 2>&1 || true

echo ""
echo -e "${C_GREEN}==============================================================${C_RESET}"
echo -e "${C_GREEN}   🎉 Google Antigravity 2.0 is Successfully Installed!       ${C_RESET}"
echo -e "${C_GREEN}==============================================================${C_RESET}"
echo -e "You can launch Antigravity in two ways:"
echo -e "  1. 🖱️  ${C_CYAN}Desktop Icon:${C_RESET} Double-click the 'Google Antigravity 2.0' icon on your desktop."
echo -e "  2. 💻  ${C_CYAN}Terminal:${C_RESET}     Type '${C_YELLOW}antigravity${C_RESET}' in terminal to launch GUI."
echo -e "  3. 🤖  ${C_CYAN}CLI Agent:${C_RESET}    Type '${C_YELLOW}agy${C_RESET}' for command-line agent."
echo -e "  4. 🔄  ${C_CYAN}Sync Chats:${C_RESET}   Type '${C_YELLOW}sync-antigravity${C_RESET}' to import PC chats."
echo ""
