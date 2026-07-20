-- entities.lua: factory functions that return plain tables (entities for tiny-ecs)
local Sprite = require("sprite")

local Entities = {}

function Entities.makePlayer(bumpWorld, x, y)
    local item = { type = "player" }
    bumpWorld:add(item, x, y, 50, 50)

    local e = {
        -- Position / size
        x = x, y = y, w = 50, h = 50,
        -- Velocity
        vx = 0, vy = 0,
        -- Physics (presence of this field = has physics)
        physics = { bumpWorld = bumpWorld, item = item, onGround = false },
        -- Health
        hp = 7, maxHp = 7, iframes = 0, flashTimer = 0,
        -- Knockback
        knockback = { vx = 0, vy = 0, timer = 0 },
        -- Player-specific
        isPlayer = true,
        facing = 1,
        state = "idle",
        jumpTimer = 0,
        attackTimer = 0,
        attackCooldown = 0,
        dashTimer = 0,
        dashCooldown = 0,
        dashDir = 1,
        animTimer = 0,
        animFrame = 0,
        walkSprites = Sprite.load("assets/helmet/helmet_walk_", 5, 0),
        attackSprites = Sprite.load("assets/helmet/helmet_attack_", 5, 0),
        attackEffect = (function()
            local img = love.graphics.newImage("assets/helmet/Attack.png")
            img:setFilter("nearest", "nearest")
            return img
        end)(),
    }
    item.entity = e
    return e
end

function Entities.makeBoss(bumpWorld, x, y)
    local item = { type = "boss" }
    bumpWorld:add(item, x, y, 100, 200)

    local e = {
        -- Position / size
        x = x, y = y, w = 100, h = 200,
        -- Velocity
        vx = 0, vy = 0,
        -- Physics
        physics = { bumpWorld = bumpWorld, item = item, onGround = false },
        -- Health
        hp = 45, maxHp = 45, iframes = 0, flashTimer = 0,
        -- Knockback
        knockback = { vx = 0, vy = 0, timer = 0 },
        -- Boss-specific (presence of this field = is a boss)
        isBoss = true,
        phase = 1,
        bossState = "idle",
        stateTimer = 1.0,
        attackType = nil,
        attackHitbox = nil,
        hitsTaken = 0,
        staggerThreshold = 12,
        comboCount = 0,
        leapCount = 0,
        leapTarget = nil,
        facing = 1,
        sprites = Sprite.load("assets/boss/boss_frame_", 4, 0),
        spriteFrame = 0,
        visible = true,
        _leapShook = false,
    }
    item.entity = e
    return e
end

return Entities
