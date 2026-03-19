# S20 AI Node — Termux Cheat Sheet

## First-Time Setup (run once)
```bash
git clone https://github.com/ChorizoMuerte/Ubers-SD-Files ~/Ubers-SD-Files
cp -r ~/Ubers-SD-Files/Phone-Server ~/Phone-Server
bash ~/Phone-Server/setup.sh
```

> Install **Termux:Boot** and **Termux:API** from F-Droid for auto-start and full functionality.

---

## Daily Start (or auto on reboot via Termux:Boot)
```bash
bash ~/Phone-Server/start.sh
```

---

## Attach to Running Services
```bash
tmux attach -t ai-node
```

| Window | Key        | Service     |
|--------|------------|-------------|
| 0      | `Ctrl+B 0` | SSH server  |
| 1      | `Ctrl+B 1` | Ollama      |
| 2      | `Ctrl+B 2` | Open WebUI  |
| 3      | `Ctrl+B 3` | Security    |
| 4      | `Ctrl+B 4` | htop        |

Detach without stopping: `Ctrl+B D`

---

## Pull AI Models
```bash
bash ~/Phone-Server/ai/pull-models.sh
```

| Model             | Size   | Best For                  |
|-------------------|--------|---------------------------|
| `phi3:mini`       | 2.3 GB | Fast chat + code          |
| `llama3.2:3b`     | 2.0 GB | General purpose           |
| `gemma2:2b`       | 1.6 GB | Lightweight / efficient   |
| `mistral:7b-q4`   | 4.1 GB | Best quality (~6 GB RAM)  |
| `nomic-embed-text`| 274 MB | Obsidian Copilot indexing |

---

## Stop Everything
```bash
bash ~/Phone-Server/stop.sh
```

---

## Endpoints

### Tailscale (works from anywhere — no VPN setup needed)
| Service    | URL                                        |
|------------|--------------------------------------------|
| Ollama API | `http://100.70.218.84:11434`               |
| Open WebUI | `http://100.70.218.84:8080`                |
| SSH        | `ssh -p 8022 u0_a277@100.70.218.84`        |

> Tailscale must be **ON** on the phone (Tailscale app toggled Connected).

### Local Network (same WiFi only)
| Service    | URL                            |
|------------|--------------------------------|
| Ollama API | `http://<phone-local-ip>:11434` |
| Open WebUI | `http://<phone-local-ip>:8080`  |
| SSH        | `ssh -p 8022 u0_a277@<phone-local-ip>` |

Find local IP:
```bash
ip route get 1.1.1.1 | grep -oP 'src \K\S+'
```

---

## Obsidian Copilot Settings
- **Embedding Provider:** Ollama → `http://127.0.0.1:11434`
- **Model:** `nomic-embed-text`
- **Partitions:** 40
- **RAM Limit:** 100–200 MB
- **Disable indexing on mobile:** OFF

---

## Troubleshooting
| Problem                  | Fix                                                   |
|--------------------------|-------------------------------------------------------|
| "0 Documents Indexed"    | Command Palette → `Copilot: Force reindex vault`      |
| "Connection Refused"     | Restart Termux, then `bash ~/Phone-Server/start.sh`   |
| Slow / crashing          | Lower "Max Sources" to 3 in Copilot QA settings       |
| Phantom process killed   | Developer Options → Disable child process restrictions |

---

## Samsung Battery Fix (one-time)
1. Android Settings → Apps → Termux → Battery → **Unrestricted**
2. Tap the Termux notification → enable **Release wake lock**
3. Developer Options → **Disable child process restrictions** → ON
