#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# Pull AI models via Ollama — optimized for S20+ (8GB RAM)
#
# Recommended models for this hardware:
#   phi3:mini       — 2.3GB, very fast, great for code/chat
#   llama3.2:3b     — 2.0GB, good general purpose
#   gemma2:2b       — 1.6GB, lightweight Google model
#   mistral:7b-q4   — 4.1GB, best quality that fits in RAM
#
# Do NOT run multiple large models at once.
# ============================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
log()  { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${CYAN}[i]${NC} $1"; }

# Ensure Ollama is running
if ! pgrep -x ollama &>/dev/null; then
    log "Starting Ollama server..."
    ollama serve &>/dev/null &
    sleep 3
fi

echo ""
echo "  Select models to pull (recommended for S20+ 8GB RAM):"
echo ""
echo "  1) phi3:mini      (~2.3GB)  — Fast, good code + chat"
echo "  2) llama3.2:3b    (~2.0GB)  — Good general purpose"
echo "  3) gemma2:2b      (~1.6GB)  — Lightweight, efficient"
echo "  4) mistral:7b-q4  (~4.1GB)  — Best quality, uses ~6GB RAM"
echo "  5) nomic-embed-text (~274MB) — Text embeddings (for RAG)"
echo "  6) All recommended (phi3:mini + nomic-embed-text)"
echo "  7) Custom model name"
echo ""
read -r -p "  Enter choice [1-7]: " CHOICE

pull_model() {
    log "Pulling $1..."
    ollama pull "$1"
    log "$1 ready."
}

case $CHOICE in
    1) pull_model "phi3:mini" ;;
    2) pull_model "llama3.2:3b" ;;
    3) pull_model "gemma2:2b" ;;
    4) pull_model "mistral:7b-q4_0" ;;
    5) pull_model "nomic-embed-text" ;;
    6)
        pull_model "phi3:mini"
        pull_model "nomic-embed-text"
        ;;
    7)
        read -r -p "  Enter model name (e.g. llama3.2:1b): " CUSTOM
        pull_model "$CUSTOM"
        ;;
    *)
        warn "Invalid choice. Pulling phi3:mini as default."
        pull_model "phi3:mini"
        ;;
esac

echo ""
log "Installed models:"
ollama list
echo ""
info "Test a model:  ollama run phi3:mini"
info "API endpoint:  http://localhost:11434/api/chat"
