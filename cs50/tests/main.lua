-- Run from the project root: lovec tests
-- Exercise the actual game callbacks without opening a window.
function love.run()
    local ok, err = pcall(function()
        math.randomseed(12345)
        local root = love.filesystem.getSourceBaseDirectory()
        package.path = root .. '/?.lua;' .. package.path
        local rectangles = {}
        local messages = {}
        local held = {}
        local quitCalled = false
        love.graphics = {
            newFont = function() return {} end,
            setFont = function() end,
            clear = function() end,
            printf = function(text) messages[#messages + 1] = text end,
            rectangle = function(_, x, y, width, height)
                rectangles[#rectangles + 1] = {x = x, y = y, width = width, height = height}
            end
        }
        love.window.getDesktopDimensions = function() return 1280, 720 end
        love.window.setMode = function() end
        love.keyboard.isDown = function(key) return held[key] or false end
        love.event.quit = function() quitCalled = true end
        package.loaded.push = {
            setupScreen = function() end,
            start = function() end,
            finish = function() end
        }

        assert(loadfile(root .. '/main.lua'))()
        love.load()
        assert(type(love.keypressed) == 'function', 'Enter cannot start game: love.keypressed is not registered')
        assert(type(love.draw) == 'function', 'love.draw is not registered')

        local initialX, initialY = ball.x, ball.y
        love.update(0.1)
        assert(ball.x == initialX and ball.y == initialY, 'Ball moved before Enter')
        love.keypressed('return')
        love.update(0.1)
        assert(ball.x == initialX and ball.y == initialY, 'Ball moved before serving')
        love.keypressed('return')
        love.update(0.1)
        assert(ball.x ~= initialX, 'Enter did not start horizontal ball movement')
        love.draw()
        local renderedBall = rectangles[#rectangles]
        assert(renderedBall.x == ball.x and renderedBall.y == ball.y, 'Draw must render the moving ball, not fixed coordinates')
        print('PASS: Enter enters serve, then starts visible ball movement')

        held.w = true
        local paddleY = player1.y
        love.update(0.01)
        assert(player1.y < paddleY, 'W must move player 1')
        held.w = false
        held.up = true
        paddleY = player2.y
        love.update(0.01)
        assert(player2.y < paddleY, 'Up must move player 2')
        held.up = false

        ball.x = player2.x - ball.width
        ball.y = player2.y
        ball.dx = 100
        ball.dy = 0
        love.update(0)
        assert(ball.dx < 0, 'Ball must bounce off player 2')
        ball.x = player1.x + player1.width
        ball.y = player1.y
        ball.dx = -100
        love.update(0)
        assert(ball.dx > 0, 'Ball must bounce off player 1')

        ball.x = -1
        love.update(0)
        assert(ball.x == initialX and ball.y == initialY, 'Scoring must reset the ball')
        love.draw()
        assert(messages[#messages] == 'Player 1: press Enter to serve', 'Player 1 must serve after conceding')
        love.keypressed('kpenter')
        love.update(0.01)
        assert(ball.x > initialX, 'Keypad Enter must launch player 1 serve')

        for _ = 1, 10 do
            ball.x = GAME_WIDTH + 1
            love.update(0)
        end
        love.draw()
        assert(messages[#messages] == 'Player 1 wins! Press Enter to restart', 'Ten points must end the game')
        love.keypressed('return')
        love.update(0)
        love.draw()
        assert(messages[#messages] == 'Player 2: press Enter to serve', 'Loser must serve after restart')
        assert(ball.x == initialX and ball.y == initialY, 'Restart must reset the ball')
        love.keypressed('return')
        love.update(0.01)
        assert(ball.x < initialX, 'Player 2 serve must move left')
        ball.x = GAME_WIDTH + 1
        love.update(0)
        love.draw()
        assert(messages[#messages] == 'Player 2: press Enter to serve', 'Restart must reset scores')
        love.keypressed('escape')
        assert(quitCalled, 'Escape must quit')
        print('PASS: paddles, collisions, scoring, keypad Enter, restart and Escape')
    end)
    if not ok then print('FAIL: ' .. tostring(err)) end
    return function() return ok and 0 or 1 end
end
