local Entity = require "entity"
local Player = Entity:extend() 

function Player:new()
  Player.super.new(self, 300, 20, 500, 50, 50)
end

function Player:update(dt)
  if love.keyboard.isDown("left") then
    self.x = self.x - self.speed * dt
  elseif love.keyboard.isDown("right") then
    self.x = self.x + self.speed * dt
  end

  self:bound()

end

return Player
