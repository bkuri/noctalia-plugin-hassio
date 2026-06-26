-- widget.luau — bar icon for HA connection status

local connected = false

noctalia.state.watch("connected", function(val)
    connected = val == true
    barWidget.setGlyph(connected and "circle-check" or "circle-xmark")
end)

-- Initial render
barWidget.setGlyph("circle-xmark")
