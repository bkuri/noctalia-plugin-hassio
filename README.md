# noctalia-plugin-hassio

Home Assistant plugin for Noctalia v5. Monitor and control HA entities from the bar.

## Architecture

```
service.luau ──runStream──→ ha-bridge.py ──WebSocket──→ hass.lan:8123
                                │
                                └─ NDJSON stdout → service parses → noctalia.state.*
                                                                     │
widget.luau ◄──────────────────────────────────────────────────────────┘
shortcut.luau ◄───────────────────────────────────────────────────────┘
panel.luau ◄──────────────────────────────────────────────────────────┘
```

## How it works

1. **`service.luau`** (headless) — spawns `ha-bridge.py` via `runStream`, reads NDJSON output, publishes entity state via `noctalia.state.set()`. Also calls HA REST API for toggle/fire-and-forget service calls.

2. **`ha-bridge.py`** — connects to HA WebSocket, authenticates, subscribes to `state_changed` events, fetches initial states via `get_states`. Outputs each message as one JSON line.

3. **`widget.luau`** — bar icon, watches `connected` state, shows home/check glyph.

4. **`shortcut.luau`** — control center tile, mirrors widget status.

5. **`panel.luau`** — entity browser with search and per-entity toggle switches. Uses value-driven `ui.toggle` with a single shared `onChange` handler (identifies toggled entity by comparing current vs new state).

## Dependencies

- `python-websockets` (installed)
- Home Assistant instance with long-lived access token

## Install

```bash
# Copy to local plugin dir
mkdir -p ~/.local/share/noctalia/plugins/noctalia/hassio
cp -r ~/source/org/noctalia-plugin-hassio/* ~/.local/share/noctalia/plugins/noctalia/hassio/

# Reload plugins in Noctalia, then enable "Home Assistant" in Settings → Plugins
```

Or add as a dev source for hot-reload:
```
# In Noctalia Settings → Plugins → Sources → Add path source
# Point to ~/source/org/noctalia/plugin-hassio
```

## Configure

**Settings → Plugins → Home Assistant** (gear icon):
- **Home Assistant URL**: `http://hass.lan:8123`
- **Long-lived access token**: generate at `Profile → Security → Long-lived access tokens`

## Files

| File | Lines | Purpose |
|---|---|---|
| `plugin.toml` | 46 | Manifest — entries, settings |
| `ha-bridge.py` | 54 | WS bridge — HA → NDJSON |
| `service.luau` | 89 | Headless — spawn bridge, publish state |
| `widget.luau` | 25 | Bar icon |
| `shortcut.luau` | 18 | CC tile |
| `panel.luau` | 138 | Entity browser |

## Known limitations

- **No brightness/color control** — only on/off toggle for now. v5 `ui.toggle` callbacks don't pass entity ID, making per-entity slider wiring awkward.
- **No pinned entities filter** — shows all entities with search. v4 had pinned-only view.
- **No reconnection in bridge** — if HA drops, the bridge exits and service re-spawns it on next `update()` tick.
