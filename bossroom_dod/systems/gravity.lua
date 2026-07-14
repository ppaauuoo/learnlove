-- systems/gravity.lua: apply gravity to all entities with vel + phys
local W = require("world")

local GRAVITY = 1200

return function(dt)
    for id, vel in pairs(W.vel) do
        if W.phys[id] then
            vel.vy = vel.vy + GRAVITY * dt
        end
    end
end
