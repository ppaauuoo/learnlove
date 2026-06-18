-- components/sprite.lua: sprite sheet loading, animation, facing-draw
local Sprite = {}

-- Load a sequence of numbered frame images (e.g. "prefix0.png", "prefix1.png", ...)
-- count: number of frames. startIndex: first frame number (default 0)
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

-- Compute ping-pong frame: cycles 0..max..1 over (max*2) steps
-- max: highest frame index (e.g. 4 for frames 0-4 → 8-step cycle)
function Sprite.pingpong(animTimer, speed, max)
    local total = max * 2
    local t = math.floor(animTimer / speed) % total
    return t <= max and t or (total - t)
end

-- Draw a sprite scaled to (w, h) with horizontal flip based on facing
-- facing: 1 = right (no flip), -1 = left (flip)
function Sprite.draw(image, x, y, w, h, facing)
    local sx = w / image:getWidth()
    local sy = h / image:getHeight()
    local dx = facing == -1 and x + w or x
    love.graphics.draw(image, dx, y, 0, sx * facing, sy)
end

-- Draw a sprite at arbitrary size with facing flip (for effects, hitbox visuals)
function Sprite.drawAt(image, dx, dy, dw, dh, facing)
    local sx = (dw / image:getWidth()) * facing
    local sy = dh / image:getHeight()
    local ox = facing == -1 and dw or 0
    love.graphics.draw(image, dx + ox, dy, 0, sx, sy)
end

return Sprite
