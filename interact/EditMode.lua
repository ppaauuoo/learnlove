local EditMode = Object:extend()

local RigidBlobSystem require "RigidBlobSystem"

local editMode = false

local button = {}

local activeTool = nil

local colors = {
    red   = {1, 0, 0},
    green = {0, 1, 0, 0.8}, -- 80% opacity
    blue  = {0.2, 0.4, 1},
    white = {1, 1, 1}
}

function addObject()
  for _,btn in ipairs(button) do
    local selected = activeTool == btn.name
    if btn.name=="addBtn" and selected then
      btn.text = "[Add]"
      btn.color = colors.red
    elseif btn.name == "addBtn" then
      btn.text = "Add"
      btn.color = colors.blue
    end
  end
end

function delObject()
  for _,btn in ipairs(button) do
    local selected = activeTool == btn.name
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
  local addBtn = {
    name = "addBtn",
    x = 100,
    y = 100,
    w = 100,
    h = 50,
    text = "Add",
    textSize = 3,
    color = colors.blue,
    func = addObject,
  }
  table.insert(button, addBtn)


  local delBtn = {
    name = "delBtn",
    x = 260,
    y = 100,
    w = 100,
    h = 50,
    text = "Del",
    textSize = 3,
    color = colors.blue,
    func = delObject,
  }
  table.insert(button, delBtn)
end

function EditMode:update()
  if not editMode then
    return
  end

  if activeTool == "delBtn" and love.mouse.isDown(1) then
    local x,y = love.mouse.getPosition()
    blob_system:destroyStaticBlob(x,y)
  end

  for _,btn in ipairs(button) do
    btn.func()
  end

end

function EditMode:draw()
  if editMode then
    for _,btn in ipairs(button) do
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
    editMode = not editMode
    love.window.setTitle(editMode and "Edit Mode" or "")
  end
end

local function pointInRect(px, py, rx, ry, rw, rh)
    return px >= rx and px <= rx + rw and
           py >= ry and py <= ry + rh
end

function EditMode:mousepressed(x, y, click)
  if not editMode or click ~= 1 then
    return
  end

  for _,btn in ipairs(button) do
    if pointInRect(x, y, btn.x, btn.y, btn.w, btn.h) then
      if activeTool == btn.name then
        activeTool = nil
        return
      end
      activeTool = btn.name
      return
    end
  end

  if activeTool == "addBtn" then
    blob_system:createStaticBlob(x,y,100)
  end

  if activeTool == "delBtn" then
    -- move to update() for drag and del
  end

end

return EditMode
