display.setStatusBar( display.HiddenStatusBar )  -- hide the status bar

local Map = require 'Map'

local map = Map.new{mapWidth = 1920, mapHeight = 1200}
local image = display.newImageRect(map, "cnh.png", 1920, 1200)
image.x, image.y = image.width / 2, image.height / 2

local button = display.newRect(10, 10, 40, 25)
button:setFillColor(255, 0, 0)
local sizes = {1, 2, 5, 10}
function button.tap(event)
	local i = button.size or 1
	map:scale(i)
	button.size = (i % #sizes) + 1
end
button:addEventListener("tap", button)