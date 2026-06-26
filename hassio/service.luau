-- service.luau — headless HA bridge. Spawns ha-bridge.py, publishes state.

local haUrl = noctalia.getConfig("haUrl") or ""
local haToken = noctalia.getConfig("haToken") or ""
local bridge = nil

local function entity_key(id) return "entity:" .. id end

local function summarize(new_state)
    if not new_state then return nil end
    local attrs = new_state.attributes or {}
    local eid = new_state.entity_id or ""
    local domain = eid:match("^(%w+)") or ""
    return {
        entity_id = eid,
        friendly_name = attrs.friendly_name or eid,
        state = new_state.state or "",
        domain = domain,
        unit = attrs.unit_of_measurement or "",
        brightness = attrs.brightness or -1,
        supports_brightness = attrs.supported_color_modes and true or false,
    }
end

local function startBridge()
    if haUrl == "" or haToken == "" then
        noctalia.state.set("connected", false)
        noctalia.log("ha: not configured")
        return
    end

    local dir = pluginDir()
    local cmd = string.format("python3 %s/ha-bridge.py '%s' '%s'", dir, haUrl, haToken)

    bridge = noctalia.runStream(cmd, function(line)
        if not line or line == "" then return end
        local ok, evt = pcall(json.decode, line)
        if not ok or not evt then return end

        if evt.type == "connected" then
            noctalia.state.set("connected", true)
            noctalia.log("ha: connected")

        elseif evt.type == "auth_failed" then
            noctalia.state.set("connected", false)
            noctalia.log("ha: auth failed")

        elseif evt.type == "error" then
            noctalia.state.set("connected", false)
            noctalia.log("ha: " .. (evt.msg or "error"))

        elseif evt.type == "event" then
            local data = evt.data
            if data and data.entity_id then
                local s = summarize(data.new_state)
                if s then noctalia.state.set(entity_key(data.entity_id), s) end
            end

        elseif evt.type == "result" then
            if evt.success and evt.result then
                local ids = {}
                for _, s in ipairs(evt.result) do
                    noctalia.state.set(entity_key(s.entity_id), summarize(s))
                    ids[#ids + 1] = s.entity_id
                end
                noctalia.state.set("entities:all", ids)
                noctalia.log("ha: " .. #ids .. " entities")
            end
        end
    end)
end

noctalia.state.set("connected", false)
startBridge()

-- ponytail: re-spawn bridge on settings change
function update()
    local u = noctalia.getConfig("haUrl") or ""
    local t = noctalia.getConfig("haToken") or ""
    if u ~= haUrl or t ~= haToken then
        haUrl = u
        haToken = t
        startBridge()
    end
end
