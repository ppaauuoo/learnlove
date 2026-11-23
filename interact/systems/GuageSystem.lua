local GuageSystem = Object:extend()

function GuageSystem:createGuage(x,y,guage,max,inc,dec)
  local g = {x=x, y=y, guage=guage, maxGuage=max, inc=inc, dec=dec}
  table.insert(self.guages, g)
end

function GuageSystem:new()
  self.guages = {}
  --init guage
  self:createGuage(750,100,190,190,0.2,0.05)
  self:createGuage(690,100,190,190,0.25,0.08)
end

function GuageSystem:update(_)
  local isDragging = blob_system.dragJoint ~= nil
  for _,g in ipairs(self.guages) do
    if g.guage > 0 and isDragging then
      g.guage = g.guage - g.inc
    elseif g.guage < g.maxGuage then
      g.guage = g.guage + g.dec
    end
  end
end

function GuageSystem:draw()
  for _,g in ipairs(self.guages) do
    love.graphics.setColor(1,1,1)
    love.graphics.rectangle("fill", g.x,g.y,50,g.maxGuage+10)
    love.graphics.setColor(0,0,0)
    love.graphics.rectangle("fill", g.x+5,g.y+5,40,g.guage)
  end
end

return GuageSystem
