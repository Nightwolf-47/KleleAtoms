function love.conf(t)
    t.identity = "kleleatoms"
    t.version = "11.3"
    t.window.vsync = 0
    t.window.title = "KleleAtoms 1.2.1"
    t.window.width = 640
    t.window.height = 480
    t.window.resizable = false
    t.modules.joystick = false
    t.modules.physics = false
    t.window.usedpiscale = false
    t.externalstorage = true
    t.console = false
    t.window.icon = "graphics/icon.png"
end
