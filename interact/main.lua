Object = require "classic"

local push = require 'push'
local lurker = require 'lurker'
local RigidBlobSystem = require "RigidBlobSystem"
local Mouse = require 'Mouse'
local EditMode= require 'EditMode'

GAME_WIDTH, GAME_HEIGHT = 432, 243

function init()
  blob_system = RigidBlobSystem(15000)
  cursor = Mouse()
  edit_mode = EditMode()
end

-- autoreload
lurker.postswap = function(f)
  init()
end

function love.load()
    -- init font
    smallFont = love.graphics.newFont('font.ttf', 8)
    mediumFont = love.graphics.newFont('font.ttf', 16)
    love.graphics.setFont(smallFont)

    -- init windows
    windowWidth, windowHeight = love.window.getDesktopDimensions()
    windowWidth, windowHeight = windowWidth*.7, windowHeight*.7 --make the window a bit smaller than the screen itself
    love.window.setMode(windowWidth, windowHeight, {resizable=false, fullscreen=false, vsync=true})

    -- init resolution
    push:setupScreen(GAME_WIDTH,GAME_HEIGHT,windowWidth,windowHeight, {upscale = 'normal'})

    --init system
    init()

end

function love.update(dt)
  lurker.update()

  edit_mode:update(dt)
  blob_system:update(dt)
  cursor:update(dt)

end

function love.draw()
  blob_system:draw()
  edit_mode:draw()
  cursor:draw()

  push:start()


  push:finish()

end

function love.keypressed(key)
  edit_mode:keypressed(key)

end

function love.mousepressed(x, y, button)
  local lock = edit_mode:mousepressed(x,y,button)
  if not lock then
    blob_system:mousepressed(x,y,button)
  end

end

function love.mousereleased(x, y, button)
  blob_system:mousereleased(x,y,button)

end

