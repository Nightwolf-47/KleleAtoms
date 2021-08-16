local gametut = {}

local logic = nil

--Event variable layout:
--name, arg1, arg2, ...

--"textbox", str, time, type - prints a textbox (types are described in the 'gametut.text' comment)
--"setptypes", {p1,p2,p3,p4} - set player types (0 - not present, 1 - player, 2 - AI, 3 - dummy/scripted)
--"curplayer", number - set current player
--"putatom", player/nil, x, y - put an atom (simulate a click --> player == nil uses logic.curplayer)
--"setatoms", player/nil, x, y, count - set atoms on a tile (no new turn --> player == nil uses logic.curplayer)
--"allow", {{x,y}, ...} - set a new allowed atoms table or no atoms allowed if arg1 is an empty table (UNUSED, NOT RECOMMENDED)
--"wait", time - pause execution for a certain time in seconds
--"clear" - clear the entire grid
local events = {
	{"setptypes",{3,3,3,3}},
	{"textbox","Welcome to the KłełeAtoms tutorial! It will teach you the basics of KłełeAtoms.\n\nYou can always press the pause button to quit the tutorial.\n\nPress any key or click the text box to continue...",0,1},
	{"textbox","Each player can place one atom per turn on empty or their own tiles.",0,1},
	{"setatoms", 3, 4, 2, 1},
	{"setatoms", 4, 5, 2, 2},
	{"wait", 0.5},
	{"putatom", 1, 2, 2},
	{"curplayer",2},
	{"wait", 0.5},
	{"putatom", 2, 3, 2},
	{"curplayer",3},
	{"wait", 0.5},
	{"putatom", 3, 4, 2},
	{"curplayer",4},
	{"wait", 0.5},
	{"putatom", 4, 5, 2},
	{"curplayer",1},
	{"wait", 1},
	{"setptypes",{3,3,3,3}},
	{"textbox","The atoms will explode if too many are present on one tile.\n\nAtoms in the corners explode if 2 or more are present.",0,1},
	{"clear"},
	{"setatoms", 1, 1, 1, 1},
	{"wait", 0.5},
	{"putatom", 1, 1, 1},
	{"wait", 1},
	{"setptypes",{3,3,3,3}},
	{"textbox","On the sides they explode if 3 or more are present.",0,1},
	{"clear"},
	{"setatoms", 2, 1, 2, 2},
	{"wait", 0.5},
	{"putatom", 2, 1, 2},
	{"wait", 1},
	{"setptypes",{3,3,3,3}},
	{"textbox","Anywhere else they only explode if 4 or more are present.",0,1},
	{"clear"},
	{"setatoms", 3, 2, 2, 3},
	{"wait", 0.5},
	{"putatom", 3, 2, 2},
	{"wait", 1},
	{"setptypes",{3,3,3,3}},
	{"textbox","Atom explosions can make nearby atoms explode, causing chain reactions.",0,1},
	{"clear"},
	{"setatoms", 4, 2, 2, 3},
	{"setatoms", 4, 1, 1, 1},
	{"setatoms", 4, 2, 1, 2},
	{"setatoms", 4, 1, 2, 2},
	{"wait", 0.5},
	{"putatom", 4, 2, 2},
	{"wait", 1},
	{"textbox","Exploding atoms turn nearby enemy atoms into current player's atoms.",0,1},
	{"clear"},
	{"setptypes",{3,3,3,3}},
	{"curplayer",1},
	{"setatoms", 1, 2, 2, 3},
	{"setatoms", 2, 1, 2, 1},
	{"setatoms", 3, 2, 1, 1},
	{"setatoms", 4, 3, 2, 1},
	{"setatoms", 2, 2, 3, 1},
	{"setatoms", 3, 5, 5, 1},
	{"wait", 0.5},
	{"putatom", 1, 2, 2},
	{"wait", 1},
	{"textbox","If the player loses all their atoms, they're out.\n\nThe last standing player wins the game.\n\nThat's it!",0,1},
}

local function parseNext() --Event parser, also handles state change after finishing
	gametut.lastparse = gametut.lastparse + 1
	if gametut.lastparse > #events then
		gametut.finished = true
		_CAState.change("menu")
		return true
	end
	local i = gametut.lastparse
	local name = events[i][1]
	if name == "setptypes" then
		if type(events[i][2]) == "table" then
			local pttab = events[i][2]
			for i = 1,4 do
				if pttab[i] > 0 then
					if logic.curplayer == -1 then logic.curplayer = i end
					logic.players = logic.players + 1
					logic.playertab[i] = true
					logic.playeratoms[i] = 0
					logic.playermoved[i] = false
					if pttab[i] == 3 then logic.playertab[i] = "dummy" end
					if pttab[i] == 2 then
						logic.ai.playertab[i] = true
					else
						logic.ai.playertab[i] = false
					end
				end
			end
		else
			_CAState.printmsg("Tutorial event "..tostring(i)..": arg1 is not a table",5)
			_CAState.change("menu")
			gametut.finished = true
			return
		end
	elseif name == "curplayer" then
		if type(events[i][2]) == "number" then
			logic.curplayer = events[i][2]
		else
			_CAState.printmsg("Tutorial event "..tostring(i)..": arg1 is not a number",5)
			_CAState.change("menu")
			gametut.finished = true
			return
		end
	elseif name == "textbox" then
		gametut.text = {events[i][2],events[i][3],events[i][4]}
	elseif name == "putatom" then
		local oldcplayer = logic.curplayer
		logic.curplayer = events[i][2] or logic.curplayer
		logic.clickedTile(events[i][3],events[i][4],true)
		logic.curplayer = oldcplayer
		return
	elseif name == "setatoms" then
		local pplayer = events[i][2] or logic.curplayer
		local atcount = events[i][5] or 1
		logic.setAtoms(events[i][3],events[i][4],atcount,pplayer)
	elseif name == "allow" then
		if type(events[i][2]) == "table" then
			gametut.allowedtiles = events[i][2]
		else
			_CAState.printmsg("Tutorial event "..tostring(i)..": arg1 is not a table",5)
			_CAState.change("menu")
			gametut.finished = true
			return
		end
	elseif name == "wait" then
		gametut.waittimer = tonumber(events[i][2]) or 0.0
	elseif name == "clear" then
		for x = 1,#logic.grid do
			for y = 1,#logic.grid[1] do
				logic.grid[x][y] = {player = 0, atoms = {}, explode = 0}
			end
		end
	else
		_CAState.printmsg("Tutorial event "..tostring(i)..": incorrect event name",5)
		_CAState.change("menu")
		gametut.finished = true
		return
	end
end

gametut.text = {nil,0,0} --string, time, type (0 - none, 1 - wait for click, 2 - timed, 3 - timed + wait)

gametut.allowedtiles = {} --If empty, no tiles are allowed, otherwise filled with {x,y} tables

gametut.lastparse = 0 --Last parsed event (0 if none)

gametut.waittimer = 0.0 --Event delay timer

gametut.finished = false --Has the tutorial been finished?

function gametut.init(gamelogic)
	logic = gamelogic
	gametut.text = {nil,0,0}
	gametut.allowedtiles = {}
	gametut.lastparse = 0
	gametut.waittimer = 0.0
	gametut.finished = false
end

function gametut.update(dt)
	if gametut.finished then return false end
	gametut.waittimer = math.max(0, gametut.waittimer - dt)
	while not animplaying and #logic.atomstack == 0 and (gametut.text[3] <= 0 or not gametut.text[1]) do
		if gametut.waittimer > 0 then break end
		if parseNext() then return end
	end
	local playergood = (not gametut.skiptab or #gametut.skiptab == 0)
	local lastplayer = logic.curplayer
	while not playergood do
		for k,v in ipairs(gametut.skiptab) do
			if v == logic.curplayer then
				logic.nextPlayer()
				break
			end
		end
		if logic.curplayer == lastplayer then
			playergood = true
		else
			lastplayer = logic.curplayer
		end
	end
	if gametut.text and gametut.text[1] and gametut.text[3] > 0 then
		if gametut.text[2] > 0 and gametut.text[3] >= 2 then
			gametut.text[2] = gametut.text[2] - dt
			if gametut.text[2] <= 0 then
				gametut.text = {nil,0,0}
			end
		end
		return true
	end
end

function gametut.draw()
	if gametut.finished then return end
	if gametut.allowedtiles and #gametut.allowedtiles > 0 then
		love.graphics.setColor(0,0,0,0.2)
		love.graphics.rectangle("fill",10,90,logic.winsize[1]-10,logic.winsize[2]-90)
		love.graphics.setColor(0.5,0.5,0.5,1)
		local gsize = logic.cGRIDSIZE
		for k,v in ipairs(gametut.allowedtiles) do
			love.graphics.rectangle("fill",11+(v[1]*gsize),91+(v[2]*gsize),gsize-1,gsize-1)
		end
	end
	if gametut.text and gametut.text[1] then
		love.graphics.setColor(0,0,0,0.5)
		love.graphics.rectangle("fill",0,0,logic.winsize[1],logic.winsize[2])
		love.graphics.setColor(0.5,0.5,0.5,1)
		love.graphics.rectangle("fill",0,logic.winsize[2]/2,logic.winsize[1],logic.winsize[2]/2)
		love.graphics.setColor(0,1,0,1)
		love.graphics.rectangle("line",2,logic.winsize[2]/2+2,logic.winsize[1]-4,logic.winsize[2]/2-4)
		love.graphics.setColor(1,1,1,1)
		love.graphics.printf(gametut.text[1],_CAFont16,8,logic.winsize[2]/2+8,logic.winsize[1]-16,"left")
	end
end

function gametut.mousepressed(x,y,button)
	if gametut.finished then return false end
	if gametut.text and gametut.text[1] and (gametut.text[3] == 1 or gametut.text[3] == 3) then
		gametut.text = {nil,0,0}
		return true
	end
	if (logic.playertab[logic.curplayer] == "dummy") then
		return true
	end
	local pressx = math.floor((x-10)/logic.cGRIDSIZE)+1
    local pressy = math.floor((y-90)/logic.cGRIDSIZE)+1
	for k,v in ipairs(gametut.allowedtiles) do
		if v[1] == pressx and v[2] == pressy then return false end
	end
	return true
end

function gametut.keyreleased(key)
	if gametut.finished then return end
	if gametut.text and gametut.text[1] and (gametut.text[3] == 1 or gametut.text[3] == 3) then
		gametut.text = {nil,0,0}
	end
end

return gametut
