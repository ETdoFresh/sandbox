--==============================
-- Movement
-- A "physics required" movement engine
-- by E.T. Garcia
-- reference Artificial Intelligence for Games 2nd Ed by Millington and Funge
--==============================
local Movement = {}

-- Require Vector functions
local Vector = require "Vector"

-- Default Values
local maxAcceleration = 10
local maxSpeed = 100 -- speed is pixels per second
local targetRadius = 3
local slowRadius = maxSpeed * 3 / 4
local timeToTarget = 0.1
local maxAngularAcceleration = 5
local maxRotation = 360 -- angle is degree per second
local targetAngularRadius = 5
local slowAngularRadius = maxRotation * 3 / 4
local timeToAngularTarget = 1
local maxPrediction = 1
local wanderOffset = 50
local wanderRadius = 32
local wanderRate = 10
local wanderOrientation = 0

-- Classes
local seek = {}
local flee = {}
local arrive = {}
local align = {}
local velocityMatch = {}
local pursue = {}
local evade = {}
local face = {}
local lookWhereYouGoing = {}
local wander = {}

-- Local Functions
local function randomBinomial()
	return math.random() - math.random()
end

local function getVelocity(object)
	local velocity = {x = 0, y = 0}
	if (object.isBodyActive) then velocity.x, velocity.y = object:getLinearVelocity()
	elseif (object.velocity) then velocity = object.velocity end
	return velocity
end

-- Class Functions
function seek.new(param)
	local self = {}
	-- Holds the static data for the character and target
	local character = param.character
	local target = param.target
	-- Holds the maximum speed the character can travel
	local maxAcceleration = param.maxAcceleration or maxAcceleration
	-- Returns the desired steering output
	function self:getSteering()
		-- Create the structure for the output
		local steering = {linear = {x = 0, y = 0}, angular = 0}
		-- Get the direction to the target
		local linear = Vector.subtract(target, character)
		-- Give full acceleration along this direction
		linear = Vector.normalize(linear)
		linear = Vector.multiply(linear, maxAcceleration)
		steering.linear = linear
		return steering
	end
	return self
end

function flee.new(param)
	local self = {}
	-- Holds the static data for the character and target
	local character = param.character
	local target = param.target
	-- Holds the maximum speed the character can travel
	local maxAcceleration = param.maxAcceleration or maxAcceleration
	-- Returns the desired steering output
	function self:getSteering()
		-- Create the structure for the output
		local steering = {linear = {x = 0, y = 0}, angular = 0}
		-- Get the direction away from the target
		local linear = Vector.subtract(character, target)
		-- Give full acceleration along this direction
		linear = Vector.normalize(linear)
		linear = Vector.multiply(linear, maxAcceleration)
		steering.linear = linear
		return steering
	end
	return self
end

function arrive.new(param)
	local self = {}
	-- Holds the static data for the character and target
	local character = param.character
	local target = param.target
	-- Holds the maximum acceleration and speed the character can travel
	local maxAcceleration = param.maxAcceleration or maxAcceleration
	local maxSpeed = param.maxSpeed or maxSpeed
	-- Holds the radius for arriving at the target
	local targetRadius = param.targetRadius or targetRadius
	-- Holds the radius for beginning to slow down
	local slowRadius = param.slowRadius or slowRadius
	-- Holds the time over which to achieve target speed
	local timeToTarget = param.timeToTarget or timeToTarget
	-- Returns the desired steering output
	function self:getSteering()
		-- Create the structure for the output
		local steering = {linear = {x = 0, y = 0}, angular = 0}
		-- Get the direction to the target
		local direction = Vector.subtract(target, character)
		local distance = Vector.magnitude(direction)
		-- Check if we are there, return blank steering
		if (distance < targetRadius) then
			return nil
		end
		-- If we are outside the slowRadius, then go max speed
		local targetSpeed
		if (distance > slowRadius) then
			targetSpeed = maxSpeed
		-- Otherwise calculate a scaled speed
		else
			targetSpeed = maxSpeed * distance / slowRadius
		end
		-- The target velocity combines speed and direction
		local targetVelocity = direction
		targetVelocity = Vector.normalize(targetVelocity)
		targetVelocity = Vector.multiply(targetVelocity, targetSpeed)
		-- Acceleration tries to get to the target velocity
		local velocity = getVelocity(character)
		local linear = Vector.subtract(targetVelocity, velocity)
		linear = Vector.divide(linear, timeToTarget)
		-- Check if the acceleration is too fast
		local acceleration = Vector.magnitude(linear)
		if (acceleration > maxAcceleration) then
			linear = Vector.normalize(linear)
			linear = Vector.multiply(linear, maxAcceleration)
		end
		steering.linear = linear
		return steering
	end
	return self
end

function align.new(param)
	local self = {}
	-- Holds the static data for the character and target
	local character = param.character
	local target = param.target
	-- Holds max angular acceleration and rotation of the character
	local maxAngularAcceleration = param.maxAngularAcceleration or maxAngularAcceleration
	local maxRotation = param.maxRotation or maxRotation
	-- Holds the radius for arriving at the target
	local targetRadius = param.targetAngularRadius or targetAngularRadius
	-- Holds the radius for beginning to slow down
	local slowRadius = param.slowAngularRadius or slowAngularRadius
	-- Holds the time over which to achieve target speed
	local timeToTarget = param.timeToAngularTarget or timeToAngularTarget
	-- Returns the desired steering output
	function self:getSteering()
		-- Create the structure for the output
		local steering = {linear = {x = 0, y = 0}, angular = 0}
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
			targetRotation = maxRotation
		-- Otherwise calculate a scaled rotation
		else
			targetRotation = maxRotation * rotationSize / slowRadius
		end
		-- The final target rotation combines speed and direction
		targetRotation = targetRotation * rotation / rotationSize
		-- Acceleration tried to get to the target rotation
		local angular = targetRotation - character.angularVelocity
		angular = angular / timeToTarget
		-- Check if the acceleration is too great
		local angularAcceleration = math.abs(angular)
		if (angularAcceleration > maxAngularAcceleration) then
			angular = angular / angularAcceleration
			angular = angular * maxAngularAcceleration
		end
		steering.angular = angular
		return steering
	end
	return self
end

function velocityMatch.new(param)
	local self = {}
	-- Holds the static data for the character and target
	local character = param.character
	local target = param.target
	-- Holds max acceleration of the character
	local maxAcceleration = param.maxAcceleration or maxAcceleration
	-- Holds the time over which to achieve target speed
	local timeToTarget = param.timeToTarget or timeToTarget
	-- Returns the desired steering output
	function self:getSteering()
		-- Create the structure for the output
		local steering = {linear = {x = 0, y = 0}, angular = 0}
		-- Acceleration tried to get to the target velocity
		local tVelocity = getVelocity(target)
		local velocity = getVelocity(character)
		local linear = Vector.subtract(tVelocity, velocity)
		linear = Vector.divide(linear, timeToTarget)
		-- Check if the acceleration is too fast
		local acceleration = Vector.magnitude(linear)
		if (acceleration > maxAcceleration) then
			linear = Vector.normalize(linear)
			linear = Vector.multiply(linear, maxAcceleration)
		end
		steering.linear = linear
		return steering
	end
	return self
end

function pursue.new(param)
	local self = {}
	-- Holds the static data for the character and target
	local character = param.character
	local target = param.target
	-- Holds the maximum prediction time
	local maxPrediction = param.maxPrediction or maxPrediction
	-- Returns the desired steering output
	function self:getSteering()
		-- Work out the distance to target
		local direction = Vector.subtract(target, character)
		local distance = Vector.magnitude(direction)
		-- Work out our current speed
		local speed = getVelocity(character)
		speed = Vector.magnitude(speed)
		-- Check if speed is too small to give a reasonable prediction time
		local prediction
		if (speed <= distance / maxPrediction) then
			prediction = maxPrediction
		-- Otherwise calculate the prediction time
		else
			prediction = distance / speed
		end
		-- Put the target together
		local newTarget = getVelocity(target)
		newTarget = Vector.multiply(newTarget, prediction)
		newTarget = Vector.add(newTarget, target)
		param.target = newTarget
		-- Delegate to seek
		local seek = seek.new(param)
		return seek:getSteering()
	end
	return self
end

function evade.new(param)
	local self = {}
	-- Holds the static data for the character and target
	local character = param.character
	local target = param.target
	-- Holds the maximum prediction time
	local maxPrediction = param.maxPrediction or maxPrediction
	-- Returns the desired steering output
	function self:getSteering()
		-- Work out the distance to target
		local direction = Vector.subtract(target, character)
		local distance = Vector.magnitude(direction)
		-- Work out our current speed
		local speed = getVelocity(character)
		speed = Vector.magnitude(speed)
		-- Check if speed is too small to give a reasonable prediction time
		local prediction
		if (speed <= distance / maxPrediction) then
			prediction = maxPrediction
		-- Otherwise calculate the prediction time
		else
			prediction = distance / speed
		end
		-- Put the target together
		local newTarget = getVelocity(target)
		newTarget = Vector.multiply(newTarget, prediction)
		newTarget = Vector.add(newTarget, target)
		param.target = newTarget
		-- Delegate to flee
		local flee = flee.new(param)
		return flee:getSteering()
	end
	return self
end

function face.new(param)
	local self = {}
	-- Holds the static data for the character and target
	local character = param.character
	local target = param.target
	-- Returns the desired steering output
	function self:getSteering()
		-- Work out direction to target
		local direction = Vector.subtract(target, character)
		-- Check for zero direction, and make no change if so
		if (Vector.magnitude(direction) == 0) then return nil end
		-- Put the target together
		local newTarget = math.deg(math.atan2(-direction.y, -direction.x))
		newTarget = {rotation = newTarget}
		-- Delegate to align
		local align = align.new{character = character, target = newTarget,
			maxAngularAcceleration = param.maxAngularAcceleration, maxRotation = param.maxRotation,
			targetRadius = param.targetAngularRadius, slowRadius = param.slowAngularRadius,
			timeToTarget = param.timeToAngularTarget
		}
		return align:getSteering()
	end
	return self
end

function lookWhereYouGoing.new(param)
	local self = {}
	-- Holds the static data for the character and target
	local character = param.character
	-- Returns the desired steering output
	function self:getSteering()
		local velocity = getVelocity(character)
		-- Check for zero direction, and make no change if so
		if (Vector.magnitude(velocity) == 0) then return nil end
		-- Put the target together
		local newTarget = math.deg(math.atan2(-velocity.y, -velocity.x))
		newTarget = {rotation = newTarget}
		-- Delegate to align
		local align = align.new{character = character, target = newTarget,
			maxAngularAcceleration = param.maxAngularAcceleration, maxRotation = param.maxRotation,
			targetRadius = param.targetAngularRadius, slowRadius = param.slowAngularRadius, 
			timeToTarget = param.timeToAngularTarget
		}
		return align:getSteering()
	end
	return self
end

function wander.new(param)
	local self = {}
	-- Holds the static data for the character and target
	local character = param.character
	-- Holds te radius and forward offset of the wander
	local wanderOffset = param.wanderOffset or wanderOffset
	local wanderRadius = param.wanderRadius or wanderRadius
	-- Holds the maximum rate at which the wanter orientation can change
	local wanderRate = param.wanderRate or wanderRate
	-- Holds the current orientation of the wander target
	local wanderOrientation = param.wanderOrientation or wanderOrientation
	-- Holds the maximum acceleration of the character
	local maxAcceleration = param.maxAcceleration or maxAcceleration
	-- Returns the desired steering output
	function self:getSteering()
		-- Update the wander orientation
		wanderOrientation = wanderOrientation + randomBinomial() * wanderRate
		-- Calculate the combined target orientation
		local targetOrientation = wanderOrientation + character.rotation
		targetOrientation = Vector.fromAngle(targetOrientation)
		targetOrientation = Vector.multiply(targetOrientation, wanderRadius)
		-- Calculate the center of the wander circle
		local target = Vector.fromAngle(character.rotation)
		target = Vector.multiply(target, wanderOffset)
		target = Vector.add(target, character)
		-- Calculate the target location
		target = Vector.add(target, targetOrientation)
		-- Delegate to face
		local face = face.new{character = character, target = target,
			maxAngularAcceleration = param.maxAngularAcceleration, maxRotation = param.maxRotation,
			targetRadius = param.targetAngularRadius, slowRadius = param.slowAngularRadius,
			timeToTarget = param.timeToAngularTarget
		}
		local steering = face:getSteering() or {angular = 0}
		-- Now set the linear acceleration to be at full acceleration
		-- in the direction of the orientation
		local linear = Vector.fromAngle(character.rotation)
		linear = Vector.multiply(linear, maxAcceleration)
		steering.linear = linear
		return steering
	end
	return self
end


function Movement.new(param)
	local self = param.self or display.newGroup()
	param.character = self
	
	-- Setup physics
	local density = param.density or 1
	local friction = param.friction or 0.2
	local bounce = param.bounce or 0.2
	local radius = param.radius
	physics.addBody(self, {density=density, friction=friction, bounce=bounce, radius=radius})
	
	-- Public variables
	self.x = param.x or display.contentWidth / 2 -- position
	self.y = param.y or display.contentHeight / 2
	self.rotation = param.rotation or 0 -- orientation
	--velocity defined by self:getLinearVelocity()
	--rotation defined by self.angularVelocity
	
	-- Setup steering code
	local movementType
	local rotationType
		
	function self:enterFrame(event)
		-- get steering vector
		local steering, aSteering
		if (movementType) then steering = movementType:getSteering() end
		if (rotationType) then aSteering = rotationType:getSteering() end
		if (aSteering) then
			if (steering and steering.angular == 0) then
				steering.angular = aSteering.angular
			elseif (not(steering)) then
				steering = aSteering
			end
		end
		-- If there is a steering vector, apply and verify
		if (steering) then
			-- and apply velocity
			self:applyForce(steering.linear.x, steering.linear.y, self.x, self.y)
			-- Check for speeding and clip (linear)
			local velocity = getVelocity(self)
			local maxSpeed = param.maxSpeed or maxSpeed
			if (Vector.magnitude(velocity) > maxSpeed) then
				velocity = Vector.normalize(velocity)
				velocity = Vector.multiply(velocity, maxSpeed)
				self:setLinearVelocity(velocity.x, velocity.y)
			end
			-- Check for speeding and clip (angular)
			self:applyTorque(steering.angular)
			local maxRotation = param.maxRotation or maxRotation
			if (math.abs(self.angularVelocity) > maxRotation) then
				local sign = self.angularVelocity / math.abs(self.angularVelocity)
				self.angularVelocity = sign * maxRotation
			end
		else
			self:setLinearVelocity(0, 0)
			self.angularVelocity = 0
		end
	end
		
	function self:setMovement(move)
		if (move == "seek") then movementType = seek.new(param)
		elseif (move == "flee") then movementType = flee.new(param)
		elseif (move == "arrive") then movementType = arrive.new(param)
		elseif (move == "velocityMatch") then movementType = velocityMatch.new(param)
		elseif (move == "pursue") then movementType = pursue.new(param)
		elseif (move == "evade") then movementType = evade.new(param)
		elseif (move == "wander") then movementType = wander.new(param)
		else movementType = nil end
	end
	
	function self:setRotation(rotate)
		if (rotate == "align") then rotationType = align.new(param)
		elseif (rotate == "face") then rotationType = face.new(param)
		elseif (rotate == "lookWhereYouGoing") then rotationType = lookWhereYouGoing.new(param)
		else rotationType = nil end
	end
	
	function self:setTarget(target)
		param.target = target
		self:setMovement(param.move)
	end
	
	function self:delete()
		Runtime:removeEventListener("enterFrame", self)
		self:removeSelf()
	end
	
	self:setMovement(param.move)
	self:setRotation(param.rotate)
	Runtime:addEventListener("enterFrame", self)
	return self
end

return Movement