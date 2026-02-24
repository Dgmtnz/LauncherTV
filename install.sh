#!/bin/bash
set -e

INSTALL_DIR="/opt/LauncherTV"
DESKTOP_FILE="/usr/share/applications/launchertv.desktop"
BIN_LINK="/usr/local/bin/launchertv"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }

if [ "$EUID" -ne 0 ]; then
    error "Run with sudo:  sudo ./install.sh"
fi

REAL_USER="${SUDO_USER:-$USER}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── Uninstall ─────────────────────────────────────────────────
if [ "$1" = "--uninstall" ]; then
    echo ""
    info "Uninstalling LauncherTV..."
    rm -rf "$INSTALL_DIR"
    rm -f "$BIN_LINK"
    rm -f "$DESKTOP_FILE"
    rm -f "/home/${REAL_USER}/.config/autostart/launchertv.desktop"
    info "Removed. User config in ~/.config/LauncherTV/ kept."
    echo ""
    exit 0
fi

# ── Install ───────────────────────────────────────────────────
echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║       LauncherTV  —  Installer       ║"
echo "  ╚══════════════════════════════════════╝"
echo ""

info "Checking dependencies..."
DEPS=(pyside6 xorg-xprop xorg-xinput xorg-xmodmap)
MISSING=()
for pkg in "${DEPS[@]}"; do
    pacman -Qi "$pkg" &>/dev/null || MISSING+=("$pkg")
done

if [ ${#MISSING[@]} -gt 0 ]; then
    warn "Installing: ${MISSING[*]}"
    pacman -S --noconfirm --needed "${MISSING[@]}"
fi
info "Dependencies OK."

info "Installing to ${INSTALL_DIR}..."
mkdir -p "$INSTALL_DIR"
cp -r "$SCRIPT_DIR/backend" "$SCRIPT_DIR/qml" "$SCRIPT_DIR/main.py" "$INSTALL_DIR/"
touch "$INSTALL_DIR/backend/__init__.py"
chmod +x "$INSTALL_DIR/main.py"

cat > "$BIN_LINK" << 'EOF'
#!/bin/bash
exec python3 /opt/LauncherTV/main.py "$@"
EOF
chmod +x "$BIN_LINK"
info "Command 'launchertv' installed."

cat > "$DESKTOP_FILE" << 'EOF'
[Desktop Entry]
Type=Application
Name=LauncherTV
Comment=Android TV-style launcher for Linux
Exec=launchertv
Icon=preferences-desktop
Terminal=false
Categories=System;
StartupWMClass=LauncherTV
Keywords=launcher;tv;home;
EOF
info "Desktop entry created."

mkdir -p "/home/${REAL_USER}/.config/LauncherTV"
chown -R "${REAL_USER}:${REAL_USER}" "/home/${REAL_USER}/.config/LauncherTV"

echo ""
info "Done! Run with: launchertv"
echo "  Uninstall:  sudo $0 --uninstall"
echo ""
