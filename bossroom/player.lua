-- player.lua: Player class
local Object = require("deps.classic")
local Combat = require("combat")
local Physics = require("components.physics")
local Health = require("components.health")
local Knockback = require("components.knockback")
local Sprite = require("components.sprite")
local Head = require("head")

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

    self.kickCooldown = 0

    self.walkSprites = Sprite.load("assets/helmet/helmet_walk_", 5, 0)
    self.attackSprites = Sprite.load("assets/helmet/helmet_attack_", 5, 0)
    self.animFrame = 0
    self.animTimer = 0

    self.attackEffect = love.graphics.newImage("assets/helmet/Attack.png")
    self.attackEffect:setFilter("nearest", "nearest")

    self.head = nil -- detached head entity, nil when attached
end

function Player:update(dt, boss)
    if self.state == "dead" then return end

    Health.update(self, dt)
    self.attackCooldown = math.max(0, self.attackCooldown - dt)
    self.dashCooldown = math.max(0, self.dashCooldown - dt)
    self.kickCooldown = math.max(0, self.kickCooldown - dt)

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

function Player:toggleHead()
    if self.head then
        if Head.canReattach(self.head, self) then
            Head.remove(self.head)
            self.head = nil
        end
    else
        self.head = Head.spawn(self)
    end
end

function Player:kickHead()
    if self.head and self.kickCooldown <= 0 then
        self.kickCooldown = 1.5
        Head.kick(self.head, self.facing)
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

return Player
