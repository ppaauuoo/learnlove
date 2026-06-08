local Object = require "classic"
local Shape = Object:extend()

function Shape:new(x, y, s)
  self.x = x
  self.y = y
  self.s = s or 100
end

function Shape:update(dt)
  self.x = self.x + self.s * dt
end

return Shape
