local Shape = require "shape"
local Rectangle = Shape:extend()

function Rectangle:new(x, y, w, h)
  Rectangle.super.new(self, x, y)
  self.w = w
  self.h = h
end

function Rectangle:draw()
  love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
end

return Rectangle
