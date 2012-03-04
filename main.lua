display.setStatusBar( display.HiddenStatusBar )  -- hide the status bar

local Camera = require 'Camera'

local target = Camera.newTarget()
local camera = Camera.new{xMax = 1920, yMax = 1200, target = target}
local image = display.newImageRect(camera, "cnh.png", 1920, 1200)
image.x, image.y = image.width / 2, image.height / 2
camera:insert(target)
camera:addEventListener("touch", target)

local zoomLevels = {1, 2, 5, 10, 50}
local function zoom(event)
	if (event.phase == "began") then
		local i = camera.zoomLevel or 2
		camera:setZoom(zoomLevels[i])
		camera.zoomLevel = (i % #zoomLevels) + 1
	end
	return true
end
target:addEventListener("touch", zoom)