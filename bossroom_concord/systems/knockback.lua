-- systems/knockback.lua: apply knockback velocity
local Concord = require("deps.concord")

local KnockbackSystem = Concord.system({ pool = {"knockback", "velocity"} })

function KnockbackSystem:update(dt)
    for _, e in ipairs(self.pool) do
        local kb = e.knockback
        if kb.timer > 0 then
            kb.timer = kb.timer - dt
            e.velocity.vx = kb.vx
            e.velocity.vy = kb.vy
        end
    end
end

return KnockbackSystem
