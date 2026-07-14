-- systems/player_input.lua: read keyboard, drive player entity
local tiny = require("deps.tiny")

local playerInputSystem = tiny.processingSystem()
playerInputSystem.filter = tiny.requireAll("isPlayer", "vx", "vy", "physics")

function playerInputSystem:process(e, dt)
    if e.state == "dead" then return end

    -- Cooldown ticks
    e.attackCooldown = math.max(0, e.attackCooldown - dt)
    e.dashCooldown = math.max(0, e.dashCooldown - dt)

    -- If in knockback, skip input (movement system handles motion)
    if e._inKnockback then return end

    -- Dash state
    if e.state == "dash" then
        e.dashTimer = e.dashTimer - dt
        if e.dashTimer <= 0 then
            e.state = "fall"
            e.vx = 0
        else
            e.vx = e.dashDir * (150 / 0.17)
            e.vy = 0
            e.iframes = 0.05
        end
        return
    end

    -- Horizontal movement
    e.vx = 0
    if love.keyboard.isDown("left", "a") then
        e.vx = -250
        e.facing = -1
    elseif love.keyboard.isDown("right", "d") then
        e.vx = 250
        e.facing = 1
    end

    -- Variable jump: cut short if key released
    if e.jumpTimer > 0 then
        e.jumpTimer = e.jumpTimer - dt
        if not love.keyboard.isDown("up", "w", "space") then
            e.jumpTimer = 0
            if e.vy < 0 then e.vy = e.vy * 0.5 end
        end
    end

    -- Attack timer
    if e.attackTimer > 0 then
        e.attackTimer = e.attackTimer - dt
    end

    -- State label
    if e.attackTimer > 0 then
        e.state = "attack"
    elseif e.physics.onGround then
        e.state = e.vx ~= 0 and "run" or "idle"
    else
        e.state = e.vy < 0 and "jump" or "fall"
    end

    -- Animation
    if e.state == "run" or e.state == "attack" then
        e.animTimer = e.animTimer + dt
    end
end

return playerInputSystem
