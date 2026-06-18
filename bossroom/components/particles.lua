-- components/particles.lua: spawn, update, draw particle effects
local Particles = {}

Particles.list = {}

function Particles.spawn(x, y, count)
    for i = 1, count do
        table.insert(Particles.list, {
            x = x,
            y = y,
            vx = (math.random() - 0.5) * 400,
            vy = (math.random() - 0.5) * 300 - 100,
            life = 0.3
        })
    end
end

function Particles.update(dt)
    for i = #Particles.list, 1, -1 do
        local p = Particles.list[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + 600 * dt
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(Particles.list, i)
        end
    end
end

function Particles.draw()
    for _, p in ipairs(Particles.list) do
        local a = p.life / 0.3
        love.graphics.setColor(1, 1, 1, a)
        love.graphics.rectangle("fill", p.x - 1.5, p.y - 1.5, 3, 3)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function Particles.reset()
    Particles.list = {}
end

return Particles
