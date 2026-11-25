local UISystem = Object:extend()

require 'config'
require 'status'

local utils = require 'lib.utils'

local PrepState = require 'states.PrepState'

function UISystem:actorMenu(x, y)
  self.menu = {
    x = x + CELLSIZE + 4, -- beside the cell
    y = y,
    cellX = x,
    cellY = y,
    width = 120,
    height = 24,
    items = Character
  }
end

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

  local menu = self.menu
  if menu then
    for i, character in ipairs(menu.items) do
      local rowY = menu.y + (i - 1) * menu.height

      love.graphics.setColor(0.15, 0.15, 0.15, 1)
      love.graphics.rectangle(
        "fill", menu.x, rowY, menu.width, menu.height
      )

      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.print(character.name, menu.x + 6, rowY + 4)
    end
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


  local menu = self.menu
  if menu then
    for i, character in ipairs(menu.items) do
      local rowY = menu.y + (i - 1) * menu.height

      if utils.pointInRect(
        x, y, menu.x, rowY, menu.width, menu.height
      ) then
        local actor = {
          character = character,
          x = menu.cellX,
          y = menu.cellY
        }

        table.insert(Actors.actors, actor)
        self.menu = nil
        return true -- click handled
      end
    end
  end

end


return UISystem
