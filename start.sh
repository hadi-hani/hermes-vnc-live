#!/bin/bash
# ============================================================
# start.sh — Launches XFCE + VNC + noVNC + Playwright Chromium
# ============================================================
set -e

# Cleanup old X locks
rm -f /tmp/.X*-lock
rm -rf /tmp/.X11-unix && mkdir -p /tmp/.X11-unix && chmod 1777 /tmp/.X11-unix

# 1) Xvfb — Virtual display
Xvfb :99 -screen 0 1280x800x24 -ac +extension GLX +render -noreset &
export DISPLAY=:99
sleep 2

# 2) dbus — Required by XFCE
export DBUS_SESSION_BUS_ADDRESS=$(dbus-daemon --session --fork --print-address 2>/dev/null)
sleep 1

# 3) XFCE4 — Full desktop with taskbar
startxfce4 &
sleep 4

# 4) x11vnc — VNC server with click/keyboard fix
x11vnc -display :99 -rfbport 5900 -nopw -forever -shared \
       -noxdamage -quiet -bg \
       -pointer_mode 2 -cursor arrow
sleep 1

# 5) websockify — noVNC web interface
websockify --web=/usr/share/novnc 6080 localhost:5900 &
sleep 1

# 6) Playwright Chromium — Headed browser
python3 /run_browser.py &
sleep 5

# 7) CDP Proxy — Allows Hermes agent to connect
python3 /cdp_proxy.py &

echo "========================================"
echo " noVNC: http://0.0.0.0:6080/vnc.html"
echo " CDP:   ws://0.0.0.0:9223"
echo "========================================"

wait
