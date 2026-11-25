local TileMapSystem = Object:extend()

require 'map'
require 'config'

function TileMapSystem:moveTo(actor)
  local range = actor.character.class.range
  local pos = {actor.x,actor.y}
  self.move_range = {
      range = range,
      pos = pos
  }

end


function TileMapSystem:new()
    self.map = Map.map1
end

function TileMapSystem:draw()
    for row = 1, #self.map do
        for col = 1, #self.map[row] do
            local x = (col - 1) * CELLSIZE 
            local y = (row - 1) * CELLSIZE

            if self.map[row][col] == 1 then
                love.graphics.setColor(Color.red) -- Red wall
                love.graphics.rectangle("fill", x, y, CELLSIZE, CELLSIZE)
            elseif self.map[row][col] == 2 and GameStateManager:getState() == PrepState then
                love.graphics.setColor(Color.green) -- Green wall
                love.graphics.rectangle("fill", x, y, CELLSIZE, CELLSIZE)
            else
                love.graphics.setColor(0.2, 0.2, 0.2) -- Dark floor outline
                love.graphics.rectangle("line", x, y, CELLSIZE, CELLSIZE)
            end

            -- local move_range = self.move_range
            -- if move_range then
            --     for i in move_range.range do
            --         love.graphics.setColor(Color.green) -- Green wall
            --         love.graphics.rectangle("fill", x, y, CELLSIZE, CELLSIZE)
            --     end
            -- end

        end
    end
end


return TileMapSystem
