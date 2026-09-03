-- =========================
-- SCREEN
-- =========================

local screenW
local screenH

local function checkScreen()
    screenW = love.graphics.getWidth()
    screenH = love.graphics.getHeight()
    return screenW > 0 and screenH > 0
end

-- =========================
-- JOYSTICK SYSTEM
-- =========================

local baseX = 150
local baseY = 500
local baseR = 90

local stickX = baseX
local stickY = baseY
local stickR = 35

local touching = false

-- =========================
-- SNAKE SYSTEM
-- =========================

local snake = {}

local dirX = 1
local dirY = 0

local speed = 180
local snakeLength = 3

local gameOver = false
local flash = 0

-- =========================
-- FOOD SYSTEM
-- =========================

local foodSize = 40
local foods = {}

local FOOD_COUNT = 3

-- =========================
-- BOOM SYSTEM
-- =========================

local explosions = {}

-- =========================
-- SPAWN FOOD
-- =========================

local function spawnFood()
    local margin = 50

    table.insert(foods, {
        x = math.random(margin, math.max(margin, screenW - foodSize - margin)),
        y = math.random(margin, math.max(margin, screenH - foodSize - margin))
    })
end

-- =========================
-- BOOM
-- =========================

local function boom(x, y)
    table.insert(explosions, {
        x = x,
        y = y,
        radius = 5,
        life = 0.35
    })
end

-- =========================
-- LOAD
-- =========================

function love.load()
    checkScreen()

    math.randomseed(os.time())

    baseX = 150
    baseY = screenH - 100

    stickX = baseX
    stickY = baseY

    local x = screenW / 2
    local y = screenH / 2

    snake = {
        {x = x, y = y},
        {x = x - 20, y = y},
        {x = x - 40, y = y}
    }

    dirX = 1
    dirY = 0

    snakeLength = 3
    gameOver = false
    flash = 0

    foods = {}

    for i = 1, FOOD_COUNT do
        spawnFood()
    end
end

-- =========================
-- DRAW
-- =========================

function love.draw()
    checkScreen()

    -- BACKGROUND
    love.graphics.setColor(0.05, 0.05, 0.05)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- FOOD
    love.graphics.setColor(1, 0, 0)
    for _, food in ipairs(foods) do
        love.graphics.rectangle("fill", food.x, food.y, foodSize, foodSize)
    end

    -- SNAKE
    love.graphics.setColor(0, 1, 0)
    for _, part in ipairs(snake) do
        love.graphics.rectangle("fill", part.x, part.y, 20, 20)
    end

    -- EXPLOSIONS
    for _, e in ipairs(explosions) do
        love.graphics.setColor(1, 0.5, 0)
        love.graphics.circle("fill", e.x, e.y, e.radius)

        love.graphics.setColor(1, 1, 0)
        love.graphics.setLineWidth(4)
        love.graphics.circle("line", e.x, e.y, e.radius)
    end

    -- JOYSTICK
    if not gameOver then
        love.graphics.setColor(1, 1, 1)
        love.graphics.setLineWidth(5)
        love.graphics.circle("line", baseX, baseY, baseR)
        love.graphics.circle("fill", stickX, stickY, stickR)
    end

    -- GAME OVER
    if gameOver then
        local blink = math.floor(love.timer.getTime() * 6) % 2

        if blink == 0 then
            love.graphics.setColor(1, 0, 0)
            love.graphics.printf("GAME OVER", 0, screenH / 2 - 40, screenW, "center")

            love.graphics.setColor(1, 1, 1)
            love.graphics.printf("You crashed!", 0, screenH / 2 + 10, screenW, "center")
        end
    end

    -- FLASH
    if flash > 0 then
        love.graphics.setColor(1, 1, 1, flash)
        love.graphics.rectangle("fill", 0, 0, screenW, screenH)
    end
end

-- =========================
-- UPDATE
-- =========================

function love.update(dt)
    checkScreen()

    -- FLASH
    if flash > 0 then
        flash = flash - dt * 6
        if flash < 0 then
            flash = 0
        end
    end

    -- EXPLOSIONS
    for i = #explosions, 1, -1 do
        local e = explosions[i]
        e.life = e.life - dt
        e.radius = e.radius + 250 * dt

        if e.life <= 0 then
            table.remove(explosions, i)
        end
    end

    if gameOver then
        return
    end

    -- =========================
    -- JOYSTICK DIRECTION
    -- =========================

    local dx = stickX - baseX
    local dy = stickY - baseY

    if math.abs(dx) > math.abs(dy) then
        if dx > 20 and dirX ~= -1 then
            dirX = 1
            dirY = 0
        elseif dx < -20 and dirX ~= 1 then
            dirX = -1
            dirY = 0
        end
    else
        if dy > 20 and dirY ~= -1 then
            dirX = 0
            dirY = 1
        elseif dy < -20 and dirY ~= 1 then
            dirX = 0
            dirY = -1
        end
    end

    -- =========================
    -- MOVE
    -- =========================

    local head = snake[1]
    local newX = head.x + dirX * speed * dt
    local newY = head.y + dirY * speed * dt

    -- =========================
    -- WALL COLLISION
    -- =========================

    if newX < 0 or newX + 20 > screenW or newY < 0 or newY + 20 > screenH then
        gameOver = true
        flash = 1

        boom(
            math.max(0, math.min(screenW, newX + 10)),
            math.max(0, math.min(screenH, newY + 10))
        )
        return
    end

    -- =========================
    -- ADD HEAD
    -- =========================

    table.insert(snake, 1, {
        x = newX,
        y = newY
    })

    -- =========================
    -- FOOD COLLISION
    -- =========================

    for i = #foods, 1, -1 do
        local food = foods[i]

        if newX < food.x + foodSize and
           newX + 20 > food.x and
           newY < food.y + foodSize and
           newY + 20 > food.y then

            snakeLength = snakeLength + 5
            boom(food.x + foodSize / 2, food.y + foodSize / 2)
            table.remove(foods, i)
            spawnFood()
        end
    end

    -- =========================
    -- SELF COLLISION
    -- =========================

    if #snake > 12 then
        for i = 12, #snake do
            local part = snake[i]
            local cx = newX + 10
            local cy = newY + 10
            local px = part.x + 10
            local py = part.y + 10

            local diffX = cx - px
            local diffY = cy - py
            local distance = math.sqrt(diffX * diffX + diffY * diffY)

            if distance < 12 then
                gameOver = true
                flash = 1
                boom(cx, cy)
                return
            end
        end
    end

    -- =========================
    -- KEEP LENGTH
    -- =========================

    while #snake > snakeLength do
        table.remove(snake)
    end
end

-- =========================
-- TOUCH PRESSED
-- =========================

function love.touchpressed(id, x, y)
    local dx = x - baseX
    local dy = y - baseY

    if dx * dx + dy * dy <= baseR * baseR then
        touching = id
        stickX = x
        stickY = y
    end
end

-- =========================
-- TOUCH MOVED
-- =========================

function love.touchmoved(id, x, y)
    if touching == id then
        local dx = x - baseX
        local dy = y - baseY
        local distance = math.sqrt(dx * dx + dy * dy)

        if distance > baseR then
            dx = dx / distance * baseR
            dy = dy / distance * baseR
        end

        stickX = baseX + dx
        stickY = baseY + dy
    end
end

-- =========================
-- TOUCH RELEASED
-- =========================

function love.touchreleased(id)
    if touching == id then
        touching = false
        stickX = baseX
        stickY = baseY
    end
end

