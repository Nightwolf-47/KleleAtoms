_CAState = require("state")

local settsvals = { --A table to convert settings2.txt line number to a setting name
    "_CAGridW",
    "_CAGridH",
    "_CAPlayExp",
    "_CAPlayer1",
    "_CAPlayer2",
    "_CAPlayer3",
    "_CAPlayer4",
    "_CAFullScreen",
    "_CAWinResizing"
}

local function checkValidPlayers() --Makes sure that at least 2 players are present
    local pc = 0
    for i = 4,7 do
        if _G[settsvals[i]] > 0 then
            pc = pc + 1
        end
    end
    if pc < 2 then
        local pos = 4
        while pc < 2 do
            if _G[settsvals[pos]] == 0 then
                pc = pc + 1
                _G[settsvals[pos]] = 1
            end
            pos = pos + 1
        end
    end
end

local function checkSetValues() --Checks if values are in a valid range and type
    _CAGridW = math.max(math.min(_CAGridW, 30), 7)
    _CAGridH = math.max(math.min(_CAGridH, 20), 4)
    _CAPlayExp = math.max(math.min(_CAPlayExp, 3), 1)
    _CAPlayer1 = math.max(math.min(_CAPlayer1, 4), 0)
    _CAPlayer2 = math.max(math.min(_CAPlayer2, 4), 0)
    _CAPlayer3 = math.max(math.min(_CAPlayer3, 4), 0)
    _CAPlayer4 = math.max(math.min(_CAPlayer4, 4), 0)
    _CAFullScreen = (_CAFullScreen and _CAFullScreen ~= 0)
    _CAWinResizing = (_CAWinResizing and _CAWinResizing ~= 0)
    checkValidPlayers()
end

local function readArgs(args)
    local valmode = 0 --0 - nothing, 1 - grid width, 2 - grid height, 3 - AI difficulty, 4-7 - Player types, 100 - OS type
    for k,v in ipairs(args) do
        if valmode == 0 then
            if v == "-gridwidth" or v == "-gw" then
                valmode = 1
            elseif v == "-gridheight" or v == "-gh" then
                valmode = 2
            elseif (string.sub(v,1,-2) == "-player" and v ~= "-players") or string.sub(v,1,-2) == "-p" then
                local pnum = tonumber(string.sub(v,-1,-1))
                if pnum and pnum >= 1 and pnum <= 4 then
                    valmode = 3 + pnum
                end
            elseif v == "-mobilemode" or v == "-mobile" then
                _CAIsMobile = true
            elseif v == "-forceos" or v == "-os" then
                valmode = 100
            elseif v == "-fullscreen" or v == "-full" then
                valmode = 101
            elseif v == "-resizable" or v == "-resize" then
                valmode = 102
            end
        elseif valmode > 0 and valmode <= 7 then
            local index = settsvals[valmode]
            _G[index] = tonumber(v) or _G[index]
            valmode = 0
        elseif valmode == 100 then --Force OS type
            _CAOSType = v
            _CAIsMobile = _CAIsMobile or (_CAOSType == "Android" or _CAOSType == "iOS" or _CAOSType == "Web")
            valmode = 0
        elseif valmode == 101 then --Fullscreen
            _CAFullScreen = tonumber(v) or _CAFullScreen
            valmode = 0
        elseif valmode == 102 then --Window resizing
            _CAWinResizing = tonumber(v) or _CAWinResizing
            valmode = 0
        end
    end
end

local function loadSettings()
    local inum = 1
    if love.filesystem.getInfo("settings2.txt") then --Load a settings file (1.2 and newer versions)
        for line in love.filesystem.lines("settings2.txt") do
            if inum <= #settsvals then
                local index = settsvals[inum]
                _G[index] = tonumber(line) or _G[index]
                inum = inum + 1
            end
        end
    elseif love.filesystem.getInfo("settings.txt") then --Convert settings format from 1.1.2 and older versions to 1.2 format (with 1.3 changes)
        local pcount = nil
        for line in love.filesystem.lines("settings.txt") do
            if inum <= 2 then
                local index = settsvals[inum]
                _G[index] = tonumber(line) or _G[index]
            elseif inum == 3 then --Old index 3 and 4 are replaced by separate player type settings
                pcount = tonumber(line)
                _CAPlayer1,_CAPlayer2,_CAPlayer3,_CAPlayer4 = 0,0,0,0
                if pcount then
                    pcount = math.min(pcount,4)
                    for i = 1,pcount do
                        local index = settsvals[3+i]
                        _G[index] = 1
                    end
                end
            elseif inum == 4 then
                local aicount = tonumber(line)
                if aicount and pcount then
                    aicount = math.min(aicount,4)
                    for i = pcount-aicount+1,pcount do
                        local index = settsvals[3+i]
                        if _G[index] == 0 then break end
                        _G[index] = 3
                    end
                end
            elseif inum == 5 then --AI difficulty
                local ailevel = tonumber(line) or 2
                for i = 1,4 do
                    local index = settsvals[3+i]
                    if _G[index] == 3 then
                        _G[index] = 1 + ailevel
                    end
                end
            end
            inum = inum + 1
        end
        _CAPlayExp = 2 --Hide the tutorial message
        _CAState.printmsg("Converted old settings to 1.2+ format!",4)
    end
end

function love.load(args)
    love.graphics.setDefaultFilter("linear","linear",0)
    _CAFont16 = love.graphics.newFont(16) --Default font, size 16
    _CAFont24 = love.graphics.newFont(24) --Default font, size 24
    _CAFont32 = love.graphics.newFont(32) --Default font, size 32
    _CAGridW = 10 --Grid width
    _CAGridH = 6 --Grid Height
    _CAPlayer1 = 1 --Player 1 type (0 - not present, 1 - player, 2 - AI easy, 3 - AI medium, 4 - AI hard, 9 - dummy/scripted)
    _CAPlayer2 = 3 --Player 2 type
    _CAPlayer3 = 0 --Player 3 type
    _CAPlayer4 = 0 --Player 4 type
    _CAPlayExp = 1 --Player experience (1 - none, 2 - started/skipped tutorial, 3 - won a game), replaces unused AI Level variable
    _CAOSType = love.system.getOS()
    _CAFullScreen = false
    _CAWinResizing = false --Window resizing (on PC)
    _CAIsMobile = (_CAOSType == "Android" or _CAOSType == "iOS" or _CAOSType == "Web") --If true, mobile mode will be enabled
    _CAKBMode = false --Keyboard mode
    loadSettings()
    readArgs(args) --Read commandline parameters
    checkSetValues() --Make sure the settings are within the acceptable range
    if _CAIsMobile then _CAFullScreen = true end --Fullscreen is always enabled in mobile mode
    _CAUseScaling = (_CAFullScreen or _CAWinResizing) --Is any type of window scaling used?
    _CAState.list["game"] = require("states.game.gamestate")
    _CAState.list["menu"] = require("states.menu.menustate")
    _CAState.change("menu")
end

love.update = _CAState.update

love.draw = _CAState.draw

love.keypressed = _CAState.keypressed

love.keyreleased = _CAState.keyreleased

love.mousepressed = _CAState.mousepressed

love.mousereleased = _CAState.mousereleased

love.focus = _CAState.focus

love.quit = _CAState.quit

love.resize = _CAState.resize
