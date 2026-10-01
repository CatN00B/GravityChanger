local function setGravity(g)
    local p = memory_read("uintptr_t", workspace.Address + 0x400)
    memory_write("float", p + 0x22c, g)
end

local target, lastApplied, autoApply = 196.2, nil, true
local rndOn, rndInt, rndMin, rndMax = false, 3.0, -200.0, 1500.0
local flipOn, flipInt = false, 2.0

local PRESETS = {
    {"Default (196.2)", 196.2}, {"Luna Low (5)", 5.0}, {"Moon (32.7)", 32.7},
    {"Mars (74.2)", 74.2}, {"Jupiter (464)", 464.0}, {"Zero-G (0)", 0.0},
    {"Inverted (-10)", -10.0}, {"Hyper (999)", 999.0}, {"Heavy (1500)", 1500.0},
}

local function roll()
    local lo, hi = math.min(rndMin, rndMax), math.max(rndMin, rndMax)
    local r = lo + math.random() * (hi - lo)
    return math.floor(r * 10 + 0.5) / 10, lo, hi
end

local function apply(v)
    target, lastApplied = v, v
    setGravity(v)
    UI.SetValue("grav_value", v)
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
        if rndOn then
            local r, lo, hi = roll()
            apply(r)
            UI.SetValue("grav_preset", 0)
            notify(string.format("Random: %.1f  [%.0f ... %.0f]", r, lo, hi), "Gravity Changer+", 1)
            print("[Gravity] Random roll:", r)
        end
        wait(rndInt)
    end
end)

task.spawn(function()
    while true do
        if flipOn then
            apply(-target)
            UI.SetValue("grav_preset", 0)
            print("[Gravity] Flip:", target)
        end
        wait(flipInt)
    end
end)

local CFG = "gravity_config.json"

local function saveCfg()
    local d = string.format(
        '{"gravity":%.2f,"autoApply":%s,"random":%s,"randomInterval":%.2f,' ..
        '"randomMin":%.2f,"randomMax":%.2f,"flip":%s,"flipInterval":%.2f}',
        target, tostring(autoApply), tostring(rndOn), rndInt, rndMin, rndMax,
        tostring(flipOn), flipInt)
    writefile(CFG, d)
    print("[Gravity] Saved:", d)
end

local function loadCfg()
    if not isfile(CFG) then return print("[Gravity] No config, defaults") end
    local ok, raw = pcall(readfile, CFG)
    if not ok then return print("[Gravity] Read failed") end

    local function num(k) local v = raw:match('"' .. k .. '":([%-%d%.]+)'); return v and tonumber(v) end
    local function bool(k) return raw:match('"' .. k .. '":(%a+)') == "true" end

    target    = num("gravity")        or target
    autoApply = bool("autoApply")
    rndOn     = bool("random")
    rndInt    = num("randomInterval") or rndInt
    rndMin    = num("randomMin")      or rndMin
    rndMax    = num("randomMax")      or rndMax
    flipOn    = bool("flip")
    flipInt   = num("flipInterval")   or flipInt

    print("[Gravity] Loaded. g =", target, "flip =", flipOn)
end

UI.AddTab("Gravity Changer+", function(tab)
    local L = tab:Section("Gravity Settings", "Left")

    L:SliderFloat("grav_value", "Gravity", -1000, 1000, target, "%.1f", function(v)
        target = v
        UI.SetValue("grav_preset", 0)
        if autoApply then setGravity(v); lastApplied = v end
    end)

    L:Toggle("grav_auto", "Auto-Apply", autoApply, function(v)
        autoApply = v
        print("[Gravity] Auto-Apply:", v)
        if v then setGravity(target); lastApplied = target else lastApplied = nil end
    end)

    L:Button("Apply Now", 140, 24, function()
        setGravity(target); lastApplied = target
        print("[Gravity] Applied:", target)
    end)

    L:Button("Reset to Default", 140, 24, function()
        apply(196.2)
        UI.SetValue("grav_preset", 1)
        notify("Reset to default gravity", "Gravity Changer+", 1.5)
        print("[Gravity] Reset")
    end)

    L:Button("Invert Gravity", 140, 24, function()
        apply(-target)
        UI.SetValue("grav_preset", 0)
        notify(string.format("Inverted: %.1f", target), "Gravity Changer+", 1.5)
        print("[Gravity] Inverted:", target)
    end)

    local items = {"Manual"}
    for _, p in ipairs(PRESETS) do table.insert(items, p[1]) end

    L:Combo("grav_preset", "Preset", items, 0, function(i)
        if i == 0 then return end
        apply(PRESETS[i][2])
        UI.SetValue("grav_preset", i)
        notify(string.format("%s -> %.1f", PRESETS[i][1], target), "Gravity Changer+", 1.5)
        print("[Gravity] Preset:", PRESETS[i][1], "=", target)
    end)

    local R = tab:Section("Random Gravity", "Right")

    R:Toggle("grav_random", "Enable Random", rndOn, function(v)
        rndOn = v; print("[Gravity] Random:", v)
    end)

    R:SliderFloat("grav_rand_min", "Min", -2000, 2000, rndMin, "%.0f", function(v)
        rndMin = v
        if rndMin > rndMax then rndMax = rndMin; UI.SetValue("grav_rand_max", rndMax) end
    end)

    R:SliderFloat("grav_rand_max", "Max", -2000, 2000, rndMax, "%.0f", function(v)
        rndMax = v
        if rndMax < rndMin then rndMin = rndMax; UI.SetValue("grav_rand_min", rndMin) end
    end)

    R:SliderFloat("grav_random_int", "Interval (s)", 0.5, 15.0, rndInt, "%.1f", function(v)
        rndInt = v
    end)

    R:Button("Roll Once", 140, 24, function()
        local r = roll()
        apply(r)
        UI.SetValue("grav_preset", 0)
        notify(string.format("Rolled: %.1f", r), "Gravity Changer+", 1.5)
        print("[Gravity] Rolled:", r)
    end)

    local F = tab:Section("Flip Gravity", "Right")

    F:Toggle("grav_flip", "Enable Flip", flipOn, function(v)
        flipOn = v; print("[Gravity] Flip:", v)
    end)

    F:SliderFloat("grav_flip_int", "Interval (s)", 0.2, 10.0, flipInt, "%.1f", function(v)
        flipInt = v
    end)

    F:Spacing()
    F:Text("Inverts gravity every N seconds")
    F:Text("196.2 -> -196.2 -> 196.2 ...")

    local C = tab:Section("Config", "Right")

    C:Text("Save / Load")
    C:Button("Save", 140, 24, saveCfg)
    C:Button("Load", 140, 24, function()
        loadCfg()
        UI.SetValue("grav_value", target)
        UI.SetValue("grav_rand_min", rndMin)
        UI.SetValue("grav_rand_max", rndMax)
        UI.SetValue("grav_flip", flipOn)
        UI.SetValue("grav_flip_int", flipInt)
        UI.SetValue("grav_preset", 0)
        setGravity(target); lastApplied = target
        print("[Gravity] Config applied")
    end)
end)

loadCfg()
