local curstate = nil --Current state name

local curstatedata = nil --Current state table/class

local globalmsg = {"",0.0} --string, time (in seconds)

local state = {}

local mobile = require("mobile") --Mobile mode

local kbmode = require("kbmode") --Keyboard mode

state.list = {} --List of states

function state.saveSettings()
    local settstr = tostring(_CAGridW).."\n"..tostring(_CAGridH).."\n"..tostring(_CAAILevel).."\n"..tostring(_CAPlayer1).."\n"..tostring(_CAPlayer2).."\n"..tostring(_CAPlayer3).."\n"..tostring(_CAPlayer4)
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
    if _CAIsMobile then
        mobile.predraw()
    end
    if curstatedata and curstatedata.draw then
        curstatedata.draw()
    end
    if globalmsg[2] > 0 then
        local wx, wy = state.getWindowSize()
        love.graphics.setColor(0,1,0,1)
        love.graphics.printf(globalmsg[1],_CAFont16,0,0,wx,"center")
        love.graphics.setColor(1,1,1,1)
    end
    if _CAKBMode then
        kbmode.draw()
    end
    if _CAIsMobile then
        mobile.postdraw()
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
    elseif curstatedata and curstatedata.keyreleased then
        curstatedata.keyreleased(key)
    end
end

function state.mousepressed(x, y, button)
    if _CAIsMobile then
        x,y = mobile.convertcoords(x,y)
    end
    if curstatedata and curstatedata.mousepressed then
        curstatedata.mousepressed(x,y,button)
    end
end
 
function state.mousereleased(x, y, button)
    if _CAIsMobile then
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
    state.saveSettings()
    if curstatedata and curstatedata.quit then
        return curstatedata.quit()
    end
    return false
end

function state.change(name,argtab) --Change state
    if _CAIsMobile then mobile.init() end
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
                if _CAIsMobile then
                    mobile.setresolution(newx,newy)
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
    if _CAIsMobile then
        mx,my = mobile.convertcoords(mx,my)
    end
    return mx,my
end

function state.getWindowSize()
    if _CAIsMobile then
        return mobile.getresolution()
    else
        return love.graphics.getDimensions()
    end
end

function state.mobileAbsMode(enable)
    if _CAIsMobile then
        mobile.absolutedrawmode(enable)
    end
end

return state
