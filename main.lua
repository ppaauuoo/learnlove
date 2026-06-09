local Player
local Enemy
local Draggable

function love.load()
  Player = require "entity.player"
  Enemy = require "entity.enemy"
  Bullet = require "entity.bullet"
  Draggable = require "entity.draggable"

  player = Player()
  enemy = Enemy()
  obj = Draggable()
  bullets = {}
end

function love.update(dt)
  player:update(dt)
  enemy:update(dt)

  mx, my = love.mouse.getPosition()
  if obj.drag or obj:collideWith(mx, my) then
    obj:update(dt, mx, my)
  end

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
  obj:draw()

  for _, bullet in ipairs(bullets) do
    bullet:draw()
  end
end

function love.mousepressed(x,y,btn)
  obj:dragging(btn)
end

function love.mousereleased(x,y,btn)
  obj:mouseReleased(btn)
end

function love.keyreleased(key)
  player:keyreleased(key)
end
