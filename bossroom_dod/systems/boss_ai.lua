-- systems/boss_ai.lua: boss state machine as a system
local W = require("world")
local Combat = require("combat")

local function enterState(b, state)
    b.state = state
    b.attackHitbox = nil
    b.attackType = nil
    b.visible = true
    b._leapShook = false

    if state == "idle" then
        b.stateTimer = 0.5 + math.random() * 1.0
    elseif state == "telegraph" then
        b.stateTimer = 0.3 + math.random() * 0.2
    elseif state == "recovery" then
        b.stateTimer = 0.3 + math.random() * 0.3
    elseif state == "stagger" then
        b.stateTimer = b.phase == 1 and 2.0 or 1.0
    end
end

local function pickAttack(b, ppos)
    local attacks = { "dash" }
    if b.phase < 3 then table.insert(attacks, "slam") end
    if b.phase >= 2 then table.insert(attacks, "shockwave") end
    if b.phase >= 3 then table.insert(attacks, "leap") end

    enterState(b, "telegraph")
    b.attackType = attacks[math.random(#attacks)]
end

local function beginAttack(b, pos, vel, phys, ppos)
    b.state = "attack"

    if b.attackType == "slam" then
        b.stateTimer = 0.6
        local targetX = ppos.x + ppos.w / 2 - pos.w / 2
        vel.vx = (targetX - pos.x) / 0.3
        vel.vy = -500
    elseif b.attackType == "dash" then
        if b.phase == 3 then
            b.stateTimer = 0.8
            local dir = ppos.x < pos.x and -1 or 1
            vel.vx = dir * 1000
        else
            b.stateTimer = 0.25
            local dir = ppos.x < pos.x and -1 or 1
            vel.vx = dir * 600
        end
    elseif b.attackType == "shockwave" then
        if b.phase == 3 then
            pos.x = 1950
            pos.y = 480
            phys.bumpWorld:update(phys.item, pos.x, pos.y)
        end
        b.stateTimer = 0.65
        vel.vx = 0
    elseif b.attackType == "leap" then
        b.stateTimer = 0.8
        b.leapTarget = { x = ppos.x, y = ppos.y }
        vel.vy = -900
        b.visible = false
    end
end

local function updateAttack(b, pos, ppos, dt)
    if b.attackType == "slam" then
        b.attackHitbox = { x = pos.x - 80, y = pos.y + pos.h, w = 260, h = 32 }
    elseif b.attackType == "dash" then
        b.attackHitbox = { x = pos.x, y = pos.y, w = pos.w, h = pos.h }
    elseif b.attackType == "shockwave" then
        if b.phase == 3 then
            if b.stateTimer < 0.15 then
                b.attackHitbox = { x = pos.x - 300, y = pos.y + pos.h - 20, w = pos.w + 600, h = 20 }
            end
        else
            local dir = ppos.x < pos.x and -1 or 1
            local sx = dir == 1 and (pos.x + pos.w) or (pos.x - 300)
            b.attackHitbox = { x = sx, y = pos.y + pos.h - 20, w = 300, h = 20 }
        end
    elseif b.attackType == "leap" then
        if b.stateTimer < 0.4 then
            b.visible = true
            if b.leapTarget then
                pos.x = b.leapTarget.x - pos.w / 2
                b.leapTarget = nil
                local vel = W.vel[b._entityId]
                if vel then vel.vy = 800 end
            end
            b.attackHitbox = { x = pos.x - 50, y = pos.y, w = 200, h = 200 }
        end
    end
end

return function(dt, playerId)
    local ppos = W.pos[playerId]
    if not ppos then return end

    for id, b in pairs(W.boss) do
        local pos = W.pos[id]
        local vel = W.vel[id]
        local phys = W.phys[id]
        local hp = W.health[id]
        if not pos or not vel or not phys or not hp then goto continue end

        b._entityId = id  -- stash for leap callback

        if hp.hp <= 0 then
            if b.state ~= "dead" then
                SFX.bigGuyScream:play()
            end
            b.state = "dead"
            b.attackHitbox = nil
            goto continue
        end

        -- Knockback (resisted while attacking)
        local kb = W.kb[id]
        if b.state ~= "attack" and kb and kb.timer > 0 then
            kb.timer = kb.timer - dt
            vel.vx = kb.vx
            vel.vy = kb.vy
        end

        -- Stagger check
        if b.state ~= "stagger" and b.hitsTaken >= b.staggerThreshold then
            SFX.critical:play()
            SFX.bigGuyScream:play()
            enterState(b, "stagger")
        end

        -- Phase
        local hpPct = hp.hp / hp.maxHp
        if hpPct > 0.66 then b.phase = 1
        elseif hpPct > 0.33 then b.phase = 2
        else b.phase = 3 end

        -- State machine
        b.stateTimer = b.stateTimer - dt
        local prevVx = vel.vx

        if b.state == "idle" then
            b.attackHitbox = nil
            vel.vx = 0
            if b.stateTimer <= 0 then pickAttack(b, ppos) end
        elseif b.state == "telegraph" then
            b.attackHitbox = nil
            vel.vx = 0
            if b.stateTimer <= 0 then beginAttack(b, pos, vel, phys, ppos) end
        elseif b.state == "attack" then
            updateAttack(b, pos, ppos, dt)
            if b.stateTimer <= 0 then
                if b.attackType == "slam" or b.attackType == "shockwave" then
                    Combat.shake(0.15)
                    SFX.smash:play()
                end
                if b.attackType == "leap" and b.phase == 3 and b.leapCount < 2 then
                    b.leapCount = b.leapCount + 1
                    enterState(b, "telegraph")
                    b.attackType = "leap"
                else
                    b.leapCount = 0
                    enterState(b, "recovery")
                end
            end
        elseif b.state == "recovery" then
            b.attackHitbox = nil
            vel.vx = 0
            if b.stateTimer <= 0 then
                if b.phase == 2 and b.comboCount < 1 then
                    b.comboCount = b.comboCount + 1
                    pickAttack(b, ppos)
                else
                    b.comboCount = 0
                    enterState(b, "idle")
                end
            end
        elseif b.state == "stagger" then
            b.attackHitbox = nil
            vel.vx = 0
            if b.stateTimer <= 0 then
                b.hitsTaken = 0
                b.comboCount = 0
                b.leapCount = 0
                enterState(b, "idle")
            end
        end

        -- Face the player
        b.facing = ppos.x < pos.x and -1 or 1

        -- Dash wall hit shake
        if b.state == "attack" and b.attackType == "dash" and prevVx ~= 0 and vel.vx == 0 then
            Combat.shake(0.15)
        end

        -- Leap landing shake
        if b.state == "attack" and b.attackType == "leap" and phys.onGround and not b._leapShook then
            b._leapShook = true
            Combat.shake(0.2)
            SFX.smash:play()
        end

        ::continue::
    end
end
