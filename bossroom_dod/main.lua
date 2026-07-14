-- main.lua: DOD/ECS Boss Room — entities are IDs, systems iterate arrays
require("deps.lick")
local bump = require("deps.bump")
local W = require("world")
local Rooms = require("rooms")
local Combat = require("combat")
local Particles = require("particles")
local Camera = require("camera")
local Sprite = require("sprite")

-- Systems
local sysGravity    = require("systems.gravity")
local sysMovement   = require("systems.movement")
local sysKnockback  = require("systems.knockback")
local sysHealth     = require("systems.health")
local sysPlayerInput = require("systems.player_input")
local sysBossAI     = require("systems.boss_ai")
local sysCombat     = require("systems.combat_sys")
local Draw          = require("systems.draw")

-- Entity IDs (set on load)
local playerId, bossId
local bumpWorld
local debugMode = false
local gameState = "playing"
local endTimer = 0
local currentRoom = "hallway"
local bossActive = false
local SCREEN_W, SCREEN_H = 800, 720

-- ============================================================
-- SPAWN FUNCTIONS (create entity + attach components)
-- ============================================================
local function spawnPlayer(world, x, y)
    local id = W.spawn()
    W.pos[id]    = { x = x, y = y, w = 50, h = 50 }
    W.vel[id]    = { vx = 0, vy = 0 }
    W.tag[id]    = "player"

    local item = { type = "player", entity = id }
    world:add(item, x, y, 50, 50)
    W.phys[id]   = { bumpWorld = world, item = item, onGround = false }

    W.health[id] = { hp = 7, maxHp = 7, iframes = 0, flashTimer = 0 }
    W.kb[id]     = { vx = 0, vy = 0, timer = 0 }

    W.player[id] = {
        facing = 1,
        state = "idle",
        jumpTimer = 0,
        jumpHeld = false,
        attackTimer = 0,
        attackCooldown = 0,
        dashTimer = 0,
        dashCooldown = 0,
        dashDir = 1,
        animTimer = 0,
        animFrame = 0,
        walkSprites = Sprite.load("assets/helmet/helmet_walk_", 5, 0),
        attackSprites = Sprite.load("assets/helmet/helmet_attack_", 5, 0),
        attackEffect = (function()
            local img = love.graphics.newImage("assets/helmet/Attack.png")
            img:setFilter("nearest", "nearest")
            return img
        end)(),
    }
    return id
end

local function spawnBoss(world, x, y)
    local id = W.spawn()
    W.pos[id]    = { x = x, y = y, w = 100, h = 200 }
    W.vel[id]    = { vx = 0, vy = 0 }
    W.tag[id]    = "boss"

    local item = { type = "boss", entity = id }
    world:add(item, x, y, 100, 200)
    W.phys[id]   = { bumpWorld = world, item = item, onGround = false }

    W.health[id] = { hp = 45, maxHp = 45, iframes = 0, flashTimer = 0 }
    W.kb[id]     = { vx = 0, vy = 0, timer = 0 }

    W.boss[id] = {
        state = "idle",
        stateTimer = 1.0,
        attackType = nil,
        attackHitbox = nil,
        phase = 1,
        hitsTaken = 0,
        staggerThreshold = 12,
        comboCount = 0,
        leapCount = 0,
        leapTarget = nil,
        facing = 1,
        sprites = Sprite.load("assets/boss/boss_frame_", 4, 0),
        spriteFrame = 0,
        visible = true,
        _leapShook = false,
    }
    return id
end

-- ============================================================
-- LOVE CALLBACKS
-- ============================================================
function love.load()
    love.window.setMode(1280, 720, { fullscreen = false })
    love.window.setTitle("Boss Room (DOD)")
    math.randomseed(os.time())

    W.reset()
    bumpWorld = Rooms.buildWorld()

    local spawn = Rooms.list.hallway.playerSpawn
    playerId = spawnPlayer(bumpWorld, spawn.x, spawn.y)

    local bossSpawn = Rooms.list.boss.bossSpawn
    bossId = spawnBoss(bumpWorld, bossSpawn.x, bossSpawn.y)
    bossActive = false

    -- Stop old sounds
    if SFX then
        for _, s in pairs(SFX) do if s.stop then s:stop() end end
    end

    SFX = {
        shortSwing = love.audio.newSource("assets/sound/ShortSwing.wav", "static"),
        critical = love.audio.newSource("assets/sound/Critical.wav", "static"),
        bigGuyScream = love.audio.newSource("assets/sound/BigGuyScream.wav", "static"),
        horrorScream = love.audio.newSource("assets/sound/HorrorScream.wav", "static"),
        lowTempo = love.audio.newSource("assets/sound/LowTempo.wav", "stream"),
        dash = love.audio.newSource("assets/sound/dash.wav", "static"),
        smash = love.audio.newSource("assets/sound/smash.wav", "static"),
    }
    SFX.shortSwing:setVolume(0.12)
    SFX.horrorScream:setVolume(0.02)
    SFX.bigGuyScream:setVolume(0.12)
    SFX.critical:setVolume(0.25)
    SFX.dash:setVolume(0.12)
    SFX.horrorScream:play()
    SFX.lowTempo:setLooping(true)
    SFX.lowTempo:setVolume(0.12)
    SFX.lowTempo:play()
    SFX.highTempo = love.audio.newSource("assets/sound/HighTempo.wav", "stream")
    SFX.highTempo:setLooping(true)
    SFX.highTempo:setVolume(0.12)

    horrorFade = 0
    tutorialFont = love.graphics.newFont(12)

    Combat.freezeTimer = 0
    Combat.shakeTimer = 0
    Combat.shakeX = 0
    Combat.shakeY = 0
    Particles.reset()
    Rooms.door.sealed = false
    gameState = "playing"
    endTimer = 0
    debugMode = false
    currentRoom = "hallway"

    Camera.reset()
    Camera.setBounds(Rooms.list.hallway)
    local pp = W.pos[playerId]
    Camera.x = pp.x - SCREEN_W / 2
    Camera.y = pp.y - SCREEN_H / 2
end

function love.update(dt)
    dt = math.min(dt, 1 / 30)

    -- Hitstop
    if Combat.freezeTimer > 0 then
        Combat.freezeTimer = Combat.freezeTimer - dt
        Combat.updateShake(dt)
        return
    end

    if gameState == "playing" then
        local pp = W.pos[playerId]

        -- Room transition
        local roomName, room = Rooms.getRoomAt(pp.x + pp.w / 2, pp.y + pp.h / 2)
        if roomName ~= currentRoom then
            currentRoom = roomName
            Camera.setBounds(room)
            Camera.zoom = roomName == "boss" and 1 or 1.25

            if roomName == "boss" and not bossActive then
                bossActive = true
                Rooms.sealDoor(bumpWorld)
                if pp.x + pp.w > Rooms.door.x and pp.x < Rooms.door.x + Rooms.door.w then
                    pp.x = Rooms.door.x + Rooms.door.w
                    bumpWorld:update(W.phys[playerId].item, pp.x, pp.y)
                end
                horrorFade = 1.5
                SFX.lowTempo:stop()
                SFX.highTempo:play()
            end
        end

        -- Run systems in order
        sysHealth(dt)
        local inKB = sysKnockback(dt)
        sysPlayerInput(dt, bossId, inKB)
        if bossActive then
            sysBossAI(dt, playerId)
        end
        sysGravity(dt)
        sysMovement(dt)
        sysCombat(dt, playerId, bossId, bossActive)

        -- Win/lose
        local bhp = W.health[bossId]
        local php = W.health[playerId]
        local pl = W.player[playerId]
        if bossActive and bhp.hp <= 0 then
            gameState = "win"
            endTimer = 1.5
            local bp = W.pos[bossId]
            Particles.spawn(bp.x + bp.w / 2, bp.y + bp.h / 2, 20)
            Rooms.unsealDoor(bumpWorld)
        elseif php.hp <= 0 then
            gameState = "dead"
            endTimer = 1.5
            pl.state = "dead"
            Particles.spawn(pp.x + pp.w / 2, pp.y + pp.h / 2, 20)
            SFX.horrorScream:play()
        end
    else
        endTimer = endTimer - dt
    end

    -- Horror fade
    if horrorFade and horrorFade > 0 then
        horrorFade = horrorFade - dt
        SFX.horrorScream:setVolume(0.02 * math.max(0, horrorFade / 1.5))
    end

    -- Camera
    local pp = W.pos[playerId]
    Camera.update(dt, pp.x + pp.w / 2, pp.y + pp.h / 2, SCREEN_W, SCREEN_H)

    Particles.update(dt)
    Combat.updateShake(dt)
end

function love.draw()
    love.graphics.push()
    Camera.apply(Combat.shakeX, Combat.shakeY)

    -- Hallway bg
    love.graphics.setColor(0.06, 0.06, 0.09)
    love.graphics.rectangle("fill", 0, 0, Rooms.list.hallway.w, Rooms.list.hallway.h)

    -- Tutorial (hallway only)
    if currentRoom == "hallway" then
        local lx, ly = 400, 120
        for r = 1, 6 do
            love.graphics.setColor(1, 0.9, 0.6, (7 - r) / 7 * 0.12)
            love.graphics.circle("fill", lx, ly, r * 60)
        end
        love.graphics.setColor(1, 0.95, 0.8, 0.25)
        love.graphics.circle("fill", lx, ly, 20)

        love.graphics.setFont(tutorialFont)
        local lines = { "MOVE: Arrow Keys / WASD", "JUMP: Up / W / Space", "ATTACK: X / J / LClick", "DASH: C / K / RClick" }
        for i, line in ipairs(lines) do
            love.graphics.setColor(0.9, 0.85, 0.7, 0.7)
            love.graphics.print(line, 40, 500 + (i - 1) * 20)
        end
    end

    -- Boss room bg
    love.graphics.setColor(0.08, 0.08, 0.12)
    local br = Rooms.list.boss
    love.graphics.rectangle("fill", br.x, br.y, br.w, br.h)

    -- Walls
    love.graphics.setColor(0.25, 0.25, 0.3)
    for _, room in pairs(Rooms.list) do
        for _, wall in ipairs(room.walls) do
            love.graphics.rectangle("fill", wall.x, wall.y, wall.w, wall.h)
        end
    end
    for _, wall in ipairs(Rooms.passage) do
        love.graphics.rectangle("fill", wall.x, wall.y, wall.w, wall.h)
    end

    -- Door
    if Rooms.door.sealed then
        love.graphics.setColor(0.5, 0.3, 0.1)
        love.graphics.rectangle("fill", Rooms.door.x, Rooms.door.y, Rooms.door.w, Rooms.door.h)
    end

    -- Draw entities via draw system
    if bossActive then Draw.boss(bossId) end
    Draw.player(playerId)

    Particles.draw()

    -- Debug
    if debugMode then
        love.graphics.setColor(0, 1, 0, 0.4)
        local pp = W.pos[playerId]
        love.graphics.rectangle("line", pp.x, pp.y, pp.w, pp.h)
        if bossActive then
            love.graphics.setColor(1, 0, 0, 0.4)
            local bp = W.pos[bossId]
            love.graphics.rectangle("line", bp.x, bp.y, bp.w, bp.h)
            love.graphics.setColor(1, 1, 1)
            local b = W.boss[bossId]
            love.graphics.print("B: " .. b.state .. (b.attackType and (" [" .. b.attackType .. "]") or ""), bp.x, bp.y - 28)
        end
    end

    love.graphics.pop()

    -- UI (screen-space)
    local scale = math.min(love.graphics.getWidth() / SCREEN_W, love.graphics.getHeight() / SCREEN_H)
    local ox = (love.graphics.getWidth() - SCREEN_W * scale) / 2
    local oy = (love.graphics.getHeight() - SCREEN_H * scale) / 2
    love.graphics.push()
    love.graphics.translate(ox, oy)
    love.graphics.scale(scale, scale)

    -- Player HP
    local php = W.health[playerId]
    for i = 1, php.maxHp do
        love.graphics.setColor(i <= php.hp and {1,1,1} or {0.3,0.3,0.3})
        love.graphics.circle("fill", 30 + (i - 1) * 22, 40, 8)
    end

    -- Boss HP bar
    local bhp = W.health[bossId]
    if bossActive and bhp.hp > 0 then
        local barW, barH = 400, 12
        local barX = (SCREEN_W - barW) / 2
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", barX, 20, barW, barH)
        love.graphics.setColor(0.9, 0.1, 0.1)
        love.graphics.rectangle("fill", barX, 20, barW * (bhp.hp / bhp.maxHp), barH)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", barX, 20, barW, barH)
    end

    -- End state
    love.graphics.setColor(1, 1, 1)
    if gameState == "win" and endTimer <= 0 then
        love.graphics.printf("YOU WIN", 0, 320, SCREEN_W, "center")
        love.graphics.printf("Press R to restart", 0, 350, SCREEN_W, "center")
    elseif gameState == "dead" and endTimer <= 0 then
        love.graphics.printf("DEAD", 0, 320, SCREEN_W, "center")
        love.graphics.printf("Press R to restart", 0, 350, SCREEN_W, "center")
    end

    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.print("Room: " .. currentRoom, 10, SCREEN_H - 20)

    love.graphics.pop()
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() end
    if key == "r" then love.load() end
    if key == "tab" then debugMode = not debugMode end
    if key == "f11" then love.window.setFullscreen(not love.window.getFullscreen()) end

    if gameState ~= "playing" then return end

    local p = W.player[playerId]
    local vel = W.vel[playerId]
    local phys = W.phys[playerId]
    if not p or not vel or not phys then return end

    if key == "up" or key == "w" or key == "space" then
        -- Jump
        if p.state ~= "dead" and p.state ~= "dash" and phys.onGround then
            vel.vy = -480
            phys.onGround = false
            p.jumpTimer = 0.15
        end
    end
    if key == "x" or key == "j" then
        -- Attack
        if p.state ~= "dead" and p.state ~= "dash" and p.attackCooldown <= 0 then
            p.attackTimer = 0.1
            p.attackCooldown = 0.41
            SFX.shortSwing:play()
        end
    end
    if key == "c" or key == "k" then
        -- Dash
        if p.state ~= "dead" and p.dashCooldown <= 0 then
            p.state = "dash"
            p.dashTimer = 0.17
            p.dashCooldown = 0.6
            p.dashDir = p.facing
            vel.vy = 0
            SFX.dash:play()
        end
    end
end

function love.mousepressed(x, y, button)
    if gameState ~= "playing" then return end
    local p = W.player[playerId]
    local vel = W.vel[playerId]
    if not p or not vel then return end
    if button == 1 then
        if p.state ~= "dead" and p.state ~= "dash" and p.attackCooldown <= 0 then
            p.attackTimer = 0.1
            p.attackCooldown = 0.41
            SFX.shortSwing:play()
        end
    elseif button == 2 then
        if p.state ~= "dead" and p.dashCooldown <= 0 then
            p.state = "dash"
            p.dashTimer = 0.17
            p.dashCooldown = 0.6
            p.dashDir = p.facing
            vel.vy = 0
            SFX.dash:play()
        end
    end
end
