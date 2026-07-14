-- sprite.lua: sprite loading + drawing helpers
local Sprite = {}

function Sprite.load(prefix, count, startIndex)
    local start = startIndex or 0
    local frames = {}
    for i = start, start + count - 1 do
        local img = love.graphics.newImage(prefix .. i .. ".png")
        img:setFilter("nearest", "nearest")
        frames[i] = img
    end
    return frames
end

function Sprite.pingpong(animTimer, speed, max)
    local total = max * 2
    local t = math.floor(animTimer / speed) % total
    return t <= max and t or (total - t)
end

function Sprite.draw(image, x, y, w, h, facing)
    local sx = w / image:getWidth()
    local sy = h / image:getHeight()
    local dx = facing == -1 and x + w or x
    love.graphics.draw(image, dx, y, 0, sx * facing, sy)
end

function Sprite.drawAt(image, dx, dy, dw, dh, facing)
    local sx = (dw / image:getWidth()) * facing
    local sy = dh / image:getHeight()
    local ox = facing == -1 and dw or 0
    love.graphics.draw(image, dx + ox, dy, 0, sx, sy)
end

return Sprite
