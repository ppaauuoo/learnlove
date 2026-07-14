-- systems/combat.lua: resolve player nail → boss and boss hitbox → player
local Concord = require("deps.concord")
local Combat = require("combat")

local CombatSystem = Concord.system({
    players = {"playerInput", "position", "health", "knockback"},
    bosses = {"bossAI", "position", "health", "knockback"},
})

function CombatSystem:update(dt)
    local playerEntity = self.players[1]
    local bossEntity = self.bosses[1]
    if not playerEntity or not bossEntity then return end

    local p = playerEntity.playerInput
    local ppos = playerEntity.position
    local php = playerEntity.health
    local pkb = playerEntity.knockback

    local b = bossEntity.bossAI
    local bpos = bossEntity.position
    local bhp = bossEntity.health
    local bkb = bossEntity.knockback

    -- Player nail → boss
    if p.attackTimer > 0 and bhp.hp > 0 then
        local ox = p.facing == 1 and ppos.w or -48
        local hb = { x = ppos.x + ox, y = ppos.y + (ppos.h - 36) / 2, w = 48, h = 36 }
        if hb.x < bpos.x + bpos.w and hb.x + hb.w > bpos.x and
           hb.y < bpos.y + bpos.h and hb.y + hb.h > bpos.y then
            Combat.resolveDamage(ppos, bpos, bhp, bkb, false, b)
        end
    end

    -- Boss hitbox → player
    if b.attackHitbox and php.iframes <= 0 and p.state ~= "dead" then
        local hb = b.attackHitbox
        if hb.x < ppos.x + ppos.w and hb.x + hb.w > ppos.x and
           hb.y < ppos.y + ppos.h and hb.y + hb.h > ppos.y then
            Combat.resolveDamage(bpos, ppos, php, pkb, true, nil)
        end
    end
end

return CombatSystem
