-- panel.luau — entity browser with toggle controls

local search = ""

function onOpen(context)
    render()
end

local function getEntities()
    local all = noctalia.state.get("entities:all")
    if not all then return {} end
    if search == "" then return all end
    local out = {}
    for _, id in ipairs(all) do
        local ent = noctalia.state.get("entity:" .. id)
        if ent then
            local name = ent.friendly_name or id
            if name:lower():find(search:lower(), 1, true) or id:lower():find(search:lower(), 1, true) then
                out[#out + 1] = id
            end
        end
    end
    return out
end

function onSearchChanged(value)
    search = value
    render()
end

-- ponytail: ui.toggle onChange only passes value, not entity id.
-- Find the entity whose current state doesn't match — that's the one toggled.
function onToggleChanged(value)
    local newOn = value == "true"
    local ids = getEntities()
    for _, id in ipairs(ids) do
        local ent = noctalia.state.get("entity:" .. id)
        if ent then
            local currentlyOn = ent.state ~= "off" and ent.state ~= "unavailable"
            if currentlyOn ~= newOn then
                local domain = ent.domain or "homeassistant"
                local service = newOn and "turn_on" or "turn_off"
                local haUrl = noctalia.getConfig("haUrl") or ""
                local haToken = noctalia.getConfig("haToken") or ""
                noctalia.http({
                    url = haUrl .. "/api/services/" .. domain .. "/" .. service,
                    method = "POST",
                    headers = {
                        ["Authorization"] = "Bearer " .. haToken,
                        ["Content-Type"] = "application/json",
                    },
                    body = json.encode({ entity_id = id }),
                }, nil)
                break
            end
        end
    end
end

function render()
    local ids = getEntities()
    local rows = {}

    for _, id in ipairs(ids) do
        local ent = noctalia.state.get("entity:" .. id)
        if ent then
            local isOn = ent.state ~= "off" and ent.state ~= "unavailable"
            rows[#rows + 1] = ui.row(
                { gap = 8, align = "center", padding = 6, key = id },
                {
                    ui.label({
                        text = ent.friendly_name or id,
                        color = "on-surface",
                        flexGrow = 1,
                    }),
                    ui.label({
                        text = ent.state .. (ent.unit ~= "" and " " .. ent.unit or ""),
                        color = "on-surface-variant",
                    }),
                    ui.toggle({
                        checked = isOn,
                        onChange = "onToggleChanged",
                    }),
                }
            )
        end
    end

    if #rows == 0 then
        rows[#rows + 1] = ui.label({
            text = search ~= "" and "No entities match" or "Loading entities...",
            color = "on-surface-variant",
            textAlign = "center",
        })
    end

    panel.render(
        ui.column(
            { gap = 4, padding = 8, fill = true },
            {
                ui.input({
                    key = "search",
                    value = search,
                    placeholder = "Search entities...",
                    onChange = "onSearchChanged",
                }),
                ui.scroll(
                    { fill = true },
                    ui.column({ gap = 2 }, rows)
                ),
            }
        )
    )
end
