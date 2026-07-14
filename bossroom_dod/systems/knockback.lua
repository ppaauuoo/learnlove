-- systems/knockback.lua: apply knockback velocity, decrement timer
local W = require("world")

-- Returns set of ids currently in knockback (callers can skip normal movement)
return function(dt)
    local inKB = {}
    for id, kb in pairs(W.kb) do
        if kb.timer > 0 then
            kb.timer = kb.timer - dt
            local vel = W.vel[id]
            if vel then
                vel.vx = kb.vx
                vel.vy = kb.vy
            end
            inKB[id] = true
        end
    end
    return inKB
end
