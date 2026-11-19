local loveblobs = require "loveblobs"
local RigidBlobSystem = Object:extend()

local function pointInPolygon(x, y, points)
  local inside = false
  local j = #points - 1

  for i = 1, #points, 2 do
    local xi, yi = points[i], points[i + 1]
    local xj, yj = points[j], points[j + 1]

    if (yi > y) ~= (yj > y) then
      local crossingX = xi + (y - yi) * (xj - xi) / (yj - yi)

      if x < crossingX then
        inside = not inside
      end
    end

    j = i
  end

  return inside
end

function RigidBlobSystem:destroyStaticBlob(x,y)
  -- ipair cant reverse loop -> use numeric loop
  for i = #self.softbodies,1 ,-1 do
    local blob = self.softbodies[i]
      if pointInPolygon(x, y, blob:getPoints()) then
        if self.dragJoint then
          self.dragJoint:destroy()
          self.dragJoint = nil
        end
        blob:destroy()
        blob.anchorBody:destroy()
        table.remove(self.softbodies, i)
      end
  end

end

function RigidBlobSystem:createStaticBlob(x, y, size)
    --init softblob
    local b = loveblobs.softbody(self.world, x, y, size, 2, 4)

    b:setFrequency(1.5)
    b:setDamping(0.1)
    b:setFriction(1)
    table.insert(self.softbodies, b)

    --init anchor
    local anchorBody = love.physics.newBody( self.world, x, y, "static")
    local anchorJoint = love.physics.newDistanceJoint(anchorBody , b.centerBody, x, y, x, y, false)
    anchorJoint:setFrequency(1.2)
    anchorJoint:setDampingRatio(0.7)
    b.anchorBody = anchorBody
end

function RigidBlobSystem:new(force)

    self.dragForce = force or 5000

    --init world
    love.physics.setMeter(16)
    self.world  = love.physics.newWorld(0, 0, true)
    self.softbodies = {}

    self:createStaticBlob(400,300,100)
end

function RigidBlobSystem:update(dt)
  if self.dragJoint then
    self.dragJoint:setTarget(love.mouse.getPosition())
  end

  for i=1,4 do
    self.world:update(dt)
  end

  for _,blob in ipairs(self.softbodies) do
    blob:update(dt)
  end
end

function RigidBlobSystem:draw()
  -- render softbodies
  for i,v in ipairs(self.softbodies) do
    love.graphics.setColor(50*i, 100, 200*i)
    if (tostring(v) == "softbody") then
      v:draw("fill",false)
    else
      v:draw(false)
    end
  end
end

function RigidBlobSystem:mousepressed(x,y,button)
  if button ~= 1 or self.dragJoint then return end

  for _, blob in ipairs(self.softbodies) do
    if pointInPolygon(x, y, blob:getPoints()) then
      self.dragJoint = love.physics.newMouseJoint(blob.centerBody, x, y)
      self.dragJoint:setMaxForce(self.dragForce)
      blob.centerBody:setAwake(true)
      break
    end
  end
end

function RigidBlobSystem:mousereleased(x,y,button)
  if button == 1 and self.dragJoint then
    self.dragJoint:destroy()
    self.dragJoint = nil
  end
end


return RigidBlobSystem
