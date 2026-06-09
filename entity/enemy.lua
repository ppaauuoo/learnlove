local Entity = require "entity.core"
local Enemy = Entity:extend() 

function Enemy:new(x, y, speed, width, height)
  Enemy.super.new(self, x or 325, y or 450, speed or 100, width or 50, height or 50)
end

function Enemy:update(dt)
  self.x = self.x + self.speed * dt

  self:bound(self.direction_change)
end

function Enemy:direction_change()
    self.speed = -self.speed
end

return Enemy
