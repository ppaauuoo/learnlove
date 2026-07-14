-- assemblages.lua: entity construction functions
local Sprite = require("sprite")

local Assemblages = {}

function Assemblages.player(e, bumpWorld, x, y)
    local item = { type = "player", entity = e }
    bumpWorld:add(item, x, y, 50, 50)

    e:give("position", x, y, 50, 50)
     :give("velocity", 0, 0)
     :give("physics", bumpWorld, item)
     :give("health", 7, 7)
     :give("knockback")
     :give("playerInput")
     :give("playerSprites",
        Sprite.load("assets/helmet/helmet_walk_", 5, 0),
        Sprite.load("assets/helmet/helmet_attack_", 5, 0),
        (function()
            local img = love.graphics.newImage("assets/helmet/Attack.png")
            img:setFilter("nearest", "nearest")
            return img
        end)()
     )
     :give("playerTag")
end

function Assemblages.boss(e, bumpWorld, x, y)
    local item = { type = "boss", entity = e }
    bumpWorld:add(item, x, y, 100, 200)

    e:give("position", x, y, 100, 200)
     :give("velocity", 0, 0)
     :give("physics", bumpWorld, item)
     :give("health", 45, 45)
     :give("knockback")
     :give("bossAI")
     :give("bossSprites", Sprite.load("assets/boss/boss_frame_", 4, 0))
     :give("bossTag")
end

return Assemblages
