# Ubers-SD-Files — Claude Context

## What This Repo Is
Flipper Zero SD card content + a Galaxy S20+ AI home server setup called the **AI Node**.

The two main areas:
- `Phone-Server/` — everything for the S20+ Termux AI data center
- Everything else — Flipper Zero payloads (BadUSB, Sub-GHz, NFC, RFID, IR, etc.)

---

## Phone-Server — S20+ AI Node

### Hardware
- Device: Samsung Galaxy S20+ (8 GB RAM, Android)
- Environment: Termux (Linux shell on Android, installed from F-Droid)

### What it runs
| Service      | Port  | Description                          |
|--------------|-------|--------------------------------------|
| SSH (sshd)   | 8022  | Key-based auth only, Ed25519         |
| Ollama       | 11434 | Local LLM inference engine           |
| Open WebUI   | 8080  | Browser-based chat UI for Ollama     |
| WireGuard    | 51820 | VPN (optional, if configured)        |

### Key paths (on the phone, inside Termux)
```
~/Phone-Server/          ← main server directory
~/Phone-Server/start.sh  ← starts all services in tmux
~/Phone-Server/stop.sh   ← kills all services
~/Phone-Server/setup.sh  ← first-time install script
~/Phone-Server/ai/pull-models.sh      ← interactive model downloader
~/Phone-Server/security/ssh-hardening.sh
~/Phone-Server/security/wireguard.sh
~/Phone-Server/security/watch-auth.sh ← brute-force monitor (auto-generated)
~/Phone-Server/chat-ui/server.py      ← lightweight Python chat proxy
~/.ai-node.env           ← env config (ports, Ollama settings)
```

### One-command startup
```bash
launch-server
```
This is a bash alias (written to `~/.bashrc` by `setup.sh`) that calls `bash ~/Phone-Server/start.sh`.
If not recognized: `source ~/.bashrc` or run `bash ~/Phone-Server/start.sh` directly.

### tmux session
All services run inside a single tmux session named `ai-node`:
```bash
tmux attach -t ai-node   # attach
# Ctrl+B D               # detach without stopping
# Ctrl+B [0-4]           # switch windows
```

| Window | Name     | Service           |
|--------|----------|-------------------|
| 0      | ssh      | SSH server        |
| 1      | ollama   | Ollama LLM server |
| 2      | webui    | Open WebUI        |
| 3      | security | Auth watcher      |
| 4      | monitor  | htop              |

### Network access
- **Tailscale (anywhere):** `100.70.218.84`
- **Local WiFi:** dynamic, check with `ip route get 1.1.1.1 | grep -oP 'src \K\S+'`
- SSH user: `u0_a277`

### AI Models (Ollama)
| Model              | Size    | Use case                        |
|--------------------|---------|---------------------------------|
| `phi3:mini`        | 2.3 GB  | Fast chat + code                |
| `llama3.2:3b`      | 2.0 GB  | General purpose                 |
| `gemma2:2b`        | 1.6 GB  | Lightweight                     |
| `mistral:7b-q4`    | 4.1 GB  | Best quality (~6 GB RAM needed) |
| `nomic-embed-text` | 274 MB  | Embeddings — Obsidian Copilot   |

### Obsidian Copilot integration
- Embedding provider: Ollama → `http://127.0.0.1:11434` (on-phone) or `http://100.70.218.84:11434` (remote)
- Model: `nomic-embed-text`
- The cheat sheet is auto-copied to: `Documents/Second Brain/Termux/S20-AI-Node-Cheatsheet.md`

### Auto-start on reboot
`setup.sh` copies `start.sh` → `~/.termux/boot/start-services.sh`.
Requires **Termux:Boot** app installed from F-Droid.

### SSH security
- Key-based only (no passwords), Ed25519
- Port 8022
- Max 3 auth tries, 20s grace period
- `watch-auth.sh` monitors for brute-force attempts and sends Termux:API notifications

---

## Flipper Zero SD Structure
```
BadUSB/      — HID/keyboard injection payloads
Sub-GHz/     — RF signal files (ceiling fans, garage doors, remotes, etc.)
NFC/         — NFC card dumps and Amiibo files
RFID/        — Low-frequency RFID files
Infrared/    — IR remote files
Music_Player/— Flipper music files
```

---

## Common Tasks
- "update the server setup" → edit `Phone-Server/setup.sh`
- "add a new service" → edit `Phone-Server/start.sh`
- "change ports" → edit `Phone-Server/setup.sh` env config block and `start.sh`
- "update cheat sheet" → edit `Phone-Server/S20-AI-Node-Cheatsheet.md`
- "add a model" → edit `Phone-Server/ai/pull-models.sh`
- Working branch: `claude/phone-data-center-setup-YaaUX`
