-- components/knockback.lua: knockback velocity + timer
local Knockback = {}

function Knockback.init(entity)
    entity.knockback = { vx = 0, vy = 0, timer = 0 }
end

function Knockback.apply(entity, vx, vy, duration)
    entity.knockback.vx = vx
    entity.knockback.vy = vy
    entity.knockback.timer = duration or 0.1
end

-- Returns true if entity is currently in knockback
function Knockback.update(entity, dt)
    if entity.knockback.timer > 0 then
        entity.knockback.timer = entity.knockback.timer - dt
        entity.vx = entity.knockback.vx
        entity.vy = entity.knockback.vy
        return true
    end
    return false
end

return Knockback
