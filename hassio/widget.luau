-- widget.luau — bar icon, click to open entity panel

noctalia.state.watch("connected", function(val)
    barWidget.setGlyph(val == true and "circle-check" or "circle-xmark")
end)

barWidget.setGlyph("circle-xmark")

function onClick()
    noctalia.runAsync("noctalia msg panel-toggle bkuri/hassio:entities", function(ok, out, err)
        -- ponytail: silent on failure, panel is best-effort
    end)
end
