local pops = 0

local buttonX = 300
local buttonY = 420
local buttonR = 150

local scale = 1
local targetScale = 1
local particles = {}

function love.load()
    love.window.setTitle("POP CAT")
    love.window.setMode(600, 700)

    fontBig = love.graphics.newFont(70)
    fontSmall = love.graphics.newFont(30)
end

function love.update(dt)
    -- Button animation
    scale = scale + (targetScale - scale) * dt * 18

    if math.abs(scale - targetScale) < 0.01 then
        scale = targetScale
    end

    -- Return to normal
    if targetScale ~= 1 then
        targetScale = 1
    end

    -- Particles
    for i = #particles, 1, -1 do
        local p = particles[i]

        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + 500 * dt
        p.life = p.life - dt

        if p.life <= 0 then
            table.remove(particles, i)
        end
    end
end

local function pop()
    pops = pops + 1

    -- Squish
    scale = 0.82
    targetScale = 1.12

    -- Burst particles
    for i = 1, 18 do
        local angle = math.random() * math.pi * 2
        local speed = math.random(150, 350)

        table.insert(particles, {
            x = buttonX,
            y = buttonY,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            life = 0.6
        })
    end
end

local function isInsideButton(x, y)
    local dx = x - buttonX
    local dy = y - buttonY

    return math.sqrt(dx * dx + dy * dy) <= buttonR * scale
end

function love.mousepressed(x, y, button)
    if button == 1 and isInsideButton(x, y) then
        pop()
    end
end

function love.touchpressed(id, x, y)
    if isInsideButton(x, y) then
        pop()
    end
end

function love.draw()
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()

    love.graphics.clear(0.08, 0.08, 0.1)

    -- Counter
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fontSmall)

    love.graphics.printf(
        "POPS",
        0, 40, w,
        "center"
    )

    love.graphics.setFont(fontBig)

    love.graphics.printf(
        tostring(pops),
        0, 75, w,
        "center"
    )

    -- Particles
    for _, p in ipairs(particles) do
        love.graphics.setColor(
            1,
            0.25 + p.life,
            0.1,
            math.max(p.life, 0)
        )

        love.graphics.circle(
            "fill",
            p.x,
            p.y,
            7
        )
    end

    -- Button shadow
    love.graphics.setColor(0, 0, 0, 0.4)

    love.graphics.circle(
        "fill",
        buttonX,
        buttonY + 15,
        buttonR * scale
    )

    -- Button
    love.graphics.setColor(1, 0.15, 0.12)

    love.graphics.circle(
        "fill",
        buttonX,
        buttonY,
        buttonR * scale
    )

    -- Button highlight
    love.graphics.setColor(1, 0.3, 0.25)

    love.graphics.circle(
        "fill",
        buttonX - 20 * scale,
        buttonY - 25 * scale,
        buttonR * 0.75 * scale
    )

    -- POP text
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fontBig)

    love.graphics.printf(
        "POP!",
        buttonX - 150 * scale,
        buttonY - 38 * scale,
        300 * scale,
        "center"
    )

    -- Hint
    love.graphics.setFont(fontSmall)
    love.graphics.setColor(1, 1, 1, 0.7)

    love.graphics.printf(
        "TAP THE BUTTON",
        0, h - 60, w,
        "center"
    )
end
