-- entities.lua: Player + Boss classes (using reusable components)
local Object = require("deps.classic")
local Combat = require("combat")
local Physics = require("components.physics")
local Health = require("components.health")
local Knockback = require("components.knockback")
local Sprite = require("components.sprite")

-- ============================================================
-- PLAYER
-- ============================================================
local Player = Object:extend()

function Player:new(world, x, y)
    Physics.init(self, world, x, y, 50, 50, "player")
    Health.init(self, 5)
    Knockback.init(self)

    self.facing = 1
    self.isPlayer = true

    self.state = "idle" -- idle/run/jump/fall/attack/dash/hurt/dead
    self.jumpHeld = false
    self.jumpTimer = 0

    self.attackTimer = 0
    self.attackCooldown = 0

    self.dashTimer = 0
    self.dashCooldown = 0
    self.dashDir = 1

    self.walkSprites = Sprite.load("assets/helmet/helmet_walk_", 5, 0)
    self.attackSprites = Sprite.load("assets/helmet/helmet_attack_", 5, 0)
    self.animFrame = 0
    self.animTimer = 0

    self.attackEffect = love.graphics.newImage("assets/helmet/Attack.png")
    self.attackEffect:setFilter("nearest", "nearest")
end

function Player:update(dt, boss)
    if self.state == "dead" then return end

    Health.update(self, dt)
    self.attackCooldown = math.max(0, self.attackCooldown - dt)
    self.dashCooldown = math.max(0, self.dashCooldown - dt)

    -- Knockback
    if Knockback.update(self, dt) then
        Physics.move(self, dt)
        return
    end

    -- Dash state
    if self.state == "dash" then
        self.dashTimer = self.dashTimer - dt
        if self.dashTimer <= 0 then
            self.state = "fall"
            self.vx = 0
        else
            self.vx = self.dashDir * (150 / 0.17)
            self.vy = 0
            self.iframes = 0.05
        end
        Physics.move(self, dt)
        return
    end

    -- Horizontal movement
    local moveSpeed = 250
    self.vx = 0
    if love.keyboard.isDown("left", "a") then
        self.vx = -moveSpeed
        self.facing = -1
    elseif love.keyboard.isDown("right", "d") then
        self.vx = moveSpeed
        self.facing = 1
    end

    -- Gravity
    Physics.applyGravity(self, dt)

    -- Variable jump: cut short if key released
    if self.jumpTimer > 0 then
        self.jumpTimer = self.jumpTimer - dt
        if not love.keyboard.isDown("up", "w", "space") then
            self.jumpTimer = 0
            if self.vy < 0 then self.vy = self.vy * 0.5 end
        end
    end

    -- Attack timer
    if self.attackTimer > 0 then
        self.attackTimer = self.attackTimer - dt
    end

    -- Update state label
    if self.attackTimer > 0 then
        self.state = "attack"
    elseif self.onGround then
        self.state = self.vx ~= 0 and "run" or "idle"
    else
        self.state = self.vy < 0 and "jump" or "fall"
    end

    -- Advance animation timer (only during movement/attack)
    if self.state == "run" or self.state == "attack" then
        self.animTimer = self.animTimer + dt
    end

    Physics.move(self, dt)

    -- Check nail hit on boss
    if self.attackTimer > 0 and boss and boss.hp > 0 then
        local hb = self:getNailHitbox()
        local items, len = self.world:queryRect(hb.x, hb.y, hb.w, hb.h, function(item)
            return item.type == "boss"
        end)
        if len > 0 then
            Combat.resolveDamage(self, boss, nil)
        end
    end
end

function Player:jump()
    if self.state == "dead" or self.state == "dash" then return end
    if self.onGround then
        self.vy = -480
        self.onGround = false
        self.jumpTimer = 0.15
    end
end

function Player:attack()
    if self.state == "dead" or self.state == "dash" then return end
    if self.attackCooldown > 0 then return end
    self.attackTimer = 0.1
    self.attackCooldown = 0.41
    SFX.shortSwing:play()
end

function Player:dash()
    if self.state == "dead" then return end
    if self.dashCooldown > 0 then return end
    self.state = "dash"
    self.dashTimer = 0.17
    self.dashCooldown = 0.6
    self.dashDir = self.facing
    self.vy = 0
    SFX.dash:play()
end

function Player:getNailHitbox()
    local ox = self.facing == 1 and self.w or -48
    return {
        x = self.x + ox,
        y = self.y + (self.h - 36) / 2,
        w = 48,
        h = 36
    }
end

function Player:draw()
    if self.state == "dead" then return end

    -- Update animation frame
    if self.state == "run" or self.state == "attack" then
        self.animFrame = Sprite.pingpong(self.animTimer, 0.1, 4)
    else
        self.animFrame = 0
    end

    -- I-frame blink
    if self.iframes > 0 then
        local blink = math.floor(self.iframes * 30) % 3
        if blink == 0 then return end
    end

    -- Pick sprite set: attack when attacking, walk otherwise
    local sprites = (self.attackTimer > 0 or self.state == "attack") and self.attackSprites or self.walkSprites
    Sprite.draw(sprites[self.animFrame], self.x, self.y, self.w, self.h, self.facing)

    -- Attack effect sprite
    if self.attackTimer > 0 then
        local hb = self:getNailHitbox()
        Sprite.drawAt(self.attackEffect, hb.x, hb.y, hb.w, hb.h, self.facing)
    end
end

-- ============================================================
-- BOSS
-- ============================================================
local Boss = Object:extend()

-- Load sprites
-- frame 0: idle
-- frame 1-2: prepare/charge/pre-attack
-- frame 3: airborne (legs up)
local function loadSprites()
    return Sprite.load("assets/boss/boss_frame_", 4, 0)
end

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

    self.hitsTaken = 0
    self.staggerThreshold = 12
    self.comboCount = 0
    self.leapCount = 0

    self.leapTarget = nil
    self.facing = 1
    self.sprites = loadSprites()
    self.spriteFrame = 0
    self.visible = true
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

function Boss:enterState(state)
    self.state = state
    self.attackHitbox = nil
    self.attackType = nil
    self.visible = true
    self._leapShook = false

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
    local attacks = { "slam", "dash" }
    if self.phase >= 2 then table.insert(attacks, "shockwave") end
    if self.phase >= 3 then table.insert(attacks, "leap") end

    self:enterState("telegraph")
    self.attackType = attacks[math.random(#attacks)]
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
            self.x = 1950
            self.y = 480
            self.world:update(self.item, self.x, self.y)
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
        love.graphics.setColor(1, 1, 1)
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

return { Player = Player, Boss = Boss }
