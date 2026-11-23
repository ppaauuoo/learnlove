require 'state'

Object = require "deps.classic"

local push = require 'deps.push'
local lurker = require 'deps.lurker'
local GameStateManager = require "deps.gamestateManager"

local RigidBlobSystem = require "systems.RigidBlobSystem"
local Mouse = require 'systems.Mouse'
local EditMode= require 'systems.EditMode'
local GuageSystem= require 'systems.GuageSystem'

GAME_WIDTH, GAME_HEIGHT = 432, 243


function initWindows()
  -- init font
  smallFont = love.graphics.newFont('assets/font.ttf', 8)
  mediumFont = love.graphics.newFont('assets/font.ttf', 16)
  love.graphics.setFont(smallFont)

  -- init windows
  windowWidth, windowHeight = love.window.getDesktopDimensions()
  windowWidth, windowHeight = windowWidth*.7, windowHeight*.7 --make the window a bit smaller than the screen itself
  love.window.setMode(windowWidth, windowHeight, {resizable=true, fullscreen=false, vsync=false})

  -- init resolution
  push:setupScreen(GAME_WIDTH,GAME_HEIGHT,windowWidth,windowHeight, {upscale = 'normal'})
end

function initSys()
  blob_system = RigidBlobSystem(15000)
  cursor = Mouse()
  edit_mode = EditMode()
  guage_system = GuageSystem()
end

-- autoreload
lurker.postswap = function(f)
  initSys()
end

function love.load()
    initWindows()
    initSys()
    GameStateManager:setState(ActiveState)
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
    if state == ActiveState then
      GameStateManager:setState(NothingState)
    else
      GameStateManager:revertState()
    end
  end
end

function love.mousepressed(x, y, button)
  GameStateManager:mousepressed(x,y,button)
end

function love.mousemoved(_,_,dx,dy)
  GameStateManager:mousemoved(nil,nil,dx,dy)
end

function love.mousereleased(x, y, button)
  GameStateManager:mousereleased(x,y,button)
end

