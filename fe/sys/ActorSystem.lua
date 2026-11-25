local ActorSystem = Object:extend()

require 'config'
require 'status'

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
  if GameStateManager:getState() ~= PrepState then
    return
  end

  -- kill occupied actor
  for i = #self.actors, 1, -1 do
    if self.actors[i].x ==  x and self.actors[i].y == y then
      table.remove(self.actors,i)
      return
    end
  end

  -- check max actor
  if #self.actors >= self.maxActors then
    Alerts:addAlert("No Actor Left", 5)
    return
  end

  UIs:actorMenu(x,y)
end

function ActorSystem:new()
    self.map = Map.map1
    self.spawnPoints = getSpawnPoints(self.map)
    self.actors = {}
    self.maxActors = #Character
end

function ActorSystem:draw()
  for _,v in ipairs(self.actors) do
    love.graphics.setColor(Color.blue)
    love.graphics.rectangle('fill', v.x, v.y, CELLSIZE, CELLSIZE)
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

  for _,v in ipairs(self.actors) do
    if utils.pointInRect(x, y, v.x, v.y, CELLSIZE, CELLSIZE) then
      Tilemaps:moveTo(v)
    end
  end

end

return ActorSystem
