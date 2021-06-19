local menustate = {}

local mbg = love.graphics.newImage("graphics/m_bg.png")

local mbutton = love.graphics.newImage("graphics/m_button.png")

local mbutsel = love.graphics.newImage("graphics/m_butsel.png")

local mgh = love.graphics.newImage("graphics/m_gh.png")

local mgw = love.graphics.newImage("graphics/m_gw.png")

local mplay = love.graphics.newImage("graphics/m_play.png")

local mplaysav = love.graphics.newImage("graphics/m_playsav.png")

local mplayers = love.graphics.newImage("graphics/m_players.png")

local maicount = love.graphics.newImage("graphics/m_aicount.png")

local mlevel = {love.graphics.newImage("graphics/m_ailevel1.png"),
                love.graphics.newImage("graphics/m_ailevel2.png"),
                love.graphics.newImage("graphics/m_ailevel3.png")}

local catom = love.graphics.newImage("graphics/atom.png")

local kalogo = love.graphics.newImage("graphics/m_kalogo.png")

local atomparts = {love.graphics.newImage("graphics/m_atp1.png"),
                love.graphics.newImage("graphics/m_atp2.png"),
                love.graphics.newImage("graphics/m_atp3.png")}

local menutimer = 0.0 --Timer to prevent accidental button presses

local buttontimer = 0.0 --Button press timer

local buttonpressed = 0 --pressed button number (0 if none)

local buttonstepback = false --Should button value go backwards?

local requestedfunc = nil --Requested function (for click type buttons)

local issavefile = false --Was the game saved before? (shows a saved game play button variant if true)

local sndclick = love.audio.newSource("sounds/click.wav","static")

local madebystr = "Made by Nightwolf-47" --Attribution string (bottom-right corner)

local function playfunc(x,y) --Play button function: start the game
    _CAState.change("game")
end

local function mailevelicon() --Return correct AI level icon
    return mlevel[_CAAILevel]
end

local function mplayicon() --Return correct play button icon
    if issavefile then
        return mplaysav
    else
        return mplay
    end
end

local menuatoms = {} --Table of background atoms

--{icon,description,x,y,type,val1,val2,val3,val4,val5}
--icon can be either a Drawable or a function returning Drawable
--type == "click" -> val1 - function(x,y)
--type == "slider" -> val1 - global_var_name, val2 - min_value, val3 - max_value, val4 - delay, val5 - speed
--type == "switch" -> val1 - global_var_name
--type == "nofunc" -> no values
local buttons = {
    {mplayicon,"Start the game.",245,205,"click",playfunc}, --Play button
    {mgw,"Set grid width. (7-30)",50,325,"slider","_CAGridW",7,30,0.3,0.1}, --Grid Width
    {mgh,"Set grid height. (4-20)",245,325,"slider","_CAGridH",4,20,0.3,0.1}, --Grid Height
    {mplayers,"Set the amount of players. (2-4)",440,325,"slider","_CAPlayers",2,4,0,0}, --Player count
    {maicount,"Set up to how many players are AI. (0-4)",440,205,"slider","_CAAI",0,4,0,0}, --Max AI player count
    {mailevelicon,"Set the AI difficulty. (1-3)",50,205,"slider","_CAAILevel",1,3,0,0}, --AI difficulty level
}

local mcoltab = { --table of atom colors by player number
    [0] = {0.2,0.2,0.2,1}, --only for testing
    [1] = {1,0.2,0.2,1}, --red
    [2] = {0.2,0.4,1,1}, --blue
    [3] = {0,1,0,1}, --green
    [4] = {1,1,0,1} --yellow
}

local function spawnAtom(color,xpos,maxatoms) --Spawn menu background atoms unless atom count > maxatoms
    if #menuatoms >= maxatoms then return end
    table.insert(menuatoms,{xpos,-50,color,love.math.random(-200,200),love.math.random(100,300),love.math.random(1,3)})
end

local function movestep(varname,min,max) --Add 1 to value, set to minimal value if too high
    _G[varname] = _G[varname] + 1
    if min > max then min, max = max, min end
    if _G[varname] > max then
        _G[varname] = min
    end
end

local function movestepback(varname,min,max) --Remove 1 from value, set to max value if too low
    _G[varname] = _G[varname] - 1
    if min > max then min, max = max, min end
    if _G[varname] < min then
        _G[varname] = max
    end
end

local function sliderclicked(varname,min,max,speed) --Move the value and play click sound every `speed` seconds when the button is pressed
    if not speed or speed == 0 then return end
    if buttontimer < speed then return end
    local amount = math.floor(buttontimer/speed)
    buttontimer = buttontimer - (amount*speed)
    love.audio.play(sndclick)
    if buttonstepback then
        for i = 1,amount do
            movestepback(varname,min,max)
        end
    else
        for i = 1,amount do
            movestep(varname,min,max)
        end
    end
end

function menustate.init() --Initialize/modify some values and set resolution
    menutimer = 0.0
    buttontimer = 0.0
    buttonpressed = 0
    buttonstepback = false
    if love.filesystem.getInfo("savegame.ksf") then
        buttons[1][2] = "Resume a saved game."
        issavefile = true 
    else
        buttons[1][2] = "Start the game."
        issavefile = false 
    end
    local winh = love.graphics.getHeight()
    local winw = love.graphics.getWidth()
    if _CAIsMobile then 
        buttons[2][8] = 18
        buttons[3][8] = 10
        buttons[2][2] = "Set grid width. (7-18)"
        buttons[3][2] = "Set grid height. (4-10)"
    end
    if _CAOSType == "Web" then --On Newgrounds, my nick is KleleMaster
        madebystr = "Made by KleleMaster"
    end
    if winw ~= 640 or winh ~= 480 or _CAOSType == "Web" then return 640,480 end
end

function menustate.update(dt)
    menutimer = menutimer + dt
    if buttonpressed > 0 and buttons[buttonpressed][5] == "slider" then
        buttontimer = buttontimer + dt
        local btab = buttons[buttonpressed]
        sliderclicked(btab[6],btab[7],btab[8],btab[10])
    end
    local newatoms = {}
    for k,v in ipairs(menuatoms) do
        v[1] = v[1] + v[4]*dt
        v[2] = v[2] + v[5]*dt
        if not (v[1] <= -44 or v[1] >= 640 or v[2] >= 524) then
            table.insert(newatoms,v)
        end
    end
    menuatoms = newatoms
    spawnAtom(love.math.random(1,4),love.math.random(20,620),15)
end

function menustate.draw()
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(mbg)
    for k,v in ipairs(menuatoms) do
        love.graphics.setColor(mcoltab[v[3]])
        love.graphics.draw(atomparts[v[6]],v[1],v[2])
    end
    for k,v in ipairs(buttons) do
        local buttonselected = false
        if buttonpressed == 0 or buttonpressed == k then
            local mx, my = _CAState.getMousePos()
            if mx >= v[3] and mx < v[3]+150 and my >= v[4] and my < v[4]+75 then --hover
                buttonselected = true
                if buttonpressed == 0 then
                    love.graphics.setColor(1,0.65,0,1)
                    love.graphics.printf(v[2],_CAFont24,20,425,600,"center")
                end
            end
        end
        love.graphics.setColor(1,1,1,1)
        if buttonselected then love.graphics.draw(mbutsel,v[3],v[4]) else love.graphics.draw(mbutton,v[3],v[4]) end
        local micon = v[1]
        if type(v[1]) == "function" then micon = v[1]() end
        if v[5] == "click" or v[5] == "nofunc" then
            love.graphics.draw(micon,v[3]+43,v[4]+5)
        elseif v[5] == "slider" then
            love.graphics.draw(micon,v[3]+10,v[4]+5)
            love.graphics.setColor(0,0,0,1)
            love.graphics.print(_G[v[6]],_CAFont24,v[3]+100,v[4]+23)
        elseif v[5] == "switch" then
            love.graphics.draw(micon,v[3]+10,v[4]+5)
            love.graphics.setColor(0,0,0,1)
            love.graphics.print(_G[v[6]],_CAFont24,v[3]+100,v[4]+23)
        end
    end
    if buttonpressed > 0 then
        love.graphics.setColor(1,0.65,0,1)
        love.graphics.printf(buttons[buttonpressed][2],_CAFont24,20,425,600,"center")
    end
    love.graphics.setColor(1,1,1,1)
    local klwidth, klheight = kalogo:getDimensions()
    love.graphics.draw(kalogo,(640-klwidth)/2,0)
    love.graphics.printf(madebystr,_CAFont16,5,460,630,"right")
    love.graphics.setColor(0,0,0,1)
    love.graphics.rectangle("fill",-50,0,50,480)
    love.graphics.rectangle("fill",640,0,50,480)
    love.graphics.setColor(1,1,1,1)
end

function menustate.keypressed(key)
    if _CAOSType ~= "Web" and menutimer >= 0.3 and key == "escape" then
        love.event.quit(0)
    end
end

function menustate.mousepressed(x,y,button)
    if menutimer >= 0.3 and (button == 1 or button == 2) then
        for k,v in ipairs(buttons) do
            if x >= v[3] and x < v[3]+150 and y >= v[4] and y < v[4]+75 then --pressed
                love.audio.play(sndclick)
                if v[5] == "click" then
                    requestedfunc = {v[6],x,y}
                elseif v[5] == "slider" then
                    if button == 1 then
                        movestep(v[6],v[7],v[8])
                        buttonstepback = false
                    else
                        movestepback(v[6],v[7],v[8])
                        buttonstepback = true
                    end
                    buttontimer = -v[9]
                elseif v[5] == "switch" then
                    _G[v[6]] = not _G[v[6]]
                end
                buttonpressed = k
            end
        end
    end
end

function menustate.mousereleased(x,y,button)
    if menutimer >= 0.3 then
        if button == 1 then
            buttonpressed = 0
            buttontimer = 0.0
        elseif button == 2 then
            buttonpressed = 0
            buttontimer = 0.0
            buttonstepback = false
        end
        if requestedfunc then
            requestedfunc[1](requestedfunc[2],requestedfunc[3])
            requestedfunc = nil
        end
    end
end

function menustate.stop() --Save settings
    local settstr = tostring(_CAGridW).."\n"..tostring(_CAGridH).."\n"..tostring(_CAPlayers).."\n"..tostring(_CAAI).."\n"..tostring(_CAAILevel)
    love.filesystem.write("settings.txt",settstr)
end

return menustate
