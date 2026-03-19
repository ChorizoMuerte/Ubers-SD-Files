#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# AI Node — Stop All Services
# ============================================================

GREEN='\033[0;32m'
NC='\033[0m'
log() { echo -e "${GREEN}[+]${NC} $1"; }

log "Stopping AI node services..."

# Stop tmux session (kills all windows/processes inside)
tmux kill-session -t ai-node 2>/dev/null && log "Stopped tmux session" || echo "  (no session running)"

# Kill individual processes if they escaped tmux
pkill -x ollama   2>/dev/null && log "Stopped Ollama"    || true
pkill -f open-webui 2>/dev/null && log "Stopped Open WebUI" || true
pkill -x sshd     2>/dev/null && log "Stopped SSH server" || true

# Stop WireGuard if running
wg show wg0 &>/dev/null && wg-quick down "$HOME/wireguard/wg0.conf" && log "Stopped WireGuard" || true

log "All services stopped."
