local curstate = nil --Current state name

local curstatedata = nil --Current state table/class

local globalmsg = {"",0.0} --string, time (in seconds)

local msgfont = nil --Font of size 16*scale, used by printmsg

local state = {}

local mobile = require("mobile") --Mobile/scaling mode

local kbmode = require("kbmode") --Keyboard mode

local specialKeys = {
    ["f3"] = function()
        mobile.toggleWinResizing()
        msgfont = nil
        if curstatedata and curstatedata.fullscreen then
            curstatedata.fullscreen(_CAUseScaling)
        end
    end,
    ["f4"] = function()
        mobile.toggleFullscreen()
        msgfont = nil
        if curstatedata and curstatedata.fullscreen then
            curstatedata.fullscreen(_CAUseScaling)
        end
    end
}

state.list = {} --List of states

function state.saveSettings()
    local fsval = _CAFullScreen and 1 or 0 --Convert boolean to number (0 - false, 1 - true)
    local wrval = _CAWinResizing and 1 or 0
    local settstr = tostring(_CAGridW).."\n"..tostring(_CAGridH).."\n"..tostring(_CAPlayExp).."\n"..tostring(_CAPlayer1).."\n"..tostring(_CAPlayer2).."\n"..tostring(_CAPlayer3).."\n"..tostring(_CAPlayer4).."\n"..tostring(fsval).."\n"..tostring(wrval)
    love.filesystem.write("settings2.txt",settstr)
end

function state.update(dt)
    if globalmsg[2] > 0 then
        globalmsg[2] = globalmsg[2] - dt
    end
    if _CAKBMode then kbmode.update(dt) end
    if curstatedata and curstatedata.update then
        curstatedata.update(dt)
    end
end

function state.draw()
    if _CAUseScaling then
        mobile.predraw()
    end
    if curstatedata and curstatedata.draw then
        curstatedata.draw()
    end
    if _CAKBMode then
        kbmode.draw()
    end
    if _CAUseScaling then
        mobile.postdraw()
    end
    if globalmsg[2] > 0 then
        local wx, wy = love.graphics.getDimensions()
        msgfont = msgfont or love.graphics.newFont(16*state.getWindowScale())
        love.graphics.setColor(0,1,0,1)
        love.graphics.printf(globalmsg[1],msgfont,0,0,wx,"center")
        love.graphics.setColor(1,1,1,1)
    end
end

function state.keypressed(key,scancode,isrepeat)
    if _CAKBMode and kbmode.keypressed(key) then
        --Nothing
    elseif curstatedata and curstatedata.keypressed then
        curstatedata.keypressed(key,scancode,isrepeat)
    end
end

function state.keyreleased(key)
    if _CAKBMode and kbmode.keyreleased(key) then
        --Nothing
    elseif not _CAIsMobile and specialKeys[key] then
        specialKeys[key]()
    elseif curstatedata and curstatedata.keyreleased then
        curstatedata.keyreleased(key)
    end
end

function state.mousepressed(x, y, button)
    if _CAUseScaling then
        x,y = mobile.convertcoords(x,y)
    end
    if curstatedata and curstatedata.mousepressed then
        curstatedata.mousepressed(x,y,button)
    end
end
 
function state.mousereleased(x, y, button)
    if _CAUseScaling then
        x,y = mobile.convertcoords(x,y)
    end
    if curstatedata and curstatedata.mousereleased then
        curstatedata.mousereleased(x,y,button)
    end
end

function state.focus(focus) --Window focus callback function
    if curstatedata and curstatedata.focus then
        curstatedata.focus(focus)
    end
end

function state.quit() --love.quit callback function, saves settings
    local retval = false
    if curstatedata and curstatedata.quit then
        retval = curstatedata.quit()
    end
    state.saveSettings()
    return retval
end

function state.resize(x,y) --love.resize callback function
    if _CAUseScaling then
        mobile.resize(x,y)
        msgfont = nil
    end
    if curstatedata and curstatedata.resize then
        curstatedata.resize(x,y)
    end
end

function state.change(name,argtab) --Change state
    if _CAUseScaling then mobile.init() end
    if state.list[name] then
        if curstatedata and curstatedata.stop then
            curstatedata.stop(name)
        end
        local laststate = curstate
        curstate = name
        curstatedata = state.list[name]
        if curstatedata.init then
            local newx,newy
            if type(argtab) == "table" then
                newx,newy = curstatedata.init(laststate,argtab)
            else
                newx,newy = curstatedata.init(laststate)
            end
            if newx and newy then
                if _CAUseScaling then
                    mobile.setresolution(newx,newy)
                    msgfont = nil
                else
                    if _CAKBMode then kbmode.setPos(newx/2,newy/2) end
                    love.window.updateMode(newx,newy)
                end
            end
        end
    else
        error("Invalid state \""..name.."\"!")
    end
end

function state.printmsg(str,time) --Print a message on the top-left corner for a specified time in seconds
    globalmsg[1] = str or ""
    globalmsg[2] = time or 1
end

function state.getMousePos() --Get current mouse position (use this instead of love.mouse.getPosition()/getX()/getY())
    if _CAKBMode then return kbmode.getPos() end
    local mx,my = love.mouse.getPosition()
    if _CAUseScaling then
        mx,my = mobile.convertcoords(mx,my)
    end
    return mx,my
end

function state.getWindowSize()
    if _CAUseScaling then
        return mobile.getresolution()
    else
        return love.graphics.getDimensions()
    end
end

function state.getWindowScale()
    if _CAUseScaling then
        return mobile.getscale()
    else
        return 1
    end
end

function state.absoluteDrawMode(enable)
    if _CAUseScaling then
        mobile.absolutedrawmode(enable)
    end
end

return state
