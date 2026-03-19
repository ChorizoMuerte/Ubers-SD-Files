#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# SSH Hardening — key-based auth only, no passwords
# ============================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
log()  { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }

SSH_DIR="$HOME/.ssh"
SSHD_CONFIG="$PREFIX/etc/ssh/sshd_config"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# ── Generate host keys if missing ────────────────────────────
if [ ! -f "$PREFIX/etc/ssh/ssh_host_ed25519_key" ]; then
    log "Generating SSH host keys..."
    ssh-keygen -t ed25519 -f "$PREFIX/etc/ssh/ssh_host_ed25519_key" -N ""
fi

# ── Generate client key pair (for your use) ───────────────────
if [ ! -f "$SSH_DIR/id_ed25519" ]; then
    log "Generating your personal SSH key pair..."
    ssh-keygen -t ed25519 -f "$SSH_DIR/id_ed25519" -N "" \
        -C "ai-node-access-$(date +%Y%m%d)"
    log "Public key (add this to your devices' known_hosts):"
    cat "$SSH_DIR/id_ed25519.pub"
fi

touch "$SSH_DIR/authorized_keys"
chmod 600 "$SSH_DIR/authorized_keys"

# ── Write hardened sshd_config ────────────────────────────────
log "Writing hardened sshd_config..."
cat > "$SSHD_CONFIG" <<EOF
# AI Node - Hardened SSH Config

Port 8022
ListenAddress 0.0.0.0

# Host key (Ed25519 only — stronger than RSA)
HostKey $PREFIX/etc/ssh/ssh_host_ed25519_key

# Auth — keys only, no passwords
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
KbdInteractiveAuthentication no

# Restrict access
PermitRootLogin no
MaxAuthTries 3
MaxSessions 3
LoginGraceTime 20

# Keep sessions alive
ClientAliveInterval 60
ClientAliveCountMax 3

# Disable unused features
X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding yes
PermitTunnel no
PrintMotd no

# Logging
SyslogFacility AUTH
LogLevel VERBOSE
EOF

log "sshd_config written."

# ── Fail attempt counter (simple brute-force protection) ──────
log "Installing simple login attempt monitor..."
cat > "$HOME/Phone-Server/security/watch-auth.sh" <<'WATCHEOF'
#!/data/data/com.termux/files/usr/bin/bash
# Watches SSH auth log and alerts on repeated failures
LOGFILE="$HOME/logs/auth.log"
mkdir -p "$HOME/logs"
echo "[$(date)] Auth watcher started" >> "$LOGFILE"

while true; do
    # Count failed attempts in the last 5 minutes (basic brute-force watch)
    FAILS=$(logcat -d -t 300 2>/dev/null | grep -c "Failed" || echo 0)
    if [ "$FAILS" -gt 5 ]; then
        echo "[$(date)] WARNING: $FAILS failed SSH attempts detected" >> "$LOGFILE"
        # Optional: termux-notification if Termux:API installed
        termux-notification \
            --title "AI Node Security Alert" \
            --content "$FAILS failed login attempts detected" \
            2>/dev/null || true
    fi
    sleep 300
done
WATCHEOF
chmod +x "$HOME/Phone-Server/security/watch-auth.sh"

# ── Print your public key for setup ───────────────────────────
echo ""
log "SSH hardening complete."
echo ""
echo "  ── Your node's public key ────────────────────────────"
cat "$SSH_DIR/id_ed25519.pub"
echo "  ──────────────────────────────────────────────────────"
echo ""
warn "IMPORTANT: To connect from your PC/Mac, add your PC's public key:"
echo "  echo 'YOUR_PC_PUBLIC_KEY' >> ~/.ssh/authorized_keys"
echo ""
warn "Start SSH server with:  sshd"
warn "Connect from PC with:   ssh -p 8022 $(whoami)@<phone-ip>"
