-- Singleton bump world — require this from any file that needs it
local bump = require("deps.bump")
return bump.newWorld()
