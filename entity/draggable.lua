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
    self.x = math.clamp(x, dt, mx)
    self.y = math.clamp(y, dt, my)
  end
end

function Draggable:mousepressed(x, y, btn)
  if btn == 1 then
    self.drag = true
  else
    self.drag = false
  end
end

function Draggable:collideWith(mx, my)
    local self_left = self.x
    local self_right = self.x + self.width
    local self_top = self.y
    local self_bottom = self.y + self.height

    if  self_right > mx
    and self_left < mx
    and self_bottom > my
    and self_top < my then
      return true
    end
end

return Draggable
