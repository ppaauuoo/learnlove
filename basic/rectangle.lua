local Shape = require "shape"
local Rectangle = Shape:extend()

function Rectangle:new(x, y, w, h, s)
  Rectangle.super.new(self, x, y, s)
  self.w = w
  self.h = h
end

function Rectangle:draw()
  love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
end

function checkCollision(a, b)
  return b.x <= a.x + a.w and a.x <= b.x + b.w and b.y <= a.y + a.h and a.y <= b.y + b.h
end

return Rectangle
