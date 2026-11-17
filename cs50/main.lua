push = require 'push'
Class = require 'class'

require 'Paddle'
require 'Ball'

PADDLE_SPEED = 200

GAME_WIDTH, GAME_HEIGHT = 432, 243
local windowWidth, windowHeight = love.window.getDesktopDimensions()
local smallFont = love.graphics.newFont('font.ttf', 8)

local playerSize = 20

local ballX = GAME_WIDTH /2 -2
local ballY = GAME_HEIGHT /2 -2
local ballSize = 4

local gameState = 'start'
local player1Score, player2Score = 0, 0
local servingPlayer = 1
local winningPlayer

function love.load()
    love.graphics.setFont(smallFont)

    windowWidth, windowHeight = windowWidth*.7, windowHeight*.7 --make the window a bit smaller than the screen itself

    love.window.setMode(windowWidth, windowHeight, {resizable=false, fullscreen=false, vsync=true})
    push:setupScreen(GAME_WIDTH,GAME_HEIGHT,windowWidth,windowHeight, {upscale = 'normal'})


    player1 = Paddle(10,30,5,playerSize)
    player2 = Paddle(GAME_WIDTH-10,GAME_HEIGHT-30,5,playerSize)
    ball = Ball(ballX, ballY, ballSize, ballSize)
end

function love.update(dt)

    if gameState == 'play' then
        ball:update(dt)
    end

    -- ball hit left side -> player 2 win, player 1 serve
    if ball.x < 0 then
        servingPlayer = 1
        player2Score = player2Score + 1
        if player2Score == 10 then
            winningPlayer = 2
            gameState = 'done'
        else
            gameState = 'serve'
            ball:reset()
        end
    end

    -- ball hit right side -> player 1 win, player 2 serve
    if ball.x > GAME_WIDTH then
        servingPlayer = 2
        player1Score = player1Score +1
        if player1Score == 10 then
            winningPlayer = 1
            gameState = 'done'
        else
            gameState = 'serve'
            ball:reset()
        end
    end

    if ball:collides(player1) then
        -- accel
        ball.dx = -ball.dx * 1.03
        -- bounce effect + prevent ball stuck
        ball.x = player1.x + 5

        -- keep velocity and make y random
        if ball.dy < 0 then
            ball.dy = -math.random(10,150)
        else
            ball.dy = math.random(10,150)
        end
    end

    if ball:collides(player2) then
        ball.dx = -math.abs(ball.dx) * 1.03
        ball.x = player2.x - ball.width
        if ball.dy < 0 then
            ball.dy = -math.random(10,150)
        else
            ball.dy = math.random(10,150)
        end
    end

    -- bounce from top and bot wall
    -- no need ballSize for top edge
    if ball.y <= 0 then
        ball.y = 0
        ball.dy = -ball.dy
    end

    if ball.y >= GAME_HEIGHT - ballSize then
        ball.y = GAME_HEIGHT -4
        ball.dy = -ball.dy
    end


    player1.dy = 0
    if love.keyboard.isDown('w') then
        player1.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('s') then
        player1.dy = PADDLE_SPEED
    end

    player2.dy = 0
    if love.keyboard.isDown('up') then
        player2.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('down') then
        player2.dy = PADDLE_SPEED
    end

    player1:update(dt)
    player2:update(dt)
end

function love.draw()
    push:start()

    love.graphics.clear(40/255, 45/255, 52/255, 255/255)
    love.graphics.printf('Hello Pong!', 0, 20, GAME_WIDTH, 'center')

    if gameState == 'start' then
        love.graphics.printf('Press Enter to begin', 0, 35, GAME_WIDTH, 'center')
    elseif gameState == 'serve' then
        love.graphics.printf('Player ' .. servingPlayer .. ': press Enter to serve', 0, 35, GAME_WIDTH, 'center')
    elseif gameState == 'done' then
        love.graphics.printf('Player ' .. winningPlayer .. ' wins! Press Enter to restart', 0, 35, GAME_WIDTH, 'center')
    end

    player1:render()
    player2:render()
    ball:render()

    push:finish()
end

function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    elseif key == 'return' or key == 'kpenter' then
        if gameState == 'start' then
            gameState = 'serve'
        elseif gameState == 'serve' then
            ball.dy = math.random(-50,50)
            ball.dx = math.random(140,200) * (servingPlayer == 1 and 1 or -1)
            gameState = 'play'
        elseif gameState == 'done' then
            -- start new round
            gameState = 'serve'
            ball:reset()
            player1Score = 0
            player2Score = 0

            -- loser serve first
            if winningPlayer ==1 then
                servingPlayer = 2
            else
                servingPlayer = 1
            end
        end
    end
end


-- function love.resize(w,h)
--     push.resize(w,h)
-- end
