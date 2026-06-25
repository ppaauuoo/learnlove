# Graph Report - .  (2026-06-25)

## Corpus Check
- Corpus is ~11,796 words - fits in a single context window. You may not need a graph.

## Summary
- 148 nodes · 277 edges · 14 communities
- Extraction: 80% EXTRACTED · 20% INFERRED · 0% AMBIGUOUS · INFERRED: 55 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Boss State Machine|Boss State Machine]]
- [[_COMMUNITY_Combat & Effects|Combat & Effects]]
- [[_COMMUNITY_Camera & Game Loop|Camera & Game Loop]]
- [[_COMMUNITY_Hot Reload (Lick)|Hot Reload (Lick)]]
- [[_COMMUNITY_Bump Collision Core|Bump Collision Core]]
- [[_COMMUNITY_Bump Query Utilities|Bump Query Utilities]]
- [[_COMMUNITY_Bump Collision Detection|Bump Collision Detection]]
- [[_COMMUNITY_Sprite Rendering|Sprite Rendering]]
- [[_COMMUNITY_Bump Cell Management|Bump Cell Management]]
- [[_COMMUNITY_Bump Grid Traversal|Bump Grid Traversal]]
- [[_COMMUNITY_Bump Segment Queries|Bump Segment Queries]]
- [[_COMMUNITY_Lua Language Config|Lua Language Config]]

## God Nodes (most connected - your core abstractions)
1. `love.update()` - 11 edges
2. `Player:update()` - 9 edges
3. `Boss:update()` - 7 edges
4. `Combat.resolveDamage()` - 7 edges
5. `assertIsRect()` - 7 edges
6. `rect_detectCollision()` - 7 edges
7. `grid_toCellRect()` - 7 edges
8. `debugPrint()` - 7 edges
9. `love.load()` - 7 edges
10. `load()` - 6 edges

## Surprising Connections (you probably didn't know these)
- `love.update()` --calls--> `Combat.updateShake()`  [INFERRED]
  main.lua → combat.lua
- `love.load()` --calls--> `Particles.reset()`  [INFERRED]
  main.lua → components/particles.lua
- `love.draw()` --calls--> `Head.draw()`  [INFERRED]
  main.lua → head.lua
- `Boss:update()` --calls--> `Combat.shake()`  [INFERRED]
  boss.lua → combat.lua
- `Boss:update()` --calls--> `Physics.moveRaw()`  [INFERRED]
  boss.lua → components/physics.lua

## Import Cycles
- None detected.

## Communities (14 total, 0 thin omitted)

### Community 0 - "Boss State Machine"
Cohesion: 0.13
Nodes (19): Boss:new(), Boss:update(), loadSprites(), Combat.resolveDamage(), Health.canTakeDamage(), Health.init(), Health.takeDamage(), Health.update() (+11 more)

### Community 1 - "Combat & Effects"
Cohesion: 0.12
Nodes (12): Combat.shake(), Combat.slowShake(), Combat.updateShake(), Particles.reset(), Head.draw(), Head.kick(), Head.remove(), Head.spawn() (+4 more)

### Community 2 - "Camera & Game Loop"
Cohesion: 0.17
Nodes (15): Camera.apply(), Camera.reset(), Camera.setBounds(), Camera.startTransition(), Camera.update(), drawDebug(), drawUI(), love.draw() (+7 more)

### Community 3 - "Hot Reload (Lick)"
Cohesion: 0.29
Nodes (14): checkFileUpdate(), collectWorkingFiles(), convertIgnorePattern(), debugPrint(), draw(), handleErrorOutput(), lick.debugPrint(), load() (+6 more)

### Community 4 - "Bump Collision Core"
Cohesion: 0.16
Nodes (6): getResponseByName(), grid_toWorld(), rect_getSquareDistance(), sortByTiAndDistance(), World:check(), World:toWorld()

### Community 5 - "Bump Query Utilities"
Cohesion: 0.33
Nodes (7): assertIsPositiveNumber(), assertIsRect(), assertType(), getDictItemsInCellRect(), rect_isIntersecting(), World:project(), World:queryRect()

### Community 6 - "Bump Collision Detection"
Cohesion: 0.29
Nodes (7): nearest(), rect_containsPoint(), rect_detectCollision(), rect_getDiff(), rect_getNearestCorner(), sign(), World:queryPoint()

### Community 8 - "Sprite Rendering"
Cohesion: 0.47
Nodes (5): Boss:draw(), Sprite.draw(), Sprite.drawAt(), Sprite.pingpong(), Player:draw()

### Community 9 - "Bump Cell Management"
Cohesion: 0.47
Nodes (6): addItemToCell(), grid_toCellRect(), removeItemFromCell(), World:add(), World:remove(), World:update()

### Community 10 - "Bump Grid Traversal"
Cohesion: 0.40
Nodes (5): getCellsTouchedBySegment(), grid_toCell(), grid_traverse(), grid_traverse_initStep(), World:toCell()

### Community 11 - "Bump Segment Queries"
Cohesion: 0.50
Nodes (4): getInfoAboutItemsTouchedBySegment(), rect_getSegmentIntersectionIndices(), World:querySegment(), World:querySegmentWithCoords()

### Community 12 - "Lua Language Config"
Cohesion: 0.50
Nodes (3): $schema, workspace, library

## Knowledge Gaps
- **2 isolated node(s):** `$schema`, `library`
  These have ≤1 connection - possible missing edges or undocumented components.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `love.load()` connect `Camera & Game Loop` to `Combat & Effects`, `Hot Reload (Lick)`?**
  _High betweenness centrality (0.204) - this node is a cross-community bridge._
- **Why does `love.run()` connect `Hot Reload (Lick)` to `Camera & Game Loop`?**
  _High betweenness centrality (0.178) - this node is a cross-community bridge._
- **Why does `love.update()` connect `Camera & Game Loop` to `Combat & Effects`?**
  _High betweenness centrality (0.051) - this node is a cross-community bridge._
- **Are the 10 inferred relationships involving `love.update()` (e.g. with `Combat.updateShake()` and `Camera.setBounds()`) actually correct?**
  _`love.update()` has 10 INFERRED edges - model-reasoned connections that need verification._
- **Are the 8 inferred relationships involving `Player:update()` (e.g. with `Combat.resolveDamage()` and `Combat.shake()`) actually correct?**
  _`Player:update()` has 8 INFERRED edges - model-reasoned connections that need verification._
- **Are the 6 inferred relationships involving `Boss:update()` (e.g. with `Combat.resolveDamage()` and `Combat.shake()`) actually correct?**
  _`Boss:update()` has 6 INFERRED edges - model-reasoned connections that need verification._
- **Are the 6 inferred relationships involving `Combat.resolveDamage()` (e.g. with `Boss:update()` and `Health.canTakeDamage()`) actually correct?**
  _`Combat.resolveDamage()` has 6 INFERRED edges - model-reasoned connections that need verification._