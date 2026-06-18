-- components/physics.lua: gravity, movement, bump collision response
local Physics = {}

function Physics.init(entity, world, x, y, w, h, itemType)
    entity.world = world
    entity.x, entity.y = x, y
    entity.w, entity.h = w, h
    entity.vx, entity.vy = 0, 0
    entity.onGround = false
    entity.item = { type = itemType, entity = entity }
    world:add(entity.item, x, y, w, h)
end

function Physics.applyGravity(entity, dt, gravity)
    entity.vy = entity.vy + (gravity or 1200) * dt
end

function Physics.move(entity, dt, filter)
    local goalX = entity.x + entity.vx * dt
    local goalY = entity.y + entity.vy * dt

    local defaultFilter = function(item, other)
        if other.type == "solid" then return "slide" end
        return nil
    end

    local actualX, actualY, cols, len = entity.world:move(
        entity.item, goalX, goalY, filter or defaultFilter
    )

    entity.x, entity.y = actualX, actualY
    entity.onGround = false

    for i = 1, len do
        local col = cols[i]
        if col.normal.y == -1 then
            entity.onGround = true
            entity.vy = 0
        elseif col.normal.y == 1 then
            entity.vy = 0
        end
        if col.normal.x ~= 0 then
            entity.vx = 0
        end
    end

    return cols, len
end

-- Move without collision (for things like boss leap going offscreen)
function Physics.moveRaw(entity, dt)
    entity.x = entity.x + entity.vx * dt
    entity.y = entity.y + entity.vy * dt
    entity.world:update(entity.item, entity.x, entity.y)
end

return Physics
