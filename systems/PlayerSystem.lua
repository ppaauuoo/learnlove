local Concord   = require("deps.concord")
local bumpWorld = require("bumpworld")

local function slideFilter(item, other)
    if other.type == "bounce" then return "bounce" end
    if other.type == "ghost"  then return "cross"  end
    return "slide"
end

local PlayerSystem = Concord.system({ pool = { "position", "player", "collider" } })

local POWER_MAX = 5

function PlayerSystem:update(dt)
    for _, e in ipairs(self.pool) do
        local p     = e.player
        local dx, dy = 0, 0

        p.using_power = love.keyboard.isDown("space") and p.power_duration > 0

        if p.using_power then
            p.power_duration = p.power_duration - dt
        elseif not love.keyboard.isDown("space") and p.power_duration < POWER_MAX then
            p.power_duration = math.min(p.power_duration + dt, POWER_MAX)
        end

        local multiplier = p.using_power and p.power or 1

        if love.keyboard.isDown("a") then dx = dx - p.speed * dt * multiplier end
        if love.keyboard.isDown("d") then dx = dx + p.speed * dt * multiplier end
        if love.keyboard.isDown("w") then dy = dy - p.speed * dt * multiplier end
        if love.keyboard.isDown("s") then dy = dy + p.speed * dt * multiplier end

        if dx ~= 0 or dy ~= 0 then
            local targetX = e.position.x + dx
            local targetY = e.position.y + dy
            local actualX, actualY = bumpWorld:move(e.collider.item, targetX, targetY, slideFilter)
            e.position.x = actualX
            e.position.y = actualY
        end
    end
end

function PlayerSystem:draw()
    for _, e in ipairs(self.pool) do
        love.graphics.circle("fill", e.position.x, e.position.y, 5)
        love.graphics.print(tostring(e.player.power_duration), 10, 10)
    end
end

return PlayerSystem
