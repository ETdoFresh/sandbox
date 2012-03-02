local Map = require 'Map'

local map = Map.new{mapWidth = 1920, mapHeight = 1200}
local image = display.newImageRect(map, "cnh.png", 1920, 1200)
image.x, image.y = image.width / 2, image.height / 2