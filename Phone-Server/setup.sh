#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# Galaxy S20+ AI Data Center Node - Termux Setup
# Run this inside Termux after installing from F-Droid
# ============================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
fail() { echo -e "${RED}[x]${NC} $1"; exit 1; }

echo ""
echo "  ========================================"
echo "   Galaxy S20+ AI Node - Setup"
echo "  ========================================"
echo ""

# ── 1. Core packages ─────────────────────────────────────────
log "Updating package lists..."
pkg update -y && pkg upgrade -y

log "Installing core packages..."
pkg install -y \
    openssh \
    git \
    curl \
    wget \
    python \
    python-pip \
    nodejs \
    nano \
    termux-api \
    wireguard-tools \
    iproute2 \
    net-tools \
    htop \
    tmux

# ── 2. Python environment ─────────────────────────────────────
log "Setting up Python virtual environment..."
python -m venv "$HOME/ai-env"
source "$HOME/ai-env/bin/activate"

pip install --upgrade pip wheel setuptools

# ── 3. Ollama ─────────────────────────────────────────────────
log "Installing Ollama..."
if ! command -v ollama &>/dev/null; then
    pkg install -y ollama 2>/dev/null || {
        warn "pkg ollama not found, trying manual install..."
        curl -fsSL https://ollama.com/install.sh | sh 2>/dev/null || \
        warn "Ollama install script failed. Install manually from https://github.com/ollama/ollama/releases"
    }
else
    log "Ollama already installed."
fi

# ── 4. Open WebUI ─────────────────────────────────────────────
log "Installing Open WebUI (this may take a few minutes)..."
pip install open-webui 2>/dev/null || warn "Open WebUI install failed — try: pip install open-webui after setup"

# ── 5. SSH hardening ──────────────────────────────────────────
log "Configuring SSH server..."
bash "$HOME/Phone-Server/security/ssh-hardening.sh"

# ── 6. Termux:Boot auto-start ─────────────────────────────────
log "Setting up auto-start on boot..."
mkdir -p "$HOME/.termux/boot"
cp "$HOME/Phone-Server/start.sh" "$HOME/.termux/boot/start-services.sh"
chmod +x "$HOME/.termux/boot/start-services.sh"

# ── 7. Shell alias ────────────────────────────────────────────
log "Adding 'launch-server' alias..."
if ! grep -q "launch-server" "$HOME/.bashrc" 2>/dev/null; then
    echo "alias launch-server='bash ~/Phone-Server/start.sh'" >> "$HOME/.bashrc"
fi

# ── 8. Environment config ─────────────────────────────────────
log "Writing environment config..."
cat > "$HOME/.ai-node.env" <<EOF
# AI Node Environment Config
OLLAMA_HOST=0.0.0.0
OLLAMA_ORIGINS=app://obsidian.md*
OLLAMA_PORT=11434
WEBUI_PORT=8080
SSH_PORT=8022
WIREGUARD_PORT=51820
EOF

# ── 8. Copy cheat sheet to Obsidian vault ─────────────────────
VAULT="$HOME/storage/shared/Documents/Second Brain/Termux"
if [ -d "$HOME/storage/shared/Documents/Second Brain" ]; then
    mkdir -p "$VAULT"
    cp "$HOME/Phone-Server/S20-AI-Node-Cheatsheet.md" "$VAULT/S20-AI-Node-Cheatsheet.md"
    cp "$HOME/Phone-Server/S20-AI-Node-Overview.md" "$VAULT/S20-AI-Node-Overview.md"
    log "Notes copied to Obsidian vault → Termux/"
else
    warn "Obsidian vault not found at ~/storage/shared/Documents/Second Brain"
    warn "Run: termux-setup-storage  then re-run this script, or copy manually:"
    warn "  cp ~/Phone-Server/S20-AI-Node-Cheatsheet.md \"/storage/emulated/0/Documents/Second Brain/Termux/\""
fi

echo ""
log "Base setup complete!"
echo ""
echo "  Next steps:"
echo "  1. Run:  bash ~/Phone-Server/security/ssh-hardening.sh"
echo "  2. Run:  bash ~/Phone-Server/security/wireguard.sh"
echo "  3. Run:  bash ~/Phone-Server/ai/pull-models.sh"
echo "  4. Run:  bash ~/Phone-Server/start.sh"
echo ""
warn "Install Termux:Boot and Termux:API from F-Droid for full functionality"
