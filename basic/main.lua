-- can be use only this file
local bigrect_state = require "bigrect"
if bigrect_state then
  print(bigrect_state)
end

local r1, r2, c1

function love.load()
  -- init global to use in muliple files
  tick = require "tick"
  local Rectangle = require "rectangle"
  local Circle = require "circle"
  local Sheep = require "sheep"

  r1 = Rectangle(100, 100, 200, 50, 100)
  r2 = Rectangle(500, 100, 200, 50, -100)

  c1 = Circle(350, 80, 40)

  sheep = Sheep(200, 200)
  listOfRectangles = {}
  drawRectangles = false
  -- delay 2 secion than draw rect
  tick.delay(function () drawRectangles = true end, 2)
end

function love.update(dt)
  -- update pos
  tick.update(dt)
  r1:update(dt)
  r2:update(dt)
  c1:update(dt)

  for i,v in ipairs(listOfRectangles) do
    v.x = v.x + v.s * dt
  end
end

function love.draw()
  -- draw graphic
  r1:draw(r1)
  r2:draw(r2)

  c1:draw(c1)
  sheep:draw(sheep)

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

