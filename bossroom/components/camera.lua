-- components/camera.lua: smooth follow + room locking
local Camera = {}

Camera.x = 0
Camera.y = 0
Camera.targetX = 0
Camera.targetY = 0
Camera.smoothSpeed = 8
Camera.zoom = 1.25
Camera.virtualW = 800
Camera.virtualH = 720

-- Room bounds the camera is currently locked to (nil = free follow)
Camera.bounds = nil

-- Transition state
Camera.transition = { active = false, fromX = 0, fromY = 0, toX = 0, toY = 0, t = 0, duration = 0.4 }

function Camera.reset()
    Camera.x = 0
    Camera.y = 0
    Camera.targetX = 0
    Camera.targetY = 0
    Camera.bounds = nil
    Camera.transition.active = false
end

function Camera.setBounds(room)
    Camera.bounds = room
end

function Camera.startTransition(toX, toY, duration)
    Camera.transition.active = true
    Camera.transition.fromX = Camera.x
    Camera.transition.fromY = Camera.y
    Camera.transition.toX = toX
    Camera.transition.toY = toY
    Camera.transition.t = 0
    Camera.transition.duration = duration or 0.4
end

function Camera.update(dt, followX, followY, screenW, screenH)
    -- During room transition, lerp between positions
    if Camera.transition.active then
        Camera.transition.t = Camera.transition.t + dt / Camera.transition.duration
        if Camera.transition.t >= 1 then
            Camera.transition.active = false
            Camera.transition.t = 1
        end
        local t = Camera.transition.t
        -- Ease out quad
        t = 1 - (1 - t) * (1 - t)
        Camera.x = Camera.transition.fromX + (Camera.transition.toX - Camera.transition.fromX) * t
        Camera.y = Camera.transition.fromY + (Camera.transition.toY - Camera.transition.fromY) * t
        return
    end

    local viewW = screenW / Camera.zoom
    local viewH = screenH / Camera.zoom

    -- Target: center on follow position
    Camera.targetX = followX - viewW / 2
    Camera.targetY = followY - viewH / 2

    -- Clamp to room bounds if set
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

    -- Smooth follow
    Camera.x = Camera.x + (Camera.targetX - Camera.x) * Camera.smoothSpeed * dt
    Camera.y = Camera.y + (Camera.targetY - Camera.y) * Camera.smoothSpeed * dt
end

function Camera.apply(shakeX, shakeY)
    -- Uniform scale to fit window, centered (letterbox)
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

-- Check if a point is near a room edge (for triggering transitions)
function Camera.isInRoom(x, y, room)
    return x >= room.x and x <= room.x + room.w and
        y >= room.y and y <= room.y + room.h
end

return Camera
