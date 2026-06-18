-- components/health.lua: hp, iframes, flash timer
local Health = {}

function Health.init(entity, hp)
    entity.hp = hp
    entity.maxHp = hp
    entity.iframes = 0
    entity.flashTimer = 0
end

function Health.update(entity, dt)
    entity.iframes = math.max(0, entity.iframes - dt)
    entity.flashTimer = math.max(0, entity.flashTimer - dt)
end

function Health.canTakeDamage(entity)
    return entity.iframes <= 0 and entity.hp > 0
end

function Health.takeDamage(entity, amount, iframeDuration)
    entity.hp = entity.hp - (amount or 1)
    entity.iframes = iframeDuration
    entity.flashTimer = 0.05
end

return Health
