-- systems/gravity.lua: apply gravity to entities with velocity + physics
local Concord = require("deps.concord")

local GravitySystem = Concord.system({ pool = {"velocity", "physics"} })

local GRAVITY = 1200

function GravitySystem:update(dt)
    for _, e in ipairs(self.pool) do
        e.velocity.vy = e.velocity.vy + GRAVITY * dt
    end
end

return GravitySystem
