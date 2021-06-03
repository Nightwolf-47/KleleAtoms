_CAState = require("state")

local settsvals = { --A table to convert settings.txt line number to a setting name
    "_CAGridW",
    "_CAGridH",
    "_CAPlayers",
    "_CAAI",
    "_CAAILevel"
}

local function checkSetValues()
    _CAGridW = math.max(math.min(_CAGridW, 30), 7)
    _CAGridH = math.max(math.min(_CAGridH, 20), 4)
    _CAPlayers = math.max(math.min(_CAPlayers, 4), 2)
    _CAAI = math.max(math.min(_CAAI, 4), 0)
    _CAAILevel = math.max(math.min(_CAAILevel, 3), 1)
end

local function readArgs(args)
    local valmode = 0 --0 - nothing, 1 - grid width, 2 - grid height, 3 - players, 4 - AI player count, 5 - AI difficulty
    for k,v in ipairs(args) do
        if valmode == 0 then
            if v == "-gridwidth" or v == "-gw" then
                valmode = 1
            elseif v == "-gridheight" or v == "-gh" then
                valmode = 2
            elseif v == "-players" or v == "-p" then
                valmode = 3
            elseif v == "-aicount" or v == "-ai" then
                valmode = 4
            elseif v == "-ailevel" or v == "-al" then
                valmode = 5
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
    if not love.filesystem.getInfo("settings.txt") then return end
    for line in love.filesystem.lines("settings.txt") do
        if inum <= #settsvals then
            local index = settsvals[inum]
            _G[index] = tonumber(line) or _G[index]
            inum = inum + 1
        end
    end
end

function love.load(args)
    love.graphics.setDefaultFilter("linear","linear",0)
    _CAFont16 = love.graphics.newFont(16) --Default font, size 16
    _CAFont24 = love.graphics.newFont(24) --Default font, size 24
    _CAFont32 = love.graphics.newFont(32) --Default font, size 32
    _CAGridW = 10 --Grid width
    _CAGridH = 6 --Grid Height
    _CAPlayers = 2 --Total player count
    _CAAI = 0 --Max AI player count
    _CAAILevel = 2 --AI difficulty level (1 - easy, 2 - medium, 3 - hard)
    _CAOSType = love.system.getOS()
    _CAIsMobile = (_CAOSType == "Android" or _CAOSType == "iOS" or _CAOSType == "Web") --If true, mobile mode will be enabled
    _CAKBMode = false --Keyboard mode
    loadSettings()
    readArgs(args) --Read commandline parameters
    checkSetValues() --Make sure the settings are within the acceptable range
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
