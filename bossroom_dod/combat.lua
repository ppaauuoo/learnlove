-- combat.lua: damage resolution + game-feel (hitstop, shake, particles)
local Particles = require("particles")

local Combat = {}

Combat.freezeTimer = 0
Combat.shakeTimer = 0
Combat.shakeX = 0
Combat.shakeY = 0

function Combat.shake(duration)
    Combat.shakeTimer = duration or 0.1
end

-- DOD version: takes component tables directly instead of OOP objects
function Combat.resolveDamage(sourcePos, targetPos, targetHealth, targetKB, targetBoss)
    if targetHealth.iframes > 0 or targetHealth.hp <= 0 then return false end

    -- Damage
    local isPlayer = (targetBoss == nil)  -- if no boss component, it's the player
    local iframeDuration = isPlayer and 1.0 or 0.1
    targetHealth.hp = targetHealth.hp - 1
    targetHealth.iframes = iframeDuration
    targetHealth.flashTimer = 0.05

    -- Knockback direction
    if targetKB then
        local dir = 1
        if sourcePos.x + (sourcePos.w or 0) / 2 > targetPos.x + targetPos.w / 2 then dir = -1 end
        targetKB.vx = dir * 300
        targetKB.vy = -80
        targetKB.timer = 0.1
    end

    -- Game feel
    Combat.freezeTimer = 0.04
    Combat.shakeTimer = 0.1

    -- Particles
    Particles.spawn(targetPos.x + targetPos.w / 2, targetPos.y + targetPos.h / 2, 10)

    -- Track hits for stagger
    if targetBoss then
        targetBoss.hitsTaken = targetBoss.hitsTaken + 1
    end

    return true
end

function Combat.updateShake(dt)
    if Combat.shakeTimer > 0 then
        Combat.shakeTimer = Combat.shakeTimer - dt
        Combat.shakeX = math.random(-3, 3)
        Combat.shakeY = math.random(-3, 3)
    else
        Combat.shakeX = 0
        Combat.shakeY = 0
    end
end

return Combat
