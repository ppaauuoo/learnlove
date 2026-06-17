local Concord = require("deps.concord")

local DrawSystem = Concord.system({ pool = { "position", "drawable" } })

function DrawSystem:draw()
    for _, e in ipairs(self.pool) do
        love.graphics.circle("fill", e.position.x, e.position.y, 5)
    end
end

return DrawSystem
