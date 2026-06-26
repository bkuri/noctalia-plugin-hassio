-- panel.luau — minimal test
function onOpen(context)
    panel.render(ui.column({ gap = 8 }, {
        ui.label({ text = "HA Panel" }),
    }))
end
