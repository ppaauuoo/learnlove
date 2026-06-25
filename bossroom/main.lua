-- main.lua: Hollow Knight Boss Room (hitbox prototype)
require("deps.lick")
local bump = require("deps.bump")
local Combat = require("combat")
local Player = require("player")
local Boss = require("boss")
local Head = require("head")
local Particles = require("components.particles")
local Camera = require("components.camera")
local Rooms = require("rooms")

local world, player, boss
local debugMode = false
local gameState = "playing" -- playing/win/dead
local endTimer = 0
local currentRoom = "hallway"
local bossActive = false
local kickCharge = 0
local kickCharging = false

local SCREEN_W, SCREEN_H = 800, 720  -- virtual resolution, scales to any window

function love.load()
    love.window.setMode(1280, 720, {fullscreen=false})
    love.window.setTitle("Boss Room")
    math.randomseed(os.time())

    -- Build the full world (hallway + boss room)
    world = Rooms.buildWorld()

    -- Spawn player in hallway
    local spawn = Rooms.list.hallway.playerSpawn
    player = Player(world, spawn.x, spawn.y)

    -- Stop all previous sounds if restarting
    if SFX then
        for _, s in pairs(SFX) do
            if s.stop then s:stop() end
        end
    end

    -- Load sounds
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

    -- Spawn boss in boss room (inactive until player enters)
    local bossSpawn = Rooms.list.boss.bossSpawn
    boss = Boss(world, bossSpawn.x, bossSpawn.y)
    bossActive = false

    -- Reset state
    Combat.freezeTimer = 0
    Combat.shakeTimer = 0
    Combat.shakeX = 0
    Combat.shakeY = 0
    Combat.slowShakeTimer = 0
    Combat.slowShakeIntensity = 0
    Combat._kickZoomActive = nil
    Particles.reset()
    Rooms.door.sealed = false
    gameState = "playing"
    endTimer = 0
    debugMode = false
    currentRoom = "hallway"
    kickCharge = 0
    kickCharging = false

    -- Camera starts on player
    Camera.reset()
    Camera.setBounds(Rooms.list.hallway)
    Camera.x = player.x - SCREEN_W / 2
    Camera.y = player.y - SCREEN_H / 2
end

function love.update(dt)
    dt = math.min(dt, 1 / 30)

    -- Camera always updates (transitions need to animate during freeze)
    if player then
        Camera.update(dt, player.x + player.w / 2, player.y + player.h / 2, SCREEN_W, SCREEN_H)
    end

    -- Hitstop freeze
    if Combat.freezeTimer > 0 then
        Combat.freezeTimer = Combat.freezeTimer - dt
        Combat.updateShake(dt)
        return
    end

    -- Restore camera zoom after kick freeze ends
    if Combat._kickZoomActive then
        local targetZoom = currentRoom == "boss" and 1 or 1.25
        Camera.startTransition(Camera.x, Camera.y, 0.2, targetZoom)
        Combat._kickZoomActive = nil
    end

    -- Charge timer: short delay before deciding hold vs tap
    if kickCharging then
        kickCharge = kickCharge + dt
        if kickCharge >= 0.08 then
            kickCharging = false
            if love.keyboard.isDown("h") and player.head then
                Combat._kickZoomActive = true
                local px = player.x + player.w / 2
                local py = player.y + player.h / 2
                Camera.startTransition(px - 400, py - 360, 0.3, 2)
                Head.kick(player.head, player.facing, true)
                player.kickCooldown = 1.5
            end
        end
    end

    if gameState == "playing" then
        -- Check room transitions
        local roomName, room = Rooms.getRoomAt(player.x + player.w / 2, player.y + player.h / 2)

        if roomName ~= currentRoom then
            -- Reattach head on room change
            if player.head then
                Head.remove(player.head)
                player.head = nil
            end
            currentRoom = roomName
            Camera.setBounds(room)
            Camera.zoom = roomName == "boss" and 1 or 1.25

            -- Fade out horror scream, switch BGM on entering boss room
            if roomName == "boss" then
                horrorFade = 1.5
                SFX.lowTempo:stop()
                SFX.highTempo:play()
                -- Slow pan to center of boss room (keeps camera under transition
                -- control so smooth follow can't fight it before entrance zooms in)
                Camera.startTransition(room.x + room.w / 2 - SCREEN_W / 2, room.y + room.h / 2 - SCREEN_H / 2, 10)
            end
        end

        -- Boss entrance triggers when player walks 25% into the room
        if roomName == "boss" and not bossActive then
            local triggerX = 1600 + 1440 * 0.25
            if player.x + player.w / 2 >= triggerX then
                bossActive = true
                boss:startEntrance()
                Rooms.sealDoor(world)
                -- Push player right of the door so bump doesn't shove them back
                if player.x + player.w > Rooms.door.x and player.x < Rooms.door.x + Rooms.door.w then
                    player.x = Rooms.door.x + Rooms.door.w
                    world:update(player.item, player.x, player.y)
                end
            end
        end

        -- Update entities
        if bossActive then
            player:update(dt, boss)
            boss:update(dt, player)
            -- Boss entrance camera signals
            if boss._requestZoom then
                boss._requestZoom = nil
                local bcx = boss.x + boss.w / 2
                local bcy = boss.y + boss.h / 2
                Camera.startTransition(bcx - SCREEN_W / 2, bcy - SCREEN_H / 2, 0.5, 1.5)
            end
            if boss._requestSnap then
                boss._requestSnap = nil
                Camera.transition.active = false
                Camera.transition.toZoom = nil
                Camera.zoom = 1
                local px = player.x + player.w / 2 - SCREEN_W / 2
                local py = player.y + player.h / 2 - SCREEN_H / 2
                Camera.x = px
                Camera.y = py
            end
        else
            player:update(dt, nil)
        end

        -- Detached head
        if player.head then
            Head.update(player.head, dt, boss)
            if player.head.dead then player.head = nil end
        end

        -- Win/lose check
        if bossActive and boss.hp <= 0 then
            gameState = "win"
            endTimer = 1.5
            Combat.spawnParticles(boss.x + boss.w / 2, boss.y + boss.h / 2, 20)
            Rooms.unsealDoor(world)
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

    -- Horror scream fade (when entering boss room)
    if horrorFade > 0 then
        horrorFade = horrorFade - dt
        SFX.horrorScream:setVolume(0.02 * math.max(0, horrorFade / 1.5))
    end

    Combat.updateParticles(dt)
    Combat.updateShake(dt)
end

function love.draw()
    love.graphics.push()
    Camera.apply(Combat.shakeX, Combat.shakeY)

    -- Draw hallway background
    love.graphics.setColor(0.06, 0.06, 0.09)
    love.graphics.rectangle("fill", 0, 0, Rooms.list.hallway.w, Rooms.list.hallway.h)

    -- Hallway light orb + tutorial (only in hallway)
    if currentRoom == "hallway" then
        local lx, ly = 400, 120
        for r = 1, 6 do
            local alpha = (7 - r) / 7 * 0.12
            love.graphics.setColor(1, 0.9, 0.6, alpha)
            love.graphics.circle("fill", lx, ly, r * 60)
        end
        love.graphics.setColor(1, 0.95, 0.8, 0.25)
        love.graphics.circle("fill", lx, ly, 20)

        -- Glowing tutorial text
        local tx, ty = 40, 500
        love.graphics.setFont(tutorialFont)
        local lines = {
            "MOVE:  Arrow Keys / WASD",
            "JUMP:  Up / W / Space",
            "ATTACK:  X / J / Left Click",
            "DASH:  C / K / Right Click",
        }
        for i, line in ipairs(lines) do
            -- Glow layers
            for g = 3, 1, -1 do
                love.graphics.setColor(1, 0.9, 0.5, 0.06 * g)
                love.graphics.print(line, tx - g, ty + (i - 1) * 20 - g)
                love.graphics.print(line, tx + g, ty + (i - 1) * 20 + g)
            end
            love.graphics.setColor(0.9, 0.85, 0.7, 0.7)
            love.graphics.print(line, tx, ty + (i - 1) * 20)
        end
    end

    -- Draw boss room background (slightly different shade)
    love.graphics.setColor(0.08, 0.08, 0.12)
    local br = Rooms.list.boss
    love.graphics.rectangle("fill", br.x, br.y, br.w, br.h)

    -- Draw all walls
    love.graphics.setColor(0.25, 0.25, 0.3)
    for _, room in pairs(Rooms.list) do
        for _, wall in ipairs(room.walls) do
            love.graphics.rectangle("fill", wall.x, wall.y, wall.w, wall.h)
        end
    end

    -- Draw passage frame
    for _, wall in ipairs(Rooms.passage) do
        love.graphics.rectangle("fill", wall.x, wall.y, wall.w, wall.h)
    end

    -- Draw sealed door
    if Rooms.door.sealed then
        love.graphics.setColor(0.5, 0.3, 0.1)
        love.graphics.rectangle("fill", Rooms.door.x, Rooms.door.y, Rooms.door.w, Rooms.door.h)
    end

    -- Entities
    if bossActive then
        boss:draw()
    end
    player:draw()
    if player.head then
        Head.draw(player.head)
    end

    -- Particles
    Combat.drawParticles()

    -- Debug overlay
    if debugMode then
        drawDebug()
    end

    love.graphics.pop()

    -- UI (screen-space, after camera pop)
    drawUI()
end

function drawUI()
    -- Scale UI to virtual resolution (uniform, centered)
    local scale = math.min(
        love.graphics.getWidth() / SCREEN_W,
        love.graphics.getHeight() / SCREEN_H
    )
    local ox = (love.graphics.getWidth() - SCREEN_W * scale) / 2
    local oy = (love.graphics.getHeight() - SCREEN_H * scale) / 2
    love.graphics.push()
    love.graphics.translate(ox, oy)
    love.graphics.scale(scale, scale)

    -- Player HP (masks)
    for i = 1, player.maxHp do
        if i <= player.hp then
            love.graphics.setColor(1, 1, 1)
        else
            love.graphics.setColor(0.3, 0.3, 0.3)
        end
        love.graphics.circle("fill", 30 + (i - 1) * 22, 40, 8)
    end

    -- Boss HP bar (top of screen, only during fight)
    if bossActive and boss.hp > 0 then
        local barW, barH = 400, 12
        local barX = (SCREEN_W - barW) / 2
        local barY = 20
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", barX, barY, barW, barH)
        love.graphics.setColor(0.9, 0.1, 0.1)
        local pct = boss.hp / boss.maxHp
        love.graphics.rectangle("fill", barX, barY, barW * pct, barH)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", barX, barY, barW, barH)
    end

    -- Screen flash on death/win (fades over the pause)
    if gameState ~= "playing" and endTimer > 0 then
        local alpha = endTimer / 1.5
        if gameState == "win" then
            love.graphics.setColor(1, 0.95, 0.7, alpha * 0.35)
        else
            love.graphics.setColor(0.8, 0.1, 0.1, alpha * 0.5)
        end
        love.graphics.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)
    end

    -- End state text
    love.graphics.setColor(1, 1, 1)
    if gameState == "win" and endTimer <= 0 then
        love.graphics.printf("YOU WIN", 0, 320, SCREEN_W, "center")
        love.graphics.printf("Press R to restart", 0, 350, SCREEN_W, "center")
    elseif gameState == "dead" and endTimer <= 0 then
        love.graphics.printf("DEAD", 0, 320, SCREEN_W, "center")
        love.graphics.printf("Press R to restart", 0, 350, SCREEN_W, "center")
    end

    -- Room indicator
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.print("Room: " .. currentRoom, 10, SCREEN_H - 20)

    -- FPS (debug)
    if debugMode then
        love.graphics.setColor(1, 1, 0)
        love.graphics.print("FPS: " .. love.timer.getFPS(), SCREEN_W - 80, 5)
    end

    love.graphics.pop()
end

function drawDebug()
    love.graphics.setColor(0, 1, 0, 0.4)
    love.graphics.rectangle("line", player.x, player.y, player.w, player.h)

    if player.attackTimer > 0 then
        love.graphics.setColor(0, 1, 1, 0.6)
        local hb = player:getNailHitbox()
        love.graphics.rectangle("line", hb.x, hb.y, hb.w, hb.h)
    end

    if bossActive then
        love.graphics.setColor(1, 0, 0, 0.4)
        love.graphics.rectangle("line", boss.x, boss.y, boss.w, boss.h)

        if boss.attackHitbox then
            love.graphics.setColor(1, 0.5, 0, 0.6)
            local hb = boss.attackHitbox
            love.graphics.rectangle("line", hb.x, hb.y, hb.w, hb.h)
        end

        -- State labels
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("B: " .. boss.state .. (boss.attackType and (" [" .. boss.attackType .. "]") or ""),
            boss.x, boss.y - 28)
        love.graphics.print("Phase: " .. boss.phase .. "  Hits: " .. boss.hitsTaken, boss.x, boss.y - 14)
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("P: " .. player.state, player.x, player.y - 14)

    -- Room bounds
    love.graphics.setColor(0, 1, 0, 0.2)
    for name, room in pairs(Rooms.list) do
        love.graphics.rectangle("line", room.x, room.y, room.w, room.h)
        love.graphics.print(name, room.x + 5, room.y + 25)
    end

    -- Door
    if Rooms.door.sealed then
        love.graphics.setColor(1, 0.5, 0, 0.5)
        love.graphics.rectangle("line", Rooms.door.x, Rooms.door.y, Rooms.door.w, Rooms.door.h)
    end
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() end
    if key == "r" then love.load() end
    if key == "tab" then debugMode = not debugMode end
    if key == "f11" then love.window.setFullscreen(not love.window.getFullscreen()) end

    if gameState ~= "playing" then return end

    if key == "up" or key == "w" or key == "space" then
        player:jump()
    end
    if key == "x" or key == "j" then
        player:attack()
    end
    if key == "c" or key == "k" then
        player:dash()
    end
    if key == "n" then
        player:toggleHead()
    end
    if key == "h" then
        if player.head and player.kickCooldown <= 0 and Head.canKick(player.head, player, 80) then
            kickCharging = true
            kickCharge = 0
        end
    end
end

function love.keyreleased(key)
    if key == "h" and kickCharging then
        kickCharging = false
        -- Released before next frame: quick tap, normal kick
        if player and player.head and player.kickCooldown <= 0 then
            Head.kick(player.head, player.facing, false)
            player.kickCooldown = 1.5
        end
    end
end

function love.mousepressed(x, y, button)
    if gameState ~= "playing" then return end
    if button == 1 then player:attack() end
    if button == 2 then player:dash() end
end
