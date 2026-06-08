local Shape = require "shape"
local Sheep = Shape:extend()

function Sheep:new(x, y, r)
  Sheep.super.new(self, x, y)
  self.sprite = love.graphics.newImage("sheep.png")
end

function Sheep:draw()
  love.graphics.draw(self.sprite, self.x, self.y)
end

return Sheep
