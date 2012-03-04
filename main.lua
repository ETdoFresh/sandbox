display.setStatusBar( display.HiddenStatusBar )  -- hide the status bar

local Camera = require 'Camera'

local camera = Camera.new{xMax = 1920, yMax = 1200}
local image = display.newImageRect(camera, "cnh.png", 1920, 1200)
image.x, image.y = image.width / 2, image.height / 2

local button = display.newRect(10, 10, 40, 25)
button:setFillColor(255, 0, 0)
local sizes = {1, 2, 5, 10}
function button:touch(event)
	if (event.phase == "began") then
		local i = button.size or 1
		camera:scale(i)
		button.size = (i % #sizes) + 1
	end
	return true
end
button:addEventListener("touch", button)