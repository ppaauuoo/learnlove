-- combat.lua: damage resolution, knockback, i-frames, effects
local Combat = {}

-- Global game-feel state (shared via require)
Combat.freezeTimer = 0
Combat.shakeTimer = 0
Combat.shakeX = 0
Combat.shakeY = 0
Combat.particles = {}

function Combat.resolveDamage(source, target, game)
    if target.iframes > 0 then return false end
    if target.hp <= 0 then return false end

    target.hp = target.hp - 1
    target.flashTimer = 0.05

    -- I-frames
    if target.isPlayer then
        target.iframes = 1.0
    else
        target.iframes = 0.1
    end

    -- Knockback direction: away from source
    local dir = 1
    if source.x + source.w / 2 > target.x + target.w / 2 then dir = -1 end
    target.knockback = { vx = dir * 300, vy = -80, timer = 0.1 }

    -- Game feel
    Combat.freezeTimer = 0.04
    Combat.shakeTimer = 0.1

    -- Particles at hit point
    local cx = target.x + target.w / 2
    local cy = target.y + target.h / 2
    Combat.spawnParticles(cx, cy, 10)

    -- Track hits for stagger
    if target.hitsTaken then
        target.hitsTaken = target.hitsTaken + 1
    end

    return true
end

function Combat.spawnParticles(x, y, count)
    for i = 1, count do
        table.insert(Combat.particles, {
            x = x, y = y,
            vx = (math.random() - 0.5) * 400,
            vy = (math.random() - 0.5) * 300 - 100,
            life = 0.3
        })
    end
end

function Combat.updateParticles(dt)
    for i = #Combat.particles, 1, -1 do
        local p = Combat.particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + 600 * dt -- gravity
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(Combat.particles, i)
        end
    end
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

function Combat.drawParticles()
    love.graphics.setColor(1, 1, 1)
    for _, p in ipairs(Combat.particles) do
        local a = p.life / 0.3
        love.graphics.setColor(1, 1, 1, a)
        love.graphics.rectangle("fill", p.x - 1.5, p.y - 1.5, 3, 3)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return Combat
