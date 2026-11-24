local utils = {}

function utils.pointInRect(px, py, rx, ry, rw, rh)
  px, py = push:toGame(px,py)
  if px == nil or py == nil or rx == nil or rw == nil or rh == nil then
    return false
  end
  return px >= rx and px <= rx + rw and
         py >= ry and py <= ry + rh
end

return utils
