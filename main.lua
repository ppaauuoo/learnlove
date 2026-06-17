local Concord = require("deps.concord")

-- Load all components (registers them with Concord as side effects)
Concord.utils.loadNamespace("components")

local Systems = {}
Concord.utils.loadNamespace("systems", Systems)

-- Create the World
local world = Concord.world()

-- Add the Systems
world:addSystems(Systems.PhysicsSystem, Systems.MoveSystem, Systems.DrawSystem, Systems.PlayerSystem)

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
