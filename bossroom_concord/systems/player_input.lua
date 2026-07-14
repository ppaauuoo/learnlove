-- systems/player_input.lua: read keyboard, drive player component
local Concord = require("deps.concord")

local PlayerInputSystem = Concord.system({ pool = {"playerInput", "position", "velocity", "physics", "health", "knockback"} })

function PlayerInputSystem:update(dt)
    for _, e in ipairs(self.pool) do
        local p = e.playerInput
        local pos = e.position
        local vel = e.velocity
        local phys = e.physics
        local hp = e.health
        local kb = e.knockback

        if p.state == "dead" then goto continue end

        -- Cooldown ticks
        p.attackCooldown = math.max(0, p.attackCooldown - dt)
        p.dashCooldown = math.max(0, p.dashCooldown - dt)

        -- If in knockback, skip normal input
        if kb.timer > 0 then goto continue end

        -- Dash state
        if p.state == "dash" then
            p.dashTimer = p.dashTimer - dt
            if p.dashTimer <= 0 then
                p.state = "fall"
                vel.vx = 0
            else
                vel.vx = p.dashDir * (150 / 0.17)
                vel.vy = 0
                hp.iframes = 0.05
            end
            goto continue
        end

        -- Horizontal movement
        vel.vx = 0
        if love.keyboard.isDown("left", "a") then
            vel.vx = -250
            p.facing = -1
        elseif love.keyboard.isDown("right", "d") then
            vel.vx = 250
            p.facing = 1
        end

        -- Variable jump
        if p.jumpTimer > 0 then
            p.jumpTimer = p.jumpTimer - dt
            if not love.keyboard.isDown("up", "w", "space") then
                p.jumpTimer = 0
                if vel.vy < 0 then vel.vy = vel.vy * 0.5 end
            end
        end

        -- Attack timer
        if p.attackTimer > 0 then
            p.attackTimer = p.attackTimer - dt
        end

        -- State label
        if p.attackTimer > 0 then
            p.state = "attack"
        elseif phys.onGround then
            p.state = vel.vx ~= 0 and "run" or "idle"
        else
            p.state = vel.vy < 0 and "jump" or "fall"
        end

        -- Animation
        if p.state == "run" or p.state == "attack" then
            p.animTimer = p.animTimer + dt
        end

        ::continue::
    end
end

return PlayerInputSystem
