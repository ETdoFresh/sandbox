--==============================
-- Kinematic movement
-- A "no physics required" movement engine
-- by E.T. Garcia
-- reference Artificial Intelligence for Games 2nd Ed by Millington and Funge
--==============================
local Kinematic = {}

-- Require Vector functions
local Vector = require "Vector"

function randomBinomial()
	return math.random() - math.random()
end

local function getNewOrienation(currentOrientation, velocity)
	-- Make sure we have a velocity
	if (Vector.magnitude(velocity) > 0) then
		--Calculate orientation using arctan of velocity components.
		return math.deg(math.atan2(velocity.y, velocity.x)) % 360
	end
	-- Otherwise use current orientation
	return currentOrientation
end

local function kinematicSeek(character)
	-- Holds the static data for the character and target
	local character = character
	local target = character.target
	-- Holds the maximum spped the character can travel
	local maxSpeed = character.maxSpeed
	-- Create the structure for the output
	local steering = {linear = {x = 0, y = 0}, angular = 0}
	-- Get the direction to the target
	local linear = Vector.subtract(target, character)
	-- Velocity in this direction at full speed
	linear = Vector.normalize(linear)
	linear = Vector.multiply(linear, maxSpeed)
	-- Face in the direction we want to move
	character.rotation = getNewOrienation(character.rotation, linear)
	steering.linear = linear
	return steering
end

local function kinematicFlee(character)
	-- Holds the static data for the character and target
	local character = character
	local target = character.target
	-- Holds the maximum spped the character can travel
	local maxSpeed = character.maxSpeed
	-- Create the structure for the output
	local steering = {linear = {x = 0, y = 0}, angular = 0}
	-- Get the direction away from the target
	local linear = Vector.subtract(character, target)
	-- Velocity in this direction at full speed
	linear = Vector.normalize(linear)
	linear = Vector.multiply(linear, maxSpeed)
	-- Face in the direction we want to move
	character.rotation = getNewOrienation(character.rotation, linear)
	steering.linear = linear
	return steering
end

local function kinematicArrive(character)
	-- Holds the static data for the character and target
	local character = character
	local target = character.target
	-- Holds the maximum spped the character can travel
	local maxSpeed = character.maxSpeed
	-- Holds the satisfaction radius
	local radius = character.targetRadius
	-- Holds the time to target constant
	local framesToTarget = character.framesToTarget
	-- Create the structure for the output
	local steering = {linear = {x = 0, y = 0}, angular = 0}
	-- Get the direction to the target
	local linear = Vector.subtract(target, character)
	-- Check if we are within radius
	local distance = Vector.magnitude(linear)
	if (distance < radius) then
		return steering -- We can return the 0 steering request
	end
	-- We need to move to our target, we'd like to get there in framesToTarget frames
	linear = Vector.divide(linear, framesToTarget)
	-- If this is too fast, clip it to the max speed
	local distance = Vector.magnitude(linear)
	if (distance > maxSpeed) then
		linear = Vector.normalize(linear)
		linear = Vector.multiply(linear, maxSpeed)
	end
	-- Face in the direction we want to move
	character.rotation = getNewOrienation(character.rotation, linear)
	steering.linear = linear
	return steering
end

local function kinematicWander(character)
	-- Holds the static data for the character
	local character = character
	-- Holds the maximum spped the character can travel
	local maxSpeed = character.maxSpeed
	-- Holds the maxiumum rotation we'd like
	local maxRotation = character.maxRotation
	-- Create the structure for the output
	local steering = {linear = {x = 0, y = 0}, angular = 0}
	-- Get velocity from vector form of orientation
	local rads = math.rad(character.rotation)
	local linear = {x = math.cos(rads), y = math.sin(rads)}
	linear = Vector.multiply(linear, maxSpeed)
	-- Change our orientation randomly
	steering.angular = randomBinomial() * maxRotation
	steering.linear = linear
	return steering
end

function Kinematic.new(param)
	param = param or {}
	local self
	if (param.type == "rect" or param.type == nil) then
		self = display.newRect(0,0,60,30)
	elseif (param.type == "circ") then
		self = display.newRect(0,0,60,30)
	else
		local width = param.imageWidth or 64
		local height = param.imageHeight or 64
		self = display.newImageRect(param.type, width, height)
	end
	self.x = param.x or self.width / 2
	self.y = param.y or self.height / 2
	self.rotation = param.rotation or 0 -- orientation
	self.velocity = {x = 0, y = 0}
	self.angularVelocity = 0 -- rotation
	self.maxSpeed = param.maxSpeed or 5 -- speed is pixels per frame (based on 30 fps)
	self.maxRotation = param.maxRotation or 12 -- angle is degree per frame
	self.target = param.target
	self.targetRadius = param.targetRadius or 1
	self.framesToTarget = param.framesToTarget or 5
	if (param.move == "seek") then self.move = kinematicSeek
	elseif (param.move == "flee") then self.move = kinematicFlee
	elseif (param.move == "arrive") then self.move = kinematicArrive
	elseif (param.move == "wander") then self.move = kinematicWander
	else self.move = nil end
	
	local lastTime = system.getTimer()
	function self:enterFrame(event)
		-- Get time passed since last event
		local time = (event.time - lastTime) / 1000 * 30 -- 1/30 second
		lastTime = event.time
		-- Update the position and rotation
		local position = {x = self.x, y = self.y}
		position = Vector.add(position, Vector.multiply(self.velocity,time))
		self.x, self.y = position.x, position.y
		self.rotation = self.rotation + self.angularVelocity * time
		if (self.move) then
			-- get steering vector
			local steering = self.move(self, self.target)
			-- and the velocity and angularVelocity
			self.velocity = Vector.multiply(steering.linear, time)
			self.angularVelocity = steering.angular * time
		end
	end
	
	Runtime:addEventListener("enterFrame", self)
	
	function self:delete()
		Runtime:removeEventListener("enterFrame", self)
		self:removeSelf()
	end
	
	return self
end

return Kinematic