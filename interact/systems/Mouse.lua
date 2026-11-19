local Mouse = Object:extend()

function Mouse:new()
    self.world  = love.physics.newWorld(0, 0, true)
    --init body and shape
    self.body = love.physics.newBody(self.world,love.mouse.getX(), love.mouse.getY(), "dynamic")
    self.shape = love.physics.newCircleShape(5)
    -- attach shape to body
    self.fixture = love.physics.newFixture(self.body,self.shape)
    -- joint body with mouse
    self.joint = love.physics.newMouseJoint(self.body, love.mouse.getPosition())
end

function Mouse:update(dt)
  --update target to mouse position
  self.joint:setTarget(love.mouse.getPosition())
  for i=1,4 do
    self.world:update(dt)
  end
end

function Mouse:draw()
  --render mouse
  love.graphics.circle("fill",self.body:getX(),self.body:getY(),self.shape:getRadius())
end

return Mouse
