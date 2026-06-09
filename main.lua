local Player
local Enemy

function love.load()
  Player = require "player"
  Enemy = require "enemy"
  player = Player()
  enemy = Enemy()
end

function love.update(dt)
  player:update(dt)
  enemy:update(dt)
end

function love.draw()
  player:draw()
  enemy:draw()
end
