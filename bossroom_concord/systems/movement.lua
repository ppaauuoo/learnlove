-- systems/movement.lua: move entities via bump collision
local Concord = require("deps.concord")

local MovementSystem = Concord.system({ pool = {"position", "velocity", "physics"} })

local function defaultFilter(item, other)
    if other.type == "solid" then return "slide" end
    return nil
end

function MovementSystem:update(dt)
    for _, e in ipairs(self.pool) do
        local pos = e.position
        local vel = e.velocity
        local phys = e.physics

        -- Boss invisible = raw move (no collision)
        if e.bossAI and not e.bossAI.visible then
            pos.x = pos.x + vel.vx * dt
            pos.y = pos.y + vel.vy * dt
            phys.bumpWorld:update(phys.item, pos.x, pos.y)
            goto continue
        end

        local goalX = pos.x + vel.vx * dt
        local goalY = pos.y + vel.vy * dt

        local actualX, actualY, cols, len = phys.bumpWorld:move(
            phys.item, goalX, goalY, defaultFilter
        )

        pos.x = actualX
        pos.y = actualY

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

return MovementSystem
