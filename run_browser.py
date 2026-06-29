#!/usr/bin/env python3
"""
run_browser.py
Launches a headed Playwright Chromium instance with remote debugging.
Hermes AI Agent connects via CDP on port 9222 (proxied to 9223).
"""
import asyncio
import os

os.environ.setdefault('DISPLAY', ':99')

async def main():
    from playwright.async_api import async_playwright
    async with async_playwright() as p:
        browser = await p.chromium.launch(
            headless=False,
            args=[
                "--no-sandbox",
                "--disable-dev-shm-usage",
                "--disable-gpu",
                "--window-size=1280,800",
                "--window-position=0,0",
                "--remote-debugging-port=9222",
                "--remote-debugging-address=0.0.0.0",
                "--no-first-run",
                "--disable-infobars",
                "--disable-translate",
                "--disable-features=TranslateUI",
                "--disable-session-crashed-bubble",
                "--password-store=basic",
            ]
        )
        # Open a blank page so the window is visible immediately
        context = await browser.new_context(viewport={"width": 1280, "height": 800})
        page = await context.new_page()
        await page.goto("about:blank")
        print("Playwright Chromium ready - window visible", flush=True)
        # Keep running indefinitely
        await asyncio.sleep(86400 * 30)

if __name__ == '__main__':
    asyncio.run(main())
