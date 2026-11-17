local push = require 'push'
local lurker = require 'lurker'
local loveblobs = require "loveblobs"

GAME_WIDTH, GAME_HEIGHT = 432, 243
local windowWidth, windowHeight = love.window.getDesktopDimensions()
local smallFont = love.graphics.newFont('font.ttf', 8)

local world
local softbodies = {}

local mouseState

function initPhysics()
    --init world
    love.physics.setMeter(16)
    world  = love.physics.newWorld(0, 0, true)
    mouseWorld  = love.physics.newWorld(0, 0, true)

    --init softblob
    local b = loveblobs.softbody(world, 40, 30, 10, 2, 4)
    b:setFrequency(1)
    b:setDamping(0.1)
    b:setFriction(1)
    table.insert(softbodies, b)

end

function initMouse()
    --init body and shape
    body = love.physics.newBody(mouseWorld,love.mouse.getX(), love.mouse.getY(), "dynamic")
    shape = love.physics.newCircleShape(5)
    -- attach shape to body
    fixture = love.physics.newFixture(body,shape)
    -- joint body with mouse
    joint = love.physics.newMouseJoint(body, love.mouse.getPosition())
end

-- autoreload
lurker.postswap = function(f)
  initPhysics()
  initMouse()
end


function love.mousepressed(x,y,btn)
  -- if btn == "1" then
  -- end
  fixture:testPoint(x,y)
  mouseJoint = love.physics.newMouseJoint(body, x, y)
end

function love.load()
    -- init font
    love.graphics.setFont(smallFont)

    -- init windows
    windowWidth, windowHeight = windowWidth*.7, windowHeight*.7 --make the window a bit smaller than the screen itself
    love.window.setMode(windowWidth, windowHeight, {resizable=false, fullscreen=false, vsync=true})

    -- init resolution
    push:setupScreen(GAME_WIDTH,GAME_HEIGHT,windowWidth,windowHeight, {upscale = 'normal'})

    --init physics world
    initPhysics()
    initMouse()

end

function love.update(dt)
  lurker.update()

  :setTarget(love.mouse.getPosition())
  for i=1,4 do
    world:update(dt)
  end

  for i,v in ipairs(softbodies) do
    v:update(dt)
  end

end

function love.draw()
  --render mouse
  love.graphics.circle("fill",body:getX(),body:getY(),shape:getRadius())

  -- render softbodies
  for i,v in ipairs(softbodies) do
    love.graphics.setColor(50*i, 100, 200*i)
    if (tostring(v) == "softbody") then
      v:draw("fill",false)
    else
      v:draw(false)
    end
  end

  push:start()

  love.graphics.printf('test',0, 35,GAME_WIDTH/2,'center')

  push:finish()
end

