-- Run from the project directory: lovec.exe tests/gamestate
local root = love.filesystem.getSource():gsub("[/\\]tests[/\\]gamestate$", "")
package.path = root .. "/?.lua;" .. root .. "/?/init.lua;" .. package.path

local function testManager()
  local manager = require "deps.gamestateManager"
  local events = {}
  local first = {
    enter = function(self) events[#events + 1] = "first.enter" end,
    quit = function(self) events[#events + 1] = "first.quit" end,
    update = function(self, dt)
      assert(self == manager:getState(), "incorrect state receiver")
      assert(dt == 0.125, "manager must forward numeric dt after self")
    end,
  }
  local second = {
    enter = function(self) events[#events + 1] = "second.enter" end,
    quit = function(self) events[#events + 1] = "second.quit" end,
  }
  manager:setState(first)
  manager:update(0.125)
  manager:setState(second)
  assert(manager:getPreviousState() == first, "previous state was not saved")
  manager:revertState()
  assert(manager:getState() == first, "previous state was not restored")
  assert(table.concat(events, ",") ==
    "first.enter,first.quit,second.enter,second.quit,first.enter", "incorrect lifecycle order")
  manager:setState(nil)
  manager.currentState, manager.stateStack = nil, {}
end

local function testMainIntegration()
  local chunk, err = loadfile(root .. "/main.lua")
  assert(chunk, err)

  local received = {}
  local function system(name)
    return function()
      return { update = function(self, dt) received[name] = dt end }
    end
  end
  package.loaded["deps.push"] = {}
  package.loaded["deps.lurker"] = { update = function() end }
  package.loaded["systems.RigidBlobSystem"] = system("blob")
  package.loaded["systems.Mouse"] = system("cursor")
  package.loaded["systems.EditMode"] = system("edit")

  chunk()
  initWindows = function() end
  love.load()
  love.update(0.125)
  for _, name in ipairs({ "blob", "cursor", "edit" }) do
    assert(received[name] == 0.125,
      name .. " update expected dt=0.125, got " .. tostring(received[name]))
  end
end

function love.run()
  local failed = false
  for _, test in ipairs({
    { "manager lifecycle and update dispatch", testManager },
    { "main startup and active-state dt forwarding", testMainIntegration },
  }) do
    local ok, err = xpcall(test[2], debug.traceback)
    print((ok and "PASS " or "FAIL ") .. test[1])
    if not ok then
      print(err)
      failed = true
    end
  end
  return function() return failed and 1 or 0 end
end
