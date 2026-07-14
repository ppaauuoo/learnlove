-- systems/boss_ai.lua: boss state machine as a tiny-ecs system
local tiny = require("deps.tiny")
local Combat = require("combat")

local bossAISystem = tiny.processingSystem()
bossAISystem.filter = tiny.requireAll("isBoss", "vx", "vy", "physics")

-- Reference to the player entity (set from main.lua)
bossAISystem.player = nil
bossAISystem.active = false

local function enterState(e, state)
    e.bossState = state
    e.attackHitbox = nil
    e.attackType = nil
    e.visible = true
    e._leapShook = false

    if state == "idle" then
        e.stateTimer = 0.5 + math.random() * 1.0
    elseif state == "telegraph" then
        e.stateTimer = 0.3 + math.random() * 0.2
    elseif state == "recovery" then
        e.stateTimer = 0.3 + math.random() * 0.3
    elseif state == "stagger" then
        e.stateTimer = e.phase == 1 and 2.0 or 1.0
    end
end

local function pickAttack(e, player)
    local attacks = { "dash" }
    if e.phase < 3 then table.insert(attacks, "slam") end
    if e.phase >= 2 then table.insert(attacks, "shockwave") end
    if e.phase >= 3 then table.insert(attacks, "leap") end

    enterState(e, "telegraph")
    e.attackType = attacks[math.random(#attacks)]
end

local function beginAttack(e, player)
    e.bossState = "attack"

    if e.attackType == "slam" then
        e.stateTimer = 0.6
        local targetX = player.x + player.w / 2 - e.w / 2
        e.vx = (targetX - e.x) / 0.3
        e.vy = -500
    elseif e.attackType == "dash" then
        if e.phase == 3 then
            e.stateTimer = 0.8
            local dir = player.x < e.x and -1 or 1
            e.vx = dir * 1000
        else
            e.stateTimer = 0.25
            local dir = player.x < e.x and -1 or 1
            e.vx = dir * 600
        end
    elseif e.attackType == "shockwave" then
        if e.phase == 3 then
            e.x = 1950
            e.y = 480
            e.physics.bumpWorld:update(e.physics.item, e.x, e.y)
        end
        e.stateTimer = 0.65
        e.vx = 0
    elseif e.attackType == "leap" then
        e.stateTimer = 0.8
        e.leapTarget = { x = player.x, y = player.y }
        e.vy = -900
        e.visible = false
    end
end

local function updateAttack(e, player, dt)
    if e.attackType == "slam" then
        e.attackHitbox = { x = e.x - 80, y = e.y + e.h, w = 260, h = 32 }
    elseif e.attackType == "dash" then
        e.attackHitbox = { x = e.x, y = e.y, w = e.w, h = e.h }
    elseif e.attackType == "shockwave" then
        if e.phase == 3 then
            if e.stateTimer < 0.15 then
                e.attackHitbox = { x = e.x - 300, y = e.y + e.h - 20, w = e.w + 600, h = 20 }
            end
        else
            local dir = player.x < e.x and -1 or 1
            local sx = dir == 1 and (e.x + e.w) or (e.x - 300)
            e.attackHitbox = { x = sx, y = e.y + e.h - 20, w = 300, h = 20 }
        end
    elseif e.attackType == "leap" then
        if e.stateTimer < 0.4 then
            e.visible = true
            if e.leapTarget then
                e.x = e.leapTarget.x - e.w / 2
                e.leapTarget = nil
                e.vy = 800
            end
            e.attackHitbox = { x = e.x - 50, y = e.y, w = 200, h = 200 }
        end
    end
end

function bossAISystem:process(e, dt)
    if not self.active then return end

    local player = self.player
    if not player then return end

    if e.hp <= 0 then
        if e.bossState ~= "dead" then
            SFX.bigGuyScream:play()
        end
        e.bossState = "dead"
        e.attackHitbox = nil
        return
    end

    -- Knockback (resisted while attacking)
    if e.bossState ~= "attack" and e.knockback.timer > 0 then
        e.knockback.timer = e.knockback.timer - dt
        e.vx = e.knockback.vx
        e.vy = e.knockback.vy
    end

    -- Stagger check
    if e.bossState ~= "stagger" and e.hitsTaken >= e.staggerThreshold then
        SFX.critical:play()
        SFX.bigGuyScream:play()
        enterState(e, "stagger")
    end

    -- Phase check
    local hpPct = e.hp / e.maxHp
    if hpPct > 0.66 then e.phase = 1
    elseif hpPct > 0.33 then e.phase = 2
    else e.phase = 3 end

    -- State machine
    e.stateTimer = e.stateTimer - dt
    local prevVx = e.vx

    if e.bossState == "idle" then
        e.attackHitbox = nil
        e.vx = 0
        if e.stateTimer <= 0 then pickAttack(e, player) end
    elseif e.bossState == "telegraph" then
        e.attackHitbox = nil
        e.vx = 0
        if e.stateTimer <= 0 then beginAttack(e, player) end
    elseif e.bossState == "attack" then
        updateAttack(e, player, dt)
        if e.stateTimer <= 0 then
            if e.attackType == "slam" or e.attackType == "shockwave" then
                Combat.shake(0.15)
                SFX.smash:play()
            end
            if e.attackType == "leap" and e.phase == 3 and e.leapCount < 2 then
                e.leapCount = e.leapCount + 1
                enterState(e, "telegraph")
                e.attackType = "leap"
            else
                e.leapCount = 0
                enterState(e, "recovery")
            end
        end
    elseif e.bossState == "recovery" then
        e.attackHitbox = nil
        e.vx = 0
        if e.stateTimer <= 0 then
            if e.phase == 2 and e.comboCount < 1 then
                e.comboCount = e.comboCount + 1
                pickAttack(e, player)
            else
                e.comboCount = 0
                enterState(e, "idle")
            end
        end
    elseif e.bossState == "stagger" then
        e.attackHitbox = nil
        e.vx = 0
        if e.stateTimer <= 0 then
            e.hitsTaken = 0
            e.comboCount = 0
            e.leapCount = 0
            enterState(e, "idle")
        end
    end

    -- Face the player
    e.facing = player.x < e.x and -1 or 1

    -- Dash wall hit shake (after movement resolves, use prevVx)
    if e.bossState == "attack" and e.attackType == "dash" and prevVx ~= 0 and e.vx == 0 then
        Combat.shake(0.15)
    end

    -- Leap landing shake
    if e.bossState == "attack" and e.attackType == "leap" and e.physics.onGround and not e._leapShook then
        e._leapShook = true
        Combat.shake(0.2)
        SFX.smash:play()
    end
end

return bossAISystem
