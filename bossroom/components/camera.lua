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
Camera.transition = { active = false, fromX = 0, fromY = 0, toX = 0, toY = 0, fromZoom = nil, toZoom = nil, t = 0, duration = 0.4 }

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

function Camera.startTransition(toX, toY, duration, toZoom)
    Camera.transition.active = true
    Camera.transition.fromX = Camera.x
    Camera.transition.fromY = Camera.y
    Camera.transition.fromZoom = Camera.zoom
    Camera.transition.toX = toX
    Camera.transition.toY = toY
    Camera.transition.toZoom = toZoom
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
            Camera.transition.toZoom = nil
        end
        local t = Camera.transition.t
        -- Ease out quad
        t = 1 - (1 - t) * (1 - t)
        Camera.x = Camera.transition.fromX + (Camera.transition.toX - Camera.transition.fromX) * t
        Camera.y = Camera.transition.fromY + (Camera.transition.toY - Camera.transition.fromY) * t
        if Camera.transition.toZoom then
            Camera.zoom = Camera.transition.fromZoom + (Camera.transition.toZoom - Camera.transition.fromZoom) * t
        end
        return
    end

    local cx, cy = screenW / 2, screenH / 2
    local viewW = screenW / Camera.zoom
    local viewH = screenH / Camera.zoom

    -- Target: center on follow position
    Camera.targetX = followX - cx
    Camera.targetY = followY - cy

    -- Clamp to room bounds if set (skip during zoom transition so player stays centered)
    if Camera.bounds and not Camera.transition.toZoom then
        local b = Camera.bounds
        if b.w <= viewW then
            Camera.targetX = b.x + b.w / 2 - cx
        else
            local minCam = b.x - cx + cx / Camera.zoom
            local maxCam = b.x + b.w - cx - cx / Camera.zoom
            Camera.targetX = math.max(minCam, math.min(Camera.targetX, maxCam))
        end
        if b.h <= viewH then
            Camera.targetY = b.y + b.h / 2 - cy
        else
            local minCam = b.y - cy + cy / Camera.zoom
            local maxCam = b.y + b.h - cy - cy / Camera.zoom
            Camera.targetY = math.max(minCam, math.min(Camera.targetY, maxCam))
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
    -- Zoom around the center of the virtual screen
    local cx, cy = Camera.virtualW / 2, Camera.virtualH / 2
    love.graphics.translate(cx, cy)
    love.graphics.scale(Camera.zoom, Camera.zoom)
    love.graphics.translate(-cx, -cy)
    love.graphics.translate(
        math.floor(-Camera.x + (shakeX or 0)),
        math.floor(-Camera.y + (shakeY or 0))
    )
end

-- Check if a point is near a room edge (for triggering transitions)
function Camera.isInRoom(x, y, room)
    return x >= room.x and x <= room.x + room.w and
        y >= room.y and y <= room.y + room.h
end

return Camera
