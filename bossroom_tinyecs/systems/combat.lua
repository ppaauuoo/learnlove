-- systems/combat.lua: AABB hitbox checks between all attackers and targets
local tiny = require("deps.tiny")
local Combat = require("combat")

local combatSystem = tiny.system()
combatSystem.filter = tiny.requireAny("isPlayer", "isBoss")
combatSystem.active = false

-- Collected entity refs (rebuilt each frame by onAdd/onRemove)
combatSystem.players = {}
combatSystem.bosses = {}

function combatSystem:onAdd(e)
    if e.isPlayer then table.insert(self.players, e) end
    if e.isBoss then table.insert(self.bosses, e) end
end

function combatSystem:onRemove(e)
    for i, v in ipairs(self.players) do if v == e then table.remove(self.players, i); break end end
    for i, v in ipairs(self.bosses) do if v == e then table.remove(self.bosses, i); break end end
end

local function aabb(a, b)
    return a.x < b.x + b.w and a.x + a.w > b.x and
           a.y < b.y + b.h and a.y + a.h > b.y
end

function combatSystem:update(dt)
    if not self.active then return end

    -- Player nail → every boss
    for _, player in ipairs(self.players) do
        if player.attackTimer > 0 then
            local ox = player.facing == 1 and player.w or -48
            local hb = { x = player.x + ox, y = player.y + (player.h - 36) / 2, w = 48, h = 36 }
            for _, boss in ipairs(self.bosses) do
                if boss.hp > 0 and aabb(hb, boss) then
                    Combat.resolveDamage(player, boss)
                end
            end
        end
    end

    -- Every boss hitbox → every player
    for _, boss in ipairs(self.bosses) do
        if boss.attackHitbox then
            for _, player in ipairs(self.players) do
                if player.iframes <= 0 and player.state ~= "dead" and aabb(boss.attackHitbox, player) then
                    Combat.resolveDamage(boss, player)
                end
            end
        end
    end
end

return combatSystem
