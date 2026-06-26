#!/usr/bin/env python3
"""HA → Noctalia bridge. Connects to HA websocket, prints state_changed as NDJSON."""

import asyncio
import json
import sys
import websockets
from websockets.asyncio.client import connect

async def main():
    if len(sys.argv) < 3:
        print(json.dumps({"type": "error", "msg": "usage: ha-bridge.py <url> <token>"}))
        sys.exit(1)

    url = sys.argv[1].rstrip("/")
    token = sys.argv[2]

    ws_url = url.replace("http://", "ws://").replace("https://", "wss://") + "/api/websocket"

    # ponytail: no retry/backoff — if HA is down the plugin respawns us
    try:
        async with connect(ws_url, close_timeout=1) as ws:
            # auth
            await ws.send(json.dumps({"type": "auth", "access_token": token}))
            msg = json.loads(await asyncio.wait_for(ws.recv(), timeout=10))
            if msg.get("type") != "auth_ok":
                print(json.dumps({"type": "auth_failed", "msg": msg.get("message", "unknown")}))
                return

            print(json.dumps({"type": "connected"}), flush=True)

            # subscribe to all state changes
            await ws.send(json.dumps({"id": 1, "type": "subscribe_events", "event_type": "state_changed"}))

            # get initial states — response comes as event_type: "result"
            await ws.send(json.dumps({"id": 2, "type": "get_states"}))

            async for raw in ws:
                line = raw.strip()
                if not line:
                    continue
                try:
                    evt = json.loads(line)
                    # pass all events through; service.luau filters
                    print(json.dumps(evt), flush=True)
                except json.JSONDecodeError:
                    pass
    except asyncio.TimeoutError:
        print(json.dumps({"type": "error", "msg": "connection timeout"}), flush=True)
    except Exception as e:
        print(json.dumps({"type": "error", "msg": str(e)}), flush=True)

if __name__ == "__main__":
    asyncio.run(main())
