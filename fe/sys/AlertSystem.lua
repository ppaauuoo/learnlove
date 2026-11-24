local AlertSystem = Object:extend()

require 'config'

function AlertSystem:addAlert(txt,time)
	local alert = {txt=txt, time=time}
	table.insert(self.alerts,alert)
	return true
end

function AlertSystem:new()
	self.alerts = {}
end

function AlertSystem:update(dt)
  if self.alerts then
    for i = #self.alerts, 1, -1 do
      if self.alerts[i].time >= 0 then
        self.alerts[i].time = self.alerts[i].time - dt
      else
        table.remove(self.alerts,i)
      end
    end
  end
end

function AlertSystem:draw()
  if not self.alerts then
    return
  end

  local w,h = push:getDimensions()
  local fontHeight = love.graphics.getFont():getHeight()

  love.graphics.setColor(Color.red)
  for i, v in ipairs(self.alerts) do
    love.graphics.printf(
      v.txt,
      0,
      (h-fontHeight) / 2 + (i - 1) * 24,
      w/2,
      "center"
    )
  end
end

return AlertSystem
