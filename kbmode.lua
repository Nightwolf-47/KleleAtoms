local xpos = 320 --Mouse X position

local ypos = 240 --Mouse Y position

local kpressed = false --Key is pressed

local movement = {0,0,0,0} --Movement up,down,left,right

local f_curspeed = function() --Get mouse speed
    return 200*math.max(xpos*2/640,ypos*2/480)
end

local curspeed = f_curspeed()

local cacursor = love.graphics.newImage("graphics/cacursor.png")

local kbmode = {}

function kbmode.draw()
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(cacursor,xpos,ypos)
end

function kbmode.update(dt)
    ypos = ypos + (movement[2]-movement[1])*curspeed*dt
    xpos = xpos + (movement[4]-movement[3])*curspeed*dt
end

function kbmode.keypressed(key)
    if not kpressed and (key == "return" or key == "space") then
        love.event.push("mousepressed",xpos,ypos,1,false)
        kpressed = true
        return true
    elseif key == "w" or key == "up" then
        movement[1] = 1
    elseif key == "s" or key == "down" then
        movement[2] = 1
    elseif key == "a" or key == "left" then
        movement[3] = 1
    elseif key == "d" or key == "right" then
        movement[4] = 1
    end
    return false
end

function kbmode.keyreleased(key)
    if kpressed and (key == "return" or key == "space") then
        love.event.push("mousereleased",xpos,ypos,1,false)
        kpressed = false
        return true
    elseif key == "w" or key == "up" then
        movement[1] = 0
    elseif key == "s" or key == "down" then
        movement[2] = 0
    elseif key == "a" or key == "left" then
        movement[3] = 0
    elseif key == "d" or key == "right" then
        movement[4] = 0
    end
    return false
end

function kbmode.getPos() --Get current position
    return xpos,ypos
end

function kbmode.setPos(x,y) --Set position (screen size is double x and y)
    xpos = x
    ypos = y
    curspeed = f_curspeed()
end

return kbmode
