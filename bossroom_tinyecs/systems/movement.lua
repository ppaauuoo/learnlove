-- systems/movement.lua: move entities via bump collision
local tiny = require("deps.tiny")

local movementSystem = tiny.processingSystem()
movementSystem.filter = tiny.requireAll("x", "y", "vx", "vy", "physics")

local function defaultFilter(item, other)
    if other.type == "solid" then return "slide" end
    return nil
end

function movementSystem:process(e, dt)
    local phys = e.physics

    -- Boss invisible = raw move (no collision)
    if e.isBoss and not e.visible then
        e.x = e.x + e.vx * dt
        e.y = e.y + e.vy * dt
        phys.bumpWorld:update(phys.item, e.x, e.y)
        return
    end

    local goalX = e.x + e.vx * dt
    local goalY = e.y + e.vy * dt

    local actualX, actualY, cols, len = phys.bumpWorld:move(
        phys.item, goalX, goalY, defaultFilter
    )

    e.x = actualX
    e.y = actualY
    phys.onGround = false

    for i = 1, len do
        local col = cols[i]
        if col.normal.y == -1 then
            phys.onGround = true
            e.vy = 0
        elseif col.normal.y == 1 then
            e.vy = 0
        end
        if col.normal.x ~= 0 then
            e.vx = 0
        end
    end
end

return movementSystem
