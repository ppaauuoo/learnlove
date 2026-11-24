local UISystem = Object:extend()

require 'config'

local utils = require 'lib.utils'

local PrepState = require 'states.PrepState'

function UISystem:new()
  self.buttons = Button
  self.buttons.startBtn.onClick = function()
    PrepState:startBattle()
  end
end

function UISystem:draw()
  for _,btn in pairs(self.buttons) do
    local font = love.graphics.getFont()
    local text = love.graphics.newText(font, btn.text)
    local textWidht = text:getWidth()

    love.graphics.setColor(btn.color)
    love.graphics.rectangle("fill", btn.x, btn.y, textWidht*btn.textSize+10, btn.h)
    love.graphics.setColor(1,1,1)
    love.graphics.draw(text, btn.x+5, btn.y+5, 0, btn.textSize, btn.textSize)
  end
end

function UISystem:mousepressed(x,y,key)
  if key ~= 1 then
    return
  end

  for _,btn in pairs(self.buttons) do
    local font = love.graphics.getFont()
    local text = love.graphics.newText(font, btn.text)
    local textWidth = text:getWidth()
    if utils.pointInRect(x,y,btn.x,btn.y,textWidth,btn.h) then
      btn.onClick()
    end

  end


end


return UISystem
