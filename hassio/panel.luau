-- panel.luau — entity browser with toggle buttons
--
-- ponytail: v5 callbacks must be string-named globals, not closures.
-- We can't dynamically generate onToggle_light_living_room etc.
-- Solution: one global toggle handler, track which entity via a
-- state key that the service sets, or simpler — just fire the HA
-- REST call directly from the click handler.
--
-- Problem: onClick = "onToggleClick" passes no arguments.
-- We use ui.button wrapping per-row, and track pending entity via
-- a table built during render. The last render's button map tells us
-- which button maps to which entity.
--
-- Actually the simplest approach: build the toggle as a ui.button
-- with a glyph, and for each entity generate a small wrapper script
-- at init time? No — we can't dynamically define globals.
--
-- REAL solution: render a list of entity rows, each row has one
-- ui.toggle in value-driven mode. onChange fires with the new value.
-- Since all toggles share one onChange, we need to figure out WHICH
-- toggle changed. We do this by comparing the new value against
-- each entity's current state — the one that doesn't match is the
-- one that was toggled.

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

-- Single onChange handler for all toggles.
-- value = "true" or "false". We find the entity whose current state
-- doesn't match the received value.
function onToggleChanged(value)
    local newOn = value == "true"
    local ids = getEntities()
    for _, id in ipairs(ids) do
        local ent = noctalia.state.get("entity:" .. id)
        if ent then
            local currentlyOn = ent.state ~= "off" and ent.state ~= "unavailable"
            if currentlyOn ~= newOn then
                -- This is the entity that was toggled
                local domain = ent.domain or "homeassistant"
                local service = newOn and "turn_on" or "turn_off"
                local haUrl = getConfig("haUrl")
                local haToken = getConfig("haToken")
                noctalia.http({
                    url = haUrl .. "/api/services/" .. domain .. "/" .. service,
                    method = "POST",
                    headers = {
                        ["Authorization"] = "Bearer " .. haToken,
                        ["Content-Type"] = "application/json",
                    },
                    body = json.encode({ entity_id = id }),
                }, nil)
                break  -- only one toggle can change at a time
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
