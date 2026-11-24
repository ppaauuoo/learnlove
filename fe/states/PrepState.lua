PrepState = {
  update = function(self,dt)
    Alerts:update(dt)
  end,
  draw = function()
    Tilemaps:draw()
    Actors:draw()
    UIs:draw()
    Alerts:draw()
  end,
  mousepressed = function(self,x,y,key)
    Actors:mousepressed(x,y,key)
    UIs:mousepressed(x,y,key)
  end,
}


function PrepState:startBattle()
  if #Actors.actors == 0 then
    Alerts:addAlert("Need Actor!",5)
    return
  end
  GameStateManager:setState(BattleState)
end

return PrepState
