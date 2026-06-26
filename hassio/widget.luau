-- widget.luau — bar icon showing HA connection status

noctalia.setUpdateInterval(10000)

local function render()
    local connected = noctalia.state.get("connected") == true
    if connected then
        barWidget.setGlyph("home")
        barWidget.setTooltip("Home Assistant — connected")
    else
        barWidget.setGlyph("home-question")
        barWidget.setTooltip("Home Assistant — disconnected")
    end
end

noctalia.state.watch("connected", function()
    render()
end)

render()

function onClick()
    -- Open the entities panel
    -- ponytail: panel open mechanism depends on v5 IPC — revisit when documented
end
