display.setStatusBar( display.HiddenStatusBar )  -- hide the status bar

-- Required files to run this code
local physics = require "physics"
local Steering = require "Steering"
local Path = require "Path"

-- Start physics simulation
physics.start()
physics.setGravity(0, 0) -- No downward gravity
physics.setDrawMode("hybrid")

--==============================
-- Start of Program
--==============================

-- Create a background
local background = display.newRect(0, 0, display.contentWidth, display.contentHeight)
background:setFillColor(32,32,32)

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
-- Popup Text Class
--==============================
local FadingText = {}
function FadingText.new(param)
	param.text = param.text or "*Blank*"
	param.x = param.x or 0
	param.y = param.y or 0
	param.font = param.font or native.systemFont
	param.size = param.size or 16
	local self = display.newText(param.text, 0, 0, param.font, param.size)
	self.x, self.y = param.x, param.y
	local function removeMe(event)
		self:removeSelf()
		self = nil
	end
	transition.to(self, {time = 500, delay = 1000, alpha = 0, onComplete = removeMe})
end

--==============================
-- Object creation
--==============================
-- Create an object to perform event
local newObject = Steering.new{radius = 16, maxSpeed = 50, maxAcceleration = 10, maxTorque = 30, maxRotation = 200, targetRadius = 50/3}
display.newImageRect(newObject, "character-01.png", 61, 61)
newObject.x, newObject.y = 30,30
newObject:setTarget({x = 0, y = 0, rotation = 0})
newObject:setSteering("wander")

local newObject2 = Steering.new{radius = 16, target = newObject, maxSpeed = 20}
display.newImageRect(newObject2, "character-02.png", 61, 61)
newObject2.x, newObject2.y = 60,60
newObject2:setSteering("wander")

local function changeTarget(event)
	local rotation = math.random(360)
	newObject:setTarget({x = event.x, y = event.y, rotation = rotation})
	FadingText.new{x = event.x, y = event.y, text = "Tap!"}
end

local moves = {"combine", "wander"}
local function changeMovement(event)
	local i = event.target.i or 1
	event.target:setSteering(moves[i])
	FadingText.new{x = event.x, y = event.y, text = moves[i]}
	event.target.i = (i % #moves) + 1
end

local path
local function drawPath(event)
	if (event.phase == "began") then
		newObject:setSteering("wander")
		if (path) then path:removeSelf() end
		path = Path.new{start = {x = event.x, y = event.y}}
	elseif (event.phase == "moved") then
		path:append{x = event.x, y = event.y}
	elseif (event.phase == "ended") then
		path:simplify{dist = 15, iterations = 2}
		newObject:setTarget(path)
		newObject:setSteering("followPath")
	end
	return true
end

background:addEventListener("touch", drawPath)
--background:addEventListener("tap", changeTarget)
--newObject:addEventListener("tap", changeMovement)
--newObject2:addEventListener("tap", changeMovement)