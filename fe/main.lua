Object = require 'lib.classic'
push = require 'lib.push'

local lurker = require 'lib.lurker'
local GameStateManager = require 'lib.stateman'

local TileMapSystem = require 'sys.TileMapSystem'
local ActorSystem =  require 'sys.ActorSystem'
local AlertSystem =  require 'sys.AlertSystem'

require 'config'

GAME_WIDTH, GAME_HEIGHT = 1080, 720 --fixed game resolution
CELLSIZE = 16

local windowWidth, windowHeight = love.window.getDesktopDimensions()

push:setupScreen(GAME_WIDTH, GAME_HEIGHT, windowWidth, windowHeight, {fullscreen = true})


local function initSys()
  Tilemaps = TileMapSystem()
  Actors = ActorSystem()
  Alerts = AlertSystem()
end

-- autoreload
lurker.postswap = function(f)
  initSys()
end

function love.load()
  initSys()
  GameStateManager:setState(GameState)
end

function love.update(dt)
  lurker:update()
  GameStateManager:update(dt)
end

function love.draw()
  push:start()
  GameStateManager:draw()
  push:finish()
end

function love.mousepressed(x,y,key)
  GameStateManager:mousepressed(x,y,key)
end
