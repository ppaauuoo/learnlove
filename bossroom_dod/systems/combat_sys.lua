-- systems/combat.lua: resolve player-nail → boss and boss-hitbox → player
local W = require("world")
local Combat = require("combat")

return function(dt, playerId, bossId, bossActive)
    if not bossActive then return end

    local ppos = W.pos[playerId]
    local pp = W.player[playerId]
    local php = W.health[playerId]
    local bpos = W.pos[bossId]
    local b = W.boss[bossId]
    local bhp = W.health[bossId]
    local bphys = W.phys[bossId]

    if not ppos or not pp or not php or not bpos or not b or not bhp then return end

    -- Player nail → boss
    if pp.attackTimer > 0 and bhp.hp > 0 then
        local ox = pp.facing == 1 and ppos.w or -48
        local hb = { x = ppos.x + ox, y = ppos.y + (ppos.h - 36) / 2, w = 48, h = 36 }

        if hb.x < bpos.x + bpos.w and hb.x + hb.w > bpos.x and
           hb.y < bpos.y + bpos.h and hb.y + hb.h > bpos.y then
            Combat.resolveDamage(ppos, bpos, bhp, W.kb[bossId], b)
        end
    end

    -- Boss hitbox → player
    if b.attackHitbox and php.iframes <= 0 and pp.state ~= "dead" then
        local hb = b.attackHitbox
        if hb.x < ppos.x + ppos.w and hb.x + hb.w > ppos.x and
           hb.y < ppos.y + ppos.h and hb.y + hb.h > ppos.y then
            Combat.resolveDamage(bpos, ppos, php, W.kb[playerId], nil)
        end
    end
end
