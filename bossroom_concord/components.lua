-- components.lua: All Concord component definitions
local Concord = require("deps.concord")

-- Position + size
Concord.component("position", function(c, x, y, w, h)
    c.x = x or 0
    c.y = y or 0
    c.w = w or 0
    c.h = h or 0
end)

-- Velocity
Concord.component("velocity", function(c, vx, vy)
    c.vx = vx or 0
    c.vy = vy or 0
end)

-- Bump physics binding
Concord.component("physics", function(c, bumpWorld, item)
    c.bumpWorld = bumpWorld
    c.item = item
    c.onGround = false
end)

-- Health + iframes
Concord.component("health", function(c, hp, maxHp)
    c.hp = hp or 1
    c.maxHp = maxHp or hp or 1
    c.iframes = 0
    c.flashTimer = 0
end)

-- Knockback state
Concord.component("knockback", function(c)
    c.vx = 0
    c.vy = 0
    c.timer = 0
end)

-- Player-specific state
Concord.component("playerInput", function(c)
    c.facing = 1
    c.state = "idle"
    c.jumpTimer = 0
    c.attackTimer = 0
    c.attackCooldown = 0
    c.dashTimer = 0
    c.dashCooldown = 0
    c.dashDir = 1
    c.animTimer = 0
    c.animFrame = 0
end)

-- Player sprites (separate so draw system can access)
Concord.component("playerSprites", function(c, walkSprites, attackSprites, attackEffect)
    c.walkSprites = walkSprites
    c.attackSprites = attackSprites
    c.attackEffect = attackEffect
end)

-- Boss AI state
Concord.component("bossAI", function(c)
    c.state = "idle"
    c.stateTimer = 1.0
    c.attackType = nil
    c.attackHitbox = nil
    c.phase = 1
    c.hitsTaken = 0
    c.staggerThreshold = 12
    c.comboCount = 0
    c.leapCount = 0
    c.leapTarget = nil
    c.facing = 1
    c.visible = true
    c._leapShook = false
end)

-- Boss sprites
Concord.component("bossSprites", function(c, sprites)
    c.sprites = sprites
    c.spriteFrame = 0
end)

-- Tag components (no data, just markers)
Concord.component("playerTag", function(c) end)
Concord.component("bossTag", function(c) end)
