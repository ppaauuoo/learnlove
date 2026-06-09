local Player
local Enemy

function love.load()
  Player = require "player"
  Enemy = require "enemy"
  Bullet = require "bullet"

  player = Player()
  enemy = Enemy()
  bullets = {}
end

function love.update(dt)
  player:update(dt)
  enemy:update(dt)

  for i,bullet in ipairs(bullets) do
    bullet:update(dt)
    if bullet:collideWith(enemy) then
      if enemy.speed > 0 then
        enemy.speed = enemy.speed + 50
      else
        enemy.speed = enemy.speed - 50
      end
      table.remove(bullets, i)
    end
  end
end

function love.draw()
  player:draw()
  enemy:draw()

  for i,bullet in ipairs(bullets) do
    bullet:draw(dt)
  end
end

function love.keypressed(key)
  player:keypressed(key)
end
