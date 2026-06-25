-- boss.lua: Boss class
local Object = require("deps.classic")
local Combat = require("combat")
local Physics = require("components.physics")
local Health = require("components.health")
local Knockback = require("components.knockback")
local Sprite = require("components.sprite")

-- Load sprites
-- frame 0: idle
-- frame 1-2: prepare/charge/pre-attack
-- frame 3: airborne (legs up)
local function loadSprites()
    return Sprite.load("assets/boss/bossv3_", 4, 0)
end

local Boss = Object:extend()

function Boss:new(world, x, y)
    Physics.init(self, world, x, y, 100, 200, "boss")
    Health.init(self, 30)
    Knockback.init(self)

    self.isPlayer = false
    self.phase = 1
    self.state = "idle"
    self.stateTimer = 1.0
    self.attackType = nil
    self.attackHitbox = nil
    self.attackWeights = {}

    self.hitsTaken = 0
    self.staggerThreshold = 12
    self.comboCount = 0
    self.leapCount = 0

    self.leapTarget = nil
    self.facing = 1
    self.sprites = loadSprites()
    self.spriteFrame = 0
    self.visible = true
    self.entranceActive = false
    self.entrancePhase = 0
    self.entranceTimer = 0
end

function Boss:update(dt, player)
    if self.hp <= 0 then
        if self.state ~= "dead" then
            SFX.bigGuyScream:play()
        end
        self.state = "dead"
        self.attackHitbox = nil
        return
    end

    if self.state == "entering" then
        self:updateEntrance(dt)
        return
    end

    Health.update(self, dt)

    -- Knockback (resisted while attacking)
    if self.state ~= "attack" and self.knockback.timer > 0 then
        self.knockback.timer = self.knockback.timer - dt
        self.vx = self.knockback.vx
        self.vy = self.knockback.vy
    end

    -- Gravity
    Physics.applyGravity(self, dt)

    -- Stagger check
    if self.state ~= "stagger" and self.hitsTaken >= self.staggerThreshold then
        SFX.critical:play()
        SFX.bigGuyScream:play()
        Combat.spawnParticles(self.x + self.w / 2, self.y + self.h / 2, 10)
        Combat.shake(0.15)
        self:enterState("stagger")
    end

    -- Phase check
    local hpPct = self.hp / self.maxHp
    if hpPct > 0.66 then
        self.phase = 1
    elseif hpPct > 0.33 then
        self.phase = 2
    else
        self.phase = 3
    end

    -- State machine
    self.stateTimer = self.stateTimer - dt

    if self.state == "idle" then
        self.attackHitbox = nil
        self.vx = 0
        if self.stateTimer <= 0 then
            self:pickAttack(player)
        end
    elseif self.state == "telegraph" then
        self.attackHitbox = nil
        self.vx = 0
        if self.stateTimer <= 0 then
            self:beginAttack(player)
        end
    elseif self.state == "attack" then
        self:updateAttack(dt, player)
        if self.stateTimer <= 0 then
            -- Screen shake on slam/shockwave impact
            if self.attackType == "slam" or self.attackType == "shockwave" then
                Combat.shake(0.15)
                SFX.smash:play()
            end
            if self.attackType == "leap" and self.phase == 3 and self.leapCount < 2 then
                self.leapCount = self.leapCount + 1
                self:enterState("telegraph")
                self.attackType = "leap"
            else
                self.leapCount = 0
                self:enterState("recovery")
            end
        end
    elseif self.state == "recovery" then
        self.attackHitbox = nil
        self.vx = 0
        if self.stateTimer <= 0 then
            if self.phase == 2 and self.comboCount < 1 then
                self.comboCount = self.comboCount + 1
                self:pickAttack(player)
            else
                self.comboCount = 0
                self:enterState("idle")
            end
        end
    elseif self.state == "stagger" then
        self.attackHitbox = nil
        self.vx = 0
        if self.stateTimer <= 0 then
            self.hitsTaken = 0
            self.comboCount = 0
            self.leapCount = 0
            self:enterState("idle")
        end
    end

    -- Face the player
    self.facing = player.x < self.x and -1 or 1

    -- Move boss
    local prevVx = self.vx
    if self.visible then
        Physics.move(self, dt)
    else
        Physics.moveRaw(self, dt)
    end

    -- Dash wall hit shake
    if self.state == "attack" and self.attackType == "dash" and prevVx ~= 0 and self.vx == 0 then
        Combat.shake(0.15)
    end

    -- Leap landing shake
    if self.state == "attack" and self.attackType == "leap" and self.onGround then
        Combat.shake(0.2)
    end

    -- Check boss attack hits player
    if self.attackHitbox and player.iframes <= 0 and player.state ~= "dead" then
        local hb = self.attackHitbox
        local px, py, pw, ph = player.x, player.y, player.w, player.h
        if hb.x < px + pw and hb.x + hb.w > px and hb.y < py + ph and hb.y + hb.h > py then
            Combat.resolveDamage(self, player, nil)
        end
    end
end

function Boss:startEntrance()
    self.state = "entering"
    self.entranceActive = true
    self.entrancePhase = 1
    self.entranceTimer = 0
    self.y = -300
    self.vy = 0
    self.vx = 0
    self.facing = -1
    self.world:update(self.item, self.x, self.y)
end

function Boss:updateEntrance(dt)
    if self.entrancePhase == 1 then
        -- Falling from above the screen
        self.vy = self.vy + 1200 * dt
        self.y = self.y + self.vy * dt
        self.world:update(self.item, self.x, self.y)
        -- Land on the boss room floor
        if self.y + self.h >= 680 then
            self.y = 680 - self.h
            self.vy = 0
            self.vx = 0
            self.onGround = true
            self.world:update(self.item, self.x, self.y)
            self:enterEntrancePhase(2)
        end
    elseif self.entrancePhase == 2 then
        self.entranceTimer = self.entranceTimer + dt
        -- At 0.75s: scream + shake while still at charge sprite, zoomed
        if self.entranceTimer >= 0.75 and not self._screamed then
            self._screamed = true
            SFX.bigGuyScream:play()
            Combat.shake(0.5)
        end
        -- At 1.5s total: snap back, go idle
        if self.entranceTimer >= 1.5 then
            self:enterEntrancePhase(3)
        end
    end
end

function Boss:enterEntrancePhase(phase)
    self.entrancePhase = phase
    if phase == 2 then
        SFX.smash:play()
        self._requestZoom = true
        self.entranceTimer = 0
    elseif phase == 3 then
        self._requestSnap = true
        self.state = "idle"
        self.stateTimer = 0.5 + math.random() * 1.0
        self.entranceActive = false
    end
end

function Boss:enterState(state)
    self.state = state
    self.attackHitbox = nil
    self.attackType = nil
    self.visible = true
    if state == "idle" then
        self.stateTimer = 0.5 + math.random() * 1.0
    elseif state == "telegraph" then
        self.stateTimer = 0.3 + math.random() * 0.2
    elseif state == "recovery" then
        self.stateTimer = 0.3 + math.random() * 0.3
    elseif state == "stagger" then
        self.stateTimer = self.phase == 1 and 2.0 or 1.0
    end
end

function Boss:pickAttack(player)
    -- Build pool: remove slam from phase 3, unlock rest by phase
    local available = { "dash" }
    if self.phase < 3 then table.insert(available, "slam") end
    if self.phase >= 2 then table.insert(available, "shockwave") end
    if self.phase >= 3 then table.insert(available, "leap") end

    -- Init weights for any new attacks
    for _, name in ipairs(available) do
        self.attackWeights[name] = self.attackWeights[name] or 1
    end

    -- Weighted random pick (higher weight = more likely)
    local total = 0
    for _, name in ipairs(available) do
        total = total + math.max(0.3, self.attackWeights[name])
    end
    local pick = math.random() * total
    self.attackType = available[#available]
    for _, name in ipairs(available) do
        pick = pick - math.max(0.3, self.attackWeights[name])
        if pick <= 0 then self.attackType = name; break end
    end

    -- Decay used attack, recover others
    for _, name in ipairs(available) do
        if name == self.attackType then
            self.attackWeights[name] = math.max(0.3, self.attackWeights[name] - 0.2)
        else
            self.attackWeights[name] = math.min(1, self.attackWeights[name] + 0.1)
        end
    end

    local chosenType = self.attackType
    self:enterState("telegraph")
    self.attackType = chosenType
end

function Boss:beginAttack(player)
    self.state = "attack"

    if self.attackType == "slam" then
        self.stateTimer = 0.6
        local targetX = player.x + player.w / 2 - self.w / 2
        self.vx = (targetX - self.x) / 0.3
        self.vy = -500
    elseif self.attackType == "dash" then
        if self.phase == 3 then
            self.stateTimer = 0.8
            local dir = player.x < self.x and -1 or 1
            self.vx = dir * 1000
        else
            self.stateTimer = 0.25
            local dir = player.x < self.x and -1 or 1
            self.vx = dir * 600
        end
    elseif self.attackType == "shockwave" then
        if self.phase == 3 then
            Particles.spawn(self.x + self.w / 2, self.y + self.h / 2, 15)
            self.x = 2680
            self.y = 480
            self.world:update(self.item, self.x, self.y)
            Particles.spawn(self.x + self.w / 2, self.y + self.h / 2, 15)
        end
        self.stateTimer = 0.15
        self.vx = 0
    elseif self.attackType == "leap" then
        self.stateTimer = 0.8
        self.leapTarget = { x = player.x, y = player.y }
        self.vy = -900
        self.visible = false
    end
end

function Boss:updateAttack(dt, player)
    if self.attackType == "slam" then
        self.attackHitbox = {
            x = self.x - 80,
            y = self.y + self.h,
            w = 260,
            h = 32
        }
    elseif self.attackType == "dash" then
        self.attackHitbox = {
            x = self.x,
            y = self.y,
            w = self.w,
            h = self.h
        }
    elseif self.attackType == "shockwave" then
        if self.phase == 3 then
            self.attackHitbox = {
                x = self.x - 300,
                y = self.y + self.h - 20,
                w = self.w + 600,
                h = 20
            }
        else
            local dir = player.x < self.x and -1 or 1
            local sx = dir == 1 and (self.x + self.w) or (self.x - 300)
            self.attackHitbox = {
                x = sx,
                y = self.y + self.h - 20,
                w = 300,
                h = 20
            }
        end
    elseif self.attackType == "leap" then
        if self.stateTimer < 0.4 then
            self.visible = true
            if self.leapTarget then
                self.x = self.leapTarget.x - self.w / 2
                self.leapTarget = nil
                self.vy = 800
            end
            self.attackHitbox = {
                x = self.x - 50,
                y = self.y,
                w = 200,
                h = 200
            }
        end
    end
end

function Boss:draw()
    if not self.visible then return end
    if self.hp <= 0 then return end

    -- Entrance animation: falling dark, then charge sprite freeze
    if self.state == "entering" then
        if self.entrancePhase == 1 then
            love.graphics.setColor(0.35, 0.35, 0.45)
            self.spriteFrame = 3
        elseif self.entrancePhase == 2 then
            love.graphics.setColor(1, 1, 1)
            self.spriteFrame = 2
        end
        Sprite.draw(self.sprites[self.spriteFrame], self.x, self.y, self.w, self.h, -self.facing)
        return
    end

    -- Choose sprite frame
    if self.state == "telegraph" then
        -- alternate between frame 1 and 2 during telegraph
        self.spriteFrame = math.floor(love.timer.getTime() * 10) % 2 == 0 and 1 or 2
    elseif not self.onGround then
        self.spriteFrame = 3
    else
        self.spriteFrame = 0
    end

    -- Tint
    if self.state == "telegraph" then
        love.graphics.setColor(1, 0.8, 0)
    elseif self.state == "stagger" then
        love.graphics.setColor(0.4, 0.4, 0.6)
    elseif self.flashTimer > 0 then
        love.graphics.setColor(1.3, 1.3, 1.3)
    else
        love.graphics.setColor(1, 1, 1)
    end

    Sprite.draw(self.sprites[self.spriteFrame], self.x, self.y, self.w, self.h, -self.facing)

    -- Attack hitbox visual
    if self.attackHitbox then
        love.graphics.setColor(1, 0.5, 0, 0.5)
        local hb = self.attackHitbox
        love.graphics.rectangle("fill", hb.x, hb.y, hb.w, hb.h)
    end

    -- HP bar
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", self.x - 10, self.y - 16, self.w + 20, 8)
    love.graphics.setColor(0.9, 0.1, 0.1)
    local pct = self.hp / self.maxHp
    love.graphics.rectangle("fill", self.x - 10, self.y - 16, (self.w + 20) * pct, 8)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", self.x - 10, self.y - 16, self.w + 20, 8)
end

return Boss
