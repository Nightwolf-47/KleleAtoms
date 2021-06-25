local pausestate = {} --PauseState class

local background = nil --Background screenshot

local gamelogic = nil --Gamelogic table reference

local winx = -1 --Current window width (on desktop limited to 480)

local winy = -1 --Current window height (on desktop limited to 360)

local pfont = _CAFont24 --Pause text font

local bfont = _CAFont16 --Button text font

local bfontsize = 16 --Button text font size

local winpos = {0,0,0,0,0,0} --1-4th numbers - positions of top-left and bottom-right corners, 5-6th are pause text width and y position

local butpos = {} 

butpos[1] = {0,0,0,0} --1-4th numbers - the same as above

butpos[2] = {0,0,0,0}

butpos[3] = {0,0,0,0}

butpos[4] = {0,0,0,0}

local cbut = nil --Button texture (rendered once)

local cbutpress = nil --Pressed button texture (rendered once)

local pausetime = 0.0 --Time spent in pause menu

local buttonclicked = nil --The pause menu button that is being clicked or nil if none

local gametime = 0.0 --A copy of in-game time (for game saving)

local sndclick = love.audio.newSource("sounds/click.wav","static")

local function pst(num) --Convert player status from 2 booleans to a number 0-2
    if gamelogic.playertab[num] then
        if gamelogic.playermoved[num] then
            return 2
        else
            return 1
        end
    else
        return 0
    end
end

local function pai(num) --Convert AI player boolean to a 0 or 1
    if gamelogic.ai.playertab[num] then
        return 1
    else
        return 0
    end
end

local function saveGame() --Save the game to savegame.ksf file
    local gw = #gamelogic.grid
    local gh = #gamelogic.grid[1]
    local str = "KSF"..string.char(gw % 256)..string.char(gh % 256)..string.char(math.min(#gamelogic.playertab,4))..string.char(gamelogic.players % 256)..string.char(gamelogic.ai.difficulty % 256)..string.char(gamelogic.curplayer % 256)..string.char(pst(1))..string.char(pst(2))..string.char(pst(3))..string.char(pst(4))..string.char(pai(1))..string.char(pai(2))..string.char(pai(3))..string.char(pai(4))..string.char(gametime % 60)..string.char((gametime/60) % 60)..string.char((gametime/3600) % 256)
    for x = 1,gw do
        for y = 1,gh do
            str = str..string.char(gamelogic.grid[x][y].player % 256)..string.char(#gamelogic.grid[x][y].atoms % 256)
        end
    end
    if love.filesystem.write("savegame.ksf",str) then
        return true
    else
        return false
    end
end

local function setupPauseMenu() --Calculate window, text and button positions, render buttons, calculate font sizes
    local yoffs = 0
    local xoffs = 0
    if not _CAIsMobile then
        if winx > 480 then
            xoffs = math.floor((winx-480)/2)
            winx = 480
        end
        if winy > 360 then
            yoffs = math.floor((winy-360)/2)
            winy = 360
        end
    end
    if winy > winx then
        yoffs = yoffs + xoffs + math.floor((winy-winx)/2)
        winy = winx
    end
    winpos = {
        math.floor(winx/16+xoffs),
        math.floor(winy/8+yoffs),
        math.floor(15*winx/16+xoffs),
        math.floor(7*winy/8+yoffs),
        math.floor(28*winx/32),
        math.floor(3*winy/20+yoffs)
    }
    butpos[1] = {
        math.floor(1*(winpos[3]-winpos[1])/25+winpos[1]),
        math.floor(8*(winpos[4]-winpos[2])/12+winpos[2]),
        math.floor(12*(winpos[3]-winpos[1])/25+winpos[1]),
        math.floor(11*(winpos[4]-winpos[2])/12+winpos[2]),
    }
    butpos[2] = {
        math.floor(13*(winpos[3]-winpos[1])/25+winpos[1]),
        butpos[1][2],
        math.floor(24*(winpos[3]-winpos[1])/25+winpos[1]),
        butpos[1][4],
    }
    butpos[3] = {
        math.floor(1*(winpos[3]-winpos[1])/25+winpos[1]),
        math.floor(4*(winpos[4]-winpos[2])/12+winpos[2]),
        math.floor(12*(winpos[3]-winpos[1])/25+winpos[1]),
        math.floor(7*(winpos[4]-winpos[2])/12+winpos[2]),
    }
    butpos[4] = {
        math.floor(13*(winpos[3]-winpos[1])/25+winpos[1]),
        butpos[3][2],
        math.floor(24*(winpos[3]-winpos[1])/25+winpos[1]),
        butpos[3][4],
    }
    local minw = math.min(winpos[3]-winpos[1],winpos[4]-winpos[2])
    pfont = love.graphics.newFont(math.floor(minw/4))
    local bx = math.abs(butpos[1][3]-butpos[1][1])
    local by = math.abs(butpos[1][4]-butpos[1][2])
    local minb = math.min(bx,by)
    bfontsize = math.floor(6*minb/20)
    bfont = love.graphics.newFont(bfontsize)
    cbut = love.graphics.newCanvas(bx,by)
    cbutpress = love.graphics.newCanvas(bx,by)
    cbut:renderTo(function()
        love.graphics.setColor(0.5,0.5,0.5,1)
        love.graphics.rectangle("fill",0,0,bx-1,by-1)
        love.graphics.setColor(0,0,0,1)
        love.graphics.rectangle("line",0,0,bx-1,by-1)
        love.graphics.setColor(1,1,1,1)
    end)
    cbutpress:renderTo(function()
        love.graphics.setColor(0.3,0.3,0.3,1)
        love.graphics.rectangle("fill",0,0,bx-1,by-1)
        love.graphics.setColor(0,0,0,1)
        love.graphics.rectangle("line",0,0,bx-1,by-1)
        love.graphics.setColor(1,1,1,1)
    end)
end

local function buttonSelected(x,y,bnum)
    if (not buttonclicked or buttonclicked == bnum) and x >= butpos[bnum][1] and x <= butpos[bnum][3] and y >= butpos[bnum][2] and y <= butpos[bnum][4] then
        return true
    end
    return false
end

function pausestate.init(laststate,argtab)
    if laststate == "game" and argtab and argtab[1] and argtab[2] and argtab[3] then
        background = argtab[1]
        gamelogic = argtab[2]
        gametime = argtab[3]
        winx, winy = _CAState.getWindowSize()
        setupPauseMenu()
    else
        _CAState.printmsg("Couldn't load pause menu properly!",3)
        _CAState.change("menu")
    end
    pausetime = 0.0
    buttonclicked = nil
end

function pausestate.update(dt)
    pausetime = pausetime + dt
end

function pausestate.draw()
   _CAState.mobileAbsMode(true)
    love.graphics.setColor(0.5,0.5,0.5,1)
    if background then love.graphics.draw(background) end
    _CAState.mobileAbsMode(false)
    love.graphics.setColor(1,1,1,1)
    love.graphics.rectangle("line",winpos[1],winpos[2],winpos[3]-winpos[1],winpos[4]-winpos[2])
    love.graphics.setColor(0.2,0.2,0.2,1)
    love.graphics.rectangle("fill",winpos[1],winpos[2],winpos[3]-winpos[1],winpos[4]-winpos[2])
    love.graphics.setColor(1,1,1,1)
    love.graphics.printf("PAUSE",pfont,winpos[1],winpos[6],winpos[5],"center")
    local mx, my = _CAState.getMousePos()
    for i = 1,4 do
        if buttonSelected(mx,my,i) then love.graphics.draw(cbutpress,butpos[i][1],butpos[i][2]) else love.graphics.draw(cbut,butpos[i][1],butpos[i][2]) end
    end
    love.graphics.printf("Menu",bfont,butpos[1][1],math.floor(butpos[1][4]+((butpos[1][2]-butpos[1][4]-bfontsize)/2)),butpos[1][3]-butpos[1][1],"center")
    love.graphics.printf("Reset",bfont,butpos[2][1],math.floor(butpos[2][4]+((butpos[2][2]-butpos[2][4]-bfontsize)/2)),butpos[2][3]-butpos[2][1],"center")
    love.graphics.printf("Play",bfont,butpos[3][1],math.floor(butpos[3][4]+((butpos[3][2]-butpos[3][4]-bfontsize)/2)),butpos[3][3]-butpos[3][1],"center")
    love.graphics.printf("Save & Quit",bfont,butpos[4][1],math.floor(butpos[4][4]+((butpos[4][2]-butpos[4][4]-bfontsize)/2)),butpos[4][3]-butpos[4][1],"center")
end

function pausestate.keyreleased(key)
    if pausetime >= 0.3 then
        if key == "escape" then
            _CAState.change("game")
        elseif key == "m" then
            _CAState.change("menu")
        end
    end
end

function pausestate.mousepressed(x,y,button)
    for i = 1,4 do
        if x >= butpos[i][1] and x <= butpos[i][3] and y >= butpos[i][2] and y <= butpos[i][4] then
            love.audio.play(sndclick)
            buttonclicked = i
            break
        end
    end
end

function pausestate.mousereleased(x,y,button)
    if buttonclicked == 1 then
        _CAState.change("menu")
    elseif buttonclicked == 2 then
        _CAState.change("game",{"restart"})
    elseif buttonclicked == 3 then
        _CAState.change("game")
    elseif buttonclicked == 4 then
        if saveGame() then
            _CAState.printmsg("Game has been saved.",2)
            _CAState.change("menu")
        else
            _CAState.printmsg("Could not save the game!",2)
        end
    end
    buttonclicked = nil
end

return pausestate
