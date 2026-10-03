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
S.gc_cp={}
S.an_speed=8
S.an_hold=1.0
S.an_erase=true
S.an_delay=0.4
S.an_on=true
S.an_show=true
S.an_on_was=false
S.an_glitch=0
S.an_style=0

local cpInputName=""

local oOn=true
local oX,oY=20,20
local oR,oG,oB,oA=120,255,120,1
local oSz=18
local oFi=5
local oBgOn=true
local oBgR,oBgG,oBgB=15,15,20
local oBgA=0.55
local oRgbOn=false
local oRgbSpeed=60
local oRgbThick=2
local oRgbWasOn=false

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

local GCH="!@#$%^&*()_+-=[]{}|;:,.<>/?~\\/"
local DCH="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*"
local GMODES={
    {"Off",0},
    {"Light (25%)",25},
    {"Medium (50%)",50},
    {"Heavy (75%)",75},
    {"Always (100%)",100},
}
local STYLES={"Default","Decrypt"}

local CFG="gravity_config.json"
local CPCFG="gravity_custom.json"
local cpCombo=nil
local ATXT="Gravity Changer"
local animText=""
local animState="typing"
local animIdx=0
local animTimer=0
local ATICK=0.02
local CP_MAX=15

local function glitchIdx()
    for i,m in ipairs(GMODES) do
        if m[2]==S.an_glitch then return i-1 end
    end
    return 0
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
    writefile(CPCFG,"["..table.concat(parts,",").."]")
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
    writefile(CFG,string.format(
        '{"gravity":%.2f,"autoApply":%s,"randomInterval":%.2f,"randomMin":%.2f,"randomMax":%.2f,'..
        '"flipInterval":%.2f,"overlay":%s,"overlayX":%d,"overlayY":%d,'..
        '"ovR":%d,"ovG":%d,"ovB":%d,"ovA":%.2f,"ovSize":%d,"ovFont":%d,'..
        '"bgOn":%s,"bgR":%d,"bgG":%d,"bgB":%d,"bgA":%.2f,'..
        '"rgbOn":%s,"rgbSpeed":%d,"rgbThick":%d,'..
        '"animOn":%s,"animShow":%s,"animStyle":%d,"animGlitch":%d,'..
        '"animSpeed":%.2f,"animHold":%.2f,"animErase":%s,"animDelay":%.2f,'..
        '"rndCount":%d,"flipCount":%d}',
        S.gc_t,tostring(S.gc_aa),S.gc_ri,S.gc_rmin,S.gc_rmax,S.gc_fi,tostring(oOn),oX,oY,
        oR,oG,oB,oA,oSz,oFi,tostring(oBgOn),oBgR,oBgG,oBgB,oBgA,
        tostring(oRgbOn),oRgbSpeed,oRgbThick,
        tostring(S.an_on),tostring(S.an_show),S.an_style,S.an_glitch,
        S.an_speed,S.an_hold,tostring(S.an_erase),S.an_delay,
        S.gc_rc,S.gc_fc))
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
    oBgOn=bl("bgOn")
    oBgR=nm("bgR") or oBgR
    oBgG=nm("bgG") or oBgG
    oBgB=nm("bgB") or oBgB
    oBgA=nm("bgA") or oBgA
    oRgbOn=bl("rgbOn")
    oRgbSpeed=nm("rgbSpeed") or oRgbSpeed
    oRgbThick=nm("rgbThick") or oRgbThick
    S.an_on=bl("animOn")
    S.an_show=bl("animShow")
    S.an_style=nm("animStyle") or S.an_style
    S.an_glitch=nm("animGlitch") or S.an_glitch
    S.an_speed=nm("animSpeed") or S.an_speed
    S.an_hold=nm("animHold") or S.an_hold
    S.an_erase=bl("animErase")
    S.an_delay=nm("animDelay") or S.an_delay
    S.gc_rc=nm("rndCount") or S.gc_rc
    S.gc_fc=nm("flipCount") or S.gc_fc
    if S.an_style<0 or S.an_style>#STYLES-1 then S.an_style=0 end
    S.gc_rn=false
    S.gc_fn=false
    return true
end

local function ap(v)
    S.gc_t,S.gc_la=v,v
    sg(v)
    UI.SetValue("grav_value",v)
end

local function setDefaults()
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
    S.an_speed=8
    S.an_hold=1.0
    S.an_erase=true
    S.an_delay=0.4
    S.an_on=true
    S.an_show=true
    S.an_on_was=false
    S.an_style=0
    S.an_glitch=0
    oOn=true
    oX,oY=20,20
    oR,oG,oB,oA=120,255,120,1
    oSz=18
    oFi=5
    oBgOn=true
    oBgR,oBgG,oBgB=15,15,20
    oBgA=0.55
    oRgbOn=false
    oRgbSpeed=60
    oRgbThick=2
    oRgbWasOn=false
end

local function rebuildCpCombo()
    if not cpCombo then return end
    cpCombo:Clear()
    cpCombo:Add("None")
    for _,p in ipairs(S.gc_cp) do cpCombo:Add(p.name) end
    UI.SetValue("grav_cp_combo",0)
end

local function syncUI()
    UI.SetValue("grav_value",S.gc_t)
    UI.SetValue("grav_auto",S.gc_aa)
    UI.SetValue("grav_random",false)
    UI.SetValue("grav_rand_min",S.gc_rmin)
    UI.SetValue("grav_rand_max",S.gc_rmax)
    UI.SetValue("grav_random_int",S.gc_ri)
    UI.SetValue("grav_flip",false)
    UI.SetValue("grav_flip_int",S.gc_fi)
    UI.SetValue("grav_overlay",oOn)
    UI.SetValue("grav_ov_font",oFi-1)
    UI.SetValue("grav_ov_size",oSz)
    UI.SetValue("grav_ov_x",oX)
    UI.SetValue("grav_ov_y",oY)
    UI.SetValue("grav_bg_on",oBgOn)
    UI.SetValue("grav_rgb_on",oRgbOn)
    UI.SetValue("grav_rgb_speed",oRgbSpeed)
    UI.SetValue("grav_rgb_thick",oRgbThick)
    UI.SetValue("grav_an_on",S.an_on)
    UI.SetValue("grav_an_show",S.an_show)
    UI.SetValue("grav_an_style",S.an_style)
    UI.SetValue("grav_an_speed",S.an_speed)
    UI.SetValue("grav_an_hold",S.an_hold)
    UI.SetValue("grav_an_delay",S.an_delay)
    UI.SetValue("grav_an_erase",S.an_erase)
    UI.SetValue("grav_an_glitch",glitchIdx())
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

local rgbLine=Drawing.new("Square")
rgbLine.Filled=false
rgbLine.Color=Color3.fromRGB(255,0,0)
rgbLine.Transparency=1
rgbLine.Thickness=oRgbThick
rgbLine.Corner=8
rgbLine.Visible=false

local N=4
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

local rgbHue=0

local function renderDefault()
    if S.an_glitch==0 then return ATXT:sub(1,animIdx) end
    local out={}
    for i=1,animIdx do
        if i==animIdx and math.random(100)<=S.an_glitch then
            local g=math.random(#GCH)
            out[i]=GCH:sub(g,g)
        else
            out[i]=ATXT:sub(i,i)
        end
    end
    return table.concat(out)
end

local function renderDecrypt()
    local out={}
    for i=1,#ATXT do
        local c=ATXT:sub(i,i)
        if c==" " then
            out[i]=" "
        elseif i<=animIdx then
            out[i]=c
        else
            local p=math.random(#DCH)
            out[i]=DCH:sub(p,p)
        end
    end
    return table.concat(out)
end

local function renderAnim()
    if S.an_style==1 then return renderDecrypt() end
    return renderDefault()
end

task.spawn(function()
    local last=tick()
    while true do
        local now=tick()
        local dt=now-last
        last=now
        if S.an_on then
            if animState=="typing" then
                animTimer=animTimer+dt
                local step=1/S.an_speed
                while animTimer>=step and animIdx<#ATXT do
                    animTimer=animTimer-step
                    animIdx=animIdx+1
                end
                animText=renderAnim()
                if animIdx>=#ATXT then
                    animState="holding"
                    animTimer=0
                    animText=ATXT
                end
            elseif animState=="holding" then
                animTimer=animTimer+dt
                if animTimer>=S.an_hold then
                    animState=S.an_erase and "erasing" or "delaying"
                    animTimer=0
                    if not S.an_erase then
                        animText=(S.an_style==1) and renderDecrypt() or ATXT
                    end
                end
            elseif animState=="erasing" then
                animTimer=animTimer+dt
                local step=1/S.an_speed
                while animTimer>=step and animIdx>0 do
                    animTimer=animTimer-step
                    animIdx=animIdx-1
                end
                if S.an_style==1 then
                    animText=renderDecrypt()
                else
                    animText=ATXT:sub(1,animIdx)
                end
                if animIdx<=0 then
                    animState="delaying"
                    animTimer=0
                    if S.an_style==1 then animText=renderDecrypt() end
                end
            elseif animState=="delaying" then
                animTimer=animTimer+dt
                if animTimer>=S.an_delay then
                    animState="typing"
                    animTimer=0
                    animIdx=0
                    animText=""
                end
            end
        else
            animText=ATXT
        end
        wait(ATICK)
    end
end)

task.spawn(function()
    while true do
        if oOn then
            local cur=rg() or 0
            local lh=oSz+4
            local rnd=S.gc_rn or S.gc_rc>0
            local flp=S.gc_fn or S.gc_fc>0
            local counter=nil
            if rnd and flp then counter=string.format("RND:%d  FLIP:%d",S.gc_rc,S.gc_fc)
            elseif rnd then counter=string.format("RND:%d",S.gc_rc)
            elseif flp then counter=string.format("FLIP:%d",S.gc_fc) end
            local txt={
                S.an_show and animText or nil,
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
            if oRgbOn and oBgOn and vc>0 then
                rgbHue=(rgbHue+oRgbSpeed*0.03)%360
                rgbLine.Position=Vector2.new(oX,oY)
                rgbLine.Size=Vector2.new(w,h)
                rgbLine.Color=Color3.fromHSV(rgbHue/360,1,1)
                rgbLine.Transparency=1
                rgbLine.Thickness=oRgbThick
                rgbLine.Visible=true
                bgLine.Visible=false
            else
                rgbLine.Visible=false
                if oBgOn and vc>0 then
                    bgLine.Position=Vector2.new(oX,oY)
                    bgLine.Size=Vector2.new(w,h)
                    bgLine.Color=Color3.fromRGB(oBgR,oBgG,oBgB)
                    bgLine.Transparency=math.min(oBgA+0.25,1)
                    bgLine.Visible=true
                else
                    bgLine.Visible=false
                end
            end
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
            rgbLine.Visible=false
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

ldCustom()
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
    L:Button("Apply Now",100,20,function() sg(S.gc_t); S.gc_la=S.gc_t end)
    L:Button("Reset Gravity",100,20,function()
        ap(196.2)
        UI.SetValue("grav_preset",1)
        notify("Reset gravity to default","Gravity Changer+",1.5)
    end)
    L:Button("Invert Gravity",100,20,function()
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
    O:Toggle("grav_bg_on","Show Background",oBgOn,function(v)
        if not v then
            oRgbWasOn=oRgbOn
            oRgbOn=false
            UI.SetValue("grav_rgb_on",false)
        else
            if oRgbWasOn then
                oRgbOn=true
                UI.SetValue("grav_rgb_on",true)
            end
        end
        oBgOn=v
    end)
    O:ColorPicker("grav_bg_col",oBgR/255,oBgG/255,oBgB/255,oBgA,function(c,a)
        oBgR=math.floor(c.R*255+0.5)
        oBgG=math.floor(c.G*255+0.5)
        oBgB=math.floor(c.B*255+0.5)
        oBgA=a
    end)
    O:Toggle("grav_rgb_on","RGB Border",oRgbOn,function(v) oRgbOn=v end)
    O:SliderInt("grav_rgb_speed","RGB Speed",5,200,oRgbSpeed,function(v) oRgbSpeed=v end)
    O:SliderInt("grav_rgb_thick","RGB Width",1,6,oRgbThick,function(v) oRgbThick=v end)
    local fi={}
    for _,f in ipairs(FONTS) do table.insert(fi,f[1]) end
    O:Combo("grav_ov_font","Font",fi,oFi-1,function(i) oFi=i+1 end)
    O:SliderInt("grav_ov_size","Size",8,48,oSz,function(v) oSz=v end)
    O:SliderInt("grav_ov_x","X",0,1920,oX,function(v) oX=v end)
    O:SliderInt("grav_ov_y","Y",0,1080,oY,function(v) oY=v end)
    O:Button("Reset Stats",100,20,function()
        S.gc_rc=0
        S.gc_fc=0
        sv()
        notify("Stats reset","Gravity Changer+",1.5)
    end)
    O:Spacing()
    O:Text("Animation")
    O:Toggle("grav_an_show","Show Title",S.an_show,function(v)
        if not v then
            S.an_on_was=S.an_on
            S.an_on=false
            UI.SetValue("grav_an_on",false)
        else
            if S.an_on_was then
                S.an_on=true
                UI.SetValue("grav_an_on",true)
            end
        end
        S.an_show=v
    end)
    O:Toggle("grav_an_on","Enable Animation",S.an_on,function(v)
        S.an_on=v
        if not v then
            animText=ATXT
            animState="typing"
            animIdx=0
            animTimer=0
        end
    end)
    O:Combo("grav_an_style","Style",STYLES,S.an_style,function(i)
        S.an_style=i
        animState="typing"
        animIdx=0
        animTimer=0
        animText=renderAnim()
    end)
    local gm={}
    for _,m in ipairs(GMODES) do table.insert(gm,m[1]) end
    O:Combo("grav_an_glitch","Glitch Mode",gm,glitchIdx(),function(i) S.an_glitch=GMODES[i+1][2] end)
    O:SliderFloat("grav_an_speed","Speed (chars/s)",1.0,10.0,S.an_speed,"%.1f",function(v) S.an_speed=v end)
    O:SliderFloat("grav_an_hold","Hold (s)",0.0,5.0,S.an_hold,"%.1f",function(v) S.an_hold=v end)
    O:SliderFloat("grav_an_delay","Delay (s)",0.0,5.0,S.an_delay,"%.1f",function(v) S.an_delay=v end)
    O:Toggle("grav_an_erase","Erase Animation",S.an_erase,function(v) S.an_erase=v end)

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
    R:Button("Roll Once",100,20,function()
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
    C:Button("Save",100,20,function()
        sv()
        svCustom()
        UI.SetValue("grav_cp_name","")
        cpInputName=""
        print("[Gravity] Saved")
    end)
    C:Button("Load",100,20,function()
        ldCustom()
        if ld() then
            syncUI()
            rebuildCpCombo()
            sg(S.gc_t); S.gc_la=S.gc_t
            cpInputName=""
            notify("Config loaded","Gravity Changer+",1.5)
        end
    end)
    C:Button("Reset to Default",100,20,function()
        setDefaults()
        syncUI()
        sg(S.gc_t); S.gc_la=S.gc_t
        cpInputName=""
        notify("Reset to defaults","Gravity Changer+",1.5)
    end)
    C:Button("Delete Config",100,20,function()
        if isfile(CFG) then delfile(CFG) end
        setDefaults()
        syncUI()
        sg(S.gc_t); S.gc_la=S.gc_t
        cpInputName=""
        notify("Config deleted (custom presets kept)","Gravity Changer+",1.5)
    end)

    if loaded then syncUI() end
    rebuildCpCombo()
end)
