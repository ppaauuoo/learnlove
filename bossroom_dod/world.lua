-- world.lua: ECS world — entity IDs + component storage (struct-of-arrays)
local World = {}

World.nextId = 1

-- Component arrays (sparse tables keyed by entity id)
World.pos     = {}  -- {x, y, w, h}
World.vel     = {}  -- {vx, vy}
World.phys    = {}  -- {bumpWorld, item, onGround}
World.health  = {}  -- {hp, maxHp, iframes, flashTimer}
World.kb      = {}  -- {vx, vy, timer}
World.player  = {}  -- {facing, state, jumpTimer, jumpHeld, attackTimer, attackCooldown, dashTimer, dashCooldown, dashDir, animTimer, animFrame, walkSprites, attackSprites, attackEffect}
World.boss    = {}  -- {state, stateTimer, attackType, attackHitbox, phase, hitsTaken, staggerThreshold, comboCount, leapCount, leapTarget, facing, sprites, spriteFrame, visible, _leapShook}
World.tag     = {}  -- "player" | "boss" | "wall"

function World.spawn()
    local id = World.nextId
    World.nextId = World.nextId + 1
    return id
end

function World.destroy(id)
    World.pos[id] = nil
    World.vel[id] = nil
    World.phys[id] = nil
    World.health[id] = nil
    World.kb[id] = nil
    World.player[id] = nil
    World.boss[id] = nil
    World.tag[id] = nil
end

function World.reset()
    World.nextId = 1
    World.pos = {}
    World.vel = {}
    World.phys = {}
    World.health = {}
    World.kb = {}
    World.player = {}
    World.boss = {}
    World.tag = {}
end

return World
