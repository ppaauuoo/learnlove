-- systems/health.lua: tick iframes and flash timers
local Concord = require("deps.concord")

local HealthSystem = Concord.system({ pool = {"health"} })

function HealthSystem:update(dt)
    for _, e in ipairs(self.pool) do
        e.health.iframes = math.max(0, e.health.iframes - dt)
        e.health.flashTimer = math.max(0, e.health.flashTimer - dt)
    end
end

return HealthSystem
