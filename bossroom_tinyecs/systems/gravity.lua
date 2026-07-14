-- systems/gravity.lua: apply gravity to entities with vy + physics
local tiny = require("deps.tiny")

local gravitySystem = tiny.processingSystem()
gravitySystem.filter = tiny.requireAll("vy", "physics")

function gravitySystem:process(e, dt)
    e.vy = e.vy + 1200 * dt
end

return gravitySystem
