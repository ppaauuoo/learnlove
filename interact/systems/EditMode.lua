local EditMode = Object:extend()

require 'config'

local colors = Config.colors

local function pointInRect(px, py, rx, ry, rw, rh)
    return px >= rx and px <= rx + rw and
           py >= ry and py <= ry + rh
end

function EditMode:addObject()
  for _,btn in ipairs(self.button) do
    local selected = self.activeTool == btn.name
    if btn.name=="addBtn" and selected then
      btn.text = "[Add]"
      btn.color = colors.red
    elseif btn.name == "addBtn" then
      btn.text = "Add"
      btn.color = colors.blue
    end
  end
end

function EditMode:delObject()
  for _,btn in ipairs(self.button) do
    local selected = self.activeTool == btn.name
    if btn.name == "delBtn" and selected then
      btn.text = "[Del]"
      btn.color = colors.red
    elseif btn.name == "delBtn" then
      btn.text = "Del"
      btn.color = colors.blue
    end
  end
end

function EditMode:new()
  self.editMode = false
  self.activeTool = nil
  self.button = {
    {
      name = "addBtn",
      x = 100,
      y = 100,
      w = 100,
      h = 50,
      text = "Add",
      textSize = 3,
      color = colors.blue,
      func = self.addObject,
    },
    {
      name = "delBtn",
      x = 260,
      y = 100,
      w = 100,
      h = 50,
      text = "Del",
      textSize = 3,
      color = colors.blue,
      func = self.delObject,
    }
  }
end

function EditMode:update()
  if not self.editMode then
    return
  end

  if self.activeTool == "delBtn" and love.mouse.isDown(1) then
    local x,y = love.mouse.getPosition()
    blob_system:destroyStaticBlob(x,y)
  end

  for _,btn in ipairs(self.button) do
    btn.func(self)
  end

end

function EditMode:draw()
  if self.editMode then
    for _,btn in ipairs(self.button) do
      local text = love.graphics.newText(mediumFont, btn.text)
      local textWidht = text:getWidth()

      love.graphics.setColor(btn.color)
      love.graphics.rectangle("fill", btn.x, btn.y, textWidht*btn.textSize+5, btn.h)
      love.graphics.setColor(1,1,1)
      love.graphics.draw(text, btn.x+5, btn.y+5, 0, btn.textSize, btn.textSize)
    end
  end
end

function EditMode:keypressed(key)
  if key == "e" and love.keyboard.isDown("lctrl") then
    self.editMode = not self.editMode
    love.window.setTitle(self.editMode and "Edit Mode" or "")
  end
end

function EditMode:mousepressed(x, y, click)
  if not self.editMode or click ~= 1 then
    return false
  end

  for _,btn in ipairs(self.button) do
    if pointInRect(x, y, btn.x, btn.y, btn.w, btn.h) then
      if self.activeTool == btn.name then
        self.activeTool = nil
        return false
      end
      self.activeTool = btn.name
      return true
    end
  end

  if self.activeTool == "addBtn" then
    blob_system:createStaticBlob(x,y,100)
    return true
  end

  -- if self.activeTool == "delBtn" then
    -- move to update() for drag and del
  -- end
  -- 
  return false
end

return EditMode
