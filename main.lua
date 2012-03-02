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

local function vectDivide(v1, num)
	return {x = v1.x / num, y = v1.y / num}
end

local function vectMagnitude(v1)
	return math.sqrt(v1.x * v1.x + v1.y * v1.y)
end

local function vectNormalize(v1)
	return {x = v1.x / vectMagnitude(v1), y = v1.y / vectMagnitude(v1)}
end

local function randomBinomial()
	return math.random() - math.random()
end

--==============================
-- Start of Program
--==============================

-- Start physics simulation
local physics = require "physics"
physics.start()

-- Set properties
physics.setGravity(0, 0) -- No downward gravity
physics.setDrawMode("hybrid")

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
local Kinematic = {}
function Kinematic.new()
	local self = display.newRect(50,50,64,32)
	--position defined by self.x, self.y
	--orientation defined by rotation
	physics.addBody( self, { density=1, friction=0.2, bounce=0.2 } )
	--velocity defined by self:getLinearVelocity()
	--rotation defined by self:getAngularVelocity()
	self.maxAcceleration = 5
	self.maxSpeed = 100	
	self.maxRotation = 360
	self.maxAngularAcceleration = 20
	return self
end

-- Create objects
local newObject = Kinematic.new()
local target = display.newCircle(0,0,10)
local function moveTarget(event)
	target.x, target.y = event.x, event.y
	target.rotation = math.random(0, 360)
end
Runtime:addEventListener("tap", moveTarget)

--==============================
-- Kinematic functions
--==============================
local function getNewOrienation(currentOrientation, velocity)
	-- Make sure we have a velocity
	if (vectMagnitude(velocity) > 0) then
		--Calculate orientation using arctan of velocity components.
		return math.deg(math.atan2(velocity.y, velocity.x)) % 360
	end
	-- Otherwise use current orientation
	return currentOrientation
end

local function kinematicSeek(character, target)
	-- Get the direction to the target
	local steering = vectSub(target, character)
	-- Velocity in this direction at full speed
	steering = vectNormalize(steering)
	steering = vectMultiply(steering, character.maxSpeed)
	-- Face in the direction we want to move
	character.rotation = getNewOrienation(character.rotation, steering)
	steering.rotation = 0
	return steering
end

local function kinematicFlee(character, target)
	-- Get the direction away from the target
	local steering = vectSub(character, target)
	-- Velocity in this direction at full speed
	steering = vectNormalize(steering)
	steering = vectMultiply(steering, character.maxSpeed)
	-- Face in the direction we want to move
	character.rotation = getNewOrienation(character.rotation, steering)
	steering.rotation = 0
	return steering
end

local function kinematicArrive(character, target, radius, timeToTarget)
	radius = radius or (character.maxSpeed / 4) -- Holds the satisfaction radius
	timeToTarget = timeToTarget or 0.25 -- Holds the time to target constant
	-- Get the direction to the target
	local steering = vectSub(target, character)
	-- Check if we are within radius
	local distance = vectMagnitude(steering)
	if (distance < radius) then
		return nil -- We can return no steering request
	end
	-- We need to move to our target, we'd like to get there in timeToTarget seconds
	steering = vectDivide(steering, timeToTarget)
	-- If this is too fast, clip it to the max speed
	local distance = vectMagnitude(steering)
	if (distance > character.maxSpeed) then
		steering = vectNormalize(steering)
		steering = vectMultiply(steering, character.maxSpeed)
	end
	-- Face in the direction we want to move
	character.rotation = getNewOrienation(character.rotation, steering)
	steering.rotation = 0
	return steering
end

local function kinematicWander(character, maxRotation)
	maxRotation = maxRotation or 20 -- max rotation speed in which to wander
	-- Get velocity from vector form of orientation
	local rads = math.rad(character.rotation)
	local steering = {x = math.cos(rads), y = math.sin(rads)}
	steering = vectMultiply(steering, character.maxSpeed)
	-- Change our orientation randomly
	steering.rotation = randomBinomial() * maxRotation
	return steering
end

local function kinematicUpdate(event)
	local steering = kinematicWander(newObject, 20)
	if (steering) then
		newObject:setLinearVelocity(steering.x, steering.y)
		newObject.angularVelocity = 0
		newObject.rotation = (newObject.rotation + steering.rotation) % 360
		return true
	end
	newObject:setLinearVelocity(0, 0)
	newObject.angularVelocity = 0
	return true
end

--==============================
-- Steering functions
--==============================
local function seek(character, target)
	-- Get the direction to the target
	local steering = vectSub(target, character)
	-- Give full acceleration along this direction
	steering = vectNormalize(steering)
	steering = vectMultiply(steering, character.maxAcceleration)
	steering.angular = 0
	return steering
end

local function flee(character, target)
	-- Get the direction to the target
	local steering = vectSub(character, target)
	-- Give full acceleration along this direction
	steering = vectNormalize(steering)
	steering = vectMultiply(steering, character.maxAcceleration)
	steering.angularVelocity = 0
	return steering
end

local function arrive(character, target, targetRadius, slowRadius, timeToTarget)
	targetRadius = targetRadius or 5 -- Holds the radius for arriving at the target
	slowRadius = slowRadius or character.maxSpeed -- Holds the radius for beginning to slow down
	timeToTarget = timeToTarget or 0.1 -- Holds the time over which to achieve target speed
	-- Get the direction to the target
	local direction = vectSub(target, character)
	local distance = vectMagnitude(direction)
	-- Check if we are there, return no steering
	if (distance < targetRadius) then
		return nil
	end
	-- If we are outside the slowRadius, then go max speed
	local targetSpeed
	if (distance > slowRadius) then
		targetSpeed = character.maxSpeed
	-- Otherwise calculate a scaled speed
	else
		targetSpeed = character.maxSpeed * distance / slowRadius
	end
	-- The target velocity combines speed and direction
	local targetVelocity = direction
	targetVelocity = vectNormalize(targetVelocity)
	targetVelocity = vectMultiply(targetVelocity, targetSpeed)
	-- Acceleration tries to get to the target velocity
	local velocity = {}
	velocity.x, velocity.y = character:getLinearVelocity()
	local steering = vectSub(targetVelocity, velocity)
	steering = vectDivide(steering, timeToTarget)
	-- Check if the acceleration is too fast
	local acceleration = vectMagnitude(steering)
	if (acceleration > character.maxAcceleration) then
		steering = vectNormalize(steering)
		steering = vectMultiply(steering, character.maxAcceleration)
	end
	steering.angularVelocity = 0
	return steering
end

local function align(character, target, targetRadius, slowRadius, timeToTarget)
	targetRadius = targetRadius or 1 -- Holds the radius for arriving at the target
	slowRadius = slowRadius or character.maxRotation -- Holds the radius for beginning to slow down
	timeToTarget = timeToTarget or 0.01 -- Holds the time over which to achieve target speed
	--Get the native direction to the target
	local rotation = target.rotation - character.rotation
	-- Map result to the (-180, 180) interval
	rotation = (rotation % 360) - 180
	rotationSize = math.abs(rotation)
	-- Check if we are there, return no steering
	if (rotationSize < targetRadius) then
		return nil
	end
	-- If we are outside the slowRadius, then use maximum rotation
	local targetRotation
	if (rotationSize > slowRadius) then
		targetRotation = character.maxRotation
	-- Otherwise calculate a scaled rotation
	else
		targetRotation = character.maxRotation * rotationSize / slowRadius
	end
	-- The final target rotation combines speed and direction
	targetRotation = targetRotation * rotation / rotationSize
	-- Acceleration tried to get to the target rotation
	local steering = targetRotation - character.angularVelocity
	steering = steering / timeToTarget
	-- Check if the acceleration is too great
	local angularAcceleration = math.abs(steering)
	if (angularAcceleration > character.maxAngularAcceleration) then
		steering = steering / angularAcceleration
		steering = steering * character.maxAngularAcceleration
	end
	return steering
end

local function face(character, target, targetRadius, slowRadius, timeToTarget)
	-- Work out direction to target
	local direction = vectSub(target, character)
	local distance = vectMagnitude(direction)
	-- Check for zero direction, and make no change if so
	if (distance == 0) then return nil end
	-- Put the target together
	local newTarget = {rotation = math.deg(math.atan2(direction.y, direction.x))}
	return align(character, newTarget, targetRadius, slowRadius, timeToTarget)
end

local function lookWhereYouGoing(character, target, targetRadius, slowRadius, timeToTarget)
	-- Check for zero direction, and make no change if so
	if (distance == 0) then return nil end
	-- Put the target together
	local velocity = {}
	velocity.x, velocity.y = character:getLinearVelocity()
	local newTarget = {rotation = math.deg(math.atan2(velocity.y, velocity.x))}
	return align(character, newTarget, targetRadius, slowRadius, timeToTarget)
end

local function wander(character, target, targetRadius, slowRadius, timeToTarget)
	
end

local function update(event)
	local steering = arrive(newObject, target)
	if (steering) then
		local velocity = {}
		velocity.x, velocity.y = newObject:getLinearVelocity()
		steering = vectAdd(steering, velocity)
		local speed = vectMagnitude(steering)
		if (speed > newObject.maxSpeed) then
			steering = vectNormalize(steering)
			steering = vectMultiply(steering, newObject.maxSpeed)
		end
		newObject:setLinearVelocity(steering.x, steering.y)
	else
		newObject:setLinearVelocity(0, 0)
	end
	
	local steering = lookWhereYouGoing(newObject)
	if (steering) then
		newObject.angularVelocity = newObject.angularVelocity + steering
	else
		newObject.angularVelocity = 0
	end
	return true
end

Runtime:addEventListener("enterFrame", update)