
Color = {
    red   = {1, 0, 0},
    green = {0, 1, 0, 0.8}, -- 80% opacity
    blue  = {0.2, 0.4, 1},
    white = {1, 1, 1}
}


GameState = {
  update = function(self,dt)
    Alerts:update(dt)
    -- Tilemaps:update(dt)
    -- Actors:update(dt)
  end,
  draw = function()
    Tilemaps:draw()
    Actors:draw()
    Alerts:draw()
  end,
  mousepressed = function(self,x,y,key)
    Actors:mousepressed(x,y,key)
  end,
}
