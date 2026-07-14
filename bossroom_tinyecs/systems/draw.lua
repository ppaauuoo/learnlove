-- systems/draw.lua: render entities (manual draw, not a tiny-ecs system)
local Sprite = require("sprite")

-- Draw system is NOT a processing system — it's called manually from love.draw()
-- We just export helper functions
local drawSystem = {}

function drawSystem:drawPlayer(e)
    if e.state == "dead" then return end

    -- Update animation frame
    if e.state == "run" or e.state == "attack" then
        e.animFrame = Sprite.pingpong(e.animTimer, 0.1, 4)
    else
        e.animFrame = 0
    end

    -- I-frame blink
    if e.iframes > 0 then
        local blink = math.floor(e.iframes * 30) % 3
        if blink == 0 then return end
    end

    -- Pick sprite set
    local sprites = (e.attackTimer > 0 or e.state == "attack") and e.attackSprites or e.walkSprites
    Sprite.draw(sprites[e.animFrame], e.x, e.y, e.w, e.h, e.facing)

    -- Attack effect
    if e.attackTimer > 0 then
        local ox = e.facing == 1 and e.w or -48
        Sprite.drawAt(e.attackEffect, e.x + ox, e.y + (e.h - 36) / 2, 48, 36, e.facing)
    end
end

function drawSystem:drawBoss(e)
    if not e.visible or e.hp <= 0 then return end

    -- Choose sprite frame
    if e.bossState == "telegraph" or (e.attackType == "shockwave" and e.phase == 3 and e.stateTimer >= 0.15) then
        e.spriteFrame = math.floor(love.timer.getTime() * 10) % 2 == 0 and 1 or 2
    elseif not e.physics.onGround then
        e.spriteFrame = 3
    else
        e.spriteFrame = 0
    end

    -- Tint
    if e.bossState == "stagger" then
        love.graphics.setColor(0.4, 0.4, 0.6)
    else
        love.graphics.setColor(1, 1, 1)
    end

    Sprite.draw(e.sprites[e.spriteFrame], e.x, e.y, e.w, e.h, -e.facing)

    -- Attack hitbox visual
    if e.attackHitbox then
        love.graphics.setColor(1, 0.5, 0, 0.5)
        local hb = e.attackHitbox
        love.graphics.rectangle("fill", hb.x, hb.y, hb.w, hb.h)
    end

    -- HP bar above boss
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", e.x - 10, e.y - 16, e.w + 20, 8)
    love.graphics.setColor(0.9, 0.1, 0.1)
    local pct = e.hp / e.maxHp
    love.graphics.rectangle("fill", e.x - 10, e.y - 16, (e.w + 20) * pct, 8)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", e.x - 10, e.y - 16, e.w + 20, 8)
end

return drawSystem
