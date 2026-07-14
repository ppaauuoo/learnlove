-- systems/health.lua: tick iframes and flash timers
local tiny = require("deps.tiny")

local healthSystem = tiny.processingSystem()
healthSystem.filter = tiny.requireAll("hp", "iframes", "flashTimer")

function healthSystem:process(e, dt)
    e.iframes = math.max(0, e.iframes - dt)
    e.flashTimer = math.max(0, e.flashTimer - dt)
end

return healthSystem
