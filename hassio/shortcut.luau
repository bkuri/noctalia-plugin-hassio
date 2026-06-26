-- shortcut.luau — control center tile

local connected = false

noctalia.state.watch("connected", function(val)
    connected = val == true
    shortcut.setActive(connected)
    shortcut.setLabel(connected and "HA on" or "HA off")
end)

shortcut.setLabel("HA off")
