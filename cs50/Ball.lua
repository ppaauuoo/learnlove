Ball = Class{}

function Ball:init(x,y, width, height)
  self.x = x
  self.y = y
  self.width = width
  self.height = height
  self.dx = 0
  self.dy = 0
end

function Ball:reset()
  self.x = GAME_WIDTH / 2 - self.width / 2
  self.y = GAME_HEIGHT / 2 - self.height / 2
  self.dx = 0
  self.dy = 0
end

function Ball:update(dt)
  self.x = self.x + self.dx * dt
  if self.dy < 0 then
    self.y = math.max(0, self.y + self.dy * dt)
  else
    self.y = math.min(GAME_HEIGHT-self.height, self.y + self.dy * dt)
  end

end

function Ball:render()
  love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
end

function Ball:collides(paddle)
  -- check left edge and right edge
  if self.x > paddle.x + paddle.width or paddle.x > self.x + self.width then
    return false
  end

  -- check bottom edge and top edge
  if self.y > paddle.y + paddle.height or paddle.y > self.y + self.height then
    return false
  end

  return true
end
