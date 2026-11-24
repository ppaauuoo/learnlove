local ActorSystem = Object:extend()

require 'config'

local utils = require 'lib.utils'

local function getSpawnPoints(map)
  local spawnPoints = {}
    for row = 1, #map do
        for col = 1, #map[row] do
            local x = (col - 1) * CELLSIZE 
            local y = (row - 1) * CELLSIZE

            if map[row][col] == 2 then
              local p = {x=x,y=y}
              table.insert(spawnPoints,p)
            end
        end
    end
    return spawnPoints
end

function ActorSystem:spawnAt(x,y)
  local actor = {x=x,y=y}
  if self.maxActors > #self.actors then
    table.insert(self.actors, actor)
  else
    Alerts:addAlert("No Actor Left", 5)
  end
end

function ActorSystem:new()
    self.map = Map.map1
    self.spawnPoints = getSpawnPoints(self.map)
    self.actors = {}
    self.maxActors = 1
end

function ActorSystem:draw()
  if self.actors then
    for _,v in ipairs(self.actors) do
      love.graphics.setColor(Color.blue)
      love.graphics.rectangle('fill', v.x, v.y, CELLSIZE, CELLSIZE)
    end
  end
end

function ActorSystem:mousepressed(x,y,key)
  if key ~=1 then
    return
  end

  for _,v in ipairs(self.spawnPoints) do
    if utils.pointInRect(x, y, v.x, v.y, CELLSIZE, CELLSIZE) then
      self:spawnAt(v.x,v.y)
    end
  end

end

return ActorSystem
