-- systems/draw.lua: render player and boss entities
local Concord = require("deps.concord")
local Sprite = require("sprite")

local DrawSystem = Concord.system({
    players = {"playerInput", "playerSprites", "position", "health"},
    bosses = {"bossAI", "bossSprites", "position", "health", "physics"},
})

function DrawSystem:draw()
    -- Draw bosses
    for _, e in ipairs(self.bosses) do
        local b = e.bossAI
        local bs = e.bossSprites
        local pos = e.position
        local hp = e.health
        local phys = e.physics

        if not b.visible or hp.hp <= 0 then goto nextBoss end

        -- Choose sprite frame
        if b.state == "telegraph" or (b.attackType == "shockwave" and b.phase == 3 and b.stateTimer >= 0.15) then
            bs.spriteFrame = math.floor(love.timer.getTime() * 10) % 2 == 0 and 1 or 2
        elseif not phys.onGround then
            bs.spriteFrame = 3
        else
            bs.spriteFrame = 0
        end

        -- Tint
        if b.state == "stagger" then
            love.graphics.setColor(0.4, 0.4, 0.6)
        else
            love.graphics.setColor(1, 1, 1)
        end

        Sprite.draw(bs.sprites[bs.spriteFrame], pos.x, pos.y, pos.w, pos.h, -b.facing)

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

        ::nextBoss::
    end

    -- Draw players
    for _, e in ipairs(self.players) do
        local p = e.playerInput
        local ps = e.playerSprites
        local pos = e.position
        local hp = e.health

        if p.state == "dead" then goto nextPlayer end

        -- Animate
        if p.state == "run" or p.state == "attack" then
            p.animFrame = Sprite.pingpong(p.animTimer, 0.1, 4)
        else
            p.animFrame = 0
        end

        -- I-frame blink
        if hp.iframes > 0 then
            local blink = math.floor(hp.iframes * 30) % 3
            if blink == 0 then goto nextPlayer end
        end

        local sprites = (p.attackTimer > 0 or p.state == "attack") and ps.attackSprites or ps.walkSprites
        Sprite.draw(sprites[p.animFrame], pos.x, pos.y, pos.w, pos.h, p.facing)

        -- Attack effect
        if p.attackTimer > 0 then
            local ox = p.facing == 1 and pos.w or -48
            Sprite.drawAt(ps.attackEffect, pos.x + ox, pos.y + (pos.h - 36) / 2, 48, 36, p.facing)
        end

        ::nextPlayer::
    end
end

return DrawSystem
