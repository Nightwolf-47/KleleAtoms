local gamestate = {}

local catom = love.graphics.newImage("graphics/atom.png")

local cexplode = love.graphics.newImage("graphics/explode.png")

local cplayer = love.graphics.newImage("graphics/player.png")

local cplayerai = love.graphics.newImage("graphics/playerai.png")

local cback = love.graphics.newImage("graphics/back.png")

local gamelogic = require("states.game.gamelogic")

local gametut = require("states.game.gametut")

local restarttime = 0.0 --In-game timer

local exiting = nil --If the exit button is clicked, it stores a mouse button

local pausing = false --Will the game pause next turn?

local tutorial = false --Is tutorial active?

local function getGameTime()
    return string.format("%0.2d:%0.2d",math.floor(restarttime / 60),math.floor(restarttime % 60))
end

local function pauseGame()
	if tutorial then
		_CAState.change("menu")
		return
	end
    if #gamelogic.atomstack > 0 or gamelogic.animplaying then
        pausing = true
        _CAState.printmsg("Pausing...",0.1)
        return
    end
    pausing = false
    love.graphics.captureScreenshot(function(imgdata)
        local screenshot = love.graphics.newImage(imgdata)
        _CAState.change("pause",{screenshot,gamelogic,restarttime})
    end)
end

function gamestate.init(laststate,argtab)
    exiting = nil
    screenshot = nil
    pausing = false
	tutorial = false
    if laststate ~= "pause" or (argtab and argtab[1] == "restart") then
		restarttime = 0.0
		local ttime = nil
		if argtab and argtab[1] == "tutorial" then
			tutorial = true
			gamelogic.loadAll(10,6,2,{1,3,3,3})
			gametut.init(gamelogic)
		else
			gamelogic.loadAll(_CAGridW,_CAGridH,_CAAILevel,{_CAPlayer1,_CAPlayer2,_CAPlayer3,_CAPlayer4})
			ttime = gamelogic.loadGame()
		end
        if ttime then restarttime = ttime; _CAState.printmsg("Saved game loaded.",2) end
        return gamelogic.winsize[1],gamelogic.winsize[2]
    else
        gamelogic.generateGrid(#gamelogic.grid,#gamelogic.grid[1])
    end
end

function gamestate.update(dt)
    if not gamelogic.bgimg then gamelogic.generateGrid(#gamelogic.grid,#gamelogic.grid[1]) end
    if gamelogic.playerwon == 0 then
        if pausing then pauseGame() end
        restarttime = restarttime + dt
		if tutorial then
			if gametut.update(dt) then return end
		end
        gamelogic.tick(dt)
    end
end

function gamestate.draw() --Draw all stuff, move animated atoms and calculate atom count for each player
    local dt = love.timer.getDelta()
    local mspeed = gamelogic.cATOMSPEED*dt*math.max(math.min(gamelogic.expcount,2000)/10,1) --move speed (in pixels)
    gamelogic.animplaying = false
    love.graphics.setColor(1,1,1,1)
    if gamelogic.bgimg then love.graphics.draw(gamelogic.bgimg) end
    for i = 1,4 do
        gamelogic.playeratoms[i] = 0
    end
	local k = 0
    for i = 1,4 do
		local v = gamelogic.playertab[i]
		if v ~= nil then
			k = k + 1
			local ypos = 20
			local xpos = math.floor(k*gamelogic.winsize[1]/(gamelogic.startplayers+1)-12)
			if not v then
				love.graphics.setColor(0.5,0.5,0.5,1)
			elseif gamelogic.curplayer == i then
				love.graphics.setColor(1,1,1,1)
				love.graphics.rectangle("fill",xpos-2,ypos-2,29,54)
				love.graphics.setColor(gamelogic.coltab[i])
			else
				love.graphics.setColor(gamelogic.coltab[i])
			end
			if gamelogic.ai.playertab[i] then
				love.graphics.draw(cplayerai,xpos,ypos)
			else
				love.graphics.draw(cplayer,xpos,ypos)
			end
		end
    end
    for x = 1,#gamelogic.grid do
        for y = 1,#gamelogic.grid[1] do
            local atomg = gamelogic.grid[x][y].atoms
            local plcolor = gamelogic.grid[x][y].player
            if gamelogic.grid[x][y].explode > 0 then --Atom is exploding
                gamelogic.animplaying = true
                gamelogic.grid[x][y].explode = math.max(gamelogic.grid[x][y].explode-dt,0)
                love.graphics.setColor(1,1,1,1)
                local qgridsize = 19*gamelogic.cGRIDSIZE/64
                love.graphics.draw(cexplode,10+((x-1)*gamelogic.cGRIDSIZE)+qgridsize,90+((y-1)*gamelogic.cGRIDSIZE)+qgridsize)
            elseif plcolor >= 0 and atomg then --Atoms are present, animate atoms if needed
                for k,v in ipairs(atomg) do
                    local xdist = math.abs(v[1]-v[3])
                    local ydist = math.abs(v[2]-v[4])
                    if xdist > 0 or ydist > 0 then
                        gamelogic.animplaying = true
                        local xdir = v[3]-v[1]
                        local ydir = v[4]-v[2]
                        if xdir > 0 then
                            xdir = 1
                        elseif xdir < 0 then
                            xdir = -1
                        end
                        if ydir > 0 then
                            ydir = 1
                        elseif ydir < 0 then
                            ydir = -1
                        end
                        local xstep = math.min(xdist,mspeed)*xdir
                        local ystep = math.min(ydist,mspeed)*ydir
                        v[1] = v[1] + xstep
                        v[2] = v[2] + ystep
                    end
                    local xpos = 10+((x-1)*gamelogic.cGRIDSIZE)+v[1]
                    local ypos = 90+((y-1)*gamelogic.cGRIDSIZE)+v[2]
                    love.graphics.setColor(gamelogic.coltab[plcolor])
                    love.graphics.draw(catom,xpos,ypos)
                end
                if plcolor > 0 and plcolor <= 4 and gamelogic.playertab[plcolor] ~= nil then gamelogic.playeratoms[plcolor] = gamelogic.playeratoms[plcolor] + #gamelogic.grid[x][y].atoms end --Calculate player atoms
            end
        end
    end
    if gamelogic.playerwon ~= 0 then 
        gamelogic.drawVictoryWin(getGameTime())
        return
    end
    love.graphics.setColor(1,1,1,1)
    love.graphics.printf(getGameTime(),_CAFont16,0,0,gamelogic.winsize[1]-2,"right")
	if tutorial then gametut.draw() end
    love.graphics.draw(cback,2,2)
end

function gamestate.keyreleased(key)
    if restarttime >= 0.3 then
        if key == "m" then
            _CAState.change("menu")
        elseif key == "escape" and gamestate.playerwon == 0 then
            pauseGame()
        end
    end
	if tutorial then gametut.keyreleased(key) end
end

function gamestate.mousepressed(x, y, button)
    local gw = #gamelogic.grid
    local gh = #gamelogic.grid[1]
    if gamelogic.playerwon ~= 0 or (x >= 0 and x <= 44 and y <= 44) then
        exiting = button
    else
        if tutorial and gametut.mousepressed(x,y,button) then 
			return 
		elseif x >= 10 and x < 10+gw*gamelogic.cGRIDSIZE and y >= 90 and y < 90+gh*gamelogic.cGRIDSIZE then
			local pressx = math.floor((x-10)/gamelogic.cGRIDSIZE)+1
        	local pressy = math.floor((y-90)/gamelogic.cGRIDSIZE)+1
        	gamelogic.clickedTile(pressx,pressy)
		end
    end
end

function gamestate.mousereleased(x,y,button)
    if exiting == button then
        if gamelogic.playerwon == 0 then
            pauseGame()
        else
            _CAState.change("menu")
        end
    end
end

return gamestate
