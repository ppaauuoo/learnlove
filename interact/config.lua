local colors = {
        red   = {1, 0, 0},
        green = {0, 1, 0, 0.8}, -- 80% opacity
        blue  = {0.2, 0.4, 1},
        white = {1, 1, 1}
}

Config = {
    colors = colors,
    --  x,y,guage,max,inc,dec,color
    gauges = {
        {750,100,0,190,3,0.5,colors.red},
        {690,100,0,190,5.5,3.5,colors.blue},
    }
}
