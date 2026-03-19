# Flipper Zero Integration

Ideas for wiring your Flipper Zero into the AI node.

---

## 1. NFC Hardware Key (Authentication)

Use an NFC tag or your Flipper to authenticate to the AI node.

**Concept:**
- Write a unique UID to an NFC tag using your Flipper
- Run a small Python listener on the S20+ (via Termux + Termux:NFC)
- Only allow SSH/WebUI access after NFC tap is detected

**Flow:**
```
Tap Flipper/NFC tag → Phone reads UID → Match found → Open firewall port for 60s → SSH in
```

This is a form of **port knocking** — the port isn't open until physical authentication happens.

See: `flipper/nfc-port-knock.py`

---

## 2. Sub-GHz Wake Signal

Use Flipper's Sub-GHz radio to send a wake signal to the phone
(via a USB-connected microcontroller or SDR receiver).

**Use case:** Wake the AI node from a low-power state remotely
without using the internet.

---

## 3. BadUSB — Automated Admin Scripts

Plug the Flipper into the S20+ via USB-C OTG.
Use BadUSB payloads to:
- Trigger service restarts
- Run diagnostics
- Emergency shutdown

Example payload location: `../BadUSB/`

**Tip:** Write a custom payload that types:
```
bash ~/Phone-Server/stop.sh
```
...as a quick physical kill-switch.

---

## 4. RFID Access Log

Use Flipper to read RFID/NFC badges and log them via the AI node
(turn your phone into a smart access logger).

---

## Hardware Shopping List

| Item | Purpose |
|------|---------|
| USB-C OTG adapter | Connect Flipper to phone |
| USB-C hub with power pass-through | Keep phone charged while connected |
| Anker 90W USB-C charger | Keep node running 24/7 |
| NFC stickers (NTAG215) | Hardware auth tags |
| Small fan | Keep phone cool under load |
