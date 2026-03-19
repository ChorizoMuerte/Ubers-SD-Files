#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# WireGuard VPN Setup — secure remote access to your AI node
#
# This configures the S20+ as a WireGuard PEER (client).
# Your router/VPS acts as the server.
#
# For a self-hosted WireGuard server, see:
#   https://github.com/WireGuard/wireguard-tools
#   or run WireGuard on your home router (most support it)
# ============================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
log()  { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${CYAN}[i]${NC} $1"; }

WG_DIR="$HOME/wireguard"
WG_CONFIG="$WG_DIR/wg0.conf"

mkdir -p "$WG_DIR"
chmod 700 "$WG_DIR"

# ── Generate key pair ─────────────────────────────────────────
log "Generating WireGuard key pair..."
PRIVATE_KEY=$(wg genkey)
PUBLIC_KEY=$(echo "$PRIVATE_KEY" | wg pubkey)
PRESHARED_KEY=$(wg genpsk)

echo "$PRIVATE_KEY"    > "$WG_DIR/private.key"
echo "$PUBLIC_KEY"     > "$WG_DIR/public.key"
echo "$PRESHARED_KEY"  > "$WG_DIR/preshared.key"
chmod 600 "$WG_DIR/private.key" "$WG_DIR/preshared.key"

log "Keys generated."

# ── Prompt for server details ─────────────────────────────────
echo ""
info "You need a WireGuard SERVER endpoint. Options:"
echo "  A) Your home router (if it supports WireGuard — many do)"
echo "  B) A cheap VPS ($5/mo — Hetzner, DigitalOcean, etc.)"
echo "  C) Another machine on your LAN"
echo ""

read -r -p "  Enter your WireGuard server endpoint (host:port, e.g. myhome.ddns.net:51820): " WG_ENDPOINT
read -r -p "  Enter your WireGuard server's public key: " SERVER_PUBLIC_KEY
read -r -p "  Enter the VPN IP for this phone (e.g. 10.0.0.2/32): " PHONE_VPN_IP
read -r -p "  Enter the VPN IP range to route (e.g. 10.0.0.0/24 for LAN only, or 0.0.0.0/0 for all traffic): " ALLOWED_IPS
read -r -p "  Enter DNS server to use over VPN (e.g. 1.1.1.1 or your router IP): " WG_DNS

# ── Write config ──────────────────────────────────────────────
log "Writing WireGuard config..."
cat > "$WG_CONFIG" <<EOF
[Interface]
PrivateKey = $PRIVATE_KEY
Address = $PHONE_VPN_IP
DNS = $WG_DNS

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
PresharedKey = $PRESHARED_KEY
Endpoint = $WG_ENDPOINT
AllowedIPs = $ALLOWED_IPS

# Keep NAT hole open (important for mobile connections)
PersistentKeepalive = 25
EOF

chmod 600 "$WG_CONFIG"
log "Config written to $WG_CONFIG"

# ── Write start/stop helpers ───────────────────────────────────
cat > "$WG_DIR/up.sh" <<'UPEOF'
#!/data/data/com.termux/files/usr/bin/bash
wg-quick up "$HOME/wireguard/wg0.conf"
echo "[+] WireGuard VPN up"
UPEOF

cat > "$WG_DIR/down.sh" <<'DOWNEOF'
#!/data/data/com.termux/files/usr/bin/bash
wg-quick down "$HOME/wireguard/wg0.conf"
echo "[+] WireGuard VPN down"
DOWNEOF

chmod +x "$WG_DIR/up.sh" "$WG_DIR/down.sh"

# ── Print info for server-side config ─────────────────────────
echo ""
echo "  ══════════════════════════════════════════════════"
echo "   Add this PEER block to your WireGuard SERVER:"
echo "  ══════════════════════════════════════════════════"
echo ""
echo "  [Peer]"
echo "  # Galaxy S20+ AI Node"
echo "  PublicKey = $PUBLIC_KEY"
echo "  PresharedKey = $PRESHARED_KEY"
echo "  AllowedIPs = ${PHONE_VPN_IP%%/*}/32"
echo ""
echo "  ══════════════════════════════════════════════════"
echo ""
log "Save the PresharedKey — it won't be shown again."
echo ""
warn "Run VPN with:  bash ~/wireguard/up.sh"
warn "Stop VPN with: bash ~/wireguard/down.sh"
warn "Status:        wg show"
