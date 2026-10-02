local function sg(g)
    local p=memory_read("uintptr_t",workspace.Address+0x400)
    memory_write("float",p+0x22c,g)
end

local function rg()
    local p=memory_read("uintptr_t",workspace.Address+0x400)
    return memory_read("float",p+0x22c)
end

local S=_G
S.gc_t=196.2
S.gc_la=nil
S.gc_aa=true
S.gc_rn=false
S.gc_ri=3.0
S.gc_rmin=-200.0
S.gc_rmax=1500.0
S.gc_fn=false
S.gc_fi=2.0
S.gc_rc=0
S.gc_fc=0

local oOn=true
local oX,oY=20,20
local oR,oG,oB,oA=120,255,120,1
local oSz=18
local oFi=5

local FONTS={
    {"UI",Drawing.Fonts.UI},
    {"System",Drawing.Fonts.System},
    {"SystemBold",Drawing.Fonts.SystemBold},
    {"Minecraft",Drawing.Fonts.Minecraft},
    {"Monospace",Drawing.Fonts.Monospace},
    {"Pixel",Drawing.Fonts.Pixel},
    {"Fortnite",Drawing.Fonts.Fortnite},
    {"ProximaSoftBold",Drawing.Fonts.ProximaSoftBold},
}

local P={
    {"Default (196.2)",196.2},
    {"Luna Low (5)",5.0},
    {"Moon (32.7)",32.7},
    {"Mars (74.2)",74.2},
    {"Jupiter (464)",464.0},
    {"Zero-G (0)",0.0},
    {"Inverted (-10)",-10.0},
    {"Hyper (999)",999.0},
    {"Heavy (1500)",1500.0},
}

local CFG="gravity_config.json"

local function detectPreset(v)
    for _,p in ipairs(P) do
        if math.abs(v-p[2])<0.05 then return p[1] end
    end
    return "Manual"
end

local function roll()
    local lo,hi=math.min(S.gc_rmin,S.gc_rmax),math.max(S.gc_rmin,S.gc_rmax)
    local r=lo+math.random()*(hi-lo)
    return math.floor(r*10+0.5)/10,lo,hi
end

local function sv()
    local d=string.format(
        '{"gravity":%.2f,"autoApply":%s,'..
        '"randomInterval":%.2f,"randomMin":%.2f,"randomMax":%.2f,'..
        '"flipInterval":%.2f,'..
        '"overlay":%s,"overlayX":%d,"overlayY":%d,'..
        '"ovR":%d,"ovG":%d,"ovB":%d,"ovA":%.2f,"ovSize":%d,"ovFont":%d,'..
        '"rndCount":%d,"flipCount":%d}',
        S.gc_t,tostring(S.gc_aa),S.gc_ri,S.gc_rmin,S.gc_rmax,
        S.gc_fi,tostring(oOn),oX,oY,
        oR,oG,oB,oA,oSz,oFi,S.gc_rc,S.gc_fc)
    writefile(CFG,d)
end

local function ld()
    if not isfile(CFG) then return false end
    local ok,raw=pcall(readfile,CFG)
    if not ok then return false end
    local function nm(k) local v=raw:match('"'..k..'":([%-%d%.]+)'); return v and tonumber(v) end
    local function bl(k) return raw:match('"'..k..'":(%a+)')=="true" end
    S.gc_t=nm("gravity") or S.gc_t
    S.gc_aa=bl("autoApply")
    S.gc_ri=nm("randomInterval") or S.gc_ri
    S.gc_rmin=nm("randomMin") or S.gc_rmin
    S.gc_rmax=nm("randomMax") or S.gc_rmax
    S.gc_fi=nm("flipInterval") or S.gc_fi
    oOn=bl("overlay")
    oX=nm("overlayX") or oX
    oY=nm("overlayY") or oY
    oR=nm("ovR") or oR
    oG=nm("ovG") or oG
    oB=nm("ovB") or oB
    oA=nm("ovA") or oA
    oSz=nm("ovSize") or oSz
    oFi=nm("ovFont") or oFi
    S.gc_rc=nm("rndCount") or S.gc_rc
    S.gc_fc=nm("flipCount") or S.gc_fc
    S.gc_rn=false
    S.gc_fn=false
    return true
end

local function ap(v)
    S.gc_t,S.gc_la=v,v
    sg(v)
    UI.SetValue("grav_value",v)
end

local N=3
local ov={}
for i=1,N do
    local t=Drawing.new("Text")
    t.Size=oSz
    t.Color=Color3.fromRGB(oR,oG,oB)
    t.Transparency=oA
    t.Outline=true
    t.Center=false
    t.Font=FONTS[oFi][2]
    t.Visible=false
    ov[i]=t
end

task.spawn(function()
    while true do
        if oOn then
            local cur=rg() or 0
            local lh=oSz+4
            local rnd = S.gc_rn or S.gc_rc>0
            local flp = S.gc_fn or S.gc_fc>0
            local counter = nil
            if rnd and flp then counter=string.format("RND:%d  FLIP:%d",S.gc_rc,S.gc_fc)
            elseif rnd then counter=string.format("RND:%d",S.gc_rc)
            elseif flp then counter=string.format("FLIP:%d",S.gc_fc) end

            local txt={
                string.format("Gravity: %.1f",cur),
                string.format("Preset:  %s",detectPreset(cur)),
                counter,
            }

            for i=1,N do
                local t=ov[i]
                if txt[i] then
                    t.Text=txt[i]
                    t.Position=Vector2.new(oX,oY+(i-1)*lh)
                    t.Size=oSz
                    t.Color=Color3.fromRGB(oR,oG,oB)
                    t.Transparency=oA
                    t.Font=FONTS[oFi][2]
                    t.Visible=true
                else
                    t.Visible=false
                end
            end
        else
            for i=1,N do ov[i].Visible=false end
        end
        wait(0.1)
    end
end)

task.spawn(function()
    while true do
        if S.gc_aa and S.gc_la~=S.gc_t then
            sg(S.gc_t)
            S.gc_la=S.gc_t
        end
        wait(0.1)
    end
end)

task.spawn(function()
    while true do
        if S.gc_rn then
            local r,lo,hi=roll()
            ap(r)
            S.gc_rc=S.gc_rc+1
            sv()
            UI.SetValue("grav_preset",0)
            notify(string.format("Random: %.1f  [%.0f ... %.0f]",r,lo,hi),"Gravity Changer+",1)
        end
        wait(S.gc_ri)
    end
end)

task.spawn(function()
    while true do
        if S.gc_fn then
            ap(-S.gc_t)
            S.gc_fc=S.gc_fc+1
            sv()
            UI.SetValue("grav_preset",0)
        end
        wait(S.gc_fi)
    end
end)

local loaded=ld()

UI.AddTab("Gravity Changer+",function(tab)
    local L=tab:Section("Gravity Settings","Left")
    L:SliderFloat("grav_value","Gravity",-1000,1000,S.gc_t,"%.1f",function(v)
        S.gc_t=v
        UI.SetValue("grav_preset",0)
        if S.gc_aa then sg(v); S.gc_la=v end
    end)
    L:Toggle("grav_auto","Auto-Apply",S.gc_aa,function(v)
        S.gc_aa=v
        if v then sg(S.gc_t); S.gc_la=S.gc_t else S.gc_la=nil end
    end)
    L:Button("Apply Now",140,24,function()
        sg(S.gc_t); S.gc_la=S.gc_t
    end)
    L:Button("Reset to Default",140,24,function()
        ap(196.2)
        UI.SetValue("grav_preset",1)
        notify("Reset to default gravity","Gravity Changer+",1.5)
    end)
    L:Button("Invert Gravity",140,24,function()
        ap(-S.gc_t)
        UI.SetValue("grav_preset",0)
        notify(string.format("Inverted: %.1f",S.gc_t),"Gravity Changer+",1.5)
    end)
    local items={"Manual"}
    for _,p in ipairs(P) do table.insert(items,p[1]) end
    L:Combo("grav_preset","Preset",items,0,function(i)
        if i==0 then return end
        ap(P[i][2])
        UI.SetValue("grav_preset",i)
        notify(string.format("%s -> %.1f",P[i][1],S.gc_t),"Gravity Changer+",1.5)
    end)

    local O=tab:Section("Overlay","Left")
    O:Toggle("grav_overlay","Show Overlay",oOn,function(v) oOn=v end)
    O:ColorPicker("grav_ov_col",oR/255,oG/255,oB/255,oA,function(c,a)
        oR=math.floor(c.R*255+0.5)
        oG=math.floor(c.G*255+0.5)
        oB=math.floor(c.B*255+0.5)
        oA=a
    end)
    local fi={}
    for _,f in ipairs(FONTS) do table.insert(fi,f[1]) end
    O:Combo("grav_ov_font","Font",fi,oFi-1,function(i) oFi=i+1 end)
    O:SliderInt("grav_ov_size","Size",8,48,oSz,function(v) oSz=v end)
    O:SliderInt("grav_ov_x","X",0,1920,oX,function(v) oX=v end)
    O:SliderInt("grav_ov_y","Y",0,1080,oY,function(v) oY=v end)
    O:Button("Reset Stats",140,24,function()
        S.gc_rc=0
        S.gc_fc=0
        sv()
        notify("Stats reset","Gravity Changer+",1.5)
    end)

    local R=tab:Section("Random Gravity","Right")
    R:Toggle("grav_random","Enable Random",false,function(v) S.gc_rn=v end)
    R:SliderFloat("grav_rand_min","Min",-2000,2000,S.gc_rmin,"%.0f",function(v)
        S.gc_rmin=v
        if S.gc_rmin>S.gc_rmax then S.gc_rmax=S.gc_rmin; UI.SetValue("grav_rand_max",S.gc_rmax) end
    end)
    R:SliderFloat("grav_rand_max","Max",-2000,2000,S.gc_rmax,"%.0f",function(v)
        S.gc_rmax=v
        if S.gc_rmax<S.gc_rmin then S.gc_rmin=S.gc_rmax; UI.SetValue("grav_rand_min",S.gc_rmin) end
    end)
    R:SliderFloat("grav_random_int","Interval (s)",0.5,15.0,S.gc_ri,"%.1f",function(v) S.gc_ri=v end)
    R:Button("Roll Once",140,24,function()
        local r=roll()
        ap(r)
        UI.SetValue("grav_preset",0)
        notify(string.format("Rolled: %.1f",r),"Gravity Changer+",1.5)
    end)

    local F=tab:Section("Flip Gravity","Right")
    F:Toggle("grav_flip","Enable Flip",false,function(v) S.gc_fn=v end)
    F:SliderFloat("grav_flip_int","Interval (s)",0.2,10.0,S.gc_fi,"%.1f",function(v) S.gc_fi=v end)
    F:Spacing()
    F:Text("Inverts gravity every N seconds")
    F:Text("196.2 -> -196.2 -> 196.2 ...")

    local C=tab:Section("Config","Right")
    C:Text("Save / Load")
    C:Button("Save",140,24,function()
        sv()
        print("[Gravity] Saved")
    end)
    C:Button("Load",140,24,function()
        if ld() then
            UI.SetValue("grav_value",S.gc_t)
            UI.SetValue("grav_auto",S.gc_aa)
            UI.SetValue("grav_rand_min",S.gc_rmin)
            UI.SetValue("grav_rand_max",S.gc_rmax)
            UI.SetValue("grav_random_int",S.gc_ri)
            UI.SetValue("grav_flip_int",S.gc_fi)
            UI.SetValue("grav_overlay",oOn)
            UI.SetValue("grav_ov_font",oFi-1)
            UI.SetValue("grav_ov_size",oSz)
            UI.SetValue("grav_ov_x",oX)
            UI.SetValue("grav_ov_y",oY)
            UI.SetValue("grav_preset",0)
            UI.SetValue("grav_random",false)
            UI.SetValue("grav_flip",false)
            sg(S.gc_t); S.gc_la=S.gc_t
            notify("Config loaded","Gravity Changer+",1.5)
        end
    end)

    if loaded then
        UI.SetValue("grav_value",S.gc_t)
        UI.SetValue("grav_auto",S.gc_aa)
        UI.SetValue("grav_rand_min",S.gc_rmin)
        UI.SetValue("grav_rand_max",S.gc_rmax)
        UI.SetValue("grav_random_int",S.gc_ri)
        UI.SetValue("grav_flip_int",S.gc_fi)
        UI.SetValue("grav_overlay",oOn)
        UI.SetValue("grav_ov_font",oFi-1)
        UI.SetValue("grav_ov_size",oSz)
        UI.SetValue("grav_ov_x",oX)
        UI.SetValue("grav_ov_y",oY)
    end
end)
