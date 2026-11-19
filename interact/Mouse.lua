local Mouse = Object:extend()

function Mouse:new()
    world  = love.physics.newWorld(0, 0, true)
    --init body and shape
    body = love.physics.newBody(world,love.mouse.getX(), love.mouse.getY(), "dynamic")
    shape = love.physics.newCircleShape(5)
    -- attach shape to body
    fixture = love.physics.newFixture(body,shape)
    -- joint body with mouse
    joint = love.physics.newMouseJoint(body, love.mouse.getPosition())
end


function Mouse:update(dt)
  --update target to mouse position
  joint:setTarget(love.mouse.getPosition())
  for i=1,4 do
    world:update(dt)
  end
end


function Mouse:draw()
  --render mouse
  love.graphics.circle("fill",body:getX(),body:getY(),shape:getRadius())
end

return Mouse
