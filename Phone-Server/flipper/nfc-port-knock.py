#!/usr/bin/env python3
"""
NFC Port Knock — Flipper Zero / NFC Hardware Auth for AI Node
=============================================================
Run this on the S20+ in Termux.
Requires: Termux:API (from F-Droid) + termux-api package

How it works:
  1. Polls for NFC tag scans via termux-nfc
  2. If the scanned UID matches an authorized tag → opens SSH port
     in iptables for 60 seconds (port knock)
  3. Logs all attempts

Usage:
  python3 nfc-port-knock.py --add-key       # Register a new NFC tag
  python3 nfc-port-knock.py                 # Run the listener

Security note:
  This pairs best with WireGuard (so the port knock only works from
  inside your VPN) or as a second factor alongside SSH keys.
"""

import subprocess
import json
import hashlib
import time
import argparse
import os
import logging
from datetime import datetime
from pathlib import Path

# ── Config ────────────────────────────────────────────────────
CONFIG_DIR  = Path.home() / ".ai-node-auth"
KEYS_FILE   = CONFIG_DIR / "authorized_nfc.json"
LOG_FILE    = CONFIG_DIR / "nfc-auth.log"
OPEN_PORT   = 8022        # SSH port to temporarily open
OPEN_SECS   = 60          # How long to keep port open after tap
POLL_SECS   = 1           # How often to check for NFC

CONFIG_DIR.mkdir(mode=0o700, exist_ok=True)

logging.basicConfig(
    filename=LOG_FILE,
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
log = logging.getLogger("nfc-knock")

# ── Key store ─────────────────────────────────────────────────
def load_keys() -> dict:
    if KEYS_FILE.exists():
        with open(KEYS_FILE) as f:
            return json.load(f)
    return {}

def save_keys(keys: dict):
    KEYS_FILE.parent.mkdir(mode=0o700, exist_ok=True)
    with open(KEYS_FILE, "w") as f:
        json.dump(keys, f, indent=2)
    os.chmod(KEYS_FILE, 0o600)

def hash_uid(uid: str) -> str:
    """Store a hash of the UID, not the raw value."""
    return hashlib.sha256(uid.strip().upper().encode()).hexdigest()

# ── NFC scan via Termux:API ───────────────────────────────────
def scan_nfc() -> str | None:
    """
    Returns the NFC tag UID if a tag is present, else None.
    Requires: termux-nfc-read command from Termux:API.
    """
    try:
        result = subprocess.run(
            ["termux-nfc-read"],
            capture_output=True, text=True, timeout=2
        )
        if result.returncode != 0 or not result.stdout.strip():
            return None
        data = json.loads(result.stdout)
        return data.get("id")  # Tag UID
    except (subprocess.TimeoutExpired, json.JSONDecodeError, FileNotFoundError):
        return None

# ── Firewall (iptables) port open/close ───────────────────────
def open_port(port: int):
    """Temporarily allow traffic on the SSH port."""
    subprocess.run(
        ["iptables", "-I", "INPUT", "-p", "tcp", "--dport", str(port),
         "-j", "ACCEPT"],
        capture_output=True
    )
    log.info("Port %d opened", port)

def close_port(port: int):
    """Remove the temporary allow rule."""
    subprocess.run(
        ["iptables", "-D", "INPUT", "-p", "tcp", "--dport", str(port),
         "-j", "ACCEPT"],
        capture_output=True
    )
    log.info("Port %d closed", port)

def notify(title: str, msg: str):
    """Push a notification via Termux:API (optional)."""
    subprocess.run(
        ["termux-notification", "--title", title, "--content", msg],
        capture_output=True
    )

# ── Main listener ─────────────────────────────────────────────
def run_listener():
    keys = load_keys()
    if not keys:
        print("No authorized NFC keys registered.")
        print("Run with --add-key to register your Flipper/NFC tag.")
        return

    print(f"NFC port-knock listener running. Port {OPEN_PORT} is locked.")
    print(f"Tap an authorized NFC tag to open SSH for {OPEN_SECS}s.")
    print("Ctrl+C to stop.\n")

    port_open_until = 0

    while True:
        uid = scan_nfc()

        if uid:
            uid_hash = hash_uid(uid)
            if uid_hash in keys:
                label = keys[uid_hash].get("label", "unknown")
                log.info("Authorized tag: %s (label: %s)", uid_hash[:12], label)
                print(f"[{datetime.now():%H:%M:%S}] Authorized: {label}")

                if time.time() < port_open_until:
                    # Already open — extend the window
                    port_open_until = time.time() + OPEN_SECS
                else:
                    open_port(OPEN_PORT)
                    notify("AI Node", f"SSH unlocked for {OPEN_SECS}s ({label})")
                    port_open_until = time.time() + OPEN_SECS
            else:
                log.warning("Unauthorized tag UID hash: %s", uid_hash[:12])
                print(f"[{datetime.now():%H:%M:%S}] DENIED: unknown tag")
                notify("AI Node Security", "Unauthorized NFC tag detected")

        # Close port when timer expires
        if port_open_until and time.time() >= port_open_until:
            close_port(OPEN_PORT)
            port_open_until = 0
            print(f"[{datetime.now():%H:%M:%S}] Port {OPEN_PORT} locked.")

        time.sleep(POLL_SECS)

# ── Register a new key ────────────────────────────────────────
def add_key():
    print("Hold your Flipper Zero or NFC tag near the phone...")
    print("Waiting for NFC scan (10 seconds)...")

    uid = None
    for _ in range(10):
        uid = scan_nfc()
        if uid:
            break
        time.sleep(1)

    if not uid:
        print("No NFC tag detected. Make sure Termux:API is installed and NFC is on.")
        return

    label = input(f"Tag detected (UID: {uid}). Enter a label for this key: ").strip()
    if not label:
        label = f"key-{datetime.now():%Y%m%d%H%M%S}"

    keys = load_keys()
    uid_hash = hash_uid(uid)
    keys[uid_hash] = {"label": label, "added": datetime.now().isoformat()}
    save_keys(keys)

    print(f"\nKey registered: '{label}'")
    print(f"UID hash stored: {uid_hash[:16]}...")
    print(f"Keys file: {KEYS_FILE}")
    log.info("New key registered: label=%s hash=%s", label, uid_hash[:12])

# ── Entry point ───────────────────────────────────────────────
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="NFC Port Knock for AI Node")
    parser.add_argument("--add-key", action="store_true",
                        help="Register a new authorized NFC tag")
    args = parser.parse_args()

    if args.add_key:
        add_key()
    else:
        run_listener()
