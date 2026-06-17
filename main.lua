local Concord = require("deps.concord")
local bump       = require 'deps.bump'

-- Create bump world early so component constructors can reference it
local bumpWorld = bump.newWorld()

-- Defining components
Concord.component("position", function(c, x, y)
    c.x = x or 0
    c.y = y or 0
end)

Concord.component('collider', function(c, x, y, w, h, ctype)
    c.item = { type = ctype or "solid" }
    bumpWorld:add(c.item, x, y, w, h)
end)

Concord.component("velocity", function(c, x, y)
    c.x = x or 0
    c.y = y or 0
end)

Concord.component("drawable")

local Player = Concord.component("player", function(c, speed, power)
    c.speed = speed or 0
    c.power = power or 0
    c.power_duration = 5
    c.using_power = false
end)


-- Defining Systems

local function slideFilter(item, other)
    if other.type == "bounce" then return "bounce" end
    if other.type == "ghost"  then return "cross"  end
    return "slide"
end

local PhysicsSystem = Concord.system({ pool = { 'position', 'collider', 'velocity' } })

function PhysicsSystem:update(dt)
    for _, e in ipairs(self.pool) do
        local pos = e.position
        local collider = e.collider
        local velocity = e.velocity -- Assuming you have a Velocity component

        -- Calculate where the entity wants to move
        local targetX = pos.x + (velocity.x * dt)
        local targetY = pos.y + (velocity.y * dt)

        -- Move in bump world and handle collisions
        local actualX, actualY, cols, len = bumpWorld:move(collider.item, targetX, targetY, slideFilter)

        -- Update Concord position with actual position
        pos.x = actualX
        pos.y = actualY

        -- Handle collision responses (e.g., bouncing off walls, triggering events)
        for i = 1, len do
            local col = cols[i]
            -- Collision response logic goes here
        end
    end
end

local PlayerSystem = Concord.system({
    pool = {"position", "player", "collider"}
})

local POWER_MAX = 5

function PlayerSystem:update(dt)
    for _, e in ipairs(self.pool) do
        local p = e.player
        local dx, dy = 0, 0

        -- 1. read input first
        p.using_power = love.keyboard.isDown("space") and p.power_duration > 0

        -- 2. drain / recharge
        if p.using_power then
            p.power_duration = p.power_duration - dt
        elseif p.power_duration < POWER_MAX then
            p.power_duration = math.min(p.power_duration + dt, POWER_MAX)
        end

        -- 3. compute multiplier
        local multiplier = p.using_power and p.power or 1

        -- 4. move
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
        love.graphics.print(e.player.power_duration, 700, 700)
    end
end

local MoveSystem = Concord.system({
    pool = {"position", "velocity"}
})

function MoveSystem:update(dt)
    for _, e in ipairs(self.pool) do
        -- Skip entities with a collider; PhysicsSystem owns their movement
        if not e.collider then
            e.position.x = e.position.x + e.velocity.x * dt
            e.position.y = e.position.y + e.velocity.y * dt
        end
    end
end

local DrawSystem = Concord.system({
    pool = {"position", "drawable"}
})

function DrawSystem:draw()
    for _, e in ipairs(self.pool) do
        love.graphics.circle("fill", e.position.x, e.position.y, 5)
    end
end


-- Create the World
local world = Concord.world()

-- Add the Systems
world:addSystems(PhysicsSystem, MoveSystem, DrawSystem, PlayerSystem)

-- This Entity will be rendered on the screen, and move to the right at 100 pixels a second
local entity_1 = Concord.entity(world)
:give("position", 100, 100)
:give("velocity", 50, 0)
:give("collider", 100, 100, 10, 10, "slide")
:give("drawable")

-- This Entity will be rendered on the screen, and stay at 50, 50
local entity_2 = Concord.entity(world)
:give("position", 50, 50)
:give("collider", 50, 50, 10, 10, "bounce")
:give("drawable")

-- This Entity does exist in the World, but since it doesn't match any System's filters it won't do anything
local entity_3 = Concord.entity(world)
:give("position", 200, 200)
:give("player", 100, 2)
:give("collider", 200, 200, 10, 10)
:give("drawable")

-- Emit the events
lick = require "deps.lick"
lick.reset = true -- reload love.load every time you save
lick.updateAllFiles = true -- watch all files
lick.fileExtensions = {} -- watch all file types
lick.clearPackages = true -- clear package cache on reload

-- Protect specific third-party libraries from being cleared
lick.ignorePackages = {
    socket = true,
    json = true
}

function love.update(dt)
    world:emit("update", dt)
end

function love.draw()
    world:emit("draw")
end
