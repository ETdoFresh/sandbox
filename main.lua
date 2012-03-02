display.setStatusBar( display.HiddenStatusBar )  -- hide the status bar

-- Required files to run this code
local physics = require "physics"
local Steering = require "Steering"

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
-- Create an object to perform event
local newObject = Steering.new{radius = 16, density = 1}
display.newImageRect(newObject, "character-01.png", 61, 61)
newObject.x, newObject.y = 30,30
newObject:setTarget({x = 0, y = 0})
newObject:setSteering("arrive")

local newObject2 = Steering.new{radius = 16, target = newObject, maxSpeed = 20, targetRadius = 40}
display.newImageRect(newObject2, "character-02.png", 61, 61)
newObject2.x, newObject2.y = 60,60
newObject2:setSteering("pursue")

local function changeTarget(event) newObject:setTarget({x = event.x, y = event.y}) end
Runtime:addEventListener("tap", changeTarget)