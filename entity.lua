local Object = require "classic"
local Entity = Object:extend() 

function Entity:new(x, y, speed, width, height)
  self.x = x or 300
  self.y = y or 20
  self.speed = speed or 500
  self.width = width or 50
  self.height = height or 50
end

function Entity:draw()
  love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
end

function Entity:bound(after_func)
  local window_width = love.graphics.getWidth()
  if self.x < 0 then
    self.x = 0
    if after_func then
      after_func(self)
    end
  elseif self.x > window_width-self.width then
    self.x = window_width - self.width
    if after_func then
      after_func(self)
    end
  end
end

function Entity:collideWith(obj)
    local self_left = self.x
    local self_right = self.x + self.width
    local self_top = self.y
    local self_bottom = self.y + self.height

    local obj_left = obj.x
    local obj_right = obj.x + obj.width
    local obj_top = obj.y
    local obj_bottom = obj.y + obj.height

    if  self_right > obj_left
    and self_left < obj_right
    and self_bottom > obj_top
    and self_top < obj_bottom then
      return true
    end
end

return Entity
