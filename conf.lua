function love.conf(t)
    t.window.title = "test"
    t.window.resizable = true
    t.window.highdpi = true
    t.window.fullscreen = true
    t.window.vsync = 1
    
    t.graphics.renderers = {"vulkan"}
end
