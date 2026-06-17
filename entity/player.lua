local Entity = require "entity.core"
local Player = Entity:extend() 

function Player:new()
  Player.super.new(self, 300, 20, 500, 50, 50)
  self.timer = 0
end

function Player:update(dt)
  if love.keyboard.isDown("left", "h") then
    self.x = self.x - self.speed * dt
  elseif love.keyboard.isDown("right", "l") then
    self.x = self.x + self.speed * dt
  end
  if love.keyboard.isDown("space") then
    self.timer = self.timer + dt
  else
    self.timer = 0
  end

  self:bound()
end

function Player:draw()
  Player.super.draw(self)
  if self.timer > 2 then
    center_text('RELEASE', 5, 5)
  end
end

function center_text(text, sx, sy)
  local y = love.graphics.getHeight()/2
  love.graphics.printf(text, 0, y, 100, "center", 0, sx, sy, 1, 1)
end

function Player:keyreleased(key)
  if key == "space" then
    if self.timer > 2 then
      self:big_shot()
    else
      self:normal_shot()
    end
  end
end

function Player:normal_shot()
  table.insert(bullets, Bullet((self.x + self.x + self.width)/2, self.y+self.height))
end

function Player:big_shot()
  table.insert(bullets, Bullet((self.x + self.x + self.width)/2, self.y+self.height, 80, 80, 1400, 200))
end

return Player
