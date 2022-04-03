local logic = {} --The main class

local cGRIDSIZE = 44 --Grid tile size in pixels

local cATOMSPEED = 60 --Atom animation speed in pixels per second

local sndput = love.audio.newSource("sounds/put.wav","static")

local sndexplode = love.audio.newSource("sounds/explode.wav","static")

local ctile = love.graphics.newImage("graphics/tile.png")

local colornames = {"Red","Blue","Green","Yellow"}

local checktab = { --Order of chain reaction checks
    {0,1},{0,-1},{1,0},{-1,0} --Down > Up > Right > Left
}

local ai = require("states.game.gameai")

local function getWinSize(w,h) --Get screen/window size based on grid size
    return (20+w*cGRIDSIZE),(100+h*cGRIDSIZE)
end

local function nextPlayer() --Set the current player to next player
    ai.resetTime()
    if logic.players < 2 then return end
    repeat
        logic.curplayer = logic.curplayer + 1
        if logic.curplayer > 4 then
            logic.curplayer = 1
        end
    until(logic.playertab[logic.curplayer])
end

local function putAtom(x,y,newplayer,count) --Put atom(s), set atom tile owner and prepare animations, return true if the tile becomes critical
    local midpos = logic.cGRIDSIZE/4+2
    local endpos = logic.cGRIDSIZE/2+1
    local oldplayer = logic.grid[x][y].player
    if not count then count = 1 end
    if not newplayer then logic.grid[x][y].player = logic.curplayer else logic.grid[x][y].player = newplayer end
    local atomg = logic.grid[x][y].atoms
    local atplayer = logic.grid[x][y].player
    for i = 1,count do
        if #atomg == 0 then
            table.insert(atomg,{midpos,midpos,midpos,midpos})
        elseif #atomg == 1 then
            logic.animplaying = true
            atomg[1][3] = endpos
            table.insert(atomg,{midpos,midpos,2,midpos})
        elseif #atomg == 2 then
            logic.animplaying = true
            atomg[1][4] = 2
            atomg[2][4] = 2
            table.insert(atomg,{midpos,midpos,midpos,endpos})
        elseif #atomg == 3 then
            logic.animplaying = true
            atomg[3][3] = 2
            table.insert(atomg,{midpos,endpos,endpos,endpos})
        elseif #atomg > 3 then
            table.insert(atomg,{midpos,midpos,love.math.random(midpos/2,3*midpos/2),love.math.random(midpos/2,3*midpos/2)})
        end
    end
    if atplayer > 0 then
        if logic.grid[x][y].atoms and #logic.grid[x][y].atoms >= logic.critgrid[x][y] then
            return true
        end
    end
    return false
end

local function checkSurrounding(x,y) --Give a position of a nearby critical atom tile or no position (nil) if there are none
    local pmovetab = nil
    for k,v in ipairs(checktab) do
        local nx = x+v[1]
        local ny = y+v[2]
        if nx >= 1 and nx <= #logic.grid and ny >= 1 and ny <= #logic.grid[1] then
            if logic.grid[nx][ny].player > 0 and logic.grid[nx][ny].atoms and #logic.grid[nx][ny].atoms >= logic.critgrid[nx][ny] then
                pmovetab = {v[1],v[2]}
                break
            end
        end
    end
    return pmovetab
end

local function explodeAtoms(x,y) --Blow up a critical atom tile, spread atoms to nearby tiles and show explosion sprite
    logic.expcount = logic.expcount + 1
    logic.grid[x][y].explode = 0.3/math.max(math.min(logic.expcount,2000)/10,1)
    local atplayer = logic.grid[x][y].player
    local extra = math.max(#logic.grid[x][y].atoms-logic.critgrid[x][y],0)
    if y < #logic.grid[1] then putAtom(x,y+1,atplayer,extra+1); extra = 0 end
    if y > 1 then putAtom(x,y-1,atplayer,extra+1); extra = 0 end
    if x < #logic.grid then putAtom(x+1,y,atplayer,extra+1); extra = 0 end
    if x > 1 then putAtom(x-1,y,atplayer,extra+1) end
    logic.grid[x][y].player = 0
    logic.grid[x][y].atoms = {}
    if logic.expcount < 2000 then love.audio.play(sndexplode) end
end

local function prepareNewAtoms(tx,ty) --Place atom on a tile, prepare for explosion if the tile is critical after that, otherwise give control to the next player
    local ttpos = {tx,ty}
    logic.playeratoms[logic.curplayer] = math.max(logic.playeratoms[logic.curplayer],1)
    if putAtom(ttpos[1],ttpos[2]) then
        logic.willexplode = {ttpos[1],ttpos[2],true}
        table.insert(logic.atomstack,ttpos)
    else
        nextPlayer()
    end
end

local function setAtomsUnsafe(x,y,atomcount,player) --Place atoms without checking for critical atoms or invalid positions/player and without animations
    local midpos = logic.cGRIDSIZE/4+2
    local endpos = logic.cGRIDSIZE/2+1
    logic.grid[x][y].explode = 0
    if atomcount == 0 then
        logic.grid[x][y].player = 0
        logic.grid[x][y].atoms = {}
    elseif atomcount == 1 then
        logic.grid[x][y].player = player
        logic.grid[x][y].atoms = {{midpos,midpos,midpos,midpos}}
    elseif atomcount == 2 then
        logic.grid[x][y].player = player
        logic.grid[x][y].atoms = {{2,midpos,2,midpos},{endpos,midpos,endpos,midpos}}
    elseif atomcount == 3 then
        logic.grid[x][y].player = player
        logic.grid[x][y].atoms = {{2,2,2,2},{endpos,2,endpos,2},{midpos,endpos,midpos,endpos}}
    elseif atomcount > 3 then
        logic.grid[x][y].player = player
        logic.grid[x][y].atoms = {{2,endpos,2,endpos},{endpos,endpos,endpos,endpos},{2,2,2,2},{endpos,2,endpos,2}}
        for i = 5,atomcount do
            local ax = love.math.random(midpos/2,3*midpos/2)
            local ay = love.math.random(midpos/2,3*midpos/2)
            table.insert(logic.grid[x][y].atoms,{ax,ay,ax,ay})
        end
    end
end

logic.ai = ai

logic.grid = {} --Atom grid (contains data in format [x][y])

logic.critgrid = {} --Stores precalculated amount of atoms required for a tile to become critical

logic.cGRIDSIZE = cGRIDSIZE

logic.cATOMSPEED = cATOMSPEED

logic.animplaying = false --Is an animation playing? If true, no explosions and animations can start

logic.bgimg = nil --It will be a background Canvas in-game

logic.winsize = {640,480} --Window size (will be different ingame)

logic.curplayer = 1 --Current player

logic.playertab = {true,true} --Player table (2-4 elements), true - not out, false - out

logic.playeratoms = {0,0} --Player atom count (2-4 elements), if it is 0 and the player has moved, player is out

logic.playermoved = {false,false} --Has player moved?

logic.players = 2 --Total players playing (1-4)

logic.startplayers = 2 --Total player count (including eliminated players)

logic.atomstack = {} --Atom split stack

logic.willexplode = {1,1,false} --Will an atom tile explode {x,y,willExplode}

logic.playerwon = 0 --0 if no player won yet

logic.expcount = 0 --Explosion count (resets when explosions stop)

logic.paused = false --Is the game paused?

logic.coltab = { --table of atom colors by player number
    [0] = {0.2,0.2,0.2,1}, --only for testing
    [1] = {1,0.2,0.2,1}, --red
    [2] = {0.2,0.4,1,1}, --blue
    [3] = {0,1,0,1}, --green
    [4] = {1,1,0,1} --yellow
}

function logic.loadAll(gridWidth,gridHeight,pttab) --Reset most of the game state with given values
    logic.grid = {}
    logic.critgrid = {}
    for x = 1,gridWidth do
        logic.grid[x] = {}
        logic.critgrid[x] = {}
        for y = 1,gridHeight do
            -- {player,atoms,explode} - player is 0 when it's empty, atoms are array of {x,y,targetx,targety} where x and y are 1 to cGRIDSIZE/2, explode is 0 when no explosion
            logic.grid[x][y] = {player = 0, atoms = {}, explode = 0}
            logic.critgrid[x][y] = 4
            if x == 1 or x == gridWidth then logic.critgrid[x][y] = logic.critgrid[x][y] - 1 end
            if y == 1 or y == gridHeight then logic.critgrid[x][y] = logic.critgrid[x][y] - 1 end
        end
    end
    logic.animplaying = false
    logic.winsize[1],logic.winsize[2] = getWinSize(gridWidth,gridHeight)
    logic.curplayer = -1
    logic.playertab = {}
    logic.playeratoms = {}
    logic.playermoved = {}
    logic.players = 0
    ai.playertab = {}
    ai.difficulty = {}
    ai.init(logic)
    for i = 1,4 do
        if pttab[i] > 0 then
            if logic.curplayer == -1 then logic.curplayer = i end
            logic.players = logic.players + 1
            logic.playertab[i] = true
            logic.playeratoms[i] = 0
            logic.playermoved[i] = false
            if pttab[i] == 9 then 
                logic.playertab[i] = "dummy"
            elseif pttab[i] > 1 then
                ai.playertab[i] = true
                ai.difficulty[i] = pttab[i] - 1
            else
                ai.playertab[i] = false
            end
        end
    end
    if logic.curplayer == -1 or logic.players < 2 then
        logic.winsize[1], logic.winsize[2] = nil, nil
        _CAState.printmsg("2 or more players required to play!",3)
        _CAState.change("menu")
        return
    end
    logic.startplayers = logic.players
    logic.atomstack = {}
    logic.willexplode = {1,1,false}
    logic.playerwon = 0
    logic.expcount = 0
    logic.bgimg = nil
end

function logic.clickedTile(tx,ty,dontcheckai) --Callback called when a tile is clicked by player or AI
    local atplayer = logic.grid[tx][ty].player
    if atplayer > 0 and atplayer ~= logic.curplayer then return end
    if not dontcheckai and ai.playertab[logic.curplayer] then return end
    if logic.players < 2 or logic.animplaying or #logic.atomstack > 0 or logic.willexplode[3] then return end
    if not logic.grid[tx][ty].atoms then logic.grid[tx][ty].atoms = {} end
    logic.expcount = 0
    logic.playermoved[logic.curplayer] = true
    love.audio.play(sndput)
    prepareNewAtoms(tx,ty)
end

function logic.tick(dt) --Game tick - disqualifies players, picks the winner, explodes atoms, checks if the player is valid, makes chain reactions and executes AI thinker
    sndexplode:setPitch(0.5)
    sndput:setPitch(0.75)
    if logic.expcount > 20000 then 
        _CAState.printmsg("More than 20000 simultaneous explosions! Stopping...",4)
        _CAState.change("menu") 
    end
    for i = 1,4 do
        local v = logic.playeratoms[i]
        if v ~= nil then
            if logic.playertab[i] and v <= 0 and logic.playermoved[i] then
                logic.players = logic.players - 1
                logic.playertab[i] = false
            end
        end
    end
    if logic.players < 2 then
        for i = 1,4 do
            if logic.playertab[i] then logic.playerwon = i; return end
        end
    end
    while not logic.playertab[logic.curplayer] do
        logic.curplayer = logic.curplayer + 1
        if logic.curplayer > 4 then
            logic.curplayer = 1
        end
    end
    if not logic.animplaying then
        if logic.willexplode[3] then
            local tx = logic.willexplode[1]
            local ty = logic.willexplode[2]
            explodeAtoms(tx,ty)
            logic.willexplode = {1,1,false}
        elseif #logic.atomstack > 0 then
            for i = 1,math.min(#logic.atomstack,50) do --Pop up to 50 positions from stack per frame if they don't cause chain reactions
                local ttpos = logic.atomstack[#logic.atomstack]
                local pmovetab = checkSurrounding(ttpos[1],ttpos[2])
                if pmovetab then
                    ttpos = {ttpos[1]+pmovetab[1],ttpos[2]+pmovetab[2]}
                    logic.willexplode = {ttpos[1],ttpos[2],true}
                    table.insert(logic.atomstack,ttpos)
                    break
                else
                    table.remove(logic.atomstack)
                    if #logic.atomstack == 0 then
                        nextPlayer()
                        break
                    end
                end
            end
        elseif ai.playertab[logic.curplayer] then
            ai.tryMove(dt)
        end
    end
end

function logic.generateGrid(gridWidth,gridHeight) --Generate the grid background
    logic.bgimg = love.graphics.newCanvas(logic.winsize[1],logic.winsize[2])
    logic.bgimg:renderTo(function()
        for y = 0,gridHeight-1 do
            for x = 0,gridWidth-1 do
                love.graphics.draw(ctile,10+(x*cGRIDSIZE),90+(y*cGRIDSIZE))
            end
        end
    end)
end

function logic.drawVictoryWin(timestr) --Draw victory window and make background darker
    local wx, wy = logic.winsize[1], logic.winsize[2]
    love.graphics.setColor(0,0,0,0.5)
    love.graphics.rectangle("fill",0,0,wx,wy)
    love.graphics.setColor(0.5,0.5,0.5,1)
    local msgx, msgy = math.floor((wx-256)/2), math.floor((wy-128)/2)
    love.graphics.rectangle("fill",msgx,msgy,256,128)
    love.graphics.setColor(0,0,0,1)
    love.graphics.rectangle("line",msgx,msgy,256,128)
    local str = colornames[logic.playerwon].." has won!\nTime: "..timestr.."\nClick to continue..."
    love.graphics.printf(str,_CAFont16,msgx+8,msgy+50,240,"center")
    love.graphics.setColor(1,1,1,1)
    love.graphics.printf("Victory!",_CAFont24,msgx+8,msgy+8,240,"center")
end

local function cai(num,val,aidiff) --For loadGame: convert player AI value to boolean and AI difficulty
    if val == 0 then
        ai.playertab[num] = false
    else
        ai.playertab[num] = true
        if val == 1 then --Default AI difficulty
            ai.difficulty[num] = aidiff
        elseif val <= 4 then
            ai.difficulty[num] = val - 1
        end
    end
end

local function cpst(num,val) --For loadGame: convert player status value to various player variables
    if val == 0 then
        logic.playertab[num] = false
        logic.playermoved[num] = true
        logic.playeratoms[num] = 0
    elseif val == 1 then
        logic.playertab[num] = true
        logic.playermoved[num] = false
        logic.playeratoms[num] = 0
    elseif val == 2 then
        logic.playertab[num] = true
        logic.playermoved[num] = true
        logic.playeratoms[num] = 1
    end
end

function logic.loadGame() --Loads the game, returns nil (on failure) or the new game time (on success)
    if not love.filesystem.getInfo("savegame.ksf") then return nil end
    local str = love.filesystem.read("savegame.ksf")
    love.filesystem.remove("savegame.ksf")
    if not str or string.sub(str,1,3) ~= "KSF" then _CAState.printmsg("Previous save is corrupted!",2); return nil end
    local gridWidth = math.max(math.min(string.byte(str,4), 30), 7)
    local gridHeight = math.max(math.min(string.byte(str,5), 20), 4)
    if string.len(str) ~= (2*gridWidth*gridHeight)+20 then _CAState.printmsg("Previous save is invalid!",2); return nil end
    logic.winsize[1],logic.winsize[2] = getWinSize(gridWidth,gridHeight)
    logic.playertab = {}
    logic.playeratoms = {}
    logic.playermoved = {}
    ai.playertab = {}
    ai.difficulty = {}
    logic.startplayers = math.min(string.byte(str,6),4)
    logic.players = math.min(string.byte(str,7),4)
    local aidifficulty = math.min(string.byte(str,8),3)
    logic.curplayer = string.byte(str,9)
    for i = 1,4 do
        cpst(i,string.byte(str,9+i))
        cai(i,string.byte(str,13+i),aidifficulty)
    end
    if logic.curplayer == 0 or logic.curplayer > 4 or logic.playertab[logic.curplayer] == nil then
        nextPlayer()
    end
    local ttime = (string.byte(str,20)*3600)+(string.byte(str,19)*60)+string.byte(str,18)
    local pos = 0
    logic.grid = {}
    logic.critgrid = {}
    for x = 1,gridWidth do
        logic.grid[x] = {}
        logic.critgrid[x] = {}
        for y = 1,gridHeight do
            logic.grid[x][y] = {player = 0, atoms = {}, explode = 0}
            setAtomsUnsafe(x,y,string.byte(str,pos+22),string.byte(str,pos+21))
            logic.critgrid[x][y] = 4
            if x == 1 or x == gridWidth then logic.critgrid[x][y] = logic.critgrid[x][y] - 1 end
            if y == 1 or y == gridHeight then logic.critgrid[x][y] = logic.critgrid[x][y] - 1 end
            pos = pos + 2
        end
    end
    ai.init(logic)
    return ttime
end

logic.nextPlayer = nextPlayer

logic.setAtoms = setAtomsUnsafe

return logic
