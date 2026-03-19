# Galaxy S20+ AI Data Center Node

Turn your Samsung Galaxy S20+ into a self-hosted AI server node using
open-source tools only. No cloud required.

## Stack

| Component | Tool | License |
|-----------|------|---------|
| Linux environment | [Termux](https://termux.dev) | GPL-3.0 |
| LLM runtime | [Ollama](https://ollama.com) | MIT |
| Web chat UI | [Open WebUI](https://github.com/open-webui/open-webui) | MIT |
| VPN | [WireGuard](https://wireguard.com) | GPL-2.0 |
| Session manager | tmux | ISC |
| Flipper auth | Custom (this repo) | MIT |

---

## Quick Start

### 1. Install Termux
Get it from **F-Droid** (not Play Store — Play Store version is outdated):
https://f-droid.org/packages/com.termux/

Also install from F-Droid:
- **Termux:Boot** — auto-start services on reboot
- **Termux:API** — NFC, notifications, sensors

### 2. Copy scripts to phone
On your PC:
```bash
adb push Phone-Server/ /sdcard/Phone-Server/
```
Then in Termux:
```bash
cp -r /sdcard/Phone-Server ~/
chmod +x ~/Phone-Server/**/*.sh
```

### 3. Run setup
```bash
bash ~/Phone-Server/setup.sh
```

### 4. Configure security
```bash
# SSH (run first)
bash ~/Phone-Server/security/ssh-hardening.sh

# Add your PC's public key so you can SSH in
echo "YOUR_PC_PUBLIC_KEY" >> ~/.ssh/authorized_keys

# WireGuard VPN (optional but recommended for remote access)
bash ~/Phone-Server/security/wireguard.sh
```

### 5. Pull an AI model
```bash
bash ~/Phone-Server/ai/pull-models.sh
```
Recommended for S20+ (8GB RAM): **phi3:mini** or **llama3.2:3b**

### 6. Start everything
```bash
bash ~/Phone-Server/start.sh
```

---

## Access Your Node

| Service | URL |
|---------|-----|
| Chat UI | `http://<phone-ip>:8080` |
| Ollama API | `http://<phone-ip>:11434` |
| SSH | `ssh -p 8022 <user>@<phone-ip>` |

Find your phone's IP in Termux:
```bash
ip route get 1.1.1.1 | grep -oP 'src \K\S+'
```

---

## Security Layers

1. **SSH** — key-based auth only, passwords disabled
2. **WireGuard** — encrypted VPN tunnel for remote access
3. **NFC port knock** — physical Flipper Zero / NFC tag required to unlock SSH
4. **Auth watcher** — alerts on repeated failed login attempts

---

## Flipper Zero Integration

See `flipper/README.md` for:
- NFC hardware key authentication
- BadUSB kill-switch payloads
- Sub-GHz wake signals

---

## Keep It Running 24/7

- Plug into a **USB-C hub with power pass-through**
- Disable battery optimization for Termux in Android Settings
- Set screen timeout to **Never** (or use `caffeine` in Termux)
- Enable **Termux:Boot** to restart services after reboots

---

## Hardware Tips for S20+

- The S20+ runs hot under sustained LLM load — keep it ventilated
- A small USB desk fan pointed at it helps a lot
- Do not use a wireless charger for 24/7 operation (use wired USB-C)
