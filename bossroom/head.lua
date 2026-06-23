-- head.lua: Detachable head that bounces off walls, ground, and the boss
local Combat = require("combat")
local Particles = require("components.particles")

local Head = {}

function Head.spawn(player)
    local h = {
        x = player.x + player.w / 2 - 12,
        y = player.y - 40,
        w = 24, h = 24,
        vx = player.facing * 150,
        vy = -100,
        onGround = false,
        particleTimer = 0,
        world = player.world,
        item = { type = "head", entity = nil },
    }
    h.item.entity = h
    h.world:add(h.item, h.x, h.y, h.w, h.h)
    return h
end

function Head.update(h, dt, boss)
    h.particleTimer = math.max(0, h.particleTimer - dt)
    h.vy = h.vy + 1200 * dt

    local goalX = h.x + h.vx * dt
    local goalY = h.y + h.vy * dt

    local actualX, actualY, cols, len = h.world:move(h.item, goalX, goalY, function(item, other)
        if other.type == "solid" or other.type == "boss" then return "slide" end
        return nil
    end)

    h.x, h.y = actualX, actualY
    h.onGround = false

    for i = 1, len do
        local col = cols[i]
        local nx, ny = col.normal.x, col.normal.y

        -- Bounce
        if nx ~= 0 then h.vx = -h.vx * 0.5 end
        if ny ~= 0 then
            h.vy = -h.vy * 0.5
            if ny == -1 then h.onGround = true end
        end

        -- Particles + shake (throttled, skip micro-bounces)
        if h.particleTimer <= 0 and math.abs(h.vy) > 50 then
            Particles.spawn(col.touch.x, col.touch.y, 6)
            Combat.shake(0.08)
            h.particleTimer = 0.15
        end
    end

    -- Ground damping
    if h.onGround then
        h.vx = h.vx * 0.9
        if math.abs(h.vy) < 50 then h.vy = 0 end
        if math.abs(h.vx) < 10 then h.vx = 0 end
    end
end

function Head.kick(h, dir)
    h.vx = dir * 400
    h.vy = -300
    Combat.shake(0.12)
    Particles.spawn(h.x + h.w / 2, h.y + h.h / 2, 10)
end

function Head.draw(h)
    love.graphics.setColor(1, 0.85, 0.65)
    love.graphics.circle("fill", h.x + h.w / 2, h.y + h.h / 2, h.w / 2)
    love.graphics.setColor(0.15, 0.12, 0.1)
    love.graphics.circle("line", h.x + h.w / 2, h.y + h.h / 2, h.w / 2)
    -- tiny face
    love.graphics.circle("fill", h.x + h.w / 2 - 4, h.y + h.h / 2 - 2, 2)
    love.graphics.circle("fill", h.x + h.w / 2 + 4, h.y + h.h / 2 - 2, 2)
end

function Head.remove(h)
    h.world:remove(h.item)
end

function Head.canReattach(h, player)
    local cx, cy = h.x + h.w / 2, h.y + h.h / 2
    local px, py = player.x + player.w / 2, player.y + player.h / 2
    local dx, dy = cx - px, cy - py
    return dx * dx + dy * dy < 65 * 65
end

return Head
