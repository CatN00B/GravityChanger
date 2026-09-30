local function setGravity(g)
    local p = memory_read("uintptr_t", workspace.Address + 0x400)
    memory_write("float", p + 0x22c, g)
end

local target          = 196.2
local lastApplied     = nil
local autoApply       = true
local randomEnabled   = false
local randomInterval  = 3.0
local randomMin       = -200.0
local randomMax       = 1500.0

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

local function randomFloat(min, max)
    return min + math.random() * (max - min)
end

local function rollRandom()
    local lo = math.min(randomMin, randomMax)
    local hi = math.max(randomMin, randomMax)
    local r  = randomFloat(lo, hi)
    r = math.floor(r * 10 + 0.5) / 10
    return r, lo, hi
end

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

task.spawn(function()
    while true do
        if randomEnabled then
            local r, lo, hi = rollRandom()
            target      = r
            lastApplied = r
            setGravity(r)
            UI.SetValue("grav_value", r)
            notify(string.format("Random: %.1f  [%.0f ... %.0f]", r, lo, hi),
                   "Gravity Changer+", 1)
            print("[Gravity] Random roll:", r)
        end
        wait(randomInterval)
    end
end)

local CFG = "gravity_config.json"

local function saveConfig()
    local data = string.format(
        '{"gravity":%.2f,"autoApply":%s,' ..
        '"random":%s,"randomInterval":%.2f,"randomMin":%.2f,"randomMax":%.2f}',
        target, tostring(autoApply),
        tostring(randomEnabled), randomInterval,
        randomMin, randomMax
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

    local g   = raw:match('"gravity":([%-%d%.]+)')
    local a   = raw:match('"autoApply":(%a+)')
    local r   = raw:match('"random":(%a+)')
    local ri  = raw:match('"randomInterval":([%-%d%.]+)')
    local rmn = raw:match('"randomMin":([%-%d%.]+)')
    local rmx = raw:match('"randomMax":([%-%d%.]+)')

    target    = tonumber(g) or target
    autoApply = (a == "true")
    if r   then randomEnabled  = (r == "true") end
    if ri  then randomInterval = tonumber(ri)  or randomInterval end
    if rmn then randomMin      = tonumber(rmn) or randomMin end
    if rmx then randomMax      = tonumber(rmx) or randomMax end

    print("[Gravity] Loaded. gravity =", target,
          "autoApply =", autoApply,
          "range =", randomMin, "..", randomMax)
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


    local R = tab:Section("Random Gravity", "Right")

    R:Toggle("grav_random", "Enable Random", randomEnabled, function(v)
        randomEnabled = v
        print("[Gravity] Random:", v)
    end)

    R:SliderFloat("grav_rand_min", "Min", -2000, 2000, randomMin, "%.0f",
        function(v)
            randomMin = v
            if randomMin > randomMax then
                randomMax = randomMin
                UI.SetValue("grav_rand_max", randomMax)
            end
        end)

    R:SliderFloat("grav_rand_max", "Max", -2000, 2000, randomMax, "%.0f",
        function(v)
            randomMax = v
            if randomMax < randomMin then
                randomMin = randomMax
                UI.SetValue("grav_rand_min", randomMin)
            end
        end)

    R:SliderFloat("grav_random_int", "Interval (s)", 0.5, 15.0, randomInterval, "%.1f",
        function(v)
            randomInterval = v
        end)

    R:Button("Roll Once", 140, 24, function()
        local r = rollRandom()
        target      = r
        lastApplied = r
        setGravity(r)
        UI.SetValue("grav_value", r)
        notify(string.format("Rolled: %.1f", r), "Gravity Changer+", 1.5)
        print("[Gravity] Rolled:", r)
    end)


    local C = tab:Section("Config", "Right")

    C:Text("Save / Load")
    C:Button("Save", 140, 24, saveConfig)
    C:Button("Load", 140, 24, function()
        loadConfig()
        UI.SetValue("grav_value",    target)
        UI.SetValue("grav_rand_min", randomMin)
        UI.SetValue("grav_rand_max", randomMax)
        setGravity(target)
        lastApplied = target
        print("[Gravity] Config applied")
    end)
end)

loadConfig()
