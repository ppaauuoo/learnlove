-- systems/draw.lua: render all visible entities
local W = require("world")
local Sprite = require("sprite")

local function pingpong(timer, speed, max)
    local total = max * 2
    local t = math.floor(timer / speed) % total
    return t <= max and t or (total - t)
end

local function drawPlayer(id)
    local pos = W.pos[id]
    local p = W.player[id]
    local hp = W.health[id]
    if not pos or not p or not hp then return end
    if p.state == "dead" then return end

    -- Animate
    if p.state == "run" or p.state == "attack" then
        p.animFrame = pingpong(p.animTimer, 0.1, 4)
    else
        p.animFrame = 0
    end

    -- I-frame blink
    if hp.iframes > 0 then
        local blink = math.floor(hp.iframes * 30) % 3
        if blink == 0 then return end
    end

    local sprites = (p.attackTimer > 0 or p.state == "attack") and p.attackSprites or p.walkSprites
    Sprite.draw(sprites[p.animFrame], pos.x, pos.y, pos.w, pos.h, p.facing)

    -- Attack effect
    if p.attackTimer > 0 then
        local ox = p.facing == 1 and pos.w or -48
        local hx, hy, hw, hh = pos.x + ox, pos.y + (pos.h - 36) / 2, 48, 36
        Sprite.drawAt(p.attackEffect, hx, hy, hw, hh, p.facing)
    end
end

local function drawBoss(id)
    local pos = W.pos[id]
    local b = W.boss[id]
    local hp = W.health[id]
    if not pos or not b or not hp then return end
    if not b.visible or hp.hp <= 0 then return end

    -- Choose frame
    if b.state == "telegraph" or (b.attackType == "shockwave" and b.phase == 3 and b.stateTimer >= 0.15) then
        b.spriteFrame = math.floor(love.timer.getTime() * 10) % 2 == 0 and 1 or 2
    elseif W.phys[id] and not W.phys[id].onGround then
        b.spriteFrame = 3
    else
        b.spriteFrame = 0
    end

    -- Tint
    if b.state == "stagger" then
        love.graphics.setColor(0.4, 0.4, 0.6)
    elseif hp.flashTimer > 0 then
        love.graphics.setColor(1, 1, 1)
    else
        love.graphics.setColor(1, 1, 1)
    end

    Sprite.draw(b.sprites[b.spriteFrame], pos.x, pos.y, pos.w, pos.h, -b.facing)

    -- Attack hitbox visual
    if b.attackHitbox then
        love.graphics.setColor(1, 0.5, 0, 0.5)
        local hb = b.attackHitbox
        love.graphics.rectangle("fill", hb.x, hb.y, hb.w, hb.h)
    end

    -- HP bar above boss
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", pos.x - 10, pos.y - 16, pos.w + 20, 8)
    love.graphics.setColor(0.9, 0.1, 0.1)
    local pct = hp.hp / hp.maxHp
    love.graphics.rectangle("fill", pos.x - 10, pos.y - 16, (pos.w + 20) * pct, 8)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", pos.x - 10, pos.y - 16, pos.w + 20, 8)
end

return {
    player = drawPlayer,
    boss = drawBoss,
}
