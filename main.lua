_CAState = require("state")

local settsvals = { --A table to convert settings2.txt line number to a setting name
    "_CAGridW",
    "_CAGridH",
    "_CAAILevel",
    "_CAPlayer1",
    "_CAPlayer2",
    "_CAPlayer3",
    "_CAPlayer4"
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

local function checkSetValues() --Checks if values are in a valid range
    _CAGridW = math.max(math.min(_CAGridW, 30), 7)
    _CAGridH = math.max(math.min(_CAGridH, 20), 4)
    _CAAILevel = math.max(math.min(_CAAILevel, 3), 1)
    _CAPlayer1 = math.max(math.min(_CAPlayer1, 2), 0)
    _CAPlayer2 = math.max(math.min(_CAPlayer2, 2), 0)
    _CAPlayer3 = math.max(math.min(_CAPlayer3, 2), 0)
    _CAPlayer4 = math.max(math.min(_CAPlayer4, 2), 0)
    checkValidPlayers()
end

local function readArgs(args)
    local valmode = 0 --0 - nothing, 1 - grid width, 2 - grid height, 3 - players, 4 - AI player count, 5 - AI difficulty
    for k,v in ipairs(args) do
        if valmode == 0 then
            if v == "-gridwidth" or v == "-gw" then
                valmode = 1
            elseif v == "-gridheight" or v == "-gh" then
                valmode = 2
            elseif v == "-ailevel" or v == "-al" then
                valmode = 3
            elseif (string.sub(v,1,-2) == "-player" and v ~= "-players") or string.sub(v,1,-2) == "-p" then
                local pnum = tonumber(string.sub(v,-1,-1))
                if pnum and pnum >= 1 and pnum <= 4 then
                    valmode = 3 + pnum
                end
            elseif v == "-mobilemode" or v == "-mobile" then
                _CAIsMobile = true
            elseif v == "-kbmode" then --Keyboard mode (adds virtual mouse controlled by keyboard)
                _CAKBMode = true
            end
        elseif valmode > 0 and valmode <= 5 then
            local index = settsvals[valmode]
            _G[index] = tonumber(v) or _G[index]
            valmode = 0
        end
    end
end

local function loadSettings()
    local inum = 1
    if love.filesystem.getInfo("settings2.txt") then
        for line in love.filesystem.lines("settings2.txt") do
            if inum <= #settsvals then
                local index = settsvals[inum]
                _G[index] = tonumber(line) or _G[index]
                inum = inum + 1
            end
        end
    elseif love.filesystem.getInfo("settings.txt") then --Convert settings format from 1.1.2 and older versions to 1.2 format
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
                        _G[index] = 2
                    end
                end
            elseif inum == 5 then
                local index = settsvals[3]
                _G[index] = tonumber(line) or _G[index]
            end
            inum = inum + 1
        end
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
    _CAPlayer1 = 1 --Player 1 type (0 - not present, 1 - player, 2 - AI, 3 - dummy/scripted)
    _CAPlayer2 = 2 --Player 2 type
    _CAPlayer3 = 0 --Player 3 type
    _CAPlayer4 = 0 --Player 4 type
    _CAAILevel = 2 --AI difficulty level (1 - easy, 2 - medium, 3 - hard)
    _CAOSType = love.system.getOS()
    _CAIsMobile = (_CAOSType == "Android" or _CAOSType == "iOS" or _CAOSType == "Web") --If true, mobile mode will be enabled
    _CAKBMode = false --Keyboard mode
    loadSettings()
    readArgs(args) --Read commandline parameters
    checkSetValues() --Make sure the settings are within the acceptable range
    _CAState.list["game"] = require("states.game.gamestate")
    _CAState.list["menu"] = require("states.menu.menustate")
    _CAState.list["pause"] = require("states.pause.pausestate")
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
