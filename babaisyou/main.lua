-- Baba Is You Clone
-- Uses colored squares + text labels (sprites can be added later)

------------------------------------------------------------
-- CONSTANTS
------------------------------------------------------------
local TILE = 32         -- tile size in pixels
local GRID_W = 24       -- grid width in tiles
local GRID_H = 18       -- grid height in tiles
local MOVE_DELAY = 0.12 -- input repeat delay
local PANEL_WIDTH = 320 -- right panel width for character portrait

------------------------------------------------------------
-- OBJECT TYPES (things that exist on the grid)
------------------------------------------------------------
local OBJECTS = {
    -- Game objects (rendered as colored squares)
    BABA        = { type = "object", color = { 1, 1, 1 }, name = "BABA" },
    WALL        = { type = "object", color = { 0.3, 0.3, 0.3 }, name = "WALL" },
    FLAG        = { type = "object", color = { 1, 1, 0 }, name = "FLAG" },
    ROCK        = { type = "object", color = { 0.6, 0.4, 0.2 }, name = "ROCK" },
    WATER       = { type = "object", color = { 0.2, 0.4, 0.8 }, name = "WATER" },
    LAVA        = { type = "object", color = { 0.9, 0.3, 0.1 }, name = "LAVA" },
    KEY         = { type = "object", color = { 0.9, 0.7, 0.1 }, name = "KEY" },
    DOOR        = { type = "object", color = { 0.5, 0.2, 0.5 }, name = "DOOR" },

    -- Text/Word blocks (nouns - refer to objects)
    TEXT_BABA   = { type = "noun", color = { 0.9, 0.9, 0.9 }, name = "BABA", refers = "BABA" },
    TEXT_WALL   = { type = "noun", color = { 0.5, 0.5, 0.5 }, name = "WALL", refers = "WALL" },
    TEXT_FLAG   = { type = "noun", color = { 0.9, 0.9, 0.3 }, name = "FLAG", refers = "FLAG" },
    TEXT_ROCK   = { type = "noun", color = { 0.7, 0.5, 0.3 }, name = "ROCK", refers = "ROCK" },
    TEXT_WATER  = { type = "noun", color = { 0.4, 0.6, 0.9 }, name = "WATER", refers = "WATER" },
    TEXT_LAVA   = { type = "noun", color = { 1.0, 0.5, 0.3 }, name = "LAVA", refers = "LAVA" },
    TEXT_KEY    = { type = "noun", color = { 1.0, 0.8, 0.3 }, name = "KEY", refers = "KEY" },
    TEXT_DOOR   = { type = "noun", color = { 0.6, 0.3, 0.6 }, name = "DOOR", refers = "DOOR" },

    -- Verb
    TEXT_IS     = { type = "verb", color = { 1, 1, 1 }, name = "IS" },

    -- Properties
    TEXT_YOU    = { type = "property", color = { 0.8, 0.2, 0.8 }, name = "YOU" },
    TEXT_STOP   = { type = "property", color = { 0.3, 0.8, 0.3 }, name = "STOP" },
    TEXT_PUSH   = { type = "property", color = { 0.6, 0.4, 0.2 }, name = "PUSH" },
    TEXT_WIN    = { type = "property", color = { 1, 1, 0 }, name = "WIN" },
    TEXT_DEFEAT = { type = "property", color = { 0.8, 0.1, 0.1 }, name = "DEFEAT" },
    TEXT_SINK   = { type = "property", color = { 0.2, 0.3, 0.7 }, name = "SINK" },
    TEXT_HOT    = { type = "property", color = { 1, 0.4, 0.1 }, name = "HOT" },
    TEXT_MELT   = { type = "property", color = { 0.3, 0.7, 1 }, name = "MELT" },
    TEXT_OPEN   = { type = "property", color = { 0.9, 0.7, 0.2 }, name = "OPEN" },
    TEXT_SHUT   = { type = "property", color = { 0.5, 0.2, 0.5 }, name = "SHUT" },
}

------------------------------------------------------------
-- GAME STATE
------------------------------------------------------------
local grid = {}      -- grid[y][x] = list of object instances
local rules = {}     -- active rules: { subject="BABA", property="YOU" }
local undoStack = {} -- for undo functionality
local currentLevel = 1
local gameWon = false
local gameLost = false
local moveTimer = 0
local particles = {} -- simple visual effects

------------------------------------------------------------
-- LEVELS
------------------------------------------------------------
local levels = {}

-- Level format: each entry is {x, y, objectKey}
-- Grid is 1-indexed

levels[1] = {
    name = "Level 1: First Steps",
    objects = {
        -- Baba
        { 3,  9, "BABA" },
        -- Flag
        { 21, 9, "FLAG" },
        -- Walls
        { 10, 5, "WALL" }, { 11, 5, "WALL" }, { 12, 5, "WALL" }, { 13, 5, "WALL" }, { 14, 5, "WALL" },
        { 10, 13, "WALL" }, { 11, 13, "WALL" }, { 12, 13, "WALL" }, { 13, 13, "WALL" }, { 14, 13, "WALL" },
        -- Rules: BABA IS YOU
        { 1,  16, "TEXT_BABA" }, { 2, 16, "TEXT_IS" }, { 3, 16, "TEXT_YOU" },
        -- Rules: FLAG IS WIN
        { 5, 16, "TEXT_FLAG" }, { 6, 16, "TEXT_IS" }, { 7, 16, "TEXT_WIN" },
        -- Rules: WALL IS STOP
        { 9, 16, "TEXT_WALL" }, { 10, 16, "TEXT_IS" }, { 11, 16, "TEXT_STOP" },
    }
}

levels[2] = {
    name = "Level 2: Push It",
    objects = {
        -- Baba
        { 3,  9, "BABA" },
        -- Flag (blocked by rocks)
        { 20, 9, "FLAG" },
        -- Rocks blocking the path
        { 10, 9, "ROCK" }, { 12, 9, "ROCK" }, { 14, 9, "ROCK" },
        -- Walls
        { 18, 7, "WALL" }, { 18, 8, "WALL" }, { 18, 9, "WALL" }, { 18, 10, "WALL" }, { 18, 11, "WALL" },
        -- Rules: BABA IS YOU
        { 1,  1, "TEXT_BABA" }, { 2, 1, "TEXT_IS" }, { 3, 1, "TEXT_YOU" },
        -- Rules: FLAG IS WIN
        { 5, 1, "TEXT_FLAG" }, { 6, 1, "TEXT_IS" }, { 7, 1, "TEXT_WIN" },
        -- Rules: ROCK IS PUSH
        { 9, 1, "TEXT_ROCK" }, { 10, 1, "TEXT_IS" }, { 11, 1, "TEXT_PUSH" },
        -- Rules: WALL IS STOP
        { 13, 1, "TEXT_WALL" }, { 14, 1, "TEXT_IS" }, { 15, 1, "TEXT_STOP" },
    }
}

levels[3] = {
    name = "Level 3: Rule Change",
    objects = {
        -- Baba
        { 3,  9, "BABA" },
        -- Flag surrounded by walls
        { 12, 9, "FLAG" },
        { 11, 8, "WALL" }, { 12, 8, "WALL" }, { 13, 8, "WALL" },
        { 11, 9,  "WALL" }, { 13, 9, "WALL" },
        { 11, 10, "WALL" }, { 12, 10, "WALL" }, { 13, 10, "WALL" },
        -- Rules: BABA IS YOU (vertical)
        { 1,  7, "TEXT_BABA" }, { 1, 8, "TEXT_IS" }, { 1, 9, "TEXT_YOU" },
        -- Rules: FLAG IS WIN
        { 20, 1, "TEXT_FLAG" }, { 21, 1, "TEXT_IS" }, { 22, 1, "TEXT_WIN" },
        -- Rules: WALL IS STOP (pushable to break the rule!)
        { 7, 14, "TEXT_WALL" }, { 8, 14, "TEXT_IS" }, { 9, 14, "TEXT_STOP" },
    }
}

levels[4] = {
    name = "Level 4: Identity Crisis",
    objects = {
        -- Baba
        { 3,  9, "BABA" },
        -- Flag far away with water in between
        { 21, 9, "FLAG" },
        -- Water lake
        { 10, 8, "WATER" }, { 11, 8, "WATER" }, { 12, 8, "WATER" },
        { 10, 9,  "WATER" }, { 11, 9, "WATER" }, { 12, 9, "WATER" },
        { 10, 10, "WATER" }, { 11, 10, "WATER" }, { 12, 10, "WATER" },
        -- Rocks to sink into water
        { 7, 8, "ROCK" }, { 7, 9, "ROCK" }, { 7, 10, "ROCK" },
        -- Rules
        { 1, 1, "TEXT_BABA" }, { 2, 1, "TEXT_IS" }, { 3, 1, "TEXT_YOU" },
        { 5, 1, "TEXT_FLAG" }, { 6, 1, "TEXT_IS" }, { 7, 1, "TEXT_WIN" },
        { 9, 1, "TEXT_ROCK" }, { 10, 1, "TEXT_IS" }, { 11, 1, "TEXT_PUSH" },
        { 13, 1, "TEXT_WATER" }, { 14, 1, "TEXT_IS" }, { 15, 1, "TEXT_SINK" },
    }
}

levels[5] = {
    name = "Level 5: Hot & Cold",
    objects = {
        -- Baba
        { 3,  9, "BABA" },
        -- Flag
        { 21, 9, "FLAG" },
        -- Lava blocking
        { 12, 7, "LAVA" }, { 12, 8, "LAVA" }, { 12, 9, "LAVA" }, { 12, 10, "LAVA" }, { 12, 11, "LAVA" },
        -- Rock to push through (but it melts!)
        { 8,  9, "ROCK" },
        -- Key and Door
        { 5,  5, "KEY" },
        { 16, 9, "DOOR" },
        -- Rules
        { 1,  1, "TEXT_BABA" }, { 2, 1, "TEXT_IS" }, { 3, 1, "TEXT_YOU" },
        { 5, 1, "TEXT_FLAG" }, { 6, 1, "TEXT_IS" }, { 7, 1, "TEXT_WIN" },
        { 9, 1, "TEXT_LAVA" }, { 10, 1, "TEXT_IS" }, { 11, 1, "TEXT_HOT" },
        { 13, 1, "TEXT_ROCK" }, { 14, 1, "TEXT_IS" }, { 15, 1, "TEXT_MELT" },
        { 17, 1, "TEXT_KEY" }, { 18, 1, "TEXT_IS" }, { 19, 1, "TEXT_PUSH" },
        { 1, 17, "TEXT_KEY" }, { 2, 17, "TEXT_IS" }, { 3, 17, "TEXT_OPEN" },
        { 5, 17, "TEXT_DOOR" }, { 6, 17, "TEXT_IS" }, { 7, 17, "TEXT_SHUT" },
    }
}

------------------------------------------------------------
-- HELPER FUNCTIONS
------------------------------------------------------------

local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = deepCopy(v)
    end
    return copy
end

local function initGrid()
    grid = {}
    for y = 1, GRID_H do
        grid[y] = {}
        for x = 1, GRID_W do
            grid[y][x] = {}
        end
    end
end

local function getObjectsAt(x, y)
    if x < 1 or x > GRID_W or y < 1 or y > GRID_H then
        return nil -- out of bounds
    end
    return grid[y][x]
end

local function addObject(x, y, key)
    if x >= 1 and x <= GRID_W and y >= 1 and y <= GRID_H then
        table.insert(grid[y][x], { key = key, x = x, y = y })
    end
end

local function removeObject(x, y, obj)
    local cell = grid[y][x]
    for i = #cell, 1, -1 do
        if cell[i] == obj then
            table.remove(cell, i)
            return
        end
    end
end

local function isTextBlock(key)
    local def = OBJECTS[key]
    return def and (def.type == "noun" or def.type == "verb" or def.type == "property")
end

local function getObjectDef(key)
    return OBJECTS[key]
end

local function hasProperty(objectKey, property)
    for _, rule in ipairs(rules) do
        if rule.subject == objectKey and rule.property == property then
            return true
        end
    end
    return false
end

local function getTransform(objectKey)
    -- Check if there's a "NOUN IS NOUN" rule (transformation)
    for _, rule in ipairs(rules) do
        if rule.subject == objectKey and rule.transform then
            return rule.transform
        end
    end
    return nil
end

------------------------------------------------------------
-- RULE PARSING
------------------------------------------------------------

local function parseRules()
    rules = {}

    -- Scan horizontally: NOUN IS PROPERTY/NOUN
    for y = 1, GRID_H do
        for x = 1, GRID_W - 2 do
            local cell1 = grid[y][x]
            local cell2 = grid[y][x + 1]
            local cell3 = grid[y][x + 2]

            for _, obj1 in ipairs(cell1) do
                local def1 = OBJECTS[obj1.key]
                if def1 and def1.type == "noun" then
                    for _, obj2 in ipairs(cell2) do
                        local def2 = OBJECTS[obj2.key]
                        if def2 and def2.type == "verb" and def2.name == "IS" then
                            for _, obj3 in ipairs(cell3) do
                                local def3 = OBJECTS[obj3.key]
                                if def3 then
                                    if def3.type == "property" then
                                        table.insert(rules, {
                                            subject = def1.refers,
                                            property = def3.name
                                        })
                                    elseif def3.type == "noun" then
                                        -- NOUN IS NOUN = transformation
                                        table.insert(rules, {
                                            subject = def1.refers,
                                            transform = def3.refers
                                        })
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- Scan vertically: NOUN IS PROPERTY/NOUN
    for x = 1, GRID_W do
        for y = 1, GRID_H - 2 do
            local cell1 = grid[y][x]
            local cell2 = grid[y + 1][x]
            local cell3 = grid[y + 2][x]

            for _, obj1 in ipairs(cell1) do
                local def1 = OBJECTS[obj1.key]
                if def1 and def1.type == "noun" then
                    for _, obj2 in ipairs(cell2) do
                        local def2 = OBJECTS[obj2.key]
                        if def2 and def2.type == "verb" and def2.name == "IS" then
                            for _, obj3 in ipairs(cell3) do
                                local def3 = OBJECTS[obj3.key]
                                if def3 then
                                    if def3.type == "property" then
                                        table.insert(rules, {
                                            subject = def1.refers,
                                            property = def3.name
                                        })
                                    elseif def3.type == "noun" then
                                        table.insert(rules, {
                                            subject = def1.refers,
                                            transform = def3.refers
                                        })
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- Text blocks are always PUSH
    -- (This is implicit in Baba Is You)
end

------------------------------------------------------------
-- MOVEMENT & PUSH LOGIC
------------------------------------------------------------

local function canPush(x, y, dx, dy, visited)
    -- Returns true if objects at (x,y) can be pushed in direction (dx,dy)
    if x < 1 or x > GRID_W or y < 1 or y > GRID_H then
        return false
    end

    visited = visited or {}
    local posKey = x .. "," .. y
    if visited[posKey] then return false end
    visited[posKey] = true

    local cell = grid[y][x]
    for _, obj in ipairs(cell) do
        local def = OBJECTS[obj.key]
        if def then
            -- Text blocks are always pushable
            local isPushable = isTextBlock(obj.key) or hasProperty(obj.key, "PUSH")
            local isStop = hasProperty(obj.key, "STOP")

            if isStop and not isPushable then
                return false -- blocked by STOP
            end

            if isPushable then
                local nx, ny = x + dx, y + dy
                if nx < 1 or nx > GRID_W or ny < 1 or ny > GRID_H then
                    return false -- can't push off grid
                end
                -- Check if next cell allows pushing
                if not canPush(nx, ny, dx, dy, visited) then
                    return false
                end
            end
        end
    end

    return true
end

local function doPush(x, y, dx, dy)
    -- Push all pushable objects at (x,y) in direction (dx,dy)
    if x < 1 or x > GRID_W or y < 1 or y > GRID_H then return end

    local cell = grid[y][x]
    local toPush = {}

    for _, obj in ipairs(cell) do
        local isPushable = isTextBlock(obj.key) or hasProperty(obj.key, "PUSH")
        if isPushable then
            table.insert(toPush, obj)
        end
    end

    if #toPush > 0 then
        -- First push whatever is in the next cell
        doPush(x + dx, y + dy, dx, dy)

        -- Then move these objects
        for _, obj in ipairs(toPush) do
            removeObject(x, y, obj)
            obj.x = x + dx
            obj.y = y + dy
            table.insert(grid[y + dy][x + dx], obj)
        end
    end
end

local function moveYou(dx, dy)
    -- Find all objects that are YOU
    local youObjects = {}
    for y = 1, GRID_H do
        for x = 1, GRID_W do
            for _, obj in ipairs(grid[y][x]) do
                if hasProperty(obj.key, "YOU") and not isTextBlock(obj.key) then
                    table.insert(youObjects, obj)
                end
            end
        end
    end

    if #youObjects == 0 then
        gameLost = true
        return
    end

    -- Try to move each YOU object
    for _, obj in ipairs(youObjects) do
        local nx, ny = obj.x + dx, obj.y + dy

        -- Check bounds
        if nx >= 1 and nx <= GRID_W and ny >= 1 and ny <= GRID_H then
            -- Check if we can move there
            local blocked = false
            local nextCell = grid[ny][nx]

            for _, other in ipairs(nextCell) do
                local isStop = hasProperty(other.key, "STOP") and not isTextBlock(other.key)
                local isPush = isTextBlock(other.key) or hasProperty(other.key, "PUSH")

                if isStop and not isPush then
                    blocked = true
                    break
                end

                if isPush then
                    if not canPush(nx, ny, dx, dy, {}) then
                        blocked = true
                        break
                    end
                end
            end

            if not blocked then
                -- Push anything pushable in the way
                doPush(nx, ny, dx, dy)
                -- Move YOU
                removeObject(obj.x, obj.y, obj)
                obj.x = nx
                obj.y = ny
                table.insert(grid[ny][nx], obj)
            end
        end
    end
end

------------------------------------------------------------
-- GAME LOGIC (post-move checks)
------------------------------------------------------------

local function applyTransformations()
    -- Handle NOUN IS NOUN transformations
    local transforms = {}
    for _, rule in ipairs(rules) do
        if rule.transform then
            transforms[rule.subject] = rule.transform
        end
    end

    if next(transforms) == nil then return end

    for y = 1, GRID_H do
        for x = 1, GRID_W do
            local cell = grid[y][x]
            for i = #cell, 1, -1 do
                local obj = cell[i]
                if not isTextBlock(obj.key) and transforms[obj.key] then
                    obj.key = transforms[obj.key]
                end
            end
        end
    end
end

local function checkWin()
    -- Check if any YOU object overlaps with a WIN object
    for y = 1, GRID_H do
        for x = 1, GRID_W do
            local cell = grid[y][x]
            local hasYou = false
            local hasWin = false

            for _, obj in ipairs(cell) do
                if not isTextBlock(obj.key) then
                    if hasProperty(obj.key, "YOU") then hasYou = true end
                    if hasProperty(obj.key, "WIN") then hasWin = true end
                end
            end

            if hasYou and hasWin then
                return true
            end
        end
    end
    return false
end

local function checkDefeat()
    -- Check if any YOU object overlaps with a DEFEAT object
    local toRemove = {}
    for y = 1, GRID_H do
        for x = 1, GRID_W do
            local cell = grid[y][x]
            local youObjs = {}
            local hasDefeat = false

            for _, obj in ipairs(cell) do
                if not isTextBlock(obj.key) then
                    if hasProperty(obj.key, "YOU") then
                        table.insert(youObjs, obj)
                    end
                    if hasProperty(obj.key, "DEFEAT") then
                        hasDefeat = true
                    end
                end
            end

            if hasDefeat then
                for _, youObj in ipairs(youObjs) do
                    table.insert(toRemove, { x = x, y = y, obj = youObj })
                end
            end
        end
    end

    for _, item in ipairs(toRemove) do
        removeObject(item.x, item.y, item.obj)
        -- Add particle effect
        table.insert(particles, {
            x = (item.x - 1) * TILE + TILE / 2,
            y = (item.y - 1) * TILE + TILE / 2,
            timer = 0.5,
            color = { 1, 0.2, 0.2 }
        })
    end
end

local function checkSink()
    -- If a SINK object overlaps with anything, both are destroyed
    local toRemove = {}
    for y = 1, GRID_H do
        for x = 1, GRID_W do
            local cell = grid[y][x]
            if #cell >= 2 then
                local sinkObjs = {}
                local otherObjs = {}

                for _, obj in ipairs(cell) do
                    if not isTextBlock(obj.key) then
                        if hasProperty(obj.key, "SINK") then
                            table.insert(sinkObjs, obj)
                        else
                            table.insert(otherObjs, obj)
                        end
                    end
                end

                if #sinkObjs > 0 and #otherObjs > 0 then
                    -- Destroy one sink and one other
                    table.insert(toRemove, { x = x, y = y, obj = sinkObjs[1] })
                    table.insert(toRemove, { x = x, y = y, obj = otherObjs[1] })
                end
            end
        end
    end

    for _, item in ipairs(toRemove) do
        removeObject(item.x, item.y, item.obj)
        table.insert(particles, {
            x = (item.x - 1) * TILE + TILE / 2,
            y = (item.y - 1) * TILE + TILE / 2,
            timer = 0.5,
            color = { 0.2, 0.4, 0.9 }
        })
    end
end

local function checkHotMelt()
    -- If a HOT object overlaps with a MELT object, the MELT object is destroyed
    local toRemove = {}
    for y = 1, GRID_H do
        for x = 1, GRID_W do
            local cell = grid[y][x]
            local hasHot = false
            local meltObjs = {}

            for _, obj in ipairs(cell) do
                if not isTextBlock(obj.key) then
                    if hasProperty(obj.key, "HOT") then hasHot = true end
                    if hasProperty(obj.key, "MELT") then
                        table.insert(meltObjs, obj)
                    end
                end
            end

            if hasHot then
                for _, mObj in ipairs(meltObjs) do
                    table.insert(toRemove, { x = x, y = y, obj = mObj })
                end
            end
        end
    end

    for _, item in ipairs(toRemove) do
        removeObject(item.x, item.y, item.obj)
        table.insert(particles, {
            x = (item.x - 1) * TILE + TILE / 2,
            y = (item.y - 1) * TILE + TILE / 2,
            timer = 0.5,
            color = { 1, 0.5, 0.1 }
        })
    end
end

local function checkOpenShut()
    -- If an OPEN object overlaps with a SHUT object, both are destroyed
    local toRemove = {}
    for y = 1, GRID_H do
        for x = 1, GRID_W do
            local cell = grid[y][x]
            local openObjs = {}
            local shutObjs = {}

            for _, obj in ipairs(cell) do
                if not isTextBlock(obj.key) then
                    if hasProperty(obj.key, "OPEN") then
                        table.insert(openObjs, obj)
                    end
                    if hasProperty(obj.key, "SHUT") then
                        table.insert(shutObjs, obj)
                    end
                end
            end

            if #openObjs > 0 and #shutObjs > 0 then
                table.insert(toRemove, { x = x, y = y, obj = openObjs[1] })
                table.insert(toRemove, { x = x, y = y, obj = shutObjs[1] })
            end
        end
    end

    for _, item in ipairs(toRemove) do
        removeObject(item.x, item.y, item.obj)
        table.insert(particles, {
            x = (item.x - 1) * TILE + TILE / 2,
            y = (item.y - 1) * TILE + TILE / 2,
            timer = 0.4,
            color = { 0.9, 0.8, 0.2 }
        })
    end
end

local function checkYouExist()
    -- If no YOU objects remain, game over
    for y = 1, GRID_H do
        for x = 1, GRID_W do
            for _, obj in ipairs(grid[y][x]) do
                if not isTextBlock(obj.key) and hasProperty(obj.key, "YOU") then
                    return true
                end
            end
        end
    end
    return false
end

------------------------------------------------------------
-- LEVEL MANAGEMENT
------------------------------------------------------------

local function loadLevel(levelNum)
    if levelNum > #levels then
        levelNum = 1 -- wrap around
    end
    currentLevel = levelNum
    gameWon = false
    gameLost = false
    undoStack = {}
    particles = {}

    initGrid()

    local lvl = levels[currentLevel]
    for _, item in ipairs(lvl.objects) do
        addObject(item[1], item[2], item[3])
    end

    parseRules()
end

local function saveState()
    local state = {}
    for y = 1, GRID_H do
        state[y] = {}
        for x = 1, GRID_W do
            state[y][x] = {}
            for _, obj in ipairs(grid[y][x]) do
                table.insert(state[y][x], { key = obj.key, x = obj.x, y = obj.y })
            end
        end
    end
    table.insert(undoStack, state)
    -- Limit undo history
    if #undoStack > 100 then
        table.remove(undoStack, 1)
    end
end

local function undo()
    if #undoStack == 0 then return end

    local state = table.remove(undoStack)
    grid = {}
    for y = 1, GRID_H do
        grid[y] = {}
        for x = 1, GRID_W do
            grid[y][x] = {}
            for _, saved in ipairs(state[y][x]) do
                table.insert(grid[y][x], { key = saved.key, x = saved.x, y = saved.y })
            end
        end
    end

    gameWon = false
    gameLost = false
    parseRules()
end

local function doMove(dx, dy)
    saveState()
    moveYou(dx, dy)
    parseRules()
    applyTransformations()
    parseRules() -- re-parse after transforms
    checkDefeat()
    checkSink()
    checkHotMelt()
    checkOpenShut()

    if checkWin() then
        gameWon = true
    elseif not checkYouExist() then
        gameLost = true
    end
end

------------------------------------------------------------
-- LOVE2D CALLBACKS
------------------------------------------------------------

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.keyboard.setKeyRepeat(false)
    loadLevel(1)
end

function love.update(dt)
    -- Update particles
    for i = #particles, 1, -1 do
        particles[i].timer = particles[i].timer - dt
        if particles[i].timer <= 0 then
            table.remove(particles, i)
        end
    end

    moveTimer = moveTimer - dt
end

function love.keypressed(key)
    if gameWon then
        if key == "return" or key == "space" then
            loadLevel(currentLevel + 1)
        end
        return
    end

    if gameLost then
        if key == "return" or key == "space" then
            loadLevel(currentLevel)
        end
        return
    end

    local dx, dy = 0, 0
    if key == "up" or key == "w" then
        dy = -1
    elseif key == "down" or key == "s" then
        dy = 1
    elseif key == "left" or key == "a" then
        dx = -1
    elseif key == "right" or key == "d" then
        dx = 1
    elseif key == "z" then
        undo()
        return
    elseif key == "r" then
        loadLevel(currentLevel)
        return
    elseif key == "escape" then
        love.event.quit()
        return
    elseif key == "n" then
        -- debug: next level
        loadLevel(currentLevel + 1)
        return
    end

    if dx ~= 0 or dy ~= 0 then
        doMove(dx, dy)
    end
end

function love.draw()
    -- Background
    love.graphics.setBackgroundColor(0.08, 0.08, 0.12)

    -- Calculate offset to center the grid (account for right panel)
    local gameAreaW = love.graphics.getWidth() - PANEL_WIDTH
    local offsetX = (gameAreaW - GRID_W * TILE) / 2
    local offsetY = (love.graphics.getHeight() - GRID_H * TILE) / 2

    love.graphics.push()
    love.graphics.translate(offsetX, offsetY)

    -- Draw grid lines (subtle)
    love.graphics.setColor(0.15, 0.15, 0.2)
    for x = 0, GRID_W do
        love.graphics.line(x * TILE, 0, x * TILE, GRID_H * TILE)
    end
    for y = 0, GRID_H do
        love.graphics.line(0, y * TILE, GRID_W * TILE, y * TILE)
    end

    -- Draw objects
    for y = 1, GRID_H do
        for x = 1, GRID_W do
            for _, obj in ipairs(grid[y][x]) do
                local def = OBJECTS[obj.key]
                if def then
                    local px = (x - 1) * TILE
                    local py = (y - 1) * TILE
                    local margin = 2

                    if isTextBlock(obj.key) then
                        -- Text blocks: outlined rectangle with text
                        love.graphics.setColor(def.color[1], def.color[2], def.color[3], 0.3)
                        love.graphics.rectangle("fill", px + margin, py + margin, TILE - margin * 2, TILE - margin * 2)
                        love.graphics.setColor(def.color[1], def.color[2], def.color[3], 1)
                        love.graphics.rectangle("line", px + margin, py + margin, TILE - margin * 2, TILE - margin * 2)

                        -- Draw text label
                        local font = love.graphics.getFont()
                        local text = def.name
                        -- Scale text to fit
                        local tw = font:getWidth(text)
                        local th = font:getHeight()
                        local scale = math.min((TILE - 6) / tw, (TILE - 6) / th)
                        scale = math.min(scale, 1)

                        love.graphics.push()
                        love.graphics.translate(px + TILE / 2, py + TILE / 2)
                        love.graphics.scale(scale, scale)
                        love.graphics.printf(text, -50, -th / 2, 100, "center")
                        love.graphics.pop()
                    else
                        -- Game objects: filled colored square
                        local r, g, b = def.color[1], def.color[2], def.color[3]

                        -- Highlight if YOU
                        if hasProperty(obj.key, "YOU") then
                            -- Pulsing glow
                            local pulse = math.sin(love.timer.getTime() * 4) * 0.2 + 0.8
                            love.graphics.setColor(r, g, b, 0.3 * pulse)
                            love.graphics.rectangle("fill", px - 1, py - 1, TILE + 2, TILE + 2)
                        end

                        love.graphics.setColor(r, g, b, 0.9)
                        love.graphics.rectangle("fill", px + margin, py + margin, TILE - margin * 2, TILE - margin * 2)

                        -- Draw object name small
                        love.graphics.setColor(0, 0, 0, 0.8)
                        local font = love.graphics.getFont()
                        local text = def.name
                        local tw = font:getWidth(text)
                        local th = font:getHeight()
                        local scale = math.min((TILE - 8) / tw, (TILE - 8) / th)
                        scale = math.min(scale, 0.8)

                        love.graphics.push()
                        love.graphics.translate(px + TILE / 2, py + TILE / 2)
                        love.graphics.scale(scale, scale)
                        love.graphics.printf(text, -50, -th / 2, 100, "center")
                        love.graphics.pop()
                    end
                end
            end
        end
    end

    -- Draw particles
    for _, p in ipairs(particles) do
        local alpha = p.timer / 0.5
        local size = (1 - alpha) * 12 + 4
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
        love.graphics.circle("fill", p.x, p.y, size)
    end

    love.graphics.pop()

    -- UI overlay
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.print(levels[currentLevel].name, 10, 2)

    -- Active rules display
    love.graphics.setColor(0.7, 0.7, 0.7, 0.6)
    local rulesText = "Rules: "
    for i, rule in ipairs(rules) do
        if rule.property then
            rulesText = rulesText .. rule.subject .. " IS " .. rule.property
        elseif rule.transform then
            rulesText = rulesText .. rule.subject .. " IS " .. rule.transform
        end
        if i < #rules then rulesText = rulesText .. " | " end
    end
    love.graphics.print(rulesText, 10, love.graphics.getHeight() - 18)

    -- Controls hint
    love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
    love.graphics.print("Arrow/WASD: Move | Z: Undo | R: Restart | N: Next Level | ESC: Quit", 10,
        love.graphics.getHeight() - 36)

    -- Right panel: character portrait
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local panelX = screenW - PANEL_WIDTH
    local panelPadding = 12

    -- Panel background
    love.graphics.setColor(0.12, 0.12, 0.18, 0.95)
    love.graphics.rectangle("fill", panelX, 0, PANEL_WIDTH, screenH)

    -- Panel border
    love.graphics.setColor(0.3, 0.3, 0.4, 1)
    love.graphics.line(panelX, 0, panelX, screenH)

    -- Tall portrait placeholder
    local portraitW = PANEL_WIDTH - panelPadding * 2
    local portraitH = portraitW * 2.5 -- tall portrait ratio
    local portraitX = panelX + panelPadding
    local portraitY = panelPadding

    -- Portrait background
    love.graphics.setColor(0.25, 0.25, 0.3, 1)
    love.graphics.rectangle("fill", portraitX, portraitY, portraitW, portraitH)

    -- Portrait border
    love.graphics.setColor(0.5, 0.5, 0.6, 1)
    love.graphics.rectangle("line", portraitX, portraitY, portraitW, portraitH)

    -- Placeholder label
    love.graphics.setColor(0.6, 0.6, 0.6, 1)
    local font = love.graphics.getFont()
    local label = "Character"
    local labelW = font:getWidth(label)
    love.graphics.print(label, portraitX + (portraitW - labelW) / 2, portraitY + portraitH / 2 - 6)

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)

    -- Win/Lose overlay
    if gameWon then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(1, 1, 0.2)
        local msg = "YOU WIN!"
        local font = love.graphics.getFont()
        love.graphics.push()
        love.graphics.translate(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2 - 20)
        love.graphics.scale(3, 3)
        love.graphics.printf(msg, -100, 0, 200, "center")
        love.graphics.pop()
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.printf("Press ENTER for next level", 0, love.graphics.getHeight() / 2 + 40,
            love.graphics.getWidth(), "center")
    elseif gameLost then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(0.9, 0.2, 0.2)
        local msg = "NO YOU!"
        local font = love.graphics.getFont()
        love.graphics.push()
        love.graphics.translate(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2 - 20)
        love.graphics.scale(3, 3)
        love.graphics.printf(msg, -100, 0, 200, "center")
        love.graphics.pop()
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.printf("Press ENTER to restart", 0, love.graphics.getHeight() / 2 + 40, love.graphics.getWidth(),
            "center")
    end
end
