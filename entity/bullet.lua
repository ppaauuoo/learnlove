
local Entity = require "entity.core"
local Bullet = Entity:extend() 

function Bullet:new(x, y, w, h, speed, damage)
  self.width = w or 10
  self.height = h or 10
  self.speed = speed or 700
  Bullet.super.new(self, x-self.width/2, y-self.height/2, self.speed, self.width, self.height)

  self.damage = damage or 50
end

function Bullet:update(dt)
  self.y = self.y + self.speed * dt
end


return Bullet
