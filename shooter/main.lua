local Player
local Enemy

function love.load()
  Player = require "entity.player"
  Enemy = require "entity.enemy"
  Bullet = require "entity.bullet"

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
        enemy.speed = enemy.speed + bullet.damage
      else
        enemy.speed = enemy.speed - bullet.damage
      end
      table.remove(bullets, i)
    end
  end
end

function love.draw()
  player:draw()
  enemy:draw()

  for i,bullet in ipairs(bullets) do
    bullet:draw()
  end
end

function love.keyreleased(key)
  player:keyreleased(key)
end
