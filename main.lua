local Map = require 'Map'

local map = display.newGroup()
display.newImageRect(map, "cnh.png", 1920, 1200)
map = Map.new{self = map}