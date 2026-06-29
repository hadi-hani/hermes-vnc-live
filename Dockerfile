# ============================================================
# Hermes VNC Live — Browser Preview for Hermes AI Agent
# Free live noVNC + Playwright Chromium + XFCE on Docker
# ============================================================
FROM debian:bookworm-slim

# --- System dependencies ---
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    xvfb x11vnc novnc websockify \
    openbox \
    xfce4 xfce4-panel xfce4-taskmanager xfce4-terminal \
    xfwm4 xfdesktop4 \
    python3 python3-pip python3-aiohttp \
    dbus-x11 curl wget ca-certificates \
    fonts-liberation fonts-noto-color-emoji \
    && rm -rf /var/lib/apt/lists/*

# --- Playwright + Chromium ---
RUN pip3 install --break-system-packages playwright 2>/dev/null || pip3 install playwright
RUN playwright install chromium 2>/dev/null || true
RUN playwright install-deps chromium 2>/dev/null || true

# --- App scripts ---
COPY start.sh /start.sh
COPY cdp_proxy.py /cdp_proxy.py
COPY run_browser.py /run_browser.py
RUN chmod +x /start.sh

EXPOSE 5900 6080 9223
CMD ["/start.sh"]
