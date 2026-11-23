ActiveState = {
  update = function(self, dt)
    edit_mode:update(dt)
    blob_system:update(dt)
    cursor:update(dt)
    guage_system:update(dt)
  end,

  draw = function(self)
    blob_system:draw()
    edit_mode:draw()
    cursor:draw()
    guage_system:draw()
  end,

  keypressed = function(self,key)
    edit_mode:keypressed(key)
  end,

  mousepressed = function(self,x,y,button)
    local lock = edit_mode:mousepressed(x,y,button)
    if not lock then
      blob_system:mousepressed(x,y,button)
    end
  end,

  mousemoved = function(self,_,_,dx,dy)
    guage_system:mousemoved(nil,nil,dx,dy)
  end,

  mousereleased = function(self,x,y,button)
    blob_system:mousereleased(x,y,button)
  end,

  quit = function()
    blob_system:mousereleased(nil,nil,1)
  end
}

NothingState = {
  draw = function(sef)
    local t = love.graphics.newText(mediumFont, "PAUSED")
    local width,height = t:getDimensions()
    local scale = 3
    love.graphics.draw(t,windowWidth/2-(width*scale),windowHeight/2-(height*scale),0,scale,scale)
  end
  
}
