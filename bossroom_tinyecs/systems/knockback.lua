-- systems/knockback.lua: apply knockback velocity, decrement timer
local tiny = require("deps.tiny")

local knockbackSystem = tiny.processingSystem()
knockbackSystem.filter = tiny.requireAll("knockback", "vx", "vy")

function knockbackSystem:process(e, dt)
    local kb = e.knockback
    if kb.timer > 0 then
        kb.timer = kb.timer - dt
        e.vx = kb.vx
        e.vy = kb.vy
        -- Mark entity as in knockback for player_input to check
        e._inKnockback = true
    else
        e._inKnockback = false
    end
end

return knockbackSystem
