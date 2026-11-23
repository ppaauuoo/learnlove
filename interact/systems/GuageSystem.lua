local GuageSystem = Object:extend()

require 'config'

function GuageSystem:createGuage(x,y,guage,max,inc,dec,color)
  local g = {x=x, y=y, guage=guage, maxGuage=max, inc=inc, dec=dec, color=color}
  table.insert(self.guages, g)
end

function GuageSystem:new()
  self.guages = {}
  --init guage
  for _,v in ipairs(Config.gauges) do
    self:createGuage(unpack(v))
  end
end

local function clamp(min, val, max)
  return math.max(min,math.min(val,max))
end

function GuageSystem:update(dt)
  self.isDragging = blob_system.dragJoint ~= nil and self.isMoving
  for _,g in ipairs(self.guages) do
    if self.isDragging then
      g.guage = clamp(0, g.guage + g.inc*dt*self.moveSpeed, g.maxGuage)
    else
      g.guage = clamp(0, g.guage - g.dec*dt, g.maxGuage)
    end
    self.isMoving = false -- 1 move per 1 guage update
  end
end


function GuageSystem:mousemoved(_,_,dx,dy)
  if dx or dy then
    self.isMoving = true
    self.moveSpeed = math.max(dx,dy)
  else
    self.isMoving = false
  end
end

function GuageSystem:draw()
  for _,g in ipairs(self.guages) do
    love.graphics.setColor(1,1,1)
    love.graphics.rectangle("fill", g.x,g.y,50,g.maxGuage+10)
    love.graphics.setColor(0,0,0)
    love.graphics.rectangle("fill", g.x+5,g.y+5,40,g.maxGuage)
    love.graphics.setColor(g.color)
    love.graphics.rectangle("fill", g.x+5,g.y+5+g.maxGuage,40,-g.guage)
  end
end

return GuageSystem
