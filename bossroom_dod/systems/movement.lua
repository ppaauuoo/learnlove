-- systems/movement.lua: move entities via bump collision
local W = require("world")

local function defaultFilter(item, other)
    if other.type == "solid" then return "slide" end
    return nil
end

return function(dt)
    for id, phys in pairs(W.phys) do
        local pos = W.pos[id]
        local vel = W.vel[id]
        if not pos or not vel then goto continue end

        -- Boss invisible = raw move (no collision)
        local b = W.boss[id]
        if b and not b.visible then
            pos.x = pos.x + vel.vx * dt
            pos.y = pos.y + vel.vy * dt
            goto continue
        end

        local goalX = pos.x + vel.vx * dt
        local goalY = pos.y + vel.vy * dt

        local actualX, actualY, cols, len = phys.bumpWorld:move(
            phys.item, goalX, goalY, defaultFilter
        )

        pos.x = actualX
        pos.y = actualY

        -- Ground detection
        phys.onGround = false
        for i = 1, len do
            if cols[i].normal.y == -1 then
                phys.onGround = true
                vel.vy = 0
            end
            if cols[i].normal.y == 1 then vel.vy = 0 end
            if cols[i].normal.x ~= 0 then vel.vx = 0 end
        end

        ::continue::
    end
end
