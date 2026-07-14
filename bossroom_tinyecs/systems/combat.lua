-- systems/combat.lua: check hitbox overlaps, resolve damage
local tiny = require("deps.tiny")
local Combat = require("combat")

local combatSystem = tiny.system()
combatSystem.filter = tiny.requireAll("isPlayer")

-- References set from main.lua
combatSystem.player = nil
combatSystem.boss = nil
combatSystem.active = false

function combatSystem:update(dt)
    if not self.active then return end

    local player = self.player
    local boss = self.boss
    if not player or not boss then return end

    -- Player nail → boss
    if player.attackTimer > 0 and boss.hp > 0 then
        local ox = player.facing == 1 and player.w or -48
        local hb = {
            x = player.x + ox,
            y = player.y + (player.h - 36) / 2,
            w = 48, h = 36,
        }
        if hb.x < boss.x + boss.w and hb.x + hb.w > boss.x and
           hb.y < boss.y + boss.h and hb.y + hb.h > boss.y then
            Combat.resolveDamage(player, boss)
        end
    end

    -- Boss hitbox → player
    if boss.attackHitbox and player.iframes <= 0 and player.state ~= "dead" then
        local hb = boss.attackHitbox
        if hb.x < player.x + player.w and hb.x + hb.w > player.x and
           hb.y < player.y + player.h and hb.y + hb.h > player.y then
            Combat.resolveDamage(boss, player)
        end
    end
end

return combatSystem
