local Concord    = require("deps.concord")
local bumpWorld  = require("bumpworld")

local Collider = Concord.component("collider", function(c, x, y, w, h, ctype)
    c.item = { type = ctype or "solid" }
    bumpWorld:add(c.item, x, y, w, h)
end)

function Collider:removed()
    if bumpWorld:hasItem(self.item) then
        bumpWorld:remove(self.item)
    end
end

return Collider
