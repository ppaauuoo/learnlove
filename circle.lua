local Shape = require "shape"
local Circle = Shape:extend()

function Circle:new(x, y, r)
  Circle.super.new(self, x, y)
  self.r = r
end

function Circle:draw()
  love.graphics.circle("fill", self.x, self.y, self.r)
end

return Circle
