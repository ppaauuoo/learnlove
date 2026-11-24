-- Run from the project root: lua tests/actor_system_test.lua
Object = require 'lib.classic'
CELLSIZE = 16
Map = {map1 = {{2, 2}}}
push = {toGame = function(_, x, y) return x, y end}
GameStateManager = require 'lib.stateman'
PrepState = require 'states.PrepState'
BattleState = require 'states.BattleState'
GameStateManager:setState(PrepState)

local alerts = {}
Alerts = {addAlert = function(_, message, duration)
  table.insert(alerts, {message = message, duration = duration})
end}

local ActorSystem = require 'sys.ActorSystem'
local actors = ActorSystem()

actors:mousepressed(8, 8, 2)
assert(#actors.actors == 0, 'non-left clicks must not spawn actors')
actors:mousepressed(80, 80, 1)
assert(#actors.actors == 0, 'clicks outside spawn points must not spawn actors')

actors:mousepressed(8, 8, 1)
assert(#actors.actors == 1, 'first left click must spawn an actor without crashing')
assert(actors.actors[1].x == 0 and actors.actors[1].y == 0)

actors:mousepressed(24, 8, 1)
assert(#actors.actors == actors.maxActors, 'a full roster must not exceed maxActors')
assert(actors.actors[1].x == 0, 'a rejected spawn must preserve the existing actor')
assert(#alerts == 1 and alerts[1].message == 'No Actor Left' and alerts[1].duration == 5)

actors:mousepressed(8, 8, 1)
assert(#actors.actors == 0, 'clicking an occupied cell must remove its actor even at capacity')
assert(#alerts == 1, 'removing an actor must not show a capacity alert')

actors:mousepressed(24, 8, 1)
assert(#actors.actors == 1 and actors.actors[1].x == 16, 'removing an actor must free capacity')
GameStateManager:setState(require 'states.BattleState')
actors:mousepressed(24, 8, 1)
assert(#actors.actors == 1 and actors.actors[1].x == 16, 'battle clicks must not remove actors')
actors.actors = {}
actors:mousepressed(8, 8, 1)
assert(#actors.actors == 0, 'battle clicks must not spawn actors')
assert(#alerts == 1, 'battle clicks must not show capacity alerts')
print('PASS: actor spawning, capacity, removal, mouse input, and battle placement lock')
