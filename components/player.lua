local Concord = require("deps.concord")
return Concord.component("player", function(c, speed, power)
    c.speed          = speed or 0
    c.power          = power or 0
    c.power_duration = 5
    c.using_power    = false
end)
