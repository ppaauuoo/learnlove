local Shape = require "shape"
local Sheep = Shape:extend()

function Sheep:new(x, y, radian, xs, ys)
  Sheep.super.new(self, x, y)
  self.radian = radian or 0
  self.xs = xs or 1
  self.ys = ys or 1
  self.sprite = love.graphics.newImage("sheep.png")
  self.ox = self.sprite:getWidth()/2
  self.oy = self.sprite:getHeight()/2
end

function Sheep:draw()
  love.graphics.draw(self.sprite, self.x, self.y, self.radian, self.xs, self.ys, self.ox, self.oy)
end

return Sheep
