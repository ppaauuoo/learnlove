-- can be use when require
function createBigRect()
  rect={}
  rect.x=200
  rect.y=200
  rect.w=200
  rect.h=200
  rect.s=50

  table.insert(listOfRectangles, rect)
end

-- can be get when require
local state = "big rect loaded"
return state


