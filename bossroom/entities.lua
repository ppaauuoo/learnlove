-- entities.lua: re-exports Player and Boss from their own files
-- Split from a single file into player.lua + boss.lua for clarity.
return { Player = require("player"), Boss = require("boss") }
