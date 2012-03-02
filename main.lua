local Map = require 'Map'

local map = display.newGroup()
local image = display.newImageRect(map, "cnh.png", 1920, 1200)
image.x, image.y = image.width / 2, image.height / 2
map = Map.new{self = map}