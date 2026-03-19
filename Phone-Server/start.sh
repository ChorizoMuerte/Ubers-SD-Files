#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# AI Node — Start All Services
# Runs inside tmux so each service has its own window
# ============================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
log()  { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }

SESSION="ai-node"

# Source env config
[ -f "$HOME/.ai-node.env" ] && source "$HOME/.ai-node.env"

OLLAMA_PORT="${OLLAMA_PORT:-11434}"
WEBUI_PORT="${WEBUI_PORT:-8080}"

# Kill existing session if running
tmux kill-session -t "$SESSION" 2>/dev/null || true
sleep 1

log "Starting AI node services in tmux session '$SESSION'..."

# ── Window 0: SSH Server ───────────────────────────────────────
tmux new-session -d -s "$SESSION" -n "ssh"
tmux send-keys -t "$SESSION:ssh" "echo '[+] Starting SSH server...' && sshd && echo '[+] SSH running on port 8022'" Enter

# ── Window 1: Ollama ──────────────────────────────────────────
tmux new-window -t "$SESSION" -n "ollama"
tmux send-keys -t "$SESSION:ollama" \
    "echo '[+] Starting Ollama on port $OLLAMA_PORT...' && OLLAMA_HOST=0.0.0.0 OLLAMA_ORIGINS=\"app://obsidian.md*\" ollama serve" Enter

sleep 2  # Let Ollama initialize

# ── Window 2: Chat UI ─────────────────────────────────────────
tmux new-window -t "$SESSION" -n "webui"
tmux send-keys -t "$SESSION:webui" \
    "echo '[+] Starting Chat UI on port $WEBUI_PORT...' && python $HOME/Phone-Server/chat-ui/server.py" Enter

# ── Window 3: Auth watcher ────────────────────────────────────
if [ -f "$HOME/Phone-Server/security/watch-auth.sh" ]; then
    tmux new-window -t "$SESSION" -n "security"
    tmux send-keys -t "$SESSION:security" \
        "bash $HOME/Phone-Server/security/watch-auth.sh" Enter
fi

# ── Window 4: Monitor ─────────────────────────────────────────
tmux new-window -t "$SESSION" -n "monitor"
tmux send-keys -t "$SESSION:monitor" "htop" Enter

# ── Back to window 0 ──────────────────────────────────────────
tmux select-window -t "$SESSION:ssh"

echo ""
log "All services started."
echo ""

# Get local IP
LOCAL_IP=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' || echo "<phone-ip>")

echo "  ┌─────────────────────────────────────────────────┐"
echo "  │  AI Node Endpoints                              │"
echo "  ├─────────────────────────────────────────────────┤"
printf "  │  SSH        ssh -p 8022 $(whoami)@%-18s │\n" "$LOCAL_IP"
printf "  │  Ollama API http://%-28s │\n" "$LOCAL_IP:$OLLAMA_PORT"
printf "  │  Web UI     http://%-28s │\n" "$LOCAL_IP:$WEBUI_PORT"
echo "  └─────────────────────────────────────────────────┘"
echo ""
echo "  Attach to services:  tmux attach -t $SESSION"
echo "  Switch windows:      Ctrl+B then number (0-4)"
echo ""
warn "Keep the phone plugged in and screen timeout disabled for 24/7 operation"
