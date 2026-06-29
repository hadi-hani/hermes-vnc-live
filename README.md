# hermes-vnc-live

A Docker container that runs **Chromium inside a virtual desktop** (VNC/noVNC), with **Chrome DevTools Protocol (CDP)** exposed so [Hermes AI agent](https://github.com/hadi-hani/hermes) can control the browser remotely.

> Built and battle-tested alongside Hermes. This is the exact setup used in production.

---

## What is this?

| Component | Role |
|-----------|------|
| **Xvfb** | Virtual screen (no physical monitor needed) |
| **Openbox** | Lightweight window manager |
| **Chromium** | The real browser Hermes controls |
| **x11vnc** | Streams the virtual screen over VNC |
| **noVNC** | Lets you watch/control the browser from any web browser |
| **socat** | Proxies CDP port so Hermes container can reach it |

---

## Architecture

```
┌──────────────────────────────────────────────────────┐
│                   Your VPS / Server                  │
│                                                      │
│  ┌─────────────────┐      ┌───────────────────────┐  │
│  │   hermes-vnc    │      │        hermes         │  │
│  │                 │      │   (AI agent + API)    │  │
│  │  Xvfb :99       │      │                       │  │
│  │  Openbox        │      │  cdp_url:             │  │
│  │  Chromium ──────┼──────┼► http://172.x.x.x:9224│  │
│  │  (CDP :9223)    │      │                       │  │
│  │  socat :9224 ◄──┘      └───────────────────────┘  │
│  │  x11vnc :5900   │                                  │
│  │  noVNC  :6080   │◄── You watch here in browser     │
│  └─────────────────┘                                  │
│                                                      │
│  Docker network: hermes_default                      │
└──────────────────────────────────────────────────────┘
```

---

## Prerequisites

- A Linux VPS (Ubuntu 22.04+ recommended)
- Docker + Docker Compose installed
- [Hermes](https://github.com/hadi-hani/hermes) already running (it creates the `hermes_default` Docker network)

---

## Setup Guide (Step by Step)

### Step 1 — Clone this repo

```bash
git clone https://github.com/hadi-hani/hermes-vnc-live.git /opt/hermes-vnc
cd /opt/hermes-vnc
```

### Step 2 — Create the persistent profile directory

This folder stores Chromium's cookies and sessions so you stay logged in across restarts:

```bash
mkdir -p /opt/data/chromium-profile
```

### Step 3 — Make sure the Hermes network exists

If Hermes is already running, its network exists. Verify:

```bash
docker network ls | grep hermes_default
```

If it doesn't exist yet, create it manually:

```bash
docker network create hermes_default
```

### Step 4 — Build and start

```bash
docker compose up -d --build
```

First build takes ~5 minutes (downloads ~300MB of packages). Subsequent builds use cache and take ~10 seconds.

### Step 5 — Verify it's running

```bash
# Check container status
docker ps | grep hermes-vnc

# Check logs
docker logs hermes-vnc --tail 20

# Open browser and go to:
http://YOUR_SERVER_IP:6080/vnc.html
```

You should see a dark blue desktop with Chromium open.

### Step 6 — Get the container IP (needed for Hermes config)

Chromium's CDP rejects hostname-based connections (DNS rebinding protection). You must use the container's IP:

```bash
docker inspect hermes-vnc --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
```

Example output: `172.22.0.3`

### Step 7 — Configure Hermes

In your Hermes `config.yaml`, set:

```yaml
browser:
  cdp_url: http://172.22.0.3:9224   # use the IP from Step 6
```

Then restart Hermes:

```bash
cd /opt/hermes && docker compose restart hermes
```

### Step 8 — Test CDP connection

From inside the Hermes container:

```bash
docker exec hermes sh -c 'curl -s http://172.22.0.3:9224/json/version'
```

Expected response:
```json
{
  "Browser": "Chrome/149.0.x.x",
  "webSocketDebuggerUrl": "ws://172.22.0.3:9224/devtools/browser/..."
}
```

If you see this — **everything is working!** ✅

---

## Persistent Login Sessions

Chromium's profile is stored at `/opt/data/chromium-profile` on your host (mapped into the container as `/chromium-profile`).

**How to save your logins:**
1. Open `http://YOUR_IP:6080/vnc.html` in your browser
2. Log in to any website (Google, Twitter, etc.) inside the VNC browser
3. Close the VNC tab — your session is saved permanently
4. Even after `docker compose restart`, you'll still be logged in ✅

**Why it works:** The startup script automatically removes Chromium's `SingletonLock` files, which prevents the "profile in use" error after restarts, while keeping all cookies and sessions intact.

---

## Updating the Container IP After Restart

Container IPs can change after a server reboot. Add this alias to your `~/.bashrc` to make updating easy:

```bash
alias hermes-vnc-ip='docker inspect hermes-vnc --format "{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}"'
```

Or use this one-liner to auto-update your Hermes config:

```bash
VNC_IP=$(docker inspect hermes-vnc --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
sed -i "s|cdp_url: http://.*:9224|cdp_url: http://$VNC_IP:9224|g" /opt/data/hermes/config.yaml
cd /opt/hermes && docker compose restart hermes
echo "Updated cdp_url to http://$VNC_IP:9224"
```

---

## Troubleshooting

### Chromium won't start — "profile in use"

```bash
rm -f /opt/data/chromium-profile/SingletonLock \
       /opt/data/chromium-profile/SingletonCookie \
       /opt/data/chromium-profile/SingletonSocket
docker compose restart
```

### CDP connection refused from Hermes

1. Check the container IP hasn't changed:
   ```bash
   docker inspect hermes-vnc --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
   ```
2. Update `cdp_url` in Hermes config with the new IP
3. Restart Hermes

### noVNC blank screen

```bash
docker logs hermes-vnc --tail 30
docker compose restart
```

### Port 6080 not accessible

Check your firewall:
```bash
# UFW
ufw allow 6080/tcp

# iptables
iptables -A INPUT -p tcp --dport 6080 -j ACCEPT
```

---

## File Structure

```
hermes-vnc-live/
├── Dockerfile          # Container definition
├── docker-compose.yml  # Service configuration with volume mounts
├── start.sh            # Startup script (Xvfb → Openbox → VNC → Chromium → socat)
├── menu.xml            # Openbox right-click menu
└── README.md           # This file
```

---

## How the CDP Proxy Works

Chromium listens on `127.0.0.1:9223` and rejects requests with non-IP `Host` headers (DNS rebinding protection). This means other containers can't connect using the hostname `hermes-vnc`.

**Solution:** `socat` listens on `0.0.0.0:9224` and forwards all traffic to `127.0.0.1:9223`. Hermes connects using the raw IP (`172.x.x.x:9224`), which Chromium accepts.

```
Hermes → http://172.x.x.x:9224 → socat → 127.0.0.1:9223 → Chromium
```

---

## License

MIT
