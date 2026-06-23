-- combat.lua: damage resolution, hitstop, screen shake
-- Uses reusable components for health, knockback, particles
local Knockback = require("components.knockback")
local Health = require("components.health")
local Particles = require("components.particles")

local Combat = {}

-- Game-feel state
Combat.freezeTimer = 0
Combat.shakeTimer = 0
Combat.shakeX = 0
Combat.shakeY = 0
Combat.slowShakeTimer = 0
Combat.slowShakeIntensity = 0

function Combat.shake(duration, intensity)
    Combat.shakeTimer = duration or 0.1
end

function Combat.slowShake(duration, intensity)
    Combat.slowShakeTimer = duration or 0.5
    Combat.slowShakeIntensity = intensity or 8
end

function Combat.resolveDamage(source, target, game)
    if not Health.canTakeDamage(target) then return false end

    -- Apply damage
    local iframeDuration = target.isPlayer and 1.0 or 0.1
    Health.takeDamage(target, 1, iframeDuration)

    -- Knockback direction: away from source
    local dir = 1
    if source.x + source.w / 2 > target.x + target.w / 2 then dir = -1 end
    Knockback.apply(target, dir * 300, -80, 0.1)

    -- Game feel
    Combat.freezeTimer = 0.04
    Combat.shakeTimer = 0.1

    -- Particles at hit point
    local cx = target.x + target.w / 2
    local cy = target.y + target.h / 2
    Particles.spawn(cx, cy, 10)

    -- Track hits for stagger
    if target.hitsTaken then
        target.hitsTaken = target.hitsTaken + 1
    end

    return true
end

function Combat.updateShake(dt)
    if Combat.slowShakeTimer > 0 then
        Combat.slowShakeTimer = Combat.slowShakeTimer - dt
        local t = love.timer.getTime()
        Combat.shakeX = math.sin(t * 10) * Combat.slowShakeIntensity
        Combat.shakeY = math.cos(t * 8) * Combat.slowShakeIntensity * 0.6
    elseif Combat.shakeTimer > 0 then
        Combat.shakeTimer = Combat.shakeTimer - dt
        Combat.shakeX = math.random(-3, 3)
        Combat.shakeY = math.random(-3, 3)
    else
        Combat.shakeX = 0
        Combat.shakeY = 0
    end
end

-- Re-export particles for convenience
Combat.spawnParticles = Particles.spawn
Combat.updateParticles = Particles.update
Combat.drawParticles = Particles.draw

return Combat
