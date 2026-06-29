#!/bin/bash
set -e

# -------------------------------------------------------
# Remove stale Chromium singleton lock files.
# These are left behind when the container stops uncleanly
# and would prevent Chromium from starting next time.
# -------------------------------------------------------
rm -f /chromium-profile/SingletonLock \
       /chromium-profile/SingletonCookie \
       /chromium-profile/SingletonSocket

# Start virtual display (invisible screen inside the container)
Xvfb :99 -screen 0 1280x800x24 -ac &
export DISPLAY=:99
sleep 1

# Start Openbox window manager
openbox &
sleep 1

# Dark blue background
xsetroot -solid "#1e3a5f" &

# Start taskbar
tint2 &

# Start VNC server (no password — secure behind your firewall/SSH tunnel)
x11vnc -display :99 -rfbport 5900 -nopw \
       -forever -shared -noxdamage -quiet &
sleep 1

# Start noVNC: converts VNC to WebSocket so you can use a browser
websockify --web /usr/share/novnc/ 6080 localhost:5900 &
sleep 1

# -------------------------------------------------------
# Launch Chromium
#   --user-data-dir  → persistent profile (cookies, sessions survive restarts)
#   --remote-debugging-port → enables CDP on port 9223 (localhost only)
#   --remote-debugging-address=0.0.0.0 → socat will proxy it out on 9224
# -------------------------------------------------------
chromium \
  --no-sandbox \
  --disable-gpu \
  --disable-dev-shm-usage \
  --display=:99 \
  --window-size=1280,800 \
  --start-maximized \
  --remote-debugging-port=9223 \
  --remote-debugging-address=0.0.0.0 \
  --user-data-dir=/chromium-profile \
  http://hermes:9119 &

sleep 3

# -------------------------------------------------------
# socat proxy: exposes CDP to other Docker containers
#
# Chromium CDP responds to requests only when the Host header
# is an IP address. Since Docker container names (hostnames)
# are rejected, we proxy 9224 → 127.0.0.1:9223 so Hermes
# can connect via the container IP directly.
# -------------------------------------------------------
socat TCP-LISTEN:9224,fork,reuseaddr TCP:127.0.0.1:9223 &

echo "================================================"
echo " hermes-vnc started successfully!"
echo " noVNC (browser): http://YOUR_SERVER_IP:6080/vnc.html"
echo " CDP (for Hermes): port 9224 on container IP"
echo "================================================"

# Keep container running
wait
