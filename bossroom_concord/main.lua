-- main.lua: Boss Room (Concord ECS version)
require("deps.lick")
local Concord = require("deps.concord")
require("components") -- registers all component definitions

local Rooms = require("rooms")
local Combat = require("combat")
local Particles = require("particles")
local Camera = require("camera")
local Assemblages = require("assemblages")

-- Systems
local GravitySystem     = require("systems.gravity")
local MovementSystem    = require("systems.movement")
local KnockbackSystem   = require("systems.knockback")
local HealthSystem      = require("systems.health")
local PlayerInputSystem = require("systems.player_input")
local BossAISystem      = require("systems.boss_ai")
local CombatSystem      = require("systems.combat")
local DrawSystem        = require("systems.draw")

local ecsWorld      -- Concord world
local bumpWorld     -- bump collision world
local playerEntity, bossEntity

local debugMode = false
local gameState = "playing"
local endTimer = 0
local currentRoom = "hallway"
local bossActive = false
local SCREEN_W, SCREEN_H = 800, 720

function love.load()
    love.window.setMode(1280, 720, { fullscreen = false })
    love.window.setTitle("Boss Room (Concord ECS)")
    math.randomseed(os.time())

    -- Build bump collision world
    bumpWorld = Rooms.buildWorld()

    -- Create ECS world and add systems (order matters for update)
    ecsWorld = Concord.world()
    ecsWorld:addSystems(
        HealthSystem,
        KnockbackSystem,
        PlayerInputSystem,
        BossAISystem,
        GravitySystem,
        MovementSystem,
        CombatSystem,
        DrawSystem
    )

    -- Spawn player
    local spawn = Rooms.list.hallway.playerSpawn
    playerEntity = Concord.entity(ecsWorld)
    playerEntity:assemble(Assemblages.player, bumpWorld, spawn.x, spawn.y)

    -- Spawn boss
    local bossSpawn = Rooms.list.boss.bossSpawn
    bossEntity = Concord.entity(ecsWorld)
    bossEntity:assemble(Assemblages.boss, bumpWorld, bossSpawn.x, bossSpawn.y)
    bossActive = false

    -- Disable boss systems until player enters boss room
    ecsWorld:getSystem(BossAISystem):setEnabled(false)
    ecsWorld:getSystem(CombatSystem):setEnabled(false)

    -- Sound setup
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
    local pp = playerEntity.position
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
        local pp = playerEntity.position

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
                    bumpWorld:update(playerEntity.physics.item, pp.x, pp.y)
                end
                horrorFade = 1.5
                SFX.lowTempo:stop()
                SFX.highTempo:play()

                -- Enable boss systems
                ecsWorld:getSystem(BossAISystem):setEnabled(true)
                ecsWorld:getSystem(CombatSystem):setEnabled(true)
            end
        end

        -- Run all ECS systems
        ecsWorld:emit("update", dt)

        -- Win/lose
        local bhp = bossEntity.health
        local php = playerEntity.health
        local pi = playerEntity.playerInput
        if bossActive and bhp.hp <= 0 then
            gameState = "win"
            endTimer = 1.5
            local bp = bossEntity.position
            Particles.spawn(bp.x + bp.w / 2, bp.y + bp.h / 2, 20)
            Rooms.unsealDoor(bumpWorld)
        elseif php.hp <= 0 then
            gameState = "dead"
            endTimer = 1.5
            pi.state = "dead"
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
    local pp = playerEntity.position
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

    -- Tutorial
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

    -- ECS draw system
    ecsWorld:emit("draw")

    Particles.draw()

    -- Debug
    if debugMode then
        love.graphics.setColor(0, 1, 0, 0.4)
        local pp = playerEntity.position
        love.graphics.rectangle("line", pp.x, pp.y, pp.w, pp.h)
        if bossActive then
            love.graphics.setColor(1, 0, 0, 0.4)
            local bp = bossEntity.position
            love.graphics.rectangle("line", bp.x, bp.y, bp.w, bp.h)
            local b = bossEntity.bossAI
            love.graphics.setColor(1, 1, 1)
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
    local php = playerEntity.health
    for i = 1, php.maxHp do
        love.graphics.setColor(i <= php.hp and {1,1,1} or {0.3,0.3,0.3})
        love.graphics.circle("fill", 30 + (i - 1) * 22, 40, 8)
    end

    -- Boss HP bar
    local bhp = bossEntity.health
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

    local p = playerEntity.playerInput
    local vel = playerEntity.velocity
    local phys = playerEntity.physics

    if key == "up" or key == "w" or key == "space" then
        if p.state ~= "dead" and p.state ~= "dash" and phys.onGround then
            vel.vy = -480
            phys.onGround = false
            p.jumpTimer = 0.15
        end
    end
    if key == "x" or key == "j" then
        if p.state ~= "dead" and p.state ~= "dash" and p.attackCooldown <= 0 then
            p.attackTimer = 0.1
            p.attackCooldown = 0.41
            SFX.shortSwing:play()
        end
    end
    if key == "c" or key == "k" then
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
    local p = playerEntity.playerInput
    local vel = playerEntity.velocity
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
