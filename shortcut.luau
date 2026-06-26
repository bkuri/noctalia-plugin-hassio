-- shortcut.luau — control center tile

local function render()
    local connected = noctalia.state.get("connected") == true
    shortcut.setIcon("home")
    shortcut.setLabel(connected and "HA On" or "HA Off")
    shortcut.setActive(connected)
end

noctalia.state.watch("connected", function()
    render()
end)

render()

function onClick()
    -- ponytail: toggle is informational only; panel open goes here when supported
end
