-- rooms.lua: room definitions and layout
local bump = require("deps.bump")

local Rooms = {}

Rooms.list = {
    hallway = {
        x = 0, y = 0, w = 1600, h = 720,
        walls = {
            { x = 0, y = 680, w = 1600, h = 40 },
            { x = 0, y = 0,   w = 1600, h = 20 },
            { x = 0, y = 0,   w = 20,   h = 720 },
        },
        playerSpawn = { x = 100, y = 600 },
        bossRoom = false,
    },
    boss = {
        x = 1600, y = 0, w = 960, h = 720,
        walls = {
            { x = 1600, y = 680, w = 960, h = 40 },
            { x = 1600, y = 0,   w = 960, h = 20 },
            { x = 2540, y = 0,   w = 20,  h = 720 },
        },
        playerSpawn = { x = 1700, y = 600 },
        bossSpawn = { x = 1950, y = 480 },
        bossRoom = true,
    },
}

Rooms.door = { x = 1580, y = 20, w = 40, h = 660, sealed = false, item = nil }

Rooms.passage = {
    { x = 1580, y = 0,   w = 40, h = 20 },
    { x = 1580, y = 680, w = 40, h = 40 },
}

function Rooms.buildWorld()
    local world = bump.newWorld(32)
    for _, room in pairs(Rooms.list) do
        for _, wall in ipairs(room.walls) do
            wall.type = "solid"
            world:add(wall, wall.x, wall.y, wall.w, wall.h)
        end
    end
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
    if world:hasItem(Rooms.door) then world:remove(Rooms.door) end
end

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
