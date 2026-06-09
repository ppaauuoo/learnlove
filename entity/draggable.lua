local Entity = require "entity.core"
local Draggable = Entity:extend()

function Draggable:new(x, y, radius)
  self.x = x or 300
  self.y = y or 200
  Draggable.super.new(self, self.x, self.y)
  self.radius = radius or 20
  self.drag = false
end

function Draggable:draw()
  love.graphics.circle("fill", self.x, self.y, self.radius)
end

function Draggable:update(dt, mx, my)
  if self.drag then
    self.x = mx
    self.y = my
  end
end

function Draggable:dragging(btn)
  self.drag = (btn == 1)
end

function Draggable:mouseReleased(btn)
  if btn == 1 then
    self.drag = false
  end
end

function Draggable:collideWith(mx, my)
  local dx = mx - self.x
  local dy = my - self.y
  return dx*dx + dy*dy <= self.radius*self.radius
end

return Draggable
