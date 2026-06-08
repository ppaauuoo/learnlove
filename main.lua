-- can be use only this file
local bigrect_state = require "bigrect"
if bigrect_state then
  print(bigrect_state)
end

function love.load()
  -- init global to use in muliple files
  tick = require "tick"
  listOfRectangles = {}
  drawRectangles = false
  -- delay 2 secion than draw rect
  tick.delay(function () drawRectangles = true end, 2)
end

function love.update(dt)
  -- update pos
  tick.update(dt)
  for i,v in ipairs(listOfRectangles) do
    v.x = v.x + v.s * dt
  end
end

function love.draw()
  -- draw graphic
  for i,v in ipairs(listOfRectangles) do
    love.graphics.rectangle("fill", v.x, v.y, v.w, v.h)
  end
  if drawRectangles then
    love.graphics.rectangle("fill", 400,400,300,200)
  end
end

function love.keypressed(key)
  if key == "space" then
    createRect()
  end
  if key == "d" then
    -- from bigrect
    createBigRect()
  end
end

function createRect()
  rect={}
  rect.x=math.random(100,500)
  rect.y=math.random(100,500)
  rect.w=100
  rect.h=100
  rect.s=100

  table.insert(listOfRectangles, rect)
end

