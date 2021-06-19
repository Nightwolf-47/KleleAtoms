local cAIDELAY = 0.3 --AI move delay

local aitime = 0.0 --Timer for AI (it can only move after cAIDELAY)

local ai = {}

local function aiIsTileEnemy(x,y) --Check if a tile belongs to another player
    local tplayer = logic.grid[x][y].player
    return (tplayer ~= 0 and tplayer ~= logic.curplayer)
end

local function aiGetCorners(gridx,gridy) --Get how many corners a player has
    local corcount = 0
    if logic.grid[1][1].player == logic.curplayer then corcount = corcount + 1 end
    if logic.grid[gridx][1].player == logic.curplayer then corcount = corcount + 1 end
    if logic.grid[1][gridy].player == logic.curplayer then corcount = corcount + 1 end
    if logic.grid[gridx][gridy].player == logic.curplayer then corcount = corcount + 1 end
    return corcount
end

local function aiAtomsNearby(x,y) --Check if any atoms are in the nearby tiles
    if y > 1 and #logic.grid[x][y-1].atoms > 0 then return true end
    if y < #logic.grid[1] and #logic.grid[x][y+1].atoms > 0 then return true end
    if x > 1 and #logic.grid[x-1][y].atoms > 0 then return true end
    if x < #logic.grid and #logic.grid[x+1][y].atoms > 0 then return true end
    return false
end

local function aiCheckAdvantage(x,y,patoms) --Check if you have advantage over any enemy tile
    if y > 1 and aiIsTileEnemy(x,y-1) and patoms >= #logic.grid[x][y-1].atoms-logic.critgrid[x][y-1] then return true end
    if y < #logic.grid[1] and aiIsTileEnemy(x,y+1) and patoms >= #logic.grid[x][y+1].atoms-logic.critgrid[x][y+1] then return true end
    if x > 1 and aiIsTileEnemy(x-1,y) and patoms >= #logic.grid[x-1][y].atoms-logic.critgrid[x-1][y] then return true end
    if x < #logic.grid and aiIsTileEnemy(x+1,y) and patoms >= #logic.grid[x+1][y].atoms-logic.critgrid[x+1][y] then return true end
    return false
end

local function aiCornerCheck(x,y) --Check if enemy or the current player has an undefended corner (1 atom on every side near the corner)
    if logic.critgrid[x][y] > 2 then return false end
    local ccval = 0
    local patoms = -2
    if y > 1 and logic.grid[x][y-1].player > 0 and patoms >= #logic.grid[x][y-1].atoms-logic.critgrid[x][y-1] then ccval = ccval + 1 end
    if y < #logic.grid[1] and logic.grid[x][y+1].player > 0 and patoms >= #logic.grid[x][y+1].atoms-logic.critgrid[x][y+1] then ccval = ccval + 1 end
    if x > 1 and logic.grid[x-1][y].player > 0 and patoms >= #logic.grid[x-1][y].atoms-logic.critgrid[x-1][y] then ccval = ccval + 1 end
    if x < #logic.grid and logic.grid[x+1][y].player > 0 and patoms >= #logic.grid[x+1][y].atoms-logic.critgrid[x+1][y] then ccval = ccval + 1 end
    return (ccval >= 2)
end

local function aiCheckPreCrit(x,y) --Check if any nearby enemy tiles are 1 atom before explosion
    if y > 1 and aiIsTileEnemy(x,y-1) and #logic.grid[x][y-1].atoms >= logic.critgrid[x][y-1]-1 then return true end
    if y < #logic.grid[1] and aiIsTileEnemy(x,y+1) and #logic.grid[x][y+1].atoms >= logic.critgrid[x][y+1]-1 then return true end
    if x > 1 and aiIsTileEnemy(x-1,y) and #logic.grid[x-1][y].atoms >= logic.critgrid[x-1][y]-1 then return true end
    if x < #logic.grid and aiIsTileEnemy(x+1,y) and #logic.grid[x+1][y].atoms >= logic.critgrid[x+1][y]-1 then return true end
    return false
end

local function aiGetSpecialTiles(difficulty) --Make a list of available tiles, avoided tiles and "special" tiles
    local sptiles = {} --Special tiles
    local advtiles = {} --Advantage tiles
    local tiles = {} --All available tiles
    local natiles = {} --Tiles without avoided ones
    local gridx = #logic.grid --Grid width
    local gridy = #logic.grid[1] --Grid height
    local wasSpCorner = false --Was any tile a special corner
    local wasAdvCorner = false --Was any tile an advantage corner
    local corners = {} --Corner tiles
    local cornercount = aiGetCorners(gridx,gridy)
    for x = 1,gridx do
        for y = 1,gridy do
            if logic.grid[x][y].player == logic.curplayer or logic.grid[x][y].player == 0 then --If tile is clickable by the player
                local isSpTile = false
                local tileAvoided = false
                table.insert(tiles,{x,y}) --Tile is valid
                table.insert(natiles,{x,y})
                if difficulty == 2 then --Medium difficulty
                    if aiCheckPreCrit(x,y) then --Check if any nearby tiles will explode after 1 atom is added
                        if #logic.grid[x][y].atoms == (logic.critgrid[x][y] - 1) then --If your tile will do it as well, focus on it
                            table.insert(sptiles,{x,y})
                            isSpTile = true
                        else --Otherwise, avoid it
                            table.remove(natiles)
                            tileAvoided = true
                        end
                    end
                elseif difficulty == 3 then --Hard (at least it's supposed to be)
                    local isCorner = (x == 1 or x == gridx) and (y == 1 or y == gridy)
                    if isCorner and atomcount == 1 and not aiAtomsNearby(x,y) then --Avoid exploding corners when no atoms are nearby
                        table.remove(natiles)
                        tileAvoided = true
                    elseif aiCheckPreCrit(x,y) then --Otherwise the same as in difficulty 2
                        if #logic.grid[x][y].atoms == (logic.critgrid[x][y] - 1) then
                            table.insert(sptiles,{x,y})
                            isSpTile = true
                        else
                            table.remove(natiles)
                            tileAvoided = true
                        end
                    end
                    local atomcount = #logic.grid[x][y].atoms
                    local isAdvantage = false
                    if not isSpTile then isAdvantage = aiCheckAdvantage(x,y,atomcount-logic.critgrid[x][y]) end --Check for any atom advantage in the tile
                    if not tileAvoided and (cornercount == 0 or aiCornerCheck(x,y)) and isCorner then --If corner tile is not avoided and the player either has no corners or the corner spot is undefended, focus on it
                        if wasSpCorner and isSpTile then --If any corner was special, only focus on special corners
                            table.insert(corners,{x,y})
                        elseif wasAdvCorner then --If any corner had an advantage, only focus on advantageous and special corners
                            if isSpTile then
                                corners = {}
                                wasSpCorner = true
                            end
                            table.insert(corners,{x,y})
                        else
                            if isSpTile then
                                corners = {}
                                wasSpCorner = true
                            elseif isAdvantage then
                                corners = {}
                                wasAdvCorner = true
                            end
                            if atomcount == 0 or isSpTile or isAdvantage then --Unless there's an advantage or it's a special tile, don't explode corner
                                table.insert(corners,{x,y})
                            end
                        end
                    elseif isAdvantage and not isCorner and not tileAvoided then --Add advantage tiles
                        table.insert(advtiles,{x,y})
                    end
                end
            end
        end
    end
    if #corners > 0 then --First priority: corners (only if none are claimed by the player or they're strategically important)
        sptiles = corners
    elseif #sptiles == 0 and #advtiles > 0 then --Second priority: special tiles, third priority: advantage tiles (difficulty 3 only)
        sptiles = advtiles
    end
    if #natiles > 0 then --If there are any tiles except avoided ones choose only them, otherwise choose any available tile
        tiles = natiles
    end
    return sptiles, tiles
end

local function aiThinker() --Pick a tile and use the clickedTile() function
    local tx = 0
    local ty = 0
    if ai.difficulty <= 3 then --Easy - just pick a random tile, Normal and Hard - more advanced strategies, not too advanced for optimization reasons
        local sptiles, tiles = aiGetSpecialTiles(ai.difficulty)
        if #sptiles > 0 then
            local rindex = love.math.random(1,#sptiles)
            tx = sptiles[rindex][1]
            ty = sptiles[rindex][2]
        else
            local rindex = love.math.random(1,#tiles)
            tx = tiles[rindex][1]
            ty = tiles[rindex][2]
        end
    else
        error("Incorrect AI difficulty - "..tostring(ai.difficulty))
    end
    logic.clickedTile(tx,ty,true) --Simulate clicking the chosen tile
end

ai.playertab = {false,false}

ai.difficulty = 2

function ai.init(logictab,pnum,aipnum,ailevel) --Initialize AI
    logic = logictab
    ai.playertab = {}
    for i = pnum,1,-1 do
        if aipnum > 0 then
            ai.playertab[i] = true
            aipnum = aipnum - 1
        else
            ai.playertab[i] = false
        end
    end
    ai.difficulty = ailevel
end

function ai.resetTime() --Reset AI delay timer
    aitime = 0.0
end

function ai.tryMove(dt) --Execute thinker if no more delay is required
    aitime = aitime + dt
    if aitime >= cAIDELAY then
        aiThinker()
    end
end

return ai
