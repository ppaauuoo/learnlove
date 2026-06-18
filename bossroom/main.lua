-- main.lua: Hollow Knight Boss Room (hitbox prototype)
-- Fix require path so deps/ from parent directory is accessible
local srcDir = love.filesystem.getSource()
package.path = srcDir .. "/../deps/?.lua;" .. srcDir .. "/../deps/?/init.lua;" .. srcDir .. "/?.lua;" .. package.path

local bump = require("bump")
local Combat = require("combat")
local Entities = require("entities")
local Particles = require("components.particles")

local world, player, boss
local debugMode = false
local gameState = "playing" -- playing/win/dead
local endTimer = 0

function love.load()
    love.window.setMode(800, 720)
    love.window.setTitle("Boss Room")
    math.randomseed(os.time())

    world = bump.newWorld(32)

    -- Arena walls (solid)
    local walls = {
        { x = 0,   y = 680, w = 800, h = 40 },  -- floor
        { x = 0,   y = 0,   w = 800, h = 20 },  -- ceiling
        { x = 0,   y = 0,   w = 20,  h = 720 }, -- left wall
        { x = 780, y = 0,   w = 20,  h = 720 }, -- right wall
    }
    for _, wall in ipairs(walls) do
        wall.type = "solid"
        world:add(wall, wall.x, wall.y, wall.w, wall.h)
    end

    player = Entities.Player(world, 100, 600)
    boss = Entities.Boss(world, 600, 580)

    -- Reset combat state
    Combat.freezeTimer = 0
    Combat.shakeTimer = 0
    Combat.shakeX = 0
    Combat.shakeY = 0
    Particles.reset()
    gameState = "playing"
    endTimer = 0
    debugMode = false
end

function love.update(dt)
    dt = math.min(dt, 1 / 30) -- cap dt

    -- Hitstop freeze
    if Combat.freezeTimer > 0 then
        Combat.freezeTimer = Combat.freezeTimer - dt
        Combat.updateShake(dt)
        return
    end

    if gameState == "playing" then
        player:update(dt, boss)
        boss:update(dt, player)

        -- Win/lose check
        if boss.hp <= 0 then
            gameState = "win"
            endTimer = 1.5
            Combat.spawnParticles(boss.x + boss.w / 2, boss.y + boss.h / 2, 20)
        elseif player.hp <= 0 then
            gameState = "dead"
            endTimer = 1.5
            player.state = "dead"
            Combat.spawnParticles(player.x + player.w / 2, player.y + player.h / 2, 20)
        end
    else
        endTimer = endTimer - dt
    end

    Combat.updateParticles(dt)
    Combat.updateShake(dt)
end

function love.draw()
    love.graphics.push()
    love.graphics.translate(Combat.shakeX, Combat.shakeY)

    -- Arena background
    love.graphics.setColor(0.08, 0.08, 0.12)
    love.graphics.rectangle("fill", 0, 0, 800, 720)

    -- Arena walls
    love.graphics.setColor(0.25, 0.25, 0.3)
    love.graphics.rectangle("fill", 0, 680, 800, 40)
    love.graphics.rectangle("fill", 0, 0, 800, 20)
    love.graphics.rectangle("fill", 0, 0, 20, 720)
    love.graphics.rectangle("fill", 780, 0, 20, 720)

    -- Entities
    boss:draw()
    player:draw()

    -- Particles
    Combat.drawParticles()

    -- Player HP (masks)
    for i = 1, player.maxHp do
        if i <= player.hp then
            love.graphics.setColor(1, 1, 1)
        else
            love.graphics.setColor(0.3, 0.3, 0.3)
        end
        love.graphics.circle("fill", 30 + (i - 1) * 22, 40, 8)
    end

    -- End state text
    love.graphics.setColor(1, 1, 1)
    if gameState == "win" and endTimer <= 0 then
        love.graphics.printf("YOU WIN", 0, 320, 800, "center")
        love.graphics.printf("Press R to restart", 0, 350, 800, "center")
    elseif gameState == "dead" and endTimer <= 0 then
        love.graphics.printf("DEAD", 0, 320, 800, "center")
        love.graphics.printf("Press R to restart", 0, 350, 800, "center")
    end

    -- Debug overlay
    if debugMode then
        drawDebug()
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

    love.graphics.setColor(1, 0, 0, 0.4)
    love.graphics.rectangle("line", boss.x, boss.y, boss.w, boss.h)

    if boss.attackHitbox then
        love.graphics.setColor(1, 0.5, 0, 0.6)
        local hb = boss.attackHitbox
        love.graphics.rectangle("line", hb.x, hb.y, hb.w, hb.h)
    end

    -- State labels
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("P: " .. player.state, player.x, player.y - 14)
    love.graphics.print("B: " .. boss.state .. (boss.attackType and (" [" .. boss.attackType .. "]") or ""),
        boss.x, boss.y - 28)
    love.graphics.print("Phase: " .. boss.phase .. "  Hits: " .. boss.hitsTaken, boss.x, boss.y - 14)

    -- FPS
    love.graphics.setColor(1, 1, 0)
    love.graphics.print("FPS: " .. love.timer.getFPS(), 700, 5)
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
