-- main.lua: Boss Room using tiny-ecs
-- Entities are plain tables, systems filter by field presence
require("deps.lick")
local tiny = require("deps.tiny")
local bump = require("deps.bump")
local Combat = require("combat")
local Entities = require("entities")
local Rooms = require("rooms")
local Sprite = require("sprite")

-- Systems
local gravitySystem    = require("systems.gravity")
local movementSystem   = require("systems.movement")
local knockbackSystem  = require("systems.knockback")
local healthSystem     = require("systems.health")
local playerInputSystem = require("systems.player_input")
local bossAISystem     = require("systems.boss_ai")
local combatSystem     = require("systems.combat")
local Draw              = require("systems.draw")

-- Game state
local ecsWorld
local player, boss
local bumpWorld
local debugMode = false
local gameState = "playing"
local endTimer = 0
local currentRoom = "hallway"
local bossActive = false

local SCREEN_W, SCREEN_H = 800, 720

-- Camera (inline, same logic)
local Camera = {
    x = 0, y = 0,
    targetX = 0, targetY = 0,
    smoothSpeed = 8,
    zoom = 1.25,
    virtualW = 800, virtualH = 720,
    bounds = nil,
}

function Camera.reset()
    Camera.x, Camera.y = 0, 0
    Camera.bounds = nil
end

function Camera.setBounds(room) Camera.bounds = room end

function Camera.update(dt, fx, fy, sw, sh)
    local viewW = sw / Camera.zoom
    local viewH = sh / Camera.zoom
    Camera.targetX = fx - viewW / 2
    Camera.targetY = fy - viewH / 2

    if Camera.bounds then
        local b = Camera.bounds
        if b.w <= viewW then
            Camera.targetX = b.x + b.w / 2 - viewW / 2
        else
            Camera.targetX = math.max(b.x, math.min(Camera.targetX, b.x + b.w - viewW))
        end
        if b.h <= viewH then
            Camera.targetY = b.y + b.h / 2 - viewH / 2
        else
            Camera.targetY = math.max(b.y, math.min(Camera.targetY, b.y + b.h - viewH))
        end
    end
    Camera.x = Camera.x + (Camera.targetX - Camera.x) * Camera.smoothSpeed * dt
    Camera.y = Camera.y + (Camera.targetY - Camera.y) * Camera.smoothSpeed * dt
end

function Camera.apply(shakeX, shakeY)
    local scale = math.min(
        love.graphics.getWidth() / Camera.virtualW,
        love.graphics.getHeight() / Camera.virtualH
    )
    local ox = (love.graphics.getWidth() - Camera.virtualW * scale) / 2
    local oy = (love.graphics.getHeight() - Camera.virtualH * scale) / 2
    love.graphics.translate(ox, oy)
    love.graphics.scale(scale, scale)
    love.graphics.translate(
        math.floor(-Camera.x + (shakeX or 0)),
        math.floor(-Camera.y + (shakeY or 0))
    )
    if Camera.zoom ~= 1 then
        love.graphics.scale(Camera.zoom, Camera.zoom)
    end
end

-- ============================================================

function love.load()
    love.window.setMode(1280, 720, { fullscreen = false })
    love.window.setTitle("Boss Room (tiny-ecs)")
    math.randomseed(os.time())

    -- Build bump world
    bumpWorld = Rooms.buildWorld()

    -- Spawn entities
    player = Entities.makePlayer(bumpWorld, Rooms.list.hallway.playerSpawn.x, Rooms.list.hallway.playerSpawn.y)
    boss = Entities.makeBoss(bumpWorld, Rooms.list.boss.bossSpawn.x, Rooms.list.boss.bossSpawn.y)

    -- Wire system references
    bossAISystem.player = player
    bossAISystem.active = false
    combatSystem.player = player
    combatSystem.boss = boss
    combatSystem.active = false

    -- Create tiny-ecs world with systems in execution order
    ecsWorld = tiny.world(
        healthSystem,
        knockbackSystem,
        playerInputSystem,
        bossAISystem,
        gravitySystem,
        movementSystem,
        combatSystem
    )

    -- Add entities
    ecsWorld:add(player, boss)

    -- Sound
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

    -- Reset state
    Combat.freezeTimer = 0
    Combat.shakeTimer = 0
    Combat.shakeX = 0
    Combat.shakeY = 0
    Combat.resetParticles()
    Rooms.door.sealed = false
    gameState = "playing"
    endTimer = 0
    debugMode = false
    currentRoom = "hallway"
    bossActive = false

    Camera.reset()
    Camera.setBounds(Rooms.list.hallway)
    Camera.x = player.x - SCREEN_W / 2
    Camera.y = player.y - SCREEN_H / 2
end

function love.update(dt)
    dt = math.min(dt, 1 / 30)

    -- Hitstop freeze
    if Combat.freezeTimer > 0 then
        Combat.freezeTimer = Combat.freezeTimer - dt
        Combat.updateShake(dt)
        return
    end

    if gameState == "playing" then
        -- Room transition
        local roomName, room = Rooms.getRoomAt(player.x + player.w / 2, player.y + player.h / 2)
        if roomName ~= currentRoom then
            currentRoom = roomName
            Camera.setBounds(room)
            Camera.zoom = roomName == "boss" and 1 or 1.25

            if roomName == "boss" and not bossActive then
                bossActive = true
                bossAISystem.active = true
                combatSystem.active = true
                Rooms.sealDoor(bumpWorld)
                if player.x + player.w > Rooms.door.x and player.x < Rooms.door.x + Rooms.door.w then
                    player.x = Rooms.door.x + Rooms.door.w
                    bumpWorld:update(player.physics.item, player.x, player.y)
                end
                horrorFade = 1.5
                SFX.lowTempo:stop()
                SFX.highTempo:play()
            end
        end

        -- Run all ECS systems
        ecsWorld:update(dt)

        -- Win/lose check
        if bossActive and boss.hp <= 0 then
            gameState = "win"
            endTimer = 1.5
            Combat.spawnParticles(boss.x + boss.w / 2, boss.y + boss.h / 2, 20)
            Rooms.unsealDoor(bumpWorld)
        elseif player.hp <= 0 then
            gameState = "dead"
            endTimer = 1.5
            player.state = "dead"
            Combat.spawnParticles(player.x + player.w / 2, player.y + player.h / 2, 20)
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
    Camera.update(dt, player.x + player.w / 2, player.y + player.h / 2, SCREEN_W, SCREEN_H)
    Combat.updateParticles(dt)
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
            for g = 3, 1, -1 do
                love.graphics.setColor(1, 0.9, 0.5, 0.06 * g)
                love.graphics.print(line, 40 - g, 500 + (i - 1) * 20 - g)
                love.graphics.print(line, 40 + g, 500 + (i - 1) * 20 + g)
            end
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

    -- Draw entities via draw system (called during world:update in update phase)
    -- Actually, tiny-ecs calls process during update. We need to draw here instead.
    -- We'll manually invoke the draw system
    love.graphics.setColor(1, 1, 1)
    if bossActive then
        Draw:drawBoss(boss)
    end
    Draw:drawPlayer(player)

    -- Particles
    Combat.drawParticles()

    -- Debug
    if debugMode then
        love.graphics.setColor(0, 1, 0, 0.4)
        love.graphics.rectangle("line", player.x, player.y, player.w, player.h)
        if player.attackTimer > 0 then
            love.graphics.setColor(0, 1, 1, 0.6)
            local ox = player.facing == 1 and player.w or -48
            love.graphics.rectangle("line", player.x + ox, player.y + (player.h - 36) / 2, 48, 36)
        end
        if bossActive then
            love.graphics.setColor(1, 0, 0, 0.4)
            love.graphics.rectangle("line", boss.x, boss.y, boss.w, boss.h)
            if boss.attackHitbox then
                love.graphics.setColor(1, 0.5, 0, 0.6)
                local hb = boss.attackHitbox
                love.graphics.rectangle("line", hb.x, hb.y, hb.w, hb.h)
            end
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("B: " .. boss.bossState .. (boss.attackType and (" [" .. boss.attackType .. "]") or ""), boss.x, boss.y - 28)
            love.graphics.print("Phase: " .. boss.phase .. "  Hits: " .. boss.hitsTaken, boss.x, boss.y - 14)
        end
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("P: " .. player.state, player.x, player.y - 14)

        love.graphics.setColor(0, 1, 0, 0.2)
        for name, room in pairs(Rooms.list) do
            love.graphics.rectangle("line", room.x, room.y, room.w, room.h)
            love.graphics.print(name, room.x + 5, room.y + 25)
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
    for i = 1, player.maxHp do
        love.graphics.setColor(i <= player.hp and {1,1,1} or {0.3,0.3,0.3})
        love.graphics.circle("fill", 30 + (i - 1) * 22, 40, 8)
    end

    -- Boss HP bar
    if bossActive and boss.hp > 0 then
        local barW, barH = 400, 12
        local barX = (SCREEN_W - barW) / 2
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", barX, 20, barW, barH)
        love.graphics.setColor(0.9, 0.1, 0.1)
        love.graphics.rectangle("fill", barX, 20, barW * (boss.hp / boss.maxHp), barH)
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

    if debugMode then
        love.graphics.setColor(1, 1, 0)
        love.graphics.print("FPS: " .. love.timer.getFPS(), SCREEN_W - 80, 5)
    end

    love.graphics.pop()
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() end
    if key == "r" then love.load() end
    if key == "tab" then debugMode = not debugMode end
    if key == "f11" then love.window.setFullscreen(not love.window.getFullscreen()) end

    if gameState ~= "playing" then return end

    if key == "up" or key == "w" or key == "space" then
        if player.state ~= "dead" and player.state ~= "dash" and player.physics.onGround then
            player.vy = -480
            player.physics.onGround = false
            player.jumpTimer = 0.15
        end
    end
    if key == "x" or key == "j" then
        if player.state ~= "dead" and player.state ~= "dash" and player.attackCooldown <= 0 then
            player.attackTimer = 0.1
            player.attackCooldown = 0.41
            SFX.shortSwing:play()
        end
    end
    if key == "c" or key == "k" then
        if player.state ~= "dead" and player.dashCooldown <= 0 then
            player.state = "dash"
            player.dashTimer = 0.17
            player.dashCooldown = 0.6
            player.dashDir = player.facing
            player.vy = 0
            SFX.dash:play()
        end
    end
end

function love.mousepressed(x, y, button)
    if gameState ~= "playing" then return end
    if button == 1 then
        if player.state ~= "dead" and player.state ~= "dash" and player.attackCooldown <= 0 then
            player.attackTimer = 0.1
            player.attackCooldown = 0.41
            SFX.shortSwing:play()
        end
    elseif button == 2 then
        if player.state ~= "dead" and player.dashCooldown <= 0 then
            player.state = "dash"
            player.dashTimer = 0.17
            player.dashCooldown = 0.6
            player.dashDir = player.facing
            player.vy = 0
            SFX.dash:play()
        end
    end
end
