-- global lib
Object = require 'lib.classic'
push = require 'lib.push'

-- states
GameStateManager = require 'lib.stateman'
PrepState = require 'states.PrepState'
BattleState = require 'states.BattleState'

-- helpers
local lurker = require 'lib.lurker'

-- systems
local TileMapSystem = require 'sys.TileMapSystem'
local ActorSystem =  require 'sys.ActorSystem'
local AlertSystem =  require 'sys.AlertSystem'
local UISystem = require 'sys.UISystem'


GAME_WIDTH, GAME_HEIGHT = 1080, 720 --fixed game resolution
CELLSIZE = 16

local windowWidth, windowHeight = love.window.getDesktopDimensions()

push:setupScreen(GAME_WIDTH, GAME_HEIGHT, windowWidth, windowHeight, {fullscreen = true})


local function initSys()
  Tilemaps = TileMapSystem()
  Actors = ActorSystem()
  UIs = UISystem()
  Alerts = AlertSystem()
end

-- autoreload
lurker.postswap = function(f)
  initSys()
end

function love.load()
  initSys()
  GameStateManager:setState(PrepState)
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

function love.resize(w,h)
  push:resize(w,h)
end
