-- ============================================================================
-- MINECRAFT 2D (LOVE2D EDITION)
-- Works on Mobile (Android Touch) and Desktop (Keyboard/Mouse)
-- ============================================================================

-- Screen & Viewport
local screenW = 800
local screenH = 600

-- World Configuration
local TILE = 24
local WORLD_W = 160
local WORLD_H = 64
local SURFACE_BASE_Y = 26

-- Block Definitions
local B_AIR       = 0
local B_GRASS     = 1
local B_DIRT      = 2
local B_STONE     = 3
local B_COBBLE    = 4
local B_WOOD      = 5
local B_LEAVES    = 6
local B_PLANKS    = 7
local B_COAL      = 8
local B_IRON      = 9
local B_GOLD      = 10
local B_DIAMOND   = 11
local B_BRICK     = 12
local B_GLASS     = 13
local B_SAND      = 14
local B_TNT       = 15
local B_TORCH     = 16
local B_BEDROCK   = 17
local B_CRAFTING  = 18

local BLOCKS = {
    [B_GRASS]    = { name = "Grass",      solid = true,  hardness = 0.4,  color = {0.30, 0.72, 0.25}, drop = B_DIRT },
    [B_DIRT]     = { name = "Dirt",       solid = true,  hardness = 0.4,  color = {0.52, 0.36, 0.22}, drop = B_DIRT },
    [B_STONE]    = { name = "Stone",      solid = true,  hardness = 1.2,  color = {0.50, 0.50, 0.50}, drop = B_COBBLE },
    [B_COBBLE]   = { name = "Cobblestone",solid = true,  hardness = 1.0,  color = {0.45, 0.45, 0.45}, drop = B_COBBLE },
    [B_WOOD]     = { name = "Oak Wood",   solid = true,  hardness = 0.8,  color = {0.55, 0.38, 0.22}, drop = B_WOOD },
    [B_LEAVES]   = { name = "Leaves",     solid = true,  hardness = 0.2,  color = {0.20, 0.60, 0.18}, drop = B_LEAVES, transparent = true },
    [B_PLANKS]   = { name = "Planks",     solid = true,  hardness = 0.6,  color = {0.72, 0.58, 0.36}, drop = B_PLANKS },
    [B_COAL]     = { name = "Coal Ore",   solid = true,  hardness = 1.3,  color = {0.20, 0.20, 0.20}, drop = B_COAL },
    [B_IRON]     = { name = "Iron Ore",   solid = true,  hardness = 1.5,  color = {0.82, 0.68, 0.58}, drop = B_IRON },
    [B_GOLD]     = { name = "Gold Ore",   solid = true,  hardness = 1.6,  color = {0.95, 0.82, 0.22}, drop = B_GOLD },
    [B_DIAMOND]  = { name = "Diamond Ore",solid = true,  hardness = 2.0,  color = {0.28, 0.88, 0.95}, drop = B_DIAMOND },
    [B_BRICK]    = { name = "Bricks",     solid = true,  hardness = 1.2,  color = {0.72, 0.28, 0.22}, drop = B_BRICK },
    [B_GLASS]    = { name = "Glass",      solid = true,  hardness = 0.25, color = {0.75, 0.90, 0.98}, drop = B_AIR, transparent = true },
    [B_SAND]     = { name = "Sand",       solid = true,  hardness = 0.35, color = {0.88, 0.82, 0.55}, drop = B_SAND },
    [B_TNT]      = { name = "TNT",        solid = true,  hardness = 0.1,  color = {0.88, 0.22, 0.18}, drop = B_TNT, tnt = true },
    [B_TORCH]    = { name = "Torch",      solid = false, hardness = 0.1,  color = {1.00, 0.80, 0.20}, drop = B_TORCH, light = true },
    [B_BEDROCK]  = { name = "Bedrock",    solid = true,  hardness = -1,   color = {0.18, 0.18, 0.18}, drop = B_AIR },
    [B_CRAFTING] = { name = "Workbench",  solid = true,  hardness = 0.7,  color = {0.68, 0.48, 0.28}, drop = B_CRAFTING },
}

-- Hotbar Configuration (Accessible on Touch / Keyboard)
local HOTBAR = {
    B_GRASS, B_DIRT, B_COBBLE, B_PLANKS, B_WOOD, B_GLASS, B_BRICK, B_TNT, B_TORCH
}

-- World Grid [x][y]
local world = {}

-- Player State
local player = {
    x = 0,
    y = 0,
    w = 14,
    h = 32,
    vx = 0,
    vy = 0,
    facing = 1,
    onGround = false,
    flying = false,
    walkAnim = 0,
    mineAnim = 0,
    health = 10,
    maxHealth = 10,
    selectedSlot = 1,
    mode = "MINE", -- "MINE" or "PLACE"
}

-- Camera
local camX = 0
local camY = 0
local shakeTime = 0
local shakeMag = 0

-- Mining State
local mining = {
    active = false,
    tileX = 0,
    tileY = 0,
    progress = 0,
    maxTime = 1,
}

-- Particles & Entities
local particles = {}
local itemDrops = {}
local primedTNT = {}
local clouds = {}

-- Audio Sources
local sounds = {}

-- Procedural Textures (Canvases)
local blockCanvases = {}
local crackCanvases = {}

-- Touch System State
local touches = {}
local uiButtons = {}

-- Day / Night Cycle
local DAY_DURATION = 180 -- seconds per full cycle
local gameTime = 30 -- start in daytime

-- Helper: Check Screen Dimensions
local function updateScreen()
    screenW = love.graphics.getWidth()
    screenH = love.graphics.getHeight()
end

-- ============================================================================
-- AUDIO SYNTHESIS (Procedural 8-bit Sound Effects)
-- ============================================================================
local function initAudio()
    local function makeTone(freq1, freq2, duration, decay)
        local rate = 22050
        local totalSamples = math.floor(rate * duration)
        local ok, sdata = pcall(love.sound.newSoundData, totalSamples, rate, 16, 1)
        if not ok or not sdata then return nil end
        for i = 0, totalSamples - 1 do
            local t = i / totalSamples
            local f = freq1 + (freq2 - freq1) * t
            local env = math.max(0, 1 - t * (decay or 1))
            local sample = math.sin(2 * math.pi * f * (i / rate)) * env * 0.35
            sdata:setSample(i, sample)
        end
        local ok2, src = pcall(love.audio.newSource, sdata, "static")
        return ok2 and src or nil
    end

    local function makeNoise(duration, decay)
        local rate = 22050
        local totalSamples = math.floor(rate * duration)
        local ok, sdata = pcall(love.sound.newSoundData, totalSamples, rate, 16, 1)
        if not ok or not sdata then return nil end
        local last = 0
        for i = 0, totalSamples - 1 do
            local t = i / totalSamples
            local env = math.max(0, 1 - t * (decay or 1))
            local r = (math.random() * 2 - 1)
            last = last * 0.65 + r * 0.35
            sdata:setSample(i, last * env * 0.4)
        end
        local ok2, src = pcall(love.audio.newSource, sdata, "static")
        return ok2 and src or nil
    end

    sounds.dig     = makeNoise(0.06, 1.2)
    sounds.break_b = makeNoise(0.14, 1.0)
    sounds.place   = makeTone(160, 90, 0.08, 1.5)
    sounds.jump    = makeTone(200, 420, 0.12, 1.0)
    sounds.pickup  = makeTone(580, 880, 0.15, 1.2)
    sounds.explode = makeNoise(0.5, 0.8)
end

local function playSnd(src)
    if src then
        pcall(function()
            src:stop()
            src:play()
        end)
    end
end

-- ============================================================================
-- TEXTURE GENERATION (16x16 Pixel Art Canvases)
-- ============================================================================
local function generateBlockTextures()
    local okCanvas = pcall(function()
        local test = love.graphics.newCanvas(16, 16)
    end)
    if not okCanvas then return end

    local function createTexture(id, drawFunc)
        local canvas = love.graphics.newCanvas(16, 16)
        canvas:setFilter("nearest", "nearest")
        love.graphics.setCanvas(canvas)
        love.graphics.clear(0, 0, 0, 0)
        drawFunc()
        love.graphics.setCanvas()
        blockCanvases[id] = canvas
    end

    -- Grass
    createTexture(B_GRASS, function()
        -- Brown dirt base
        love.graphics.setColor(0.50, 0.35, 0.22)
        love.graphics.rectangle("fill", 0, 0, 16, 16)
        love.graphics.setColor(0.40, 0.28, 0.17)
        for _, p in ipairs({{2,5},{7,9},{12,6},{4,12},{10,13},{14,11}}) do
            love.graphics.rectangle("fill", p[1], p[2], 2, 2)
        end
        -- Green grass top
        love.graphics.setColor(0.32, 0.74, 0.24)
        love.graphics.rectangle("fill", 0, 0, 16, 4)
        -- Grass tufts hanging down
        love.graphics.rectangle("fill", 2, 4, 2, 2)
        love.graphics.rectangle("fill", 6, 4, 3, 3)
        love.graphics.rectangle("fill", 11, 4, 2, 2)
        love.graphics.rectangle("fill", 14, 4, 2, 1)
        love.graphics.setColor(0.44, 0.85, 0.32)
        love.graphics.rectangle("fill", 0, 0, 16, 1)
    end)

    -- Dirt
    createTexture(B_DIRT, function()
        love.graphics.setColor(0.52, 0.36, 0.22)
        love.graphics.rectangle("fill", 0, 0, 16, 16)
        love.graphics.setColor(0.42, 0.29, 0.18)
        for _, p in ipairs({{2,3},{8,2},{13,4},{4,8},{9,10},{14,9},{1,13},{6,14},{11,13}}) do
            love.graphics.rectangle("fill", p[1], p[2], 2, 2)
        end
        love.graphics.setColor(0.62, 0.44, 0.28)
        for _, p in ipairs({{5,5},{11,6},{2,10},{8,13}}) do
            love.graphics.rectangle("fill", p[1], p[2], 1, 1)
        end
    end)

    -- Stone
    createTexture(B_STONE, function()
        love.graphics.setColor(0.50, 0.50, 0.50)
        love.graphics.rectangle("fill", 0, 0, 16, 16)
        love.graphics.setColor(0.40, 0.40, 0.40)
        for _, p in ipairs({{3,2},{10,4},{6,8},{13,11},{2,13},{9,14}}) do
            love.graphics.rectangle("fill", p[1], p[2], 2, 2)
        end
        love.graphics.setColor(0.62, 0.62, 0.62)
        for _, p in ipairs({{5,3},{12,5},{4,9},{11,12}}) do
            love.graphics.rectangle("fill", p[1], p[2], 2, 1)
        end
    end)

    -- Cobblestone
    createTexture(B_COBBLE, function()
        love.graphics.setColor(0.32, 0.32, 0.32)
        love.graphics.rectangle("fill", 0, 0, 16, 16)
        local cobbles = {
            {1,1,6,4}, {8,1,7,5}, {1,6,7,4}, {9,7,6,4}, {1,11,6,4}, {8,12,7,3}
        }
        for _, c in ipairs(cobbles) do
            love.graphics.setColor(0.55, 0.55, 0.55)
            love.graphics.rectangle("fill", c[1], c[2], c[3], c[4])
            love.graphics.setColor(0.68, 0.68, 0.68)
            love.graphics.rectangle("fill", c[1], c[2], c[3], 1)
            love.graphics.rectangle("fill", c[1], c[2], 1, c[4])
        end
    end)

    -- Oak Wood Log
    createTexture(B_WOOD, function()
        love.graphics.setColor(0.42, 0.28, 0.16)
        love.graphics.rectangle("fill", 0, 0, 16, 16)
        love.graphics.setColor(0.58, 0.40, 0.24)
        love.graphics.rectangle("fill", 2, 0, 4, 16)
        love.graphics.rectangle("fill", 8, 0, 5, 16)
        love.graphics.setColor(0.32, 0.20, 0.12)
        love.graphics.rectangle("fill", 6, 0, 2, 16)
        love.graphics.rectangle("fill", 13, 0, 2, 16)
        love.graphics.setColor(0.65, 0.46, 0.28)
        love.graphics.rectangle("fill", 3, 2, 2, 5)
        love.graphics.rectangle("fill", 9, 8, 2, 6)
    end)

    -- Leaves
    createTexture(B_LEAVES, function()
        love.graphics.setColor(0.18, 0.52, 0.15)
        love.graphics.rectangle("fill", 0, 0, 16, 16)
        love.graphics.setColor(0.28, 0.70, 0.22)
        for _, p in ipairs({{2,1},{6,3},{11,1},{3,6},{8,7},{13,6},{1,11},{6,12},{11,10},{4,14},{13,14}}) do
            love.graphics.rectangle("fill", p[1], p[2], 3, 2)
        end
        love.graphics.setColor(0.10, 0.38, 0.08)
        for _, p in ipairs({{0,4},{7,0},{14,4},{5,9},{11,13},{0,12}}) do
            love.graphics.rectangle("fill", p[1], p[2], 2, 2)
        end
    end)

    -- Planks
    createTexture(B_PLANKS, function()
        love.graphics.setColor(0.72, 0.56, 0.35)
        love.graphics.rectangle("fill", 0, 0, 16, 16)
        love.graphics.setColor(0.48, 0.35, 0.20)
        love.graphics.rectangle("fill", 0, 4, 16, 1)
        love.graphics.rectangle("fill", 0, 8, 16, 1)
        love.graphics.rectangle("fill", 0, 12, 16, 1)
        love.graphics.rectangle("fill", 6, 0, 1, 4)
        love.graphics.rectangle("fill", 11, 4, 1, 4)
        love.graphics.rectangle("fill", 4, 8, 1, 4)
        love.graphics.rectangle("fill", 13, 12, 1, 4)
        -- Nails
        love.graphics.setColor(0.35, 0.24, 0.14)
        love.graphics.rectangle("fill", 1, 1, 1, 1)
        love.graphics.rectangle("fill", 7, 5, 1, 1)
        love.graphics.rectangle("fill", 1, 9, 1, 1)
        love.graphics.rectangle("fill", 8, 13, 1, 1)
    end)

    -- Ore generator helper
    local function createOreTexture(id, oreR, oreG, oreB)
        createTexture(id, function()
            -- Stone base
            love.graphics.setColor(0.50, 0.50, 0.50)
            love.graphics.rectangle("fill", 0, 0, 16, 16)
            love.graphics.setColor(0.40, 0.40, 0.40)
            for _, p in ipairs({{1,1},{14,2},{2,14},{13,13}}) do
                love.graphics.rectangle("fill", p[1], p[2], 2, 2)
            end
            -- Ore deposits
            love.graphics.setColor(oreR, oreG, oreB)
            local spots = {{3,3,3,2}, {8,2,2,3}, {12,5,3,2}, {4,9,3,3}, {10,8,3,2}, {2,12,2,2}, {8,12,3,2}, {13,11,2,3}}
            for _, s in ipairs(spots) do
                love.graphics.rectangle("fill", s[1], s[2], s[3], s[4])
            end
            -- Ore shine highlight
            love.graphics.setColor(math.min(1, oreR + 0.25), math.min(1, oreG + 0.25), math.min(1, oreB + 0.25))
            for _, s in ipairs(spots) do
                love.graphics.rectangle("fill", s[1], s[2], 1, 1)
            end
        end)
    end

    createOreTexture(B_COAL,    0.15, 0.15, 0.15)
    createOreTexture(B_IRON,    0.85, 0.70, 0.58)
    createOreTexture(B_GOLD,    0.98, 0.85, 0.20)
    createOreTexture(B_DIAMOND, 0.28, 0.90, 0.95)

    -- Bricks
    createTexture(B_BRICK, function()
        love.graphics.setColor(0.82, 0.82, 0.80) -- Mortar
        love.graphics.rectangle("fill", 0, 0, 16, 16)
        love.graphics.setColor(0.70, 0.26, 0.20)
        -- Row 1
        love.graphics.rectangle("fill", 0, 0, 7, 3)
        love.graphics.rectangle("fill", 8, 0, 7, 3)
        -- Row 2
        love.graphics.rectangle("fill", 0, 4, 3, 3)
        love.graphics.rectangle("fill", 4, 4, 7, 3)
        love.graphics.rectangle("fill", 12, 4, 4, 3)
        -- Row 3
        love.graphics.rectangle("fill", 0, 8, 7, 3)
        love.graphics.rectangle("fill", 8, 8, 7, 3)
        -- Row 4
        love.graphics.rectangle("fill", 0, 12, 3, 3)
        love.graphics.rectangle("fill", 4, 12, 7, 3)
        love.graphics.rectangle("fill", 12, 12, 4, 3)
    end)

    -- Glass
    createTexture(B_GLASS, function()
        love.graphics.setColor(0.70, 0.88, 0.95, 0.35)
        love.graphics.rectangle("fill", 0, 0, 16, 16)
        -- Glass Border
        love.graphics.setColor(0.85, 0.95, 1.0, 0.8)
        love.graphics.rectangle("line", 0.5, 0.5, 15, 15)
        -- Glint
        love.graphics.setColor(1.0, 1.0, 1.0, 0.7)
        love.graphics.rectangle("fill", 3, 3, 3, 1)
        love.graphics.rectangle("fill", 2, 4, 1, 3)
        love.graphics.rectangle("fill", 10, 10, 3, 1)
        love.graphics.rectangle("fill", 9, 11, 1, 3)
    end)

    -- Sand
    createTexture(B_SAND, function()
        love.graphics.setColor(0.88, 0.82, 0.55)
        love.graphics.rectangle("fill", 0, 0, 16, 16)
        love.graphics.setColor(0.78, 0.72, 0.45)
        for _, p in ipairs({{2,2},{8,5},{13,3},{4,9},{9,12},{14,10},{3,14}}) do
            love.graphics.rectangle("fill", p[1], p[2], 2, 1)
        end
        love.graphics.setColor(0.95, 0.90, 0.65)
        for _, p in ipairs({{5,3},{11,6},{2,11},{8,14}}) do
            love.graphics.rectangle("fill", p[1], p[2], 1, 1)
        end
    end)

    -- TNT
    createTexture(B_TNT, function()
        -- Red bands
        love.graphics.setColor(0.88, 0.22, 0.16)
        love.graphics.rectangle("fill", 0, 0, 16, 16)
        -- White center band
        love.graphics.setColor(0.95, 0.95, 0.95)
        love.graphics.rectangle("fill", 0, 5, 16, 6)
        -- TNT letters
        love.graphics.setColor(0.1, 0.1, 0.1)
        -- T
        love.graphics.rectangle("fill", 2, 6, 3, 1)
        love.graphics.rectangle("fill", 3, 7, 1, 3)
        -- N
        love.graphics.rectangle("fill", 6, 6, 1, 4)
        love.graphics.rectangle("fill", 7, 7, 1, 1)
        love.graphics.rectangle("fill", 8, 8, 1, 1)
        love.graphics.rectangle("fill", 9, 6, 1, 4)
        -- T
        love.graphics.rectangle("fill", 11, 6, 3, 1)
        love.graphics.rectangle("fill", 12, 7, 1, 3)
    end)

    -- Torch
    createTexture(B_TORCH, function()
        -- Stick
        love.graphics.setColor(0.55, 0.38, 0.22)
        love.graphics.rectangle("fill", 7, 6, 2, 9)
        -- Head / Flame
        love.graphics.setColor(1.0, 0.75, 0.15)
        love.graphics.rectangle("fill", 6, 3, 4, 4)
        love.graphics.setColor(1.0, 0.95, 0.5)
        love.graphics.rectangle("fill", 7, 4, 2, 2)
    end)

    -- Bedrock
    createTexture(B_BEDROCK, function()
        love.graphics.setColor(0.12, 0.12, 0.12)
        love.graphics.rectangle("fill", 0, 0, 16, 16)
        love.graphics.setColor(0.25, 0.25, 0.25)
        for _, p in ipairs({{1,1,4,4},{7,3,5,3},{1,8,6,3},{9,9,5,4},{3,13,5,2}}) do
            love.graphics.rectangle("fill", p[1], p[2], p[3], p[4])
        end
        love.graphics.setColor(0.05, 0.05, 0.05)
        for _, p in ipairs({{4,5,3,3},{11,1,3,4},{7,11,4,3}}) do
            love.graphics.rectangle("fill", p[1], p[2], p[3], p[4])
        end
    end)

    -- Workbench
    createTexture(B_CRAFTING, function()
        love.graphics.setColor(0.68, 0.48, 0.28)
        love.graphics.rectangle("fill", 0, 0, 16, 16)
        love.graphics.setColor(0.48, 0.32, 0.18)
        love.graphics.rectangle("line", 0.5, 0.5, 15, 15)
        love.graphics.rectangle("fill", 0, 3, 16, 1)
        love.graphics.setColor(0.35, 0.22, 0.12)
        -- Tools icons on side
        love.graphics.rectangle("fill", 3, 6, 2, 7)
        love.graphics.rectangle("fill", 2, 6, 4, 2)
        love.graphics.rectangle("fill", 9, 6, 4, 2)
        love.graphics.rectangle("fill", 11, 7, 2, 6)
    end)

    -- Crack textures (Stages 1 to 5)
    for stage = 1, 5 do
        local canvas = love.graphics.newCanvas(16, 16)
        canvas:setFilter("nearest", "nearest")
        love.graphics.setCanvas(canvas)
        love.graphics.clear(0, 0, 0, 0)
        love.graphics.setColor(0, 0, 0, 0.75)
        if stage >= 1 then
            love.graphics.line(7, 7, 9, 9)
            love.graphics.line(9, 9, 9, 12)
        end
        if stage >= 2 then
            love.graphics.line(7, 7, 4, 5)
            love.graphics.line(4, 5, 2, 7)
        end
        if stage >= 3 then
            love.graphics.line(7, 7, 10, 4)
            love.graphics.line(10, 4, 13, 3)
            love.graphics.line(9, 9, 12, 11)
        end
        if stage >= 4 then
            love.graphics.line(4, 5, 4, 2)
            love.graphics.line(9, 12, 7, 15)
            love.graphics.line(12, 11, 15, 13)
        end
        if stage >= 5 then
            love.graphics.line(2, 7, 0, 8)
            love.graphics.line(13, 3, 15, 1)
            love.graphics.line(7, 15, 6, 16)
            love.graphics.line(7, 7, 12, 8)
        end
        love.graphics.setCanvas()
        crackCanvases[stage] = canvas
    end
end

-- ============================================================================
-- WORLD GENERATION
-- ============================================================================
local function generateWorld()
    world = {}
    for x = 1, WORLD_W do
        world[x] = {}
        for y = 1, WORLD_H do
            world[x][y] = B_AIR
        end
    end

    local heights = {}
    for x = 1, WORLD_W do
        local h = math.floor(
            SURFACE_BASE_Y
            + math.sin(x * 0.05) * 6
            + math.sin(x * 0.12) * 3
            + math.cos(x * 0.02) * 4
        )
        if h < 10 then h = 10 end
        if h > WORLD_H - 12 then h = WORLD_H - 12 end
        heights[x] = h
    end

    for x = 1, WORLD_W do
        local sy = heights[x]
        for y = sy, WORLD_H do
            if y == sy then
                world[x][y] = B_GRASS
            elseif y <= sy + 4 then
                world[x][y] = B_DIRT
            elseif y < WORLD_H - 1 then
                world[x][y] = B_STONE
            else
                world[x][y] = B_BEDROCK
            end
        end
    end

    -- Caves
    local numCaves = 18
    for _ = 1, numCaves do
        local cx = math.random(10, WORLD_W - 10)
        local cy = math.random(SURFACE_BASE_Y + 6, WORLD_H - 6)
        local length = math.random(12, 24)
        for _ = 1, length do
            local radius = math.random(1, 3)
            for ox = -radius, radius do
                for oy = -radius, radius do
                    if ox * ox + oy * oy <= radius * radius then
                        local wx = cx + ox
                        local wy = cy + oy
                        if wx >= 2 and wx <= WORLD_W - 1 and wy >= 5 and wy < WORLD_H - 1 then
                            world[wx][wy] = B_AIR
                        end
                    end
                end
            end
            cx = cx + math.random(-2, 2)
            cy = cy + math.random(-1, 2)
            if cx < 5 then cx = 5 end
            if cx > WORLD_W - 5 then cx = WORLD_W - 5 end
            if cy > WORLD_H - 3 then cy = WORLD_H - 3 end
        end
    end

    -- Ore Veins
    local function spawnVeins(blockId, count, minY, maxY, veinSize)
        for _ = 1, count do
            local vx = math.random(3, WORLD_W - 3)
            local vy = math.random(minY, maxY)
            local size = math.random(veinSize - 1, veinSize + 2)
            for _ = 1, size do
                if vx >= 1 and vx <= WORLD_W and vy >= 1 and vy < WORLD_H - 1 then
                    if world[vx][vy] == B_STONE then
                        world[vx][vy] = blockId
                    end
                end
                vx = vx + math.random(-1, 1)
                vy = vy + math.random(-1, 1)
            end
        end
    end

    spawnVeins(B_COAL,    45, SURFACE_BASE_Y + 2, WORLD_H - 4, 5)
    spawnVeins(B_IRON,    32, SURFACE_BASE_Y + 10, WORLD_H - 4, 4)
    spawnVeins(B_GOLD,    18, SURFACE_BASE_Y + 22, WORLD_H - 3, 3)
    spawnVeins(B_DIAMOND, 12, SURFACE_BASE_Y + 28, WORLD_H - 2, 3)

    -- Trees
    local x = 6
    while x <= WORLD_W - 6 do
        if math.random() < 0.38 then
            local sy = heights[x]
            if world[x][sy] == B_GRASS and world[x][sy - 1] == B_AIR then
                local trunkHeight = math.random(4, 5)
                for ty = sy - 1, sy - trunkHeight, -1 do
                    world[x][ty] = B_WOOD
                end
                local leafTop = sy - trunkHeight
                for lx = x - 2, x + 2 do
                    for ly = leafTop - 2, leafTop + 1 do
                        if lx >= 1 and lx <= WORLD_W and ly >= 1 then
                            local dist = math.abs(lx - x) + math.abs(ly - (leafTop - 1))
                            if dist <= 3 and world[lx][ly] == B_AIR then
                                world[lx][ly] = B_LEAVES
                            end
                        end
                    end
                end
                x = x + 4
            end
        end
        x = x + 1
    end

    -- Bedrock Floor
    for bx = 1, WORLD_W do
        world[bx][WORLD_H] = B_BEDROCK
        if math.random() < 0.65 then
            world[bx][WORLD_H - 1] = B_BEDROCK
        end
    end
end

-- ============================================================================
-- SPAWN & RESPAWN
-- ============================================================================
local function spawnPlayer()
    local spawnX = math.floor(WORLD_W / 2)
    local spawnY = 10
    for y = 1, WORLD_H do
        if world[spawnX][y] ~= B_AIR then
            spawnY = (y - 2) * TILE
            break
        end
    end
    player.x = (spawnX - 1) * TILE
    player.y = spawnY
    player.vx = 0
    player.vy = 0
    player.health = player.maxHealth
end

-- ============================================================================
-- PHYSICS & COLLISION
-- ============================================================================
local function isTileSolid(tx, ty)
    if tx < 1 or tx > WORLD_W or ty < 1 or ty > WORLD_H then
        return true
    end
    local b = world[tx][ty]
    if b == B_AIR then return false end
    local def = BLOCKS[b]
    return def and def.solid
end

local function updatePlayer(dt, moveInput, jumpInput, upInput, downInput)
    local GRAVITY = 850
    local ACCEL = 900
    local FRICTION = 9
    local MAX_RUN = 140

    -- Animation
    if math.abs(player.vx) > 10 and player.onGround then
        player.walkAnim = player.walkAnim + dt * 10
    else
        player.walkAnim = 0
    end
    if player.mineAnim > 0 then
        player.mineAnim = math.max(0, player.mineAnim - dt * 5)
    end

    if player.flying then
        -- Creative Fly Mode
        player.vy = 0
        local flySpeed = 220
        if moveInput ~= 0 then
            player.vx = moveInput * flySpeed
            player.facing = moveInput > 0 and 1 or -1
        else
            player.vx = 0
        end
        if upInput then
            player.vy = -flySpeed
        elseif downInput then
            player.vy = flySpeed
        end
        player.x = player.x + player.vx * dt
        player.y = player.y + player.vy * dt
        return
    end

    -- Horizontal Acceleration
    if moveInput ~= 0 then
        player.vx = player.vx + moveInput * ACCEL * dt
        if math.abs(player.vx) > MAX_RUN then
            player.vx = (player.vx > 0 and 1 or -1) * MAX_RUN
        end
        player.facing = moveInput > 0 and 1 or -1
    else
        local f = FRICTION * dt
        if f > 1 then f = 1 end
        player.vx = player.vx * (1 - f)
        if math.abs(player.vx) < 5 then player.vx = 0 end
    end

    -- Gravity
    player.vy = player.vy + GRAVITY * dt
    if player.vy > 650 then player.vy = 650 end

    -- Jump
    if jumpInput and player.onGround then
        player.vy = -370
        player.onGround = false
        playSnd(sounds.jump)
    end

    -- Horizontal Movement & Collision
    player.x = player.x + player.vx * dt
    local tLeft   = math.floor(player.x / TILE) + 1
    local tRight  = math.floor((player.x + player.w) / TILE) + 1
    local tTop    = math.floor((player.y + 2) / TILE) + 1
    local tBottom = math.floor((player.y + player.h - 1) / TILE) + 1

    if player.vx > 0 then
        for ty = tTop, tBottom do
            if isTileSolid(tRight, ty) then
                -- Auto-step 1-block feature
                if ty == tBottom and not isTileSolid(tRight, tBottom - 1) and not isTileSolid(tLeft, tBottom - 1) and player.onGround then
                    player.y = (tBottom - 2) * TILE
                else
                    player.x = (tRight - 1) * TILE - player.w - 0.01
                    player.vx = 0
                    break
                end
            end
        end
    elseif player.vx < 0 then
        for ty = tTop, tBottom do
            if isTileSolid(tLeft, ty) then
                if ty == tBottom and not isTileSolid(tLeft, tBottom - 1) and not isTileSolid(tRight, tBottom - 1) and player.onGround then
                    player.y = (tBottom - 2) * TILE
                else
                    player.x = tLeft * TILE + 0.01
                    player.vx = 0
                    break
                end
            end
        end
    end

    -- Vertical Movement & Collision
    player.y = player.y + player.vy * dt
    local curTLeft   = math.floor((player.x + 2) / TILE) + 1
    local curTRight  = math.floor((player.x + player.w - 2) / TILE) + 1
    local curTTop    = math.floor(player.y / TILE) + 1
    local curTBottom = math.floor((player.y + player.h) / TILE) + 1

    player.onGround = false
    if player.vy >= 0 then
        for tx = curTLeft, curTRight do
            if isTileSolid(tx, curTBottom) then
                player.y = (curTBottom - 1) * TILE - player.h
                player.vy = 0
                player.onGround = true
                break
            end
        end
    elseif player.vy < 0 then
        for tx = curTLeft, curTRight do
            if isTileSolid(tx, curTTop) then
                player.y = curTTop * TILE + 0.01
                player.vy = 0
                break
            end
        end
    end

    -- Clamp to World
    if player.x < 0 then player.x = 0; player.vx = 0 end
    local maxWorldX = WORLD_W * TILE - player.w
    if player.x > maxWorldX then player.x = maxWorldX; player.vx = 0 end
    if player.y > (WORLD_H + 4) * TILE then
        spawnPlayer()
    end
end

-- ============================================================================
-- PARTICLES & DROPS & TNT
-- ============================================================================
local function addBlockParticles(tx, ty, blockId)
    local def = BLOCKS[blockId]
    local color = def and def.color or {0.6, 0.6, 0.6}
    local cx = (tx - 0.5) * TILE
    local cy = (ty - 0.5) * TILE
    for _ = 1, 8 do
        table.insert(particles, {
            x = cx + (math.random() - 0.5) * 12,
            y = cy + (math.random() - 0.5) * 12,
            vx = (math.random() - 0.5) * 160,
            vy = -math.random(40, 180),
            size = math.random(3, 5),
            color = color,
            life = 0.5,
            maxLife = 0.5,
        })
    end
end

local function addExplosionParticles(cx, cy)
    for _ = 1, 30 do
        local angle = math.random() * math.pi * 2
        local spd = math.random(50, 320)
        local isFire = math.random() < 0.6
        table.insert(particles, {
            x = cx,
            y = cy,
            vx = math.cos(angle) * spd,
            vy = math.sin(angle) * spd,
            size = math.random(5, 10),
            color = isFire and {1.0, math.random(0.3, 0.8), 0.1} or {0.4, 0.4, 0.4},
            life = 0.6,
            maxLife = 0.6,
        })
    end
end

local function spawnItemDrop(tx, ty, blockId)
    if blockId == B_AIR then return end
    local def = BLOCKS[blockId]
    local dropId = def and def.drop or blockId
    if dropId == B_AIR then return end
    table.insert(itemDrops, {
        x = (tx - 0.5) * TILE,
        y = (ty - 0.5) * TILE,
        blockId = dropId,
        bob = math.random() * 10,
        vy = -80,
    })
end

local function igniteTNT(tx, ty)
    world[tx][ty] = B_AIR
    table.insert(primedTNT, {
        x = (tx - 1) * TILE,
        y = (ty - 1) * TILE,
        vx = (math.random() - 0.5) * 40,
        vy = -180,
        timer = 2.0,
        flash = 0,
    })
    playSnd(sounds.place)
end

local function triggerExplosion(ex, ey)
    shakeTime = 0.4
    shakeMag = 12
    playSnd(sounds.explode)
    addExplosionParticles(ex, ey)

    local tileCenterX = math.floor(ex / TILE) + 1
    local tileCenterY = math.floor(ey / TILE) + 1
    local radius = 3

    for ox = -radius, radius do
        for oy = -radius, radius do
            if ox * ox + oy * oy <= radius * radius then
                local tx = tileCenterX + ox
                local ty = tileCenterY + oy
                if tx >= 1 and tx <= WORLD_W and ty >= 1 and ty < WORLD_H then
                    local b = world[tx][ty]
                    if b ~= B_AIR and b ~= B_BEDROCK then
                        if b == B_TNT then
                            igniteTNT(tx, ty)
                        else
                            addBlockParticles(tx, ty, b)
                            if math.random() < 0.4 then
                                spawnItemDrop(tx, ty, b)
                            end
                            world[tx][ty] = B_AIR
                        end
                    end
                end
            end
        end
    end

    -- Damage / Push Player if close
    local pDist = math.sqrt((player.x - ex)^2 + (player.y - ey)^2)
    if pDist < radius * TILE * 1.5 then
        player.vy = -350
        player.vx = (player.x > ex and 1 or -1) * 280
    end
end

-- ============================================================================
-- MINING & BUILDING INTERACTIONS
-- ============================================================================
local function breakBlock(tx, ty)
    if tx < 1 or tx > WORLD_W or ty < 1 or ty > WORLD_H then return end
    local b = world[tx][ty]
    if b == B_AIR or b == B_BEDROCK then return end

    if b == B_TNT then
        igniteTNT(tx, ty)
        return
    end

    addBlockParticles(tx, ty, b)
    spawnItemDrop(tx, ty, b)
    world[tx][ty] = B_AIR
    playSnd(sounds.break_b)
end

local function placeBlock(tx, ty, blockId)
    if tx < 1 or tx > WORLD_W or ty < 1 or ty > WORLD_H then return end
    if world[tx][ty] ~= B_AIR then return end

    -- Ensure doesn't overlap player body for solid blocks
    local def = BLOCKS[blockId]
    if def and def.solid then
        local bx = (tx - 1) * TILE
        local by = (ty - 1) * TILE
        if player.x + player.w > bx and player.x < bx + TILE and
           player.y + player.h > by and player.y < by + TILE then
            return
        end
    end

    world[tx][ty] = blockId
    player.mineAnim = 1
    playSnd(sounds.place)
end

local function canReach(tx, ty)
    local pcx = player.x + player.w / 2
    local pcy = player.y + player.h / 2
    local tcx = (tx - 0.5) * TILE
    local tcy = (ty - 0.5) * TILE
    local dist = math.sqrt((pcx - tcx)^2 + (pcy - tcy)^2)
    return dist <= 6.5 * TILE
end

-- ============================================================================
-- UI BUTTON DEFINITIONS & TOUCH HANDLING
-- ============================================================================
local function getUIButtons()
    local btnW = 65
    local btnH = 55
    local pad = 20

    local btns = {
        left = {
            id = "left",
            x = pad,
            y = screenH - pad - btnH,
            w = btnW,
            h = btnH,
            text = "◀",
        },
        right = {
            id = "right",
            x = pad + btnW + 12,
            y = screenH - pad - btnH,
            w = btnW,
            h = btnH,
            text = "▶",
        },
        jump = {
            id = "jump",
            x = screenW - pad - 75,
            y = screenH - pad - 65,
            w = 75,
            h = 65,
            text = "▲ JUMP",
        },
        mode = {
            id = "mode",
            x = screenW - 130,
            y = 12,
            w = 115,
            h = 38,
            text = player.mode == "MINE" and "⛏ MINE" or "📦 BUILD",
        },
        fly = {
            id = "fly",
            x = screenW - 225,
            y = 12,
            w = 85,
            h = 38,
            text = player.flying and "🕊 FLY:ON" or "🕊 FLY",
        },
        spawn = {
            id = "spawn",
            x = 15,
            y = 12,
            w = 90,
            h = 38,
            text = "⟳ SPAWN",
        },
    }

    if player.flying then
        btns.up = {
            id = "up",
            x = screenW - pad - 75,
            y = screenH - pad - 140,
            w = 75,
            h = 55,
            text = "▲ UP",
        }
        btns.down = {
            id = "down",
            x = screenW - pad - 75,
            y = screenH - pad - 65,
            w = 75,
            h = 55,
            text = "▼ DOWN",
        }
    end

    return btns
end

local function hitTest(btn, x, y)
    return x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h
end

local function getHotbarSlotAt(x, y)
    local slotSize = 36
    local slotPad = 6
    local totalW = #HOTBAR * slotSize + (#HOTBAR - 1) * slotPad
    local startX = math.floor((screenW - totalW) / 2)
    local startY = 12

    if y >= startY and y <= startY + slotSize then
        for i = 1, #HOTBAR do
            local sx = startX + (i - 1) * (slotSize + slotPad)
            if x >= sx and x <= sx + slotSize then
                return i
            end
        end
    end
    return nil
end

-- ============================================================================
-- LOVE2D CALLBACKS
-- ============================================================================

function love.load()
    updateScreen()
    math.randomseed(os.time())
    love.graphics.setDefaultFilter("nearest", "nearest")

    initAudio()
    generateBlockTextures()
    generateWorld()
    spawnPlayer()

    -- Generate Clouds
    clouds = {}
    for i = 1, 8 do
        table.insert(clouds, {
            x = math.random(0, WORLD_W * TILE),
            y = math.random(20, 160),
            w = math.random(70, 140),
            h = math.random(20, 35),
            speed = math.random(8, 22),
        })
    end
end

function love.update(dt)
    updateScreen()
    if dt > 0.1 then dt = 0.1 end

    -- Day/Night Cycle Progression
    gameTime = (gameTime + dt) % DAY_DURATION

    -- Screenshake Decay
    if shakeTime > 0 then
        shakeTime = shakeTime - dt
        if shakeTime <= 0 then shakeMag = 0 end
    end

    -- Process Clouds
    for _, c in ipairs(clouds) do
        c.x = c.x + c.speed * dt
        if c.x > WORLD_W * TILE + 200 then
            c.x = -c.w - 50
            c.y = math.random(20, 160)
        end
    end

    -- Input Collection (Desktop + Touch combined)
    local moveInput = 0
    local jumpInput = false
    local upInput = false
    local downInput = false

    -- Desktop Keyboard Input
    if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
        moveInput = moveInput - 1
    end
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
        moveInput = moveInput + 1
    end
    if love.keyboard.isDown("w") or love.keyboard.isDown("space") or love.keyboard.isDown("up") then
        jumpInput = true
        upInput = true
    end
    if love.keyboard.isDown("s") or love.keyboard.isDown("down") then
        downInput = true
    end

    -- Touch Controls Input
    local btns = getUIButtons()
    local worldTouchX, worldTouchY = nil, nil

    for _, t in pairs(touches) do
        if t.btn == "left" then
            moveInput = moveInput - 1
        elseif t.btn == "right" then
            moveInput = moveInput + 1
        elseif t.btn == "jump" then
            jumpInput = true
        elseif t.btn == "up" then
            upInput = true
        elseif t.btn == "down" then
            downInput = true
        elseif t.btn == "world" then
            worldTouchX = t.x
            worldTouchY = t.y
        end
    end

    -- Update Player Movement & Physics
    updatePlayer(dt, moveInput, jumpInput, upInput, downInput)

    -- Mouse mining / placing on desktop
    local desktopMining = false
    if love.mouse.isDown(1) and not worldTouchX then
        local mx, my = love.mouse.getPosition()
        local slot = getHotbarSlotAt(mx, my)
        local onAnyBtn = false
        for _, b in pairs(btns) do
            if hitTest(b, mx, my) then onAnyBtn = true; break end
        end
        if not slot and not onAnyBtn then
            worldTouchX = mx
            worldTouchY = my
            desktopMining = true
        end
    end

    -- World Interaction (Mining / Building)
    if worldTouchX and worldTouchY then
        local targetX = math.floor((worldTouchX + camX) / TILE) + 1
        local targetY = math.floor((worldTouchY + camY) / TILE) + 1

        if canReach(targetX, targetY) then
            local currentBlock = (targetX >= 1 and targetX <= WORLD_W and targetY >= 1 and targetY <= WORLD_H)
                and world[targetX][targetY] or B_AIR

            if player.mode == "MINE" or desktopMining then
                if currentBlock ~= B_AIR and currentBlock ~= B_BEDROCK then
                    player.mineAnim = 1
                    if mining.active and mining.tileX == targetX and mining.tileY == targetY then
                        mining.progress = mining.progress + dt
                        if math.random() < 0.25 then playSnd(sounds.dig) end
                        if mining.progress >= mining.maxTime then
                            breakBlock(targetX, targetY)
                            mining.active = false
                            mining.progress = 0
                        end
                    else
                        mining.active = true
                        mining.tileX = targetX
                        mining.tileY = targetY
                        mining.progress = 0
                        local def = BLOCKS[currentBlock]
                        mining.maxTime = (def and def.hardness > 0) and (player.flying and 0.05 or def.hardness) or 0.5
                    end
                else
                    mining.active = false
                end
            elseif player.mode == "PLACE" then
                mining.active = false
                if currentBlock == B_AIR then
                    local selBlock = HOTBAR[player.selectedSlot] or B_DIRT
                    placeBlock(targetX, targetY, selBlock)
                end
            end
        else
            mining.active = false
        end
    else
        mining.active = false
    end

    -- Update Primed TNT
    for i = #primedTNT, 1, -1 do
        local tnt = primedTNT[i]
        tnt.vy = tnt.vy + 600 * dt
        tnt.x = tnt.x + tnt.vx * dt
        tnt.y = tnt.y + tnt.vy * dt
        tnt.timer = tnt.timer - dt
        tnt.flash = (tnt.flash + dt * 10) % 1

        -- Floor check
        local tx = math.floor(tnt.x / TILE) + 1
        local ty = math.floor((tnt.y + 16) / TILE) + 1
        if isTileSolid(tx, ty) then
            tnt.y = (ty - 1) * TILE - 16
            tnt.vy = 0
            tnt.vx = tnt.vx * 0.5
        end

        if tnt.timer <= 0 then
            triggerExplosion(tnt.x + 8, tnt.y + 8)
            table.remove(primedTNT, i)
        end
    end

    -- Update Item Drops
    for i = #itemDrops, 1, -1 do
        local item = itemDrops[i]
        item.bob = item.bob + dt * 4
        item.vy = item.vy + 500 * dt
        item.y = item.y + item.vy * dt

        local tx = math.floor(item.x / TILE) + 1
        local ty = math.floor((item.y + 12) / TILE) + 1
        if isTileSolid(tx, ty) then
            item.y = (ty - 1) * TILE - 12
            item.vy = 0
        end

        -- Pickup Magnet
        local dx = (player.x + player.w / 2) - item.x
        local dy = (player.y + player.h / 2) - item.y
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist < 42 then
            item.x = item.x + dx * 8 * dt
            item.y = item.y + dy * 8 * dt
            if dist < 16 then
                playSnd(sounds.pickup)
                table.remove(itemDrops, i)
            end
        end
    end

    -- Update Particles
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.life = p.life - dt
        p.vy = p.vy + 400 * dt
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        if p.life <= 0 then
            table.remove(particles, i)
        end
    end

    -- Smooth Camera Follow
    local targetCamX = (player.x + player.w / 2) - screenW / 2
    local targetCamY = (player.y + player.h / 2) - screenH / 2

    local minCamX = 0
    local maxCamX = WORLD_W * TILE - screenW
    local minCamY = -200
    local maxCamY = WORLD_H * TILE - screenH

    targetCamX = math.max(minCamX, math.min(maxCamX, targetCamX))
    targetCamY = math.max(minCamY, math.min(maxCamY, targetCamY))

    camX = camX + (targetCamX - camX) * 8 * dt
    camY = camY + (targetCamY - camY) * 8 * dt
end

-- ============================================================================
-- RENDERING / DRAW
-- ============================================================================
function love.draw()
    updateScreen()

    -- Calculate Day / Night Sky Color
    local cycle = gameTime / DAY_DURATION
    local skyR, skyG, skyB
    if cycle < 0.25 then
        -- Dawn: 0.0 -> 0.25
        local t = cycle / 0.25
        skyR = 0.10 + t * 0.35
        skyG = 0.12 + t * 0.60
        skyB = 0.25 + t * 0.70
    elseif cycle < 0.60 then
        -- Daytime
        skyR = 0.45
        skyG = 0.72
        skyB = 0.95
    elseif cycle < 0.75 then
        -- Sunset
        local t = (cycle - 0.60) / 0.15
        skyR = 0.45 + t * 0.38 - t * 0.65
        skyG = 0.72 - t * 0.55
        skyB = 0.95 - t * 0.70
    else
        -- Night
        skyR = 0.06
        skyG = 0.07
        skyB = 0.15
    end

    -- Clear Background with Sky Color
    love.graphics.setColor(skyR, skyG, skyB)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Screenshake Offset
    local sx = 0
    local sy = 0
    if shakeTime > 0 then
        sx = (math.random() * 2 - 1) * shakeMag
        sy = (math.random() * 2 - 1) * shakeMag
    end

    love.graphics.push()
    love.graphics.translate(-math.floor(camX) + sx, -math.floor(camY) + sy)

    -- Draw Stars at Night
    if cycle >= 0.65 or cycle <= 0.20 then
        love.graphics.setColor(1, 1, 1, 0.8)
        for i = 1, 40 do
            local starX = (i * 97) % (WORLD_W * TILE)
            local starY = (i * 53) % 220
            love.graphics.rectangle("fill", starX, starY, 2, 2)
        end
    end

    -- Draw Sun & Moon
    local sunAngle = cycle * math.pi * 2
    local sunX = (WORLD_W * TILE / 2) + math.cos(sunAngle) * (WORLD_W * TILE * 0.45)
    local sunY = 180 + math.sin(sunAngle) * 200
    if sunY < 320 then
        -- Sun
        love.graphics.setColor(1.0, 0.92, 0.35)
        love.graphics.rectangle("fill", sunX - 18, sunY - 18, 36, 36)
        love.graphics.setColor(1.0, 0.82, 0.15, 0.4)
        love.graphics.rectangle("fill", sunX - 22, sunY - 22, 44, 44)
    end
    -- Moon (opposite side)
    local moonX = (WORLD_W * TILE / 2) + math.cos(sunAngle + math.pi) * (WORLD_W * TILE * 0.45)
    local moonY = 180 + math.sin(sunAngle + math.pi) * 200
    if moonY < 320 then
        love.graphics.setColor(0.92, 0.94, 0.98)
        love.graphics.rectangle("fill", moonX - 14, moonY - 14, 28, 28)
        love.graphics.setColor(0.75, 0.80, 0.88)
        love.graphics.rectangle("fill", moonX - 6, moonY - 6, 8, 8)
    end

    -- Draw Clouds
    love.graphics.setColor(1, 1, 1, 0.85)
    for _, c in ipairs(clouds) do
        love.graphics.rectangle("fill", c.x, c.y, c.w, c.h, 4, 4)
    end

    -- Viewport Tile Bounds (Render only visible tiles for top performance)
    local startTileX = math.max(1, math.floor(camX / TILE))
    local endTileX   = math.min(WORLD_W, math.ceil((camX + screenW) / TILE) + 1)
    local startTileY = math.max(1, math.floor(camY / TILE))
    local endTileY   = math.min(WORLD_H, math.ceil((camY + screenH) / TILE) + 1)

    -- Draw World Tiles
    for tx = startTileX, endTileX do
        local col = world[tx]
        if col then
            for ty = startTileY, endTileY do
                local b = col[ty]
                if b and b ~= B_AIR then
                    local bx = (tx - 1) * TILE
                    local by = (ty - 1) * TILE
                    local canvas = blockCanvases[b]

                    if canvas then
                        love.graphics.setColor(1, 1, 1, 1)
                        love.graphics.draw(canvas, bx, by, 0, TILE / 16, TILE / 16)
                    else
                        local def = BLOCKS[b]
                        local c = def and def.color or {0.5, 0.5, 0.5}
                        love.graphics.setColor(c[1], c[2], c[3])
                        love.graphics.rectangle("fill", bx, by, TILE, TILE)
                    end

                    -- Ambient depth shading for underground
                    if ty > SURFACE_BASE_Y + 12 then
                        local darkFactor = math.min(0.45, (ty - SURFACE_BASE_Y - 12) * 0.015)
                        love.graphics.setColor(0, 0, 0, darkFactor)
                        love.graphics.rectangle("fill", bx, by, TILE, TILE)
                    end
                end
            end
        end
    end

    -- Draw Mining Cracks Overlay
    if mining.active and mining.progress > 0 then
        local stage = math.min(5, math.max(1, math.floor((mining.progress / mining.maxTime) * 5) + 1))
        local crackCanvas = crackCanvases[stage]
        local bx = (mining.tileX - 1) * TILE
        local by = (mining.tileY - 1) * TILE
        if crackCanvas then
            love.graphics.setColor(1, 1, 1, 0.9)
            love.graphics.draw(crackCanvas, bx, by, 0, TILE / 16, TILE / 16)
        else
            love.graphics.setColor(0, 0, 0, 0.45)
            love.graphics.rectangle("fill", bx, by, TILE * (mining.progress / mining.maxTime), TILE)
        end
        -- Red target selection box
        love.graphics.setColor(1, 1, 1, 0.7)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", bx + 0.5, by + 0.5, TILE - 1, TILE - 1)
    end

    -- Draw Item Drops
    for _, item in ipairs(itemDrops) do
        local canvas = blockCanvases[item.blockId]
        local floatY = item.y + math.sin(item.bob) * 3
        if canvas then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(canvas, item.x - 6, floatY - 6, 0, 12 / 16, 12 / 16)
        else
            local def = BLOCKS[item.blockId]
            local c = def and def.color or {0.8, 0.8, 0.2}
            love.graphics.setColor(c[1], c[2], c[3])
            love.graphics.rectangle("fill", item.x - 5, floatY - 5, 10, 10)
        end
    end

    -- Draw Primed TNT
    for _, tnt in ipairs(primedTNT) do
        local canvas = blockCanvases[B_TNT]
        if tnt.flash > 0.5 then
            love.graphics.setColor(1, 1, 1, 1)
        else
            love.graphics.setColor(1, 0.3, 0.3, 1)
        end
        if canvas then
            love.graphics.draw(canvas, tnt.x, tnt.y, 0, TILE / 16, TILE / 16)
        else
            love.graphics.rectangle("fill", tnt.x, tnt.y, TILE, TILE)
        end
    end

    -- Draw Particles
    for _, p in ipairs(particles) do
        local alpha = p.life / p.maxLife
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
        love.graphics.rectangle("fill", p.x - p.size / 2, p.y - p.size / 2, p.size, p.size)
    end

    -- ========================================================================
    -- DRAW PLAYER (Minecraft Steve)
    -- ========================================================================
    love.graphics.push()
    local px = math.floor(player.x + player.w / 2)
    local py = math.floor(player.y)
    love.graphics.translate(px, py)
    love.graphics.scale(player.facing, 1)

    local swing = math.sin(player.walkAnim)
    local armSwing = player.mineAnim > 0 and (math.sin(love.timer.getTime() * 25) * 0.6 + 0.4) or (-swing * 0.4)

    -- Back Arm
    love.graphics.setColor(0.75, 0.52, 0.38)
    love.graphics.push()
    love.graphics.translate(0, 11)
    love.graphics.rotate(-swing * 0.5)
    love.graphics.rectangle("fill", -2, 0, 4, 10)
    love.graphics.setColor(0.0, 0.62, 0.68)
    love.graphics.rectangle("fill", -2, 0, 4, 4)
    love.graphics.pop()

    -- Legs
    -- Left Leg
    love.graphics.push()
    love.graphics.translate(-3, 20)
    love.graphics.rotate(swing * 0.5)
    love.graphics.setColor(0.18, 0.28, 0.58) -- Blue jeans
    love.graphics.rectangle("fill", -2, 0, 4, 9)
    love.graphics.setColor(0.28, 0.28, 0.28) -- Shoes
    love.graphics.rectangle("fill", -2, 9, 4, 3)
    love.graphics.pop()

    -- Right Leg
    love.graphics.push()
    love.graphics.translate(3, 20)
    love.graphics.rotate(-swing * 0.5)
    love.graphics.setColor(0.18, 0.28, 0.58)
    love.graphics.rectangle("fill", -2, 0, 4, 9)
    love.graphics.setColor(0.28, 0.28, 0.28)
    love.graphics.rectangle("fill", -2, 9, 4, 3)
    love.graphics.pop()

    -- Torso (Cyan Shirt)
    love.graphics.setColor(0.0, 0.68, 0.75)
    love.graphics.rectangle("fill", -5, 10, 10, 10)

    -- Head
    love.graphics.setColor(0.85, 0.62, 0.45) -- Skin tone
    love.graphics.rectangle("fill", -5, 0, 10, 10)
    -- Hair
    love.graphics.setColor(0.32, 0.18, 0.08)
    love.graphics.rectangle("fill", -5, 0, 10, 3)
    love.graphics.rectangle("fill", -5, 3, 2, 2)
    -- Eyes
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", 1, 4, 2, 2)
    love.graphics.setColor(0.15, 0.35, 0.75)
    love.graphics.rectangle("fill", 2, 4, 1, 2)
    -- Mouth / Beard
    love.graphics.setColor(0.38, 0.22, 0.12)
    love.graphics.rectangle("fill", 0, 8, 3, 1)

    -- Front Arm (Mining / Tool Swing)
    love.graphics.setColor(0.85, 0.62, 0.45)
    love.graphics.push()
    love.graphics.translate(2, 11)
    love.graphics.rotate(armSwing)
    love.graphics.rectangle("fill", -2, 0, 4, 10)
    love.graphics.setColor(0.0, 0.68, 0.75)
    love.graphics.rectangle("fill", -2, 0, 4, 4)

    -- In-hand item if placing or holding block
    local heldBlock = HOTBAR[player.selectedSlot]
    if heldBlock and blockCanvases[heldBlock] then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(blockCanvases[heldBlock], 0, 8, -0.3, 8 / 16, 8 / 16)
    end
    love.graphics.pop()

    love.graphics.pop()
    love.graphics.pop() -- End world transform

    -- ========================================================================
    -- HUD & TOUCH CONTROLS OVERLAY
    -- ========================================================================

    -- 1. Hotbar Slots
    local slotSize = 38
    local slotPad = 6
    local totalW = #HOTBAR * slotSize + (#HOTBAR - 1) * slotPad
    local startX = math.floor((screenW - totalW) / 2)
    local startY = 12

    -- Hotbar background plate
    love.graphics.setColor(0, 0, 0, 0.55)
    love.graphics.rectangle("fill", startX - 6, startY - 4, totalW + 12, slotSize + 8, 6, 6)

    for i, blockId in ipairs(HOTBAR) do
        local bx = startX + (i - 1) * (slotSize + slotPad)
        local isSel = (i == player.selectedSlot)

        -- Slot box
        if isSel then
            love.graphics.setColor(1.0, 0.85, 0.2, 0.85)
            love.graphics.rectangle("fill", bx - 2, startY - 2, slotSize + 4, slotSize + 4, 4, 4)
            love.graphics.setColor(0.25, 0.25, 0.25, 0.95)
            love.graphics.rectangle("fill", bx, startY, slotSize, slotSize, 3, 3)
        else
            love.graphics.setColor(0.18, 0.18, 0.18, 0.8)
            love.graphics.rectangle("fill", bx, startY, slotSize, slotSize, 3, 3)
        end

        -- Block Icon
        local canvas = blockCanvases[blockId]
        if canvas then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(canvas, bx + 5, startY + 5, 0, (slotSize - 10) / 16, (slotSize - 10) / 16)
        else
            local def = BLOCKS[blockId]
            local c = def and def.color or {0.5, 0.5, 0.5}
            love.graphics.setColor(c[1], c[2], c[3])
            love.graphics.rectangle("fill", bx + 6, startY + 6, slotSize - 12, slotSize - 12)
        end

        -- Slot Number
        love.graphics.setColor(1, 1, 1, 0.85)
        love.graphics.print(tostring(i), bx + 3, startY + 2)
    end

    -- Selected Block Name below hotbar
    local selDef = BLOCKS[HOTBAR[player.selectedSlot]]
    if selDef then
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.printf(selDef.name, startX, startY + slotSize + 8, totalW, "center")
    end

    -- 2. UI Buttons (Mobile Friendly)
    local btns = getUIButtons()
    for _, b in pairs(btns) do
        local isPressed = false
        for _, t in pairs(touches) do
            if t.btn == b.id then isPressed = true; break end
        end

        if isPressed then
            love.graphics.setColor(0.9, 0.9, 0.9, 0.75)
        else
            love.graphics.setColor(0.12, 0.12, 0.12, 0.55)
        end
        love.graphics.rectangle("fill", b.x, b.y, b.w, b.h, 8, 8)

        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", b.x + 0.5, b.y + 0.5, b.w - 1, b.h - 1, 8, 8)

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(b.text, b.x, b.y + (b.h - 14) / 2, b.w, "center")
    end

    -- 3. Health & Status
    local hearts = player.health
    love.graphics.setColor(1, 0.2, 0.2, 0.9)
    for h = 1, hearts do
        love.graphics.rectangle("fill", 15 + (h - 1) * 14, 56, 10, 10, 2, 2)
    end

    -- Fly Mode Indicator
    if player.flying then
        love.graphics.setColor(0.3, 0.9, 1.0, 0.9)
        love.graphics.print("CREATIVE FLY MODE ACTIVE", 15, 72)
    end
end

-- ============================================================================
-- INPUT EVENT HANDLERS
-- ============================================================================

function love.keypressed(key)
    -- Number Keys for Hotbar
    local num = tonumber(key)
    if num and num >= 1 and num <= #HOTBAR then
        player.selectedSlot = num
    end

    -- Toggle Creative Fly Mode
    if key == "f" then
        player.flying = not player.flying
        playSnd(sounds.jump)
    end

    -- Toggle Mine / Place Mode
    if key == "m" or key == "tab" then
        player.mode = (player.mode == "MINE") and "PLACE" or "MINE"
    end

    -- Respawn
    if key == "r" then
        spawnPlayer()
    end
end

function love.wheelmoved(x, y)
    if y > 0 then
        player.selectedSlot = player.selectedSlot - 1
        if player.selectedSlot < 1 then player.selectedSlot = #HOTBAR end
    elseif y < 0 then
        player.selectedSlot = player.selectedSlot + 1
        if player.selectedSlot > #HOTBAR then player.selectedSlot = 1 end
    end
end

function love.mousepressed(x, y, button)
    -- Check hotbar click
    local slot = getHotbarSlotAt(x, y)
    if slot then
        player.selectedSlot = slot
        return
    end

    -- Check UI button click
    local btns = getUIButtons()
    for _, b in pairs(btns) do
        if hitTest(b, x, y) then
            if b.id == "mode" then
                player.mode = (player.mode == "MINE") and "PLACE" or "MINE"
            elseif b.id == "fly" then
                player.flying = not player.flying
                playSnd(sounds.jump)
            elseif b.id == "spawn" then
                spawnPlayer()
            end
            return
        end
    end

    -- Right Click: Place Block
    if button == 2 then
        local targetX = math.floor((x + camX) / TILE) + 1
        local targetY = math.floor((y + camY) / TILE) + 1
        if canReach(targetX, targetY) and world[targetX] and world[targetX][targetY] == B_AIR then
            local selBlock = HOTBAR[player.selectedSlot] or B_DIRT
            placeBlock(targetX, targetY, selBlock)
        end
    end
end

-- Mobile Multi-Touch Event Handlers
function love.touchpressed(id, x, y)
    local slot = getHotbarSlotAt(x, y)
    if slot then
        player.selectedSlot = slot
        touches[id] = {x = x, y = y, btn = "hotbar"}
        return
    end

    local btns = getUIButtons()
    for _, b in pairs(btns) do
        if hitTest(b, x, y) then
            if b.id == "mode" then
                player.mode = (player.mode == "MINE") and "PLACE" or "MINE"
            elseif b.id == "fly" then
                player.flying = not player.flying
                playSnd(sounds.jump)
            elseif b.id == "spawn" then
                spawnPlayer()
            end
            touches[id] = {x = x, y = y, btn = b.id}
            return
        end
    end

    -- Touch on game world
    touches[id] = {x = x, y = y, btn = "world"}
end

function love.touchmoved(id, x, y)
    if touches[id] then
        touches[id].x = x
        touches[id].y = y
    end
end

function love.touchreleased(id)
    touches[id] = nil
end
