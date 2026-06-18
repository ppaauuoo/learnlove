local player
local enemy
local obj

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

  local mx, my = love.mouse.getPosition()
  if obj.drag or obj:collideWith(mx, my) then
    obj:update(dt, mx, my)
  end

  -- Full-screen bounce by default; bounce between objects when they intersect enemy's vertical range
  local player_at_enemy = player.y + player.height > enemy.y and player.y < enemy.y + enemy.height
  local obj_at_enemy = obj.y + (obj.radius or 0) > enemy.y and obj.y - (obj.radius or 0) < enemy.y + enemy.height

  if player_at_enemy or obj_at_enemy then
    enemy:update(dt, math.min(player.x, obj.x), math.max(player.x + player.width, obj.x))
  else
    enemy:update(dt)
  end

  for i,bullet in ipairs(bullets) do
    bullet:update(dt)
    if bullet:collideWith(enemy) then
      attack_logic(bullet, enemy)
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

function attack_logic(origin, target)
  if target.speed > 0 then
    target.speed = target.speed + origin.damage
  else
    target.speed = target.speed - origin.damage
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
