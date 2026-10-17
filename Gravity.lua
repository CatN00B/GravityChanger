local HttpService=game:GetService("HttpService")

local WORLD_OFF=nil
local GRAV_OFF=nil

local function fetchRemote()
    local ok,ver=pcall(function()
        return game:HttpGet("https://offsets.imtheo.lol/roblox/version")
    end)
    if not ok or not ver or ver=="" then return nil end
    ver=ver:gsub("%s+","")
    local url="https://offsets.imtheo.lol/"..ver.."/offsets.json"
    local ok2,raw=pcall(function()
        return game:HttpGet(url)
    end)
    if not ok2 or not raw or raw=="" then return nil end
    local ok3,data=pcall(function()
        return HttpService:JSONDecode(raw)
    end)
    if not ok3 or not data then return nil end
    local offs=data.Offsets
    if not offs or not offs.Workspace or not offs.World then return nil end
    local w=offs.Workspace.World
    local g=offs.World.Gravity
    if not w or not g then return nil end
    return w,g
end

local function resolveOffsets()
    local rw,rg=fetchRemote()
    if rw and rg then
        WORLD_OFF=rw
        GRAV_OFF=rg
        return true
    end
    return false
end

local function sg(g)
    if not WORLD_OFF or not GRAV_OFF then return end
    local ok,p=pcall(memory_read,"uintptr_t",workspace.Address+WORLD_OFF)
    if not ok or not p or p==0 then return end
    pcall(memory_write,"float",p+GRAV_OFF,g)
    pcall(memory_write,"float",p+GRAV_OFF-4,g)
end

local function rg()
    if not WORLD_OFF or not GRAV_OFF then return nil end
    local ok,p=pcall(memory_read,"uintptr_t",workspace.Address+WORLD_OFF)
    if not ok or not p or p==0 then return nil end
    local ok2,v=pcall(memory_read,"float",p+GRAV_OFF)
    if not ok2 or not v then return nil end
    if v~=v then return nil end
    return v
end

local S=_G
S.gc_t=196.2
S.gc_aa=true
S.gc_re=true
S.gc_rn=false
S.gc_ri=3.0
S.gc_rmin=-200.0
S.gc_rmax=1500.0
S.gc_fn=false
S.gc_fi=2.0
S.gc_fni=1.0
S.gc_fst=0
S.gc_ftime=0
S.gc_rtime=0
S.gc_rc=0
S.gc_fc=0
S.gc_cp={}

local cpInputName=""

local oOn=true
local oX,oY=20,20
local oR,oG,oB,oA=120,255,120,1
local oSz=18
local oFi=5
local oBgOn=true
local oBgR,oBgG,oBgB=15,15,20
local oBgA=0.55

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
local CPCFG="gravity_custom.json"
local cpCombo=nil
local ATXT="Gravity Changer"
local CP_MAX=15

local KB = { flip=nil, rnd=nil, reset=nil, invert=nil, custom=nil }
local KPrev = { flip=false, rnd=false, reset=false, invert=false, custom=false }

local function kbHeld(kb)
    if not kb then return false end
    local ok,v=pcall(function() return kb:IsEnabled() end)
    return ok and v==true
end

local function kbPressed(id,kb)
    local h=kbHeld(kb)
    local was=KPrev[id]
    KPrev[id]=h
    return h and not was
end

local function detectPreset(v)
    for _,p in ipairs(P) do
        if math.abs(v-p[2])<0.05 then return p[1] end
    end
    for _,p in ipairs(S.gc_cp) do
        if math.abs(v-p.value)<0.05 then return p.name end
    end
    return "Manual"
end

local function roll()
    local lo,hi=math.min(S.gc_rmin,S.gc_rmax),math.max(S.gc_rmin,S.gc_rmax)
    local r=lo+math.random()*(hi-lo)
    return math.floor(r*10+0.5)/10,lo,hi
end

local function esc(s) return (s:gsub('\\','\\\\'):gsub('"','\\"')) end

local function svCustom()
    local parts={}
    for _,p in ipairs(S.gc_cp) do
        table.insert(parts,string.format('{"name":"%s","value":%.2f}',esc(p.name),p.value))
    end
    pcall(writefile,CPCFG,"["..table.concat(parts,",").."]")
end

local function ldCustom()
    S.gc_cp={}
    if not isfile(CPCFG) then return end
    local ok,raw=pcall(readfile,CPCFG)
    if not ok then return end
    for name,val in raw:gmatch('"name":"(.-)","value":([%-%d%.]+)') do
        table.insert(S.gc_cp,{name=name:gsub('\\"','"'):gsub('\\\\','\\'),value=tonumber(val)})
    end
end

local function sv()
    local kbr = tonumber(UI.GetValue("grav_kb_reset")) or 0
    local kbi = tonumber(UI.GetValue("grav_kb_invert")) or 0
    local kbc = tonumber(UI.GetValue("grav_kb_custom")) or 0
    local kbrn = tonumber(UI.GetValue("grav_kb_random")) or 0
    local kbf = tonumber(UI.GetValue("grav_kb_flip")) or 0
    pcall(writefile,CFG,string.format(
        '{"gravity":%.2f,"autoApply":%s,"reApply":%s,"randomInterval":%.2f,"randomMin":%.2f,"randomMax":%.2f,'..
        '"flipInterval":%.2f,"flipNormalInterval":%.2f,"overlay":%s,"overlayX":%d,"overlayY":%d,'..
        '"ovR":%d,"ovG":%d,"ovB":%d,"ovA":%.2f,"ovSize":%d,"ovFont":%d,'..
        '"bgOn":%s,"bgR":%d,"bgG":%d,"bgB":%d,"bgA":%.2f,'..
        '"kbReset":%d,"kbInvert":%d,"kbCustom":%d,"kbRandom":%d,"kbFlip":%d,'..
        '"rndCount":%d,"flipCount":%d}',
        S.gc_t,tostring(S.gc_aa),tostring(S.gc_re),S.gc_ri,S.gc_rmin,S.gc_rmax,S.gc_fi,S.gc_fni,tostring(oOn),oX,oY,
        oR,oG,oB,oA,oSz,oFi,tostring(oBgOn),oBgR,oBgG,oBgB,oBgA,
        kbr,kbi,kbc,kbrn,kbf,
        S.gc_rc,S.gc_fc))
end

local function ld()
    if not isfile(CFG) then return false end
    local ok,raw=pcall(readfile,CFG)
    if not ok then return false end
    local function nm(k) local v=raw:match('"'..k..'":([%-%d%.]+)'); return v and tonumber(v) end
    local function bl(k) local v=raw:match('"'..k..'":(%a+)'); if v==nil then return nil end; return v=="true" end
    S.gc_t=nm("gravity") or S.gc_t
    local aa=bl("autoApply"); if aa~=nil then S.gc_aa=aa end
    local re=bl("reApply"); if re~=nil then S.gc_re=re end
    S.gc_ri=nm("randomInterval") or S.gc_ri
    S.gc_rmin=nm("randomMin") or S.gc_rmin
    S.gc_rmax=nm("randomMax") or S.gc_rmax
    S.gc_fi=nm("flipInterval") or S.gc_fi
    S.gc_fni=nm("flipNormalInterval") or S.gc_fni
    local ov=bl("overlay"); if ov~=nil then oOn=ov end
    oX=nm("overlayX") or oX
    oY=nm("overlayY") or oY
    oR=nm("ovR") or oR
    oG=nm("ovG") or oG
    oB=nm("ovB") or oB
    oA=nm("ovA") or oA
    oSz=nm("ovSize") or oSz
    oFi=nm("ovFont") or oFi
    local bgo=bl("bgOn"); if bgo~=nil then oBgOn=bgo end
    oBgR=nm("bgR") or oBgR
    oBgG=nm("bgG") or oBgG
    oBgB=nm("bgB") or oBgB
    oBgA=nm("bgA") or oBgA
    S.gc_rc=nm("rndCount") or S.gc_rc
    S.gc_fc=nm("flipCount") or S.gc_fc
    S.gc_rn=false
    S.gc_fn=false
    S.gc_fst=0
    S.gc_ftime=0
    S.gc_rtime=0
    local kr=nm("kbReset")
    local ki=nm("kbInvert")
    local kc=nm("kbCustom")
    local krn=nm("kbRandom")
    local kf=nm("kbFlip")
    if kr then UI.SetValue("grav_kb_reset",kr) end
    if ki then UI.SetValue("grav_kb_invert",ki) end
    if kc then UI.SetValue("grav_kb_custom",kc) end
    if krn then UI.SetValue("grav_kb_random",krn) end
    if kf then UI.SetValue("grav_kb_flip",kf) end
    return true
end

local function ap(v)
    S.gc_t=v
    sg(v)
    UI.SetValue("grav_value",v)
end

local function setDefaults()
    S.gc_t=196.2
    S.gc_aa=true
    S.gc_re=true
    S.gc_rn=false
    S.gc_ri=3.0
    S.gc_rmin=-200.0
    S.gc_rmax=1500.0
    S.gc_fn=false
    S.gc_fi=2.0
    S.gc_fni=1.0
    S.gc_fst=0
    S.gc_ftime=0
    S.gc_rtime=0
    S.gc_rc=0
    S.gc_fc=0
    oOn=true
    oX,oY=20,20
    oR,oG,oB,oA=120,255,120,1
    oSz=18
    oFi=5
    oBgOn=true
    oBgR,oBgG,oBgB=15,15,20
    oBgA=0.55
end

local function rebuildCpCombo()
    if not cpCombo then return end
    cpCombo:Clear()
    cpCombo:Add("None")
    for _,p in ipairs(S.gc_cp) do cpCombo:Add(p.name) end
end

local function syncUI()
    UI.SetValue("grav_value",S.gc_t)
    UI.SetValue("grav_auto",S.gc_aa)
    UI.SetValue("grav_reapply",S.gc_re)
    UI.SetValue("grav_random",S.gc_rn)
    UI.SetValue("grav_rand_min",S.gc_rmin)
    UI.SetValue("grav_rand_max",S.gc_rmax)
    UI.SetValue("grav_random_int",S.gc_ri)
    UI.SetValue("grav_flip",S.gc_fn)
    UI.SetValue("grav_flip_int",S.gc_fi)
    UI.SetValue("grav_flip_nint",S.gc_fni)
    UI.SetValue("grav_overlay",oOn)
    UI.SetValue("grav_ov_font",oFi-1)
    UI.SetValue("grav_ov_size",oSz)
    UI.SetValue("grav_ov_x",oX)
    UI.SetValue("grav_ov_y",oY)
    UI.SetValue("grav_bg_on",oBgOn)
    UI.SetValue("grav_cp_name","")
    UI.SetValue("grav_preset",0)
    UI.SetValue("grav_cp_combo",0)
end

local bg=Drawing.new("Square")
bg.Filled=true
bg.Color=Color3.fromRGB(oBgR,oBgG,oBgB)
bg.Transparency=oBgA
bg.Corner=8
bg.Visible=false

local bgLine=Drawing.new("Square")
bgLine.Filled=false
bgLine.Color=Color3.fromRGB(oBgR,oBgG,oBgB)
bgLine.Transparency=math.min(oBgA+0.25,1)
bgLine.Thickness=1
bgLine.Corner=8
bgLine.Visible=false

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
    local last=tick()
    while true do
        local now=tick()
        local dt=now-last
        last=now
        if S.gc_fn then
            S.gc_ftime=S.gc_ftime+dt
            local limit=S.gc_fst==0 and S.gc_fi or S.gc_fni
            if S.gc_ftime>=limit then
                S.gc_ftime=0
                if S.gc_fst==0 then
                    S.gc_t=-math.abs(S.gc_t)
                    S.gc_fst=1
                    S.gc_fc=S.gc_fc+1
                else
                    S.gc_t=math.abs(S.gc_t)
                    S.gc_fst=0
                end
                UI.SetValue("grav_value",S.gc_t)
                sv()
                UI.SetValue("grav_preset",0)
            end
        else
            S.gc_fst=0
            S.gc_ftime=0
        end
        task.wait()
    end
end)

task.spawn(function()
    local last=tick()
    while true do
        local now=tick()
        local dt=now-last
        last=now
        if S.gc_rn then
            S.gc_rtime=S.gc_rtime+dt
            if S.gc_rtime>=S.gc_ri then
                S.gc_rtime=0
                local r=roll()
                S.gc_t=r
                S.gc_rc=S.gc_rc+1
                UI.SetValue("grav_value",r)
                sv()
                UI.SetValue("grav_preset",0)
                notify(string.format("Random: %.1f",r),"Gravity Changer+",1)
            end
        else
            S.gc_rtime=0
        end
        task.wait()
    end
end)

task.spawn(function()
    while true do
        pcall(function()
            if S.gc_re and WORLD_OFF and GRAV_OFF and S.gc_t then
                local ok,p=pcall(memory_read,"uintptr_t",workspace.Address+WORLD_OFF)
                if ok and p and p~=0 then
                    local ok2,v=pcall(memory_read,"float",p+GRAV_OFF)
                    if ok2 and v and v==v then
                        if math.abs(v-S.gc_t)>0.01 then
                            pcall(memory_write,"float",p+GRAV_OFF,S.gc_t)
                            pcall(memory_write,"float",p+GRAV_OFF-4,S.gc_t)
                        end
                    end
                end
            end
        end)
        task.wait()
    end
end)

local function bindFlip()
    S.gc_fn=not S.gc_fn
    S.gc_fst=0
    S.gc_ftime=0
    if not S.gc_fn then
        S.gc_fc=0
        S.gc_t=math.abs(S.gc_t)
        sg(S.gc_t)
        UI.SetValue("grav_value",S.gc_t)
    end
    UI.SetValue("grav_flip",S.gc_fn)
    notify(S.gc_fn and "Flip: ON" or "Flip: OFF","Gravity Changer+",1.5)
end

local function bindRandom()
    S.gc_rn=not S.gc_rn
    S.gc_rtime=0
    if not S.gc_rn then S.gc_rc=0 end
    UI.SetValue("grav_random",S.gc_rn)
    notify(S.gc_rn and "Random: ON" or "Random: OFF","Gravity Changer+",1.5)
end

local function bindReset()
    ap(196.2)
    UI.SetValue("grav_preset",1)
    notify("Reset gravity to default","Gravity Changer+",1.5)
end

local function bindInvert()
    ap(-S.gc_t)
    UI.SetValue("grav_preset",0)
    notify(string.format("Inverted: %.1f",S.gc_t),"Gravity Changer+",1.5)
end

local function bindCustom()
    local i=UI.GetValue("grav_cp_combo")
    if type(i)~="number" or i<=0 or not S.gc_cp[i] then
        notify("Select a custom preset first","Gravity Changer+",1.5)
        return
    end
    ap(S.gc_cp[i].value)
    UI.SetValue("grav_preset",0)
    notify(string.format("%s -> %.1f",S.gc_cp[i].name,S.gc_t),"Gravity Changer+",1.5)
end

task.spawn(function()
    while true do
        if kbPressed("flip",KB.flip) then pcall(bindFlip) end
        if kbPressed("rnd",KB.rnd) then pcall(bindRandom) end
        if kbPressed("reset",KB.reset) then pcall(bindReset) end
        if kbPressed("invert",KB.invert) then pcall(bindInvert) end
        if kbPressed("custom",KB.custom) then pcall(bindCustom) end
        wait(0.02)
    end
end)

task.spawn(function()
    while true do
        if oOn then
            local cur=rg() or 0
            local lh=oSz+4
            local rnd=S.gc_rn
            local flp=S.gc_fn
            local counter=nil
            if rnd and flp then counter=string.format("RND:%d  FLIP:%d",S.gc_rc,S.gc_fc)
            elseif rnd then counter=string.format("RND:%d",S.gc_rc)
            elseif flp then counter=string.format("FLIP:%d",S.gc_fc) end
            local txt={
                ATXT,
                string.format("Gravity: %.1f",cur),
                string.format("Preset:  %s",detectPreset(cur)),
                counter,
            }
            local maxLen=0
            local vc=0
            for i=1,N do
                if txt[i] then
                    if #txt[i]>maxLen then maxLen=#txt[i] end
                    vc=vc+1
                end
            end
            local padX=math.floor(oSz*0.6)
            local padY=math.floor(oSz*0.4)
            local w=maxLen*oSz*0.6+padX*2
            local h=(vc-1)*lh+oSz+padY*2
            if oBgOn and vc>0 then
                bg.Position=Vector2.new(oX,oY)
                bg.Size=Vector2.new(w,h)
                bg.Color=Color3.fromRGB(oBgR,oBgG,oBgB)
                bg.Transparency=oBgA
                bg.Visible=true
            else
                bg.Visible=false
            end
            bgLine.Visible=false
            local li=0
            for i=1,N do
                local t=ov[i]
                if txt[i] then
                    li=li+1
                    t.Text=txt[i]
                    t.Position=Vector2.new(oX+padX,oY+padY+(li-1)*lh)
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
            bg.Visible=false
            bgLine.Visible=false
        end
        wait(0.1)
    end
end)

task.spawn(function()
    while true do
        wait(30)
        if not WORLD_OFF or not GRAV_OFF then
            resolveOffsets()
        else
            local v=rg()
            if v==nil or v~=v then resolveOffsets() end
        end
    end
end)

ldCustom()
resolveOffsets()
local loaded=ld()

UI.AddTab("Gravity Changer+",function(tab)
    local L=tab:Section("Gravity Settings","Left")
    L:SliderFloat("grav_value","Gravity",-1000,1000,S.gc_t,"%.1f",function(v)
        S.gc_t=v
        UI.SetValue("grav_preset",0)
        if S.gc_aa then sg(v) end
    end)
    L:Toggle("grav_auto","Auto-Apply",S.gc_aa,function(v)
        S.gc_aa=v
        if v then sg(S.gc_t) end
    end)
    L:Toggle("grav_reapply","Re-Apply",S.gc_re,function(v)
        S.gc_re=v
        if v then sg(S.gc_t) end
    end)
    L:Spacing()
    L:Text("Re-Apply: keeps every frame if game resets")
    L:Button("Apply Now",100,20,function() sg(S.gc_t) end)
    L:Button("Reset Gravity",100,20,function()
        ap(196.2)
        UI.SetValue("grav_preset",1)
        notify("Reset gravity to default","Gravity Changer+",1.5)
    end)
    KB.reset=L:Keybind("grav_kb_reset",0,"hold")
    L:Button("Invert Gravity",100,20,function()
        ap(-S.gc_t)
        UI.SetValue("grav_preset",0)
        notify(string.format("Inverted: %.1f",S.gc_t),"Gravity Changer+",1.5)
    end)
    KB.invert=L:Keybind("grav_kb_invert",0,"hold")
    local items={"Manual"}
    for _,p in ipairs(P) do table.insert(items,p[1]) end
    L:Combo("grav_preset","Preset",items,0,function(i)
        if i==0 then return end
        ap(P[i][2])
        notify(string.format("%s -> %.1f",P[i][1],S.gc_t),"Gravity Changer+",1.5)
    end)

    local CP=tab:Section("Custom Presets","Left")
    CP:InputText("grav_cp_name","Name","",function(t)
        cpInputName=t:sub(1,CP_MAX)
    end)
    CP:Button("Add Preset",100,20,function()
        if cpInputName=="" then
            notify("Enter a name first","Gravity Changer+",1.5)
            return
        end
        local fullName=string.format("%s (%.1f)",cpInputName,S.gc_t)
        table.insert(S.gc_cp,{name=fullName,value=S.gc_t})
        UI.SetValue("grav_cp_name","")
        cpInputName=""
        svCustom()
        rebuildCpCombo()
        notify(string.format("Added: %s",fullName),"Gravity Changer+",1.5)
    end)
    local cpItems={"None"}
    for _,p in ipairs(S.gc_cp) do table.insert(cpItems,p.name) end
    cpCombo=CP:Combo("grav_cp_combo","Custom",cpItems,0,function(i)
        if i==0 then return end
        ap(S.gc_cp[i].value)
        notify(string.format("%s -> %.1f",S.gc_cp[i].name,S.gc_t),"Gravity Changer+",1.5)
    end)
    KB.custom=CP:Keybind("grav_kb_custom",0,"hold")
    CP:Button("Delete Selected",100,20,function()
        local i=UI.GetValue("grav_cp_combo")
        if not i or i==0 then
            notify("Select a custom preset","Gravity Changer+",1.5)
            return
        end
        local removed=S.gc_cp[i]
        table.remove(S.gc_cp,i)
        svCustom()
        rebuildCpCombo()
        notify(string.format("Deleted: %s",removed.name),"Gravity Changer+",1.5)
    end)

    local O=tab:Section("Overlay","Left")
    O:Toggle("grav_overlay","Show Overlay",oOn,function(v) oOn=v end)
    O:ColorPicker("grav_ov_col",oR/255,oG/255,oB/255,oA,function(c,a)
        oR=math.floor(c.R*255+0.5)
        oG=math.floor(c.G*255+0.5)
        oB=math.floor(c.B*255+0.5)
        oA=a
    end)
    O:Toggle("grav_bg_on","Show Background",oBgOn,function(v) oBgOn=v end)
    O:ColorPicker("grav_bg_col",oBgR/255,oBgG/255,oBgB/255,oBgA,function(c,a)
        oBgR=math.floor(c.R*255+0.5)
        oBgG=math.floor(c.G*255+0.5)
        oBgB=math.floor(c.B*255+0.5)
        oBgA=a
    end)
    local fi={}
    for _,f in ipairs(FONTS) do table.insert(fi,f[1]) end
    O:Combo("grav_ov_font","Font",fi,oFi-1,function(i) oFi=i+1 end)
    O:SliderInt("grav_ov_size","Size",8,48,oSz,function(v) oSz=v end)
    O:SliderInt("grav_ov_x","X",0,1920,oX,function(v) oX=v end)
    O:SliderInt("grav_ov_y","Y",0,1080,oY,function(v) oY=v end)

    local R=tab:Section("Random Gravity","Right")
    R:Toggle("grav_random","Enable Random",S.gc_rn,function(v)
        S.gc_rn=v
        S.gc_rtime=0
        if not v then S.gc_rc=0 end
    end)
    KB.rnd=R:Keybind("grav_kb_random",0,"hold")
    R:SliderFloat("grav_rand_min","Min",-2000,2000,S.gc_rmin,"%.0f",function(v)
        S.gc_rmin=v
        if S.gc_rmin>S.gc_rmax then S.gc_rmax=S.gc_rmin; UI.SetValue("grav_rand_max",S.gc_rmax) end
    end)
    R:SliderFloat("grav_rand_max","Max",-2000,2000,S.gc_rmax,"%.0f",function(v)
        S.gc_rmax=v
        if S.gc_rmax<S.gc_rmin then S.gc_rmin=S.gc_rmax; UI.SetValue("grav_rand_min",S.gc_rmin) end
    end)
    R:SliderFloat("grav_random_int","Interval (s)",0.5,15.0,S.gc_ri,"%.1f",function(v) S.gc_ri=v end)
    R:Button("Roll Once",100,20,function()
        local r=roll()
        ap(r)
        UI.SetValue("grav_preset",0)
        notify(string.format("Rolled: %.1f",r),"Gravity Changer+",1.5)
    end)

    local F=tab:Section("Flip Gravity","Right")
    F:Toggle("grav_flip","Enable Flip",S.gc_fn,function(v)
        S.gc_fn=v
        S.gc_fst=0
        S.gc_ftime=0
        if not v then
            S.gc_fc=0
            S.gc_t=math.abs(S.gc_t)
            sg(S.gc_t)
            UI.SetValue("grav_value",S.gc_t)
        end
    end)
    KB.flip=F:Keybind("grav_kb_flip",0,"hold")
    F:SliderFloat("grav_flip_int","Inverted Gravity Time (sec)",0.2,10.0,S.gc_fi,"%.1f",function(v) S.gc_fi=v end)
    F:SliderFloat("grav_flip_nint","Normal Gravity Time (sec)",0.2,10.0,S.gc_fni,"%.1f",function(v) S.gc_fni=v end)
    F:Spacing()
    F:Text("How long each gravity state is held")
    F:Text("before switching to the other one")

    local C=tab:Section("Config","Right")
    C:Text("Save / Load")
    C:Button("Save",100,20,function()
        sv()
        svCustom()
        UI.SetValue("grav_cp_name","")
        cpInputName=""
    end)
    C:Button("Load",100,20,function()
        ldCustom()
        if ld() then
            rebuildCpCombo()
            syncUI()
            sg(S.gc_t)
            cpInputName=""
            notify("Config loaded","Gravity Changer+",1.5)
        end
    end)
    C:Button("Reset to Default",100,20,function()
        setDefaults()
        syncUI()
        sg(S.gc_t)
        cpInputName=""
        notify("Reset to defaults","Gravity Changer+",1.5)
    end)
    C:Button("Delete Config",100,20,function()
        if isfile(CFG) then delfile(CFG) end
        setDefaults()
        syncUI()
        sg(S.gc_t)
        cpInputName=""
        notify("Config deleted (custom presets kept)","Gravity Changer+",1.5)
    end)

    if loaded then
        rebuildCpCombo()
        syncUI()
        loaded=false
    end
end)
