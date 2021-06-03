local gamestate = {}

local catom = love.graphics.newImage("graphics/atom.png")

local cexplode = love.graphics.newImage("graphics/explode.png")

local cplayer = love.graphics.newImage("graphics/player.png")

local cplayerai = love.graphics.newImage("graphics/playerai.png")

local cback = love.graphics.newImage("graphics/back.png")

local gamelogic = require("states.game.gamelogic")

local restarttime = 0.0 --In-game timer

local exiting = nil --If the exit button is clicked, it stores a mouse button

local colornames = {"Red","Blue","Green","Yellow"}

local function getGameTime()
    return string.format("%0.2d:%0.2d",restarttime / 60,restarttime % 60)
end

function gamestate.init()
    gamelogic.loadAll(_CAGridW,_CAGridH,_CAPlayers,_CAAI,_CAAILevel)
    if _CARFill then gamelogic.randomFill(_CAGridW,math.ceil(_CAGridH/2)) end
    restarttime = 0.0
    exiting = nil
    return gamelogic.winsize[1],gamelogic.winsize[2]
end

function gamestate.update(dt)
    if not gamelogic.bgimg then gamelogic.generateGrid(_CAGridW,_CAGridH) end
    restarttime = restarttime + dt
    if gamelogic.playerwon == 0 then
        gamelogic.tick(dt)
    else
        love.window.showMessageBox("Victory!","Player "..tostring(gamelogic.playerwon).." ("..colornames[gamelogic.playerwon]..") has won!\nTime: "..getGameTime(),"info")
        _CAState.change("menu")
    end
end

function gamestate.draw() --Draw all stuff except victory window, move animated atoms and calculate atom count for each player
    local dt = love.timer.getDelta()
    local mspeed = gamelogic.cATOMSPEED*dt*math.max(math.min(gamelogic.expcount,2000)/10,1) --move speed (in pixels)
    gamelogic.animplaying = false
    love.graphics.setColor(1,1,1,1)
    if gamelogic.bgimg then love.graphics.draw(gamelogic.bgimg) end
    for k,v in ipairs(gamelogic.playeratoms) do
        gamelogic.playeratoms[k] = 0
    end
    for k,v in ipairs(gamelogic.playertab) do
        local ypos = 20
        local xpos = math.floor(k*gamelogic.winsize[1]/(#gamelogic.playertab+1)-12)
        if not v then
            love.graphics.setColor(0.5,0.5,0.5,1)
        elseif gamelogic.curplayer == k then
            love.graphics.setColor(1,1,1,1)
            love.graphics.rectangle("fill",xpos-2,ypos-2,29,54)
            love.graphics.setColor(gamelogic.coltab[k])
        else
            love.graphics.setColor(gamelogic.coltab[k])
        end
        if gamelogic.ai.playertab[k] then
            love.graphics.draw(cplayerai,xpos,ypos)
        else
            love.graphics.draw(cplayer,xpos,ypos)
        end
    end
    for x = 1,_CAGridW do
        for y = 1,_CAGridH do
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
                if plcolor > 0 and plcolor <= #gamelogic.playertab then gamelogic.playeratoms[plcolor] = gamelogic.playeratoms[plcolor] + #gamelogic.grid[x][y].atoms end --Calculate player atoms
            end
        end
    end
    love.graphics.setColor(1,1,1,1)
    love.graphics.printf(getGameTime(),_CAFont16,0,0,gamelogic.winsize[1]-2,"right")
    love.graphics.draw(cback,2,2)
end

function gamestate.keypressed(key,scancode,isrepeat)
    if restarttime >= 0.3 and (key == "m" or key == "escape") then
        _CAState.change("menu")
    end
end

function gamestate.mousepressed(x, y, button)
    if x >= 0 and x <= 44 and y <= 44 then
        exiting = button
    elseif x >= 10 and x < 10+_CAGridW*gamelogic.cGRIDSIZE and y >= 90 and y < 90+_CAGridH*gamelogic.cGRIDSIZE then
        local pressx = math.floor((x-10)/gamelogic.cGRIDSIZE)+1
        local pressy = math.floor((y-90)/gamelogic.cGRIDSIZE)+1
        gamelogic.clickedTile(pressx,pressy)
    end
end

function gamestate.mousereleased(x,y,button)
    if exiting == button then
        _CAState.change("menu")
    end
end

return gamestate
