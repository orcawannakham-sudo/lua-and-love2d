local baseX = 150
local baseY = 500
local baseR = 90

local dxg = 0
local dyg = 0

local stickX = baseX
local stickY = baseY
local stickR = 35

local touching = nil

function love.draw()

    -- JOYSTICK
    love.graphics.setLineWidth(5)
    love.graphics.circle("line", baseX, baseY, baseR)
    love.graphics.circle("fill", stickX, stickY, stickR)

    -- X AXIS BAR
    love.graphics.rectangle("line", 20, 20, 200, 20)

    -- X value
    love.graphics.rectangle(
        "fill",
        120,
        20,
        dxg * 100,
        20
    )

    -- Y AXIS BAR (90 DEG)
    love.graphics.rectangle("line", 250, 20, 20, 200)

    -- Y value
    love.graphics.rectangle(
        "fill",
        250,
        120,
        20,
        dyg * 100
    )
end


function love.touchpressed(id, x, y)

    local dx = x - baseX
    local dy = y - baseY

    if dx * dx + dy * dy <= baseR * baseR then
        touching = id
    end
end


function love.touchmoved(id, x, y)

    if touching == id then

        local dx = x - baseX
        local dy = y - baseY

        local distance = math.sqrt(dx * dx + dy * dy)

        -- LIMIT STICK
        if distance > baseR then
            dx = dx / distance * baseR
            dy = dy / distance * baseR
        end

        stickX = baseX + dx
        stickY = baseY + dy

        -- JOYSTICK VALUES
        dxg = dx / baseR
        dyg = dy / baseR
    end
end


function love.touchreleased(id)

    if touching == id then

        touching = nil

        stickX = baseX
        stickY = baseY

        dxg = 0
        dyg = 0
    end
end
