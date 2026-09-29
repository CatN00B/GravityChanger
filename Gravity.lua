local function setGravity(g)
    local p = memory_read("uintptr_t", workspace.Address + 0x400)
    memory_write("float", p + 0x22c, g)
end

local target, autoApply = 100.0, true
local lastApplied = nil

local PRESETS = {
    {"Earth (100)", 100.0}, {"Moon (16.6)", 16.6}, {"Mars (37.8)", 37.8},
    {"Jupiter (247.9)", 247.9}, {"Zero-G (0)", 0.0},
    {"Inverted (-10)", -10.0}, {"Hyper (999)", 999.0},
}

task.spawn(function()
    while true do
        if autoApply and lastApplied ~= target then
            setGravity(target)
            lastApplied = target
            print("[Gravity] Auto-applied:", target)
        end
        wait(0.25)
    end
end)

local CFG = "gravity_config.json"

local function saveConfig()
    local data = string.format('{"gravity":%.2f,"autoApply":%s}', target, tostring(autoApply))
    writefile(CFG, data)
    print("[Gravity] Saved:", data)
end

local function loadConfig()
    if not isfile(CFG) then
        print("[Gravity] No config found, using defaults")
        return
    end
    local ok, raw = pcall(readfile, CFG)
    if not ok then
        print("[Gravity] Failed to read config")
        return
    end
    local g = raw:match('"gravity":([%-%d%.]+)')
    local a = raw:match('"autoApply":(%a+)')
    target = tonumber(g) or target
    autoApply = (a == "true")
    print("[Gravity] Loaded. gravity =", target, "autoApply =", autoApply)
end

UI.AddTab("Gravity Changer+", function(tab)
    local L = tab:Section("Gravity Settings", "Left")

    L:SliderFloat("grav_value", "Gravity", -500, 500, target, "%.1f",
        function(v)
            target = v
            if autoApply then
                setGravity(target)
                lastApplied = target
            end
        end)

    L:Toggle("grav_auto", "Auto-Apply", autoApply, function(v)
        autoApply = v
        print("[Gravity] Auto-Apply:", v)
        if v then
            setGravity(target)
            lastApplied = target
        else
            lastApplied = nil
        end
    end)

    L:Button("Apply Now", 140, 24, function()
        setGravity(target)
        lastApplied = target
        print("[Gravity] Applied:", target)
    end)

    local items = {}
    for _, p in ipairs(PRESETS) do table.insert(items, p[1]) end

    L:Combo("grav_preset", "Presets", items, 0, function(i)
        target = PRESETS[i + 1][2]
        UI.SetValue("grav_value", target)
        setGravity(target)
        lastApplied = target
        print("[Gravity] Preset:", PRESETS[i + 1][1], "=", target)
    end)

    local R = tab:Section("Config", "Right")
    R:Text("Save / Load")
    R:Button("Save", 140, 24, saveConfig)
    R:Button("Load", 140, 24, function()
        loadConfig()
        UI.SetValue("grav_value", target)
        setGravity(target)
        lastApplied = target
    end)
end)

loadConfig()