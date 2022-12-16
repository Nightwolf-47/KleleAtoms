local scale = 1 --Mobile scale

local res = {640,480} --Ingame resolution (units)

local sxo = 0 --Safe area X offset (avoids drawing on the notch)

local realx = 0 --Real screen width (in pixels)

local realy = 0 --Real screen height (in pixels)

local movex = 0 --move screen X pixels to the right

local movey = 0 --move screen Y pixels down

local isGfxPushed = false --Is scaling active or not

local mobile = {}

local isInit = false --Is mobile mode initialized or not

function mobile.init() --Initialize window scaling
    if isInit then return end
    if _CAOSType == "Web" then
        realx = 800
        realy = 600
        love.window.updateMode(realx,realy)
    elseif _CAFullScreen then
        res[1], res[2] = love.graphics.getDimensions()
        sxo = love.window.getSafeArea()
        realx, realy = love.window.getDesktopDimensions()
        realx = realx - sxo*2
        love.window.updateMode(realx,realy,{fullscreen=true,resizable=false})
    else -- _CAWinResizing
        res[1], res[2] = love.graphics.getDimensions()
        realx, realy = res[1], res[2]
        love.window.updateMode(realx,realy,{resizable=true})
    end
    isInit = true
end

function mobile.toggleFullscreen()
    _CAFullScreen = not _CAFullScreen
    isInit = false
    if _CAFullScreen then
        if _CAWinResizing then --Prevent scaling issues caused by resizable windows
            realx = res[1]
            realy = res[2]
            love.window.updateMode(res[1],res[2],{resizable=false})
        end
        mobile.init()
    else
        if not _CAWinResizing and isGfxPushed then
            love.graphics.pop()
            isGfxPushed = false
            scale = 1
        end
        realx = res[1]
        realy = res[2]
        love.window.updateMode(res[1],res[2],{fullscreen=false,resizable=_CAWinResizing})
    end
    _CAUseScaling = (_CAFullScreen or _CAWinResizing)
    _CAState.printmsg(string.format("Fullscreen mode %s.",_CAFullScreen and "enabled" or "disabled"),3)
end

function mobile.toggleWinResizing()
    _CAWinResizing = not _CAWinResizing
    _CAState.printmsg(string.format("Window resizing %s.",_CAWinResizing and "enabled" or "disabled"),3)
    if _CAFullScreen then return end
    isInit = false
    if _CAWinResizing then
        mobile.init()
    else
        if isGfxPushed then
            love.graphics.pop()
            isGfxPushed = false
            scale = 1
        end
        realx = res[1]
        realy = res[2]
        love.window.updateMode(res[1],res[2],{resizable=false})
    end
    _CAUseScaling = (_CAFullScreen or _CAWinResizing)
end

function mobile.resize(x,y)
    realx, realy = x-sxo*2, y
end

function mobile.predraw() --Setup graphics scaling
    scale = math.min(realx/res[1],realy/res[2])
    movex = math.floor((realx/2)-((res[1]/2)*scale))+sxo
    movey = math.floor((realy/2)-((res[2]/2)*scale))
    love.graphics.push()
    love.graphics.translate(movex,movey)
    love.graphics.scale(scale,scale)
    isGfxPushed = true
end

function mobile.postdraw() --Stop graphics scaling
    if isGfxPushed then 
        love.graphics.pop()
        isGfxPushed = false
    end
end

function mobile.setresolution(winx,winy) --Set ingame resolution
    res = {winx,winy}
end

function mobile.getresolution() --Get ingame resolution
    return res[1],res[2]
end

function mobile.convertcoords(x,y) --Convert screen coordinates to ingame coordinates
    x = (x-movex)/scale
    y = (y-movey)/scale
    return x,y
end

function mobile.absolutedrawmode(enable) --Draw without scaling and x,y coordinate offsets
    if enable and isGfxPushed then
        love.graphics.pop()
        isGfxPushed = false
    end
    if not enable and not isGfxPushed then
        love.graphics.push()
        love.graphics.translate(movex,movey)
        love.graphics.scale(scale,scale)
        isGfxPushed = true
    end
end

function mobile.getscale()
    return scale
end

return mobile
