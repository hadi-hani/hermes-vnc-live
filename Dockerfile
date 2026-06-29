FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install all required packages
RUN apt-get update && apt-get install -y \
    chromium \
    x11vnc \
    xvfb \
    novnc \
    websockify \
    openbox \
    xterm \
    curl \
    procps \
    x11-xserver-utils \
    tint2 \
    socat \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user (optional, Chromium runs as root with --no-sandbox)
RUN useradd -m -s /bin/bash vnc \
    && mkdir -p /home/vnc/.vnc \
    && chown -R vnc:vnc /home/vnc/.vnc

# Openbox right-click menu
RUN mkdir -p /etc/xdg/openbox
COPY menu.xml /etc/xdg/openbox/menu.xml

# Startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Ports:
#   5900 - VNC
#   6080 - noVNC (web browser access)
#   9223 - Chromium CDP (internal)
#   9224 - socat CDP proxy (accessible from other containers)
EXPOSE 5900 6080 9224

CMD ["/start.sh"]
