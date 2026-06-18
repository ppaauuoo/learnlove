-- main.lua: Hollow Knight Boss Room (hitbox prototype)
-- Fix require path so deps/ from parent directory is accessible
local srcDir = love.filesystem.getSource()
package.path = srcDir .. "/../deps/?.lua;" .. srcDir .. "/../deps/?/init.lua;" .. srcDir .. "/?.lua;" .. package.path

require("lick")
local bump = require("bump")
local Combat = require("combat")
local Entities = require("entities")
local Particles = require("components.particles")
local Camera = require("components.camera")
local Rooms = require("rooms")

local world, player, boss
local debugMode = false
local gameState = "playing" -- playing/win/dead
local endTimer = 0
local currentRoom = "hallway"
local bossActive = false

local SCREEN_W, SCREEN_H = 800, 720

function love.load()
    love.window.setMode(SCREEN_W, SCREEN_H)
    love.window.setTitle("Boss Room")
    math.randomseed(os.time())

    -- Build the full world (hallway + boss room)
    world = Rooms.buildWorld()

    -- Spawn player in hallway
    local spawn = Rooms.list.hallway.playerSpawn
    player = Entities.Player(world, spawn.x, spawn.y)

    -- Spawn boss in boss room (inactive until player enters)
    local bossSpawn = Rooms.list.boss.bossSpawn
    boss = Entities.Boss(world, bossSpawn.x, bossSpawn.y)
    bossActive = false

    -- Reset state
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

    -- Camera starts on player
    Camera.reset()
    Camera.setBounds(Rooms.list.hallway)
    Camera.x = player.x - love.graphics.getWidth() / 2
    Camera.y = player.y - love.graphics.getHeight() / 2
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
        -- Check room transitions
        local roomName, room = Rooms.getRoomAt(player.x + player.w / 2, player.y + player.h / 2)

        if roomName ~= currentRoom then
            currentRoom = roomName
            Camera.setBounds(room)

            -- Entering boss room: activate boss, seal door
            if roomName == "boss" and not bossActive then
                bossActive = true
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
        else
            player:update(dt, nil)
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
        end
    else
        endTimer = endTimer - dt
    end

    -- Camera follows player center
    Camera.update(dt, player.x + player.w / 2, player.y + player.h / 2, love.graphics.getWidth(), love.graphics.getHeight())

    Combat.updateParticles(dt)
    Combat.updateShake(dt)
end

function love.draw()
    love.graphics.push()
    Camera.apply(Combat.shakeX, Combat.shakeY)

    -- Draw hallway background
    love.graphics.setColor(0.06, 0.06, 0.09)
    love.graphics.rectangle("fill", 0, 0, Rooms.list.hallway.w, Rooms.list.hallway.h)

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
        local barX = (love.graphics.getWidth() - barW) / 2
        local barY = 20
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", barX, barY, barW, barH)
        love.graphics.setColor(0.9, 0.1, 0.1)
        local pct = boss.hp / boss.maxHp
        love.graphics.rectangle("fill", barX, barY, barW * pct, barH)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", barX, barY, barW, barH)
    end

    -- End state text
    love.graphics.setColor(1, 1, 1)
    if gameState == "win" and endTimer <= 0 then
        love.graphics.printf("YOU WIN", 0, 320, love.graphics.getWidth(), "center")
        love.graphics.printf("Press R to restart", 0, 350, love.graphics.getWidth(), "center")
    elseif gameState == "dead" and endTimer <= 0 then
        love.graphics.printf("DEAD", 0, 320, love.graphics.getWidth(), "center")
        love.graphics.printf("Press R to restart", 0, 350, love.graphics.getWidth(), "center")
    end

    -- Room indicator
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.print("Room: " .. currentRoom, 10, love.graphics.getHeight() - 20)

    -- FPS (debug)
    if debugMode then
        love.graphics.setColor(1, 1, 0)
        love.graphics.print("FPS: " .. love.timer.getFPS(), love.graphics.getWidth() - 80, 5)
    end
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
end
