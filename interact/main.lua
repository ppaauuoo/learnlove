Object = require "deps.classic"

local push = require 'deps.push'
local lurker = require 'deps.lurker'
local GameStateManager = require "deps.gamestateManager"

local RigidBlobSystem = require "systems.RigidBlobSystem"
local Mouse = require 'systems.Mouse'
local EditMode= require 'systems.EditMode'

GAME_WIDTH, GAME_HEIGHT = 432, 243

local activeState = {
  update = function(self, dt)
    edit_mode:update(dt)
    blob_system:update(dt)
    cursor:update(dt)
  end,

  draw = function(self)
    blob_system:draw()
    edit_mode:draw()
    cursor:draw()
  end,

  keypressed = function(self,key)
    edit_mode:keypressed(key)
  end,

  mousepressed = function(self,x,y,button)
    local lock = edit_mode:mousepressed(x,y,button)
    if not lock then
      blob_system:mousepressed(x,y,button)
    end
  end,

  mousereleased = function(self,x,y,button)
    blob_system:mousereleased(x,y,button)
  end,
}

local nothingState = {}

function initWindows()
  -- init font
  smallFont = love.graphics.newFont('assets/font.ttf', 8)
  mediumFont = love.graphics.newFont('assets/font.ttf', 16)
  love.graphics.setFont(smallFont)

  -- init windows
  windowWidth, windowHeight = love.window.getDesktopDimensions()
  windowWidth, windowHeight = windowWidth*.7, windowHeight*.7 --make the window a bit smaller than the screen itself
  love.window.setMode(windowWidth, windowHeight, {resizable=false, fullscreen=false, vsync=true})

  -- init resolution
  push:setupScreen(GAME_WIDTH,GAME_HEIGHT,windowWidth,windowHeight, {upscale = 'normal'})
end

function initSys()
  blob_system = RigidBlobSystem(15000)
  cursor = Mouse()
  edit_mode = EditMode()
end

-- autoreload
lurker.postswap = function(f)
  initSys()
end

function love.load()
    initWindows()
    initSys()
    GameStateManager:setState(activeState)
end

function love.update(dt)
  lurker.update()
  GameStateManager:update(dt)
end

function love.draw()
  GameStateManager:draw()
  push:start()


  push:finish()
end

function love.keypressed(key)
  GameStateManager:keypressed(key)
  if key == "return" then
    local state = GameStateManager:getState()
    if state ~= activeState then
      GameStateManager:setState(activeState)
    else
      GameStateManager:setState(nothingState)
    end
  end
end

function love.mousepressed(x, y, button)
  GameStateManager:mousepressed(x,y,button)
end

function love.mousereleased(x, y, button)
  GameStateManager:mousereleased(x,y,button)
end

