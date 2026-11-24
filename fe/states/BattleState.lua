BattleState = {
  update = function(self,dt)
  end,
  draw = function()
    Tilemaps:draw()
    Actors:draw()
  end,
  mousepressed = function(self,x,y,key)
    Actors:mousepressed(x,y,key)
  end,
}

return BattleState
