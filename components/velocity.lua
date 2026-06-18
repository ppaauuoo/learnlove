local Concord = require("deps.concord")
return Concord.component("velocity", function(c, x, y)
    c.x = x or 0
    c.y = y or 0
end)
