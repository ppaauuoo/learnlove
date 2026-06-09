local Entity = require "entity"
local Enemy = Entity:extend() 

function Enemy:new()
  Enemy.super.new(self, 325, 450, 100, 50, 50)
end

function Enemy:update(dt)
  self.x = self.x + self.speed * dt
  local window_width = love.graphics.getWidth()

  -- if self.x < 0 then
  --   self.speed = -self.speed
  -- elseif self.x > window_width-self.width then
  --   self.speed = -self.speed
  -- end

  self:bound(self.direction_change)

end

function Enemy:direction_change()
    self.speed = -self.speed
end

return Enemy
