#!/usr/bin/env python3
"""
cdp_proxy.py
A lightweight HTTP proxy that rewrites CDP WebSocket URLs.
Exposes port 9223 externally, proxying to Chromium's internal port 9222.
This allows Hermes agent to connect using the container's external IP.
"""
import asyncio
import json
import os
import aiohttp
from aiohttp import web

CHROME_HOST = "localhost"
CHROME_PORT = 9222
PROXY_PORT  = 9223
# Public IP/hostname for this container (set via env or auto-detected)
PROXY_HOST  = os.environ.get("PROXY_HOST", f"0.0.0.0:{PROXY_PORT}")


async def rewrite_json(data: bytes) -> bytes:
    """Replace internal ws://localhost:9222 URLs with external proxy URL."""
    try:
        items = json.loads(data)
        text = json.dumps(items)
        text = text.replace(
            f"localhost:{CHROME_PORT}",
            PROXY_HOST
        )
        return text.encode()
    except Exception:
        return data


async def proxy_handler(request: web.Request) -> web.Response:
    path = request.rel_url
    target = f"http://{CHROME_HOST}:{CHROME_PORT}{path}"
    async with aiohttp.ClientSession() as session:
        async with session.get(target) as resp:
            body = await resp.read()
            body = await rewrite_json(body)
            return web.Response(
                body=body,
                status=resp.status,
                content_type="application/json"
            )


async def main():
    app = web.Application()
    app.router.add_route("GET", "/{path_info:.*}", proxy_handler)
    runner = web.AppRunner(app)
    await runner.setup()
    site = web.TCPSite(runner, "0.0.0.0", PROXY_PORT)
    await site.start()
    print(f"CDP proxy :{PROXY_PORT} -> http://{CHROME_HOST}:{CHROME_PORT} [PROXY_HOST={PROXY_HOST}]")
    await asyncio.Event().wait()


if __name__ == "__main__":
    asyncio.run(main())
