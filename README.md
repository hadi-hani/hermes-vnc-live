# 🤖 Hermes VNC Live — Free Live Browser Preview

> **Watch your Hermes AI Agent browse the web in real-time — completely free, self-hosted.**

![noVNC Preview](https://img.shields.io/badge/noVNC-Live%20Preview-blue?style=flat-square)
![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?style=flat-square&logo=docker)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)
![Free](https://img.shields.io/badge/Cost-100%25%20Free-brightgreen?style=flat-square)

---

## 🎯 What is this?

This project gives [Hermes AI Agent](https://github.com/hadi-hani/hermes) a **live visual browser** you can watch from any browser — no paid services, no subscriptions, no cloud fees.

When Hermes is given a task (e.g. via Telegram), you can open a URL and **watch it navigate, click, and type in real-time**.

---

## ✨ Features

- 🌐 **Live browser preview** — watch Hermes browse in real-time via noVNC
- 🖱️ **Full mouse & keyboard support** — interact manually if needed
- 🗂️ **XFCE taskbar** — see all open windows and apps
- 🔌 **CDP proxy** — Hermes connects via Chrome DevTools Protocol
- 🐳 **Single Docker container** — easy to deploy anywhere
- 💰 **100% free** — runs on any VPS or spare machine
- 🔄 **Auto-restart** — recovers automatically if the container crashes

---

## 📋 Requirements

- A Linux server (VPS, dedicated, or local machine)
- Docker & Docker Compose installed
- Hermes AI Agent already running
- Open ports: `6080` (noVNC), `9223` (CDP), `5900` (VNC optional)

---

## 🚀 Quick Start (Step by Step)

### Step 1 — Clone this repository

```bash
git clone https://github.com/hadi-hani/hermes-vnc-live.git
cd hermes-vnc-live
```

### Step 2 — Set your server IP

Edit `docker-compose.yml` and replace `YOUR_SERVER_IP` with your actual server IP:

```yaml
environment:
  - PROXY_HOST=123.456.78.90:9223
```

### Step 3 — Create the Docker network (if not exists)

```bash
docker network create hermes_net
```

> ⚠️ The network name must match what Hermes agent uses. Change it in `docker-compose.yml` if needed.

### Step 4 — Build and run

```bash
docker compose up -d --build
```

First build takes ~5 minutes (downloads Chromium ~177MB). Subsequent builds are cached and take seconds.

### Step 5 — Open the live preview

Open your browser and go to:

```
http://YOUR_SERVER_IP:6080/vnc.html
```

You will see the **XFCE desktop with Chromium already open** — ready to be controlled by Hermes!

---

## ⚙️ Configure Hermes Agent

In your Hermes `config.yaml`, set the CDP URL to point to this container:

```yaml
browser:
  cdp_url: 'http://CONTAINER_IP:9223'
```

To get the container's IP:

```bash
docker inspect hermes-vnc --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
```

Then restart Hermes:

```bash
docker restart hermes
```

---

## 📁 Project Structure

```
hermes-vnc-live/
├── Dockerfile          # Container definition
├── docker-compose.yml  # Easy deployment config
├── start.sh            # Startup script (Xvfb → XFCE → VNC → Chromium)
├── run_browser.py      # Playwright Chromium launcher
├── cdp_proxy.py        # CDP HTTP proxy (port 9222 → 9223)
└── README.md           # This file
```

---

## 🔧 How It Works

```
[Telegram] → [Hermes Agent] → [CDP Proxy :9223] → [Chromium :9222]
                                                          ↓
                                              [Xvfb Virtual Display]
                                                          ↓
                                              [x11vnc VNC Server :5900]
                                                          ↓
                                              [websockify :6080]
                                                          ↓
                                          [You watching at /vnc.html] 👁️
```

1. **Xvfb** creates a virtual display (no physical monitor needed)
2. **XFCE4** provides a full desktop environment with taskbar
3. **Playwright Chromium** opens headed in that virtual display
4. **x11vnc** captures the virtual display and streams it via VNC
5. **websockify + noVNC** converts VNC to WebSocket so any browser can view it
6. **cdp_proxy** rewrites internal CDP URLs so Hermes can connect from outside the container

---

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| Black screen on noVNC | Wait 10-15 seconds after starting, XFCE takes time to load |
| Click/keyboard not working | Ensure you're using this image (includes `-pointer_mode 2` fix) |
| Hermes can't connect to browser | Check `cdp_url` in Hermes config matches container IP |
| Container keeps restarting | Run `docker logs hermes-vnc` to see the error |
| Port 6080 not accessible | Check your firewall: `ufw allow 6080` |

---

## 🔒 Security Note

This setup has **no VNC password** by default — suitable for private/internal networks. For public servers, consider:
- Setting a VNC password (`-rfbauth` in x11vnc)
- Using a reverse proxy with HTTPS (nginx + Let's Encrypt)
- Restricting port 6080 to trusted IPs only

---

## 📜 License

MIT — free to use, modify, and distribute.

---

## 🙏 Credits

Built as part of the [Hermes AI Agent](https://github.com/hadi-hani/hermes) project.

Stack: [noVNC](https://novnc.com) · [Playwright](https://playwright.dev) · [x11vnc](https://github.com/LibVNC/x11vnc) · [XFCE](https://xfce.org) · [Docker](https://docker.com)
