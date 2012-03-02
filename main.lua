display.setStatusBar( display.HiddenStatusBar )  -- hide the status bar

-- Required files to run this code
local physics = require "physics"
local Movement = require "Movement"

-- Start physics simulation
physics.start()
physics.setGravity(0, 0) -- No downward gravity
physics.setDrawMode("hybrid")

--==============================
-- Start of Program
--==============================

-- Create borders around the edges
local borderTop = display.newRect(0, 0, display.contentWidth, 1)
local borderBottom = display.newRect(0, display.contentHeight-1, display.contentWidth, 1)
local borderLeft = display.newRect(0, 0, 1, display.contentHeight)
local borderRight = display.newRect(display.contentWidth-1, 1, 1, display.contentHeight)

-- add physics to the borders
local borderBody = {friction=0.4, bounce=0.2}
physics.addBody(borderTop, "static", borderBody)
physics.addBody(borderBottom, "static", borderBody)
physics.addBody(borderLeft, "static", borderBody)
physics.addBody(borderRight, "static", borderBody)

--==============================
-- Object creation
--==============================

-- Create a target that moves on tap
local target = display.newCircle(0,0,10)
local function moveTarget(event)
	target.x, target.y = event.x, event.y
	target.rotation = math.random(0, 360)
end
Runtime:addEventListener("tap", moveTarget)

-- Create an object to perform event

local newObject = Movement.new{target = target, move = "arrive"}