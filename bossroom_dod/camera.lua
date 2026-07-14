-- camera.lua: smooth follow + room locking (stateless module, same logic)
local Camera = {}

Camera.x = 0
Camera.y = 0
Camera.targetX = 0
Camera.targetY = 0
Camera.smoothSpeed = 8
Camera.zoom = 1.25
Camera.virtualW = 800
Camera.virtualH = 720
Camera.bounds = nil
Camera.transition = { active = false, fromX = 0, fromY = 0, toX = 0, toY = 0, t = 0, duration = 0.4 }

function Camera.reset()
    Camera.x, Camera.y = 0, 0
    Camera.targetX, Camera.targetY = 0, 0
    Camera.bounds = nil
    Camera.transition.active = false
end

function Camera.setBounds(room)
    Camera.bounds = room
end

function Camera.update(dt, followX, followY, screenW, screenH)
    if Camera.transition.active then
        Camera.transition.t = Camera.transition.t + dt / Camera.transition.duration
        if Camera.transition.t >= 1 then
            Camera.transition.active = false
            Camera.transition.t = 1
        end
        local t = 1 - (1 - Camera.transition.t) * (1 - Camera.transition.t)
        Camera.x = Camera.transition.fromX + (Camera.transition.toX - Camera.transition.fromX) * t
        Camera.y = Camera.transition.fromY + (Camera.transition.toY - Camera.transition.fromY) * t
        return
    end

    local viewW = screenW / Camera.zoom
    local viewH = screenH / Camera.zoom

    Camera.targetX = followX - viewW / 2
    Camera.targetY = followY - viewH / 2

    if Camera.bounds then
        local b = Camera.bounds
        if b.w <= viewW then
            Camera.targetX = b.x + b.w / 2 - viewW / 2
        else
            Camera.targetX = math.max(b.x, math.min(Camera.targetX, b.x + b.w - viewW))
        end
        if b.h <= viewH then
            Camera.targetY = b.y + b.h / 2 - viewH / 2
        else
            Camera.targetY = math.max(b.y, math.min(Camera.targetY, b.y + b.h - viewH))
        end
    end

    Camera.x = Camera.x + (Camera.targetX - Camera.x) * Camera.smoothSpeed * dt
    Camera.y = Camera.y + (Camera.targetY - Camera.y) * Camera.smoothSpeed * dt
end

function Camera.apply(shakeX, shakeY)
    local scale = math.min(
        love.graphics.getWidth() / Camera.virtualW,
        love.graphics.getHeight() / Camera.virtualH
    )
    local ox = (love.graphics.getWidth() - Camera.virtualW * scale) / 2
    local oy = (love.graphics.getHeight() - Camera.virtualH * scale) / 2
    love.graphics.translate(ox, oy)
    love.graphics.scale(scale, scale)
    love.graphics.translate(
        math.floor(-Camera.x + (shakeX or 0)),
        math.floor(-Camera.y + (shakeY or 0))
    )
    if Camera.zoom ~= 1 then
        love.graphics.scale(Camera.zoom, Camera.zoom)
    end
end

return Camera
