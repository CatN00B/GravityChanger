local function setGravity(g)
    local p = memory_read("uintptr_t", workspace.Address + 0x400)
    memory_write("float", p + 0x22c, g)
end

local target      = 196.2
local lastApplied = nil
local autoApply   = true

local PRESETS = {
    {"Default (196.2)", 196.2},
    {"Luna Low (5)",    5.0},
    {"Moon (32.7)",     32.7},
    {"Mars (74.2)",     74.2},
    {"Jupiter (464)",   464.0},
    {"Zero-G (0)",      0.0},
    {"Inverted (-10)",  -10.0},
    {"Hyper (999)",     999.0},
    {"Heavy (1500)",    1500.0},
}

task.spawn(function()
    while true do
        if autoApply and lastApplied ~= target then
            setGravity(target)
            lastApplied = target
            print("[Gravity] Auto-applied:", target)
        end
        wait(0.1)
    end
end)

local CFG = "gravity_config.json"

local function saveConfig()
    local data = string.format(
        '{"gravity":%.2f,"autoApply":%s}',
        target, tostring(autoApply)
    )
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

    target    = tonumber(g) or target
    autoApply = (a == "true")

    print("[Gravity] Loaded. gravity =", target, "autoApply =", autoApply)
end

UI.AddTab("Gravity Changer+", function(tab)
    local L = tab:Section("Gravity Settings", "Left")

    L:SliderFloat("grav_value", "Gravity", -1000, 1000, target, "%.1f",
        function(v)
            target = v
            UI.SetValue("grav_preset", 0)
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

    L:Button("Reset to Default", 140, 24, function()
        target = 196.2
        UI.SetValue("grav_value", 196.2)
        UI.SetValue("grav_preset", 1)
        setGravity(196.2)
        lastApplied = 196.2
        notify("Reset to default gravity", "Gravity Changer+", 1.5)
        print("[Gravity] Reset to default")
    end)

    L:Button("Invert Gravity", 140, 24, function()
        target = -target
        UI.SetValue("grav_value", target)
        UI.SetValue("grav_preset", 0)
        setGravity(target)
        lastApplied = target
        notify(string.format("Inverted: %.1f", target), "Gravity Changer+", 1.5)
        print("[Gravity] Inverted:", target)
    end)

    local items = {"Manual"}
    for _, p in ipairs(PRESETS) do table.insert(items, p[1]) end

    L:Combo("grav_preset", "Preset", items, 0, function(i)
        if i == 0 then return end
        target = PRESETS[i][2]
        UI.SetValue("grav_value", target)
        setGravity(target)
        lastApplied = target
        notify(string.format("%s -> %.1f", PRESETS[i][1], target),
               "Gravity Changer+", 1.5)
        print("[Gravity] Preset:", PRESETS[i][1], "=", target)
    end)

    local C = tab:Section("Config", "Right")

    C:Text("Save / Load")
    C:Button("Save", 140, 24, saveConfig)
    C:Button("Load", 140, 24, function()
        loadConfig()
        UI.SetValue("grav_value", target)
        setGravity(target)
        lastApplied = target
        print("[Gravity] Config applied")
    end)
end)

loadConfig()
