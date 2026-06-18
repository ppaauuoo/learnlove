-- rooms.lua: room definitions and layout
local bump = require("bump")

local Rooms = {}

-- Room definitions (world coordinates)
Rooms.list = {
    hallway = {
        x = 0,
        y = 0,
        w = 1600,
        h = 720,
        walls = {
            { x = 0, y = 680, w = 1600, h = 40 },     -- floor
            { x = 0, y = 0,   w = 1600, h = 20 },     -- ceiling
            { x = 0, y = 0,   w = 20,   h = 720 },    -- left wall
            -- no right wall (connects to boss room)
        },
        playerSpawn = { x = 100, y = 600 },
        bossRoom = false,
    },
    boss = {
        x = 1600,
        y = 0,
        w = 800,
        h = 720,
        walls = {
            { x = 1600, y = 680, w = 800, h = 40 },  -- floor
            { x = 1600, y = 0,   w = 800, h = 20 },  -- ceiling
            { x = 2380, y = 0,   w = 20,  h = 720 }, -- right wall
            -- no left wall (connects to hallway)
        },
        playerSpawn = { x = 1700, y = 600 },
        bossSpawn = { x = 1950, y = 480 },
        bossRoom = true,
    },
}

-- The door that seals during boss fight
Rooms.door = {
    x = 1580,
    y = 20,
    w = 40,
    h = 660,
    sealed = false,
    item = nil,
}

-- Shared wall between rooms (passable until boss fight starts)
Rooms.passage = {
    { x = 1580, y = 0,   w = 40, h = 20 }, -- top frame
    { x = 1580, y = 680, w = 40, h = 40 }, -- bottom frame
}

function Rooms.buildWorld()
    local world = bump.newWorld(32)

    -- Add all room walls
    for _, room in pairs(Rooms.list) do
        for _, wall in ipairs(room.walls) do
            wall.type = "solid"
            world:add(wall, wall.x, wall.y, wall.w, wall.h)
        end
    end

    -- Add passage frame (always solid)
    for _, wall in ipairs(Rooms.passage) do
        wall.type = "solid"
        world:add(wall, wall.x, wall.y, wall.w, wall.h)
    end

    return world
end

function Rooms.sealDoor(world)
    if Rooms.door.sealed then return end
    Rooms.door.sealed = true
    Rooms.door.type = "solid"
    Rooms.door.item = Rooms.door
    world:add(Rooms.door, Rooms.door.x, Rooms.door.y, Rooms.door.w, Rooms.door.h)
end

function Rooms.unsealDoor(world)
    if not Rooms.door.sealed then return end
    Rooms.door.sealed = false
    if world:hasItem(Rooms.door) then
        world:remove(Rooms.door)
    end
end

-- Determine which room a point is in
function Rooms.getRoomAt(x, y)
    for name, room in pairs(Rooms.list) do
        if x >= room.x and x <= room.x + room.w and
            y >= room.y and y <= room.y + room.h then
            return name, room
        end
    end
    return "hallway", Rooms.list.hallway
end

return Rooms
