local scale = 1 --Mobile scale

local res = {640,480} --Ingame resolution (units)

local realx = 0 --Real screen width (in pixels)

local realy = 0 --Real screen height (in pixels)

local movex = 0 --move screen X pixels to the right

local isGfxPushed = false --Is scaling active or not

local mobile = {}

local isInit = false --Is mobile mode initialized or not

function mobile.init() --Initialize mobile mode
    if isInit then return end
    if _CAOSType == "Web" then
        realx = 800
        realy = 600
        love.window.updateMode(realx,realy)
    else
        realx, realy = love.window.getDesktopDimensions()
        love.window.updateMode(realx,realy,{fullscreen=true})
    end
    isInit = true
end

function mobile.predraw() --Setup graphics scaling
    scale = math.min(realx/res[1],realy/res[2])
    movex = math.floor((realx/2)-((res[1]/2)*scale))
    love.graphics.push()
    love.graphics.translate(movex,0)
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

function mobile.convertcoords(x,y) --Convert screen coordinates to ingame coordinates
    x = (x-movex)/scale
    y = y/scale
    return x,y
end

return mobile
