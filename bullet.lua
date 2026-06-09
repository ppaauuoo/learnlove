
local Entity = require "entity"
local Bullet = Entity:extend() 

function Bullet:new(x, y)
  Bullet.super.new(self, x, y, 700, 10, 10)
end

function Bullet:update(dt)
  self.y = self.y + self.speed * dt
end


return Bullet
