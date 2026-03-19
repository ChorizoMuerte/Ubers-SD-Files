# S20+ AI Node — System Overview

> **MOC** (Map of Content) for the Galaxy S20+ home AI server.
> See also: [[S20-AI-Node-Cheatsheet]] for quick commands.

---

## What Is This?

My Galaxy S20+ runs as a 24/7 AI data center node using **Termux** (a Linux shell on Android). It hosts local AI models, a web chat interface, and an SSH server — all accessible from anywhere via Tailscale or on the local network.

**Why the S20+?**
- 8 GB RAM — enough to run 7B parameter models
- Always plugged in
- No monthly cloud fees
- Private — models run locally, nothing leaves the house

---

## Architecture

```
┌─────────────────────────────────────────────┐
│              Galaxy S20+                    │
│                                             │
│  Termux (Linux shell)                       │
│  └── tmux session: "ai-node"                │
│       ├── Window 0: SSH server (port 8022)  │
│       ├── Window 1: Ollama (port 11434)     │
│       ├── Window 2: Open WebUI (port 8080)  │
│       ├── Window 3: Auth watcher            │
│       └── Window 4: htop (monitor)          │
│                                             │
│  Tailscale IP: 100.70.218.84                │
└─────────────────────────────────────────────┘
         │                    │
   Obsidian Copilot      Browser / SSH
   (embeddings)          from any device
```

---

## Services

### Ollama — Local LLM Engine
- Runs AI models entirely on-device
- API endpoint: `http://100.70.218.84:11434`
- Models stored on SD card / internal storage

### Open WebUI — Chat Interface
- Browser-based ChatGPT-style interface
- URL: `http://100.70.218.84:8080`
- Connects to Ollama on the backend

### SSH Server
- Port: `8022` (non-standard to avoid conflicts)
- Auth: Ed25519 keys only, no passwords
- Connect: `ssh -p 8022 u0_a277@100.70.218.84`

---

## AI Models Available

| Model              | Size    | Best For                        |
|--------------------|---------|---------------------------------|
| `phi3:mini`        | 2.3 GB  | Fast chat, code                 |
| `llama3.2:3b`      | 2.0 GB  | General purpose                 |
| `gemma2:2b`        | 1.6 GB  | Lightweight tasks               |
| `mistral:7b-q4`    | 4.1 GB  | Highest quality (needs ~6 GB)   |
| `nomic-embed-text` | 274 MB  | Vault embeddings (Copilot)      |

> Only run one large model at a time — 8 GB RAM is shared with Android.

---

## Obsidian Copilot Integration

This node powers **local AI in Obsidian** — no OpenAI key needed.

**Settings:**
- Plugin: Obsidian Copilot
- Embedding provider: `Ollama`
- Base URL: `http://127.0.0.1:11434` (if on-phone) or `http://100.70.218.84:11434` (from desktop)
- Embedding model: `nomic-embed-text`
- Partitions: 40
- RAM limit: 100–200 MB

**To reindex vault:** Command Palette → `Copilot: Force reindex vault`

---

## Network Access

### Tailscale (works anywhere, no port forwarding needed)
| Service    | Address                              |
|------------|--------------------------------------|
| Ollama API | `http://100.70.218.84:11434`         |
| Web Chat   | `http://100.70.218.84:8080`          |
| SSH        | `ssh -p 8022 u0_a277@100.70.218.84`  |

### Local WiFi (same network only)
Find phone IP: open Termux and run `ip route get 1.1.1.1 | grep -oP 'src \K\S+'`

---

## File Structure (on phone)

```
~/Phone-Server/
├── setup.sh              ← First-time install (run once)
├── start.sh              ← Start all services → alias: launch-server
├── stop.sh               ← Stop all services
├── ai/
│   └── pull-models.sh    ← Interactive model downloader
├── security/
│   ├── ssh-hardening.sh  ← Hardens SSH config, generates keys
│   ├── wireguard.sh      ← WireGuard VPN setup
│   └── watch-auth.sh     ← Brute-force login monitor (auto-generated)
├── chat-ui/
│   └── server.py         ← Lightweight chat proxy
└── S20-AI-Node-Cheatsheet.md
```

Source repo: `~/Ubers-SD-Files/Phone-Server/` (cloned from GitHub)

---

## Starting the Server

```bash
launch-server
```

That's it. All services start inside a tmux session called `ai-node`.

To watch what's happening:
```bash
tmux attach -t ai-node
```

Auto-starts on phone reboot via **Termux:Boot** (installed from F-Droid).

---

## Samsung-Specific Setup (required once)

| Setting | Where | Value |
|---|---|---|
| Battery | Settings → Apps → Termux → Battery | Unrestricted |
| Wake lock | Termux notification | Enable "Release wake lock" |
| Child processes | Developer Options | Disable child process restrictions → ON |

Without these, Android will kill Termux in the background.

---

## Related Notes
- [[S20-AI-Node-Cheatsheet]] — Quick command reference
- [[Obsidian Copilot Setup]] — AI search across vault
- [[Flipper Zero SD Files]] — The rest of the Ubers-SD-Files repo

---

## Tags
#homelab #ai #termux #android #ollama #self-hosted #phone-server
