local Concord   = require("deps.concord")
local bumpWorld = require("bumpworld")

local function slideFilter(item, other)
    if other.type == "bounce" then return "bounce" end
    if other.type == "ghost"  then return "cross"  end
    return "slide"
end

local PhysicsSystem = Concord.system({ pool = { "position", "collider", "velocity" } })

function PhysicsSystem:update(dt)
    for _, e in ipairs(self.pool) do
        local pos      = e.position
        local collider = e.collider
        local velocity = e.velocity

        local targetX = pos.x + (velocity.x * dt)
        local targetY = pos.y + (velocity.y * dt)

        local actualX, actualY, cols, len = bumpWorld:move(collider.item, targetX, targetY, slideFilter)

        pos.x = actualX
        pos.y = actualY

        for i = 1, len do
            local col = cols[i] -- luacheck: ignore
        end
    end
end

return PhysicsSystem
