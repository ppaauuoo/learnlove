Object = require "classic"

local push = require 'push'
local lurker = require 'lurker'
local RigidBlobSystem = require "RigidBlobSystem"
local Mouse = require 'Mouse'

GAME_WIDTH, GAME_HEIGHT = 432, 243
local windowWidth, windowHeight = love.window.getDesktopDimensions()
local smallFont = love.graphics.newFont('font.ttf', 8)

function init()
  blob_system = RigidBlobSystem(15000)
  cursor = Mouse()
end

-- autoreload
lurker.postswap = function(f)
  init()
end

function love.load()
    -- init font
    love.graphics.setFont(smallFont)

    -- init windows
    windowWidth, windowHeight = windowWidth*.7, windowHeight*.7 --make the window a bit smaller than the screen itself
    love.window.setMode(windowWidth, windowHeight, {resizable=false, fullscreen=false, vsync=true})

    -- init resolution
    push:setupScreen(GAME_WIDTH,GAME_HEIGHT,windowWidth,windowHeight, {upscale = 'normal'})

    --init system
    init()

end

function love.update(dt)
  lurker.update()

  cursor:update(dt)

  blob_system:update(dt)

end

function love.draw()
  cursor:draw()

  blob_system:draw()

  push:start()

  love.graphics.printf('test',0, 35,GAME_WIDTH/2,'center')

  push:finish()

end

function love.mousepressed(x, y, button)
  blob_system:mousepressed(x,y,button)

end

function love.mousereleased(x, y, button)
  blob_system:mousereleased(x,y,button)

end

