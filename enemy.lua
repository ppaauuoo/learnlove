local Entity = require "entity"
local Enemy = Entity:extend() 

function Enemy:new()
  Enemy.super.new(self, 325, 450, 100, 50, 50)
end

function Enemy:update(dt)
  self.x = self.x + self.speed * dt

  self:bound(self.direction_change)
end

function Enemy:direction_change()
    self.speed = -self.speed
end

return Enemy
