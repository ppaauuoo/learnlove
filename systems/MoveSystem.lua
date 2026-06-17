local Concord = require("deps.concord")

local MoveSystem = Concord.system({ pool = { "position", "velocity" } })

function MoveSystem:update(dt)
    for _, e in ipairs(self.pool) do
        -- Skip entities with a collider; PhysicsSystem owns their movement
        if not e.collider then
            e.position.x = e.position.x + e.velocity.x * dt
            e.position.y = e.position.y + e.velocity.y * dt
        end
    end
end

return MoveSystem
