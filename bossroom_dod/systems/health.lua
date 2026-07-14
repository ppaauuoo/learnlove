-- systems/health.lua: tick iframes and flash timers
local W = require("world")

return function(dt)
    for id, h in pairs(W.health) do
        h.iframes = math.max(0, h.iframes - dt)
        h.flashTimer = math.max(0, h.flashTimer - dt)
    end
end
