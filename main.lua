display.setStatusBar( display.HiddenStatusBar )  -- hide the status bar

--==============================
-- Useful local functions
--==============================
local function vectAdd(v1, v2)
	return {x = v1.x + v2.x, y = v1.y + v2.y}
end

local function vectSub(v1, v2)
	return {x = v1.x - v2.x, y = v1.y - v2.y}
end

local function vectMultiply(v1, num)
	return {x = v1.x * num, y = v1.y * num}
end

local function vectMagnitude(v1)
	return math.sqrt(v1.x * v1.x + v1.y * v1.y)
end

local function vectNormalize(v1)
	return {x = v1.x / vectMagnitude(v1), y = v1.y / vectMagnitude(v1)}
end

--==============================
-- Start of Program
--==============================

-- Start physics simulation
local physics = require "physics"
physics.start()

-- Set properties
physics.setGravity(0, 0) -- No downward gravity

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
local target = display.newCircle(10,10,10)
physics.addBody( target, {density=50, friction=0.5, bounce=0.3, radius=5} )
target.linearDamping = 0.5
local function setTarget(event)
	local v = vectSub(event, target)
	target:setLinearVelocity(v.x, v.y)
end

Runtime:addEventListener("tap", setTarget)

-- Create a vehicle
local crate1 = display.newRect(50,50,64,32)
physics.addBody( crate1, { density=5, friction=0.5, bounce=0.3 } )
crate1.max_force = 1
crate1.max_speed = 20
crate1.mode = "seek"

local function update(event)
	local velocity = {}
	velocity.x, velocity.y = crate1:getLinearVelocity()
	
	local vect
	if (crate1.mode == "flee") then
		vect = vectSub(crate1, target)
	elseif (crate1.mode == "seek") then
		vect = vectSub(target, crate1)
	else --if (crate1.mode == "pursuit") then
		local tV = {}
		tV.x, tV.y = target:getLinearVelocity()
		tV = vectMultiply(tV, vectMagnitude(target,crate1)/100)
		tV = vectAdd(target, tV)
		vect = vectSub(tV, crate1)
	end
	local nVect = vectNormalize(vect)
	local desiredVelocity = vectMultiply(nVect, crate1.max_speed)
	if (velocity.x ~= desiredVelocity.x or velocity.y ~= desiredVelocity.y) then
		local steering = vectSub(desiredVelocity, velocity)
		steering = vectNormalize(steering)
		steering = vectMultiply(steering, crate1.max_force)
		local newVelocity = vectAdd(velocity, steering)
		crate1:setLinearVelocity(newVelocity.x, newVelocity.y)
	end
end

Runtime:addEventListener("enterFrame", update)