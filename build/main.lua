function love.load()
    t = 0
end

function love.update(dt)
    t = t + dt
end

function love.draw()
    local r = (math.sin(t) + 1) / 2
    local g = (math.sin(t + 2.094) + 1) / 2
    local b = (math.sin(t + 4.189) + 1) / 2

    love.graphics.setColor(r, g, b)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
end
