--==============================
-- Steering
-- A "physics required" movement engine
-- by E.T. Garcia
-- reference Artificial Intelligence for Games 2nd Ed by Millington and Funge
--==============================

-- Require Vector functions
local Vector = require "Vector"

-- Classes in this file
local Steering = {}
local Seek = {}
local Arrive = {}
local Pursue = {}

-- Default Values
local maxAcceleration = 10 -- Holds the maximum acceleration the character can travel (pix/sec)
local maxSpeed  = 150 -- Holds the maximum speed the character can travel (pix/sec)
local targetRadius = 5 -- Holds the radius for arriving at the target
local slowRadius = maxSpeed / 2 -- Holds the radius for beginning to slow down
local timeToTarget = 0.1 -- Holds the time over which to achieve target speed
local maxPrediction = 2 -- Holds the maxiumum prediction time

local function getVelocity(object)
	local velocity = {x = 0, y = 0}
	if (object.isBodyActive) then velocity.x, velocity.y = object:getLinearVelocity()
	elseif (object.velocity) then velocity = object.velocity end
	return velocity
end

function Seek.new(param)
	local self = {}
	self.character = param.character -- Holds the static data for the character and target
	self.target = param.target
	self.maxAcceleration = param.maxAcceleration or maxAcceleration -- Holds the maximum acceleration the character can travel
	
	-- Returns the desired steering output
	function self:getSteering()
		local character, target, maxAcceleration = self.character, self.target, self.maxAcceleration
		local steering = {linear = {x = 0, y = 0}, angular = 0} -- Create the structure for the output
		local linear = Vector.subtract(target, character) -- Get the direction to the target
		linear = Vector.normalize(linear)	-- Give full acceleration along this direction
		linear = Vector.multiply(linear, maxAcceleration)
		steering.linear = linear
		return steering
	end
	return self
end

function Arrive.new(param)
	local self = {}
	self.character = param.character -- Holds the static data for the character and target
	self.target = param.target
	self.maxAcceleration = param.maxAcceleration or maxAcceleration -- Holds the maximum acceleration and speed the character can travel
	self.maxSpeed = param.maxSpeed or maxSpeed
	self.targetRadius = param.targetRadius or targetRadius -- Holds the radius for arriving at the target
	self.slowRadius = param.slowRadius or slowRadius -- Holds the radius for beginning to slow down
	self.timeToTarget = param.timeToTarget or timeToTarget -- Holds the time over which to achieve target speed
	
	function self:getSteering()
		local character, target, maxAcceleration = self.character, self.target, self.maxAcceleration
		local maxSpeed, targetRadius, slowRadius = self.maxSpeed, self.targetRadius, self.slowRadius
		local timeToTarget = self.timeToTarget
		local steering = {linear = {x = 0, y = 0}, angular = 0} -- Create the structure for the output
		local direction = Vector.subtract(target, character) -- Get the direction to the target
		local distance = Vector.magnitude(direction)
		if (distance < targetRadius) then -- Check if we are there, return blank steering
			return nil
		end
		local targetSpeed
		if (distance > slowRadius) then -- If we are outside the slowRadius, then go max speed
			targetSpeed = maxSpeed
		else -- Otherwise calculate a scaled speed
			targetSpeed = maxSpeed * distance / slowRadius
		end
		-- The target velocity combines speed and direction
		local targetVelocity = direction
		targetVelocity = Vector.normalize(targetVelocity)
		targetVelocity = Vector.multiply(targetVelocity, targetSpeed)
		local velocity = getVelocity(character) -- Acceleration tries to get to the target velocity
		local linear = Vector.subtract(targetVelocity, velocity)
		linear = Vector.divide(linear, timeToTarget)
		local acceleration = Vector.magnitude(linear) -- Check if the acceleration is too fast
		if (acceleration > maxAcceleration) then
			linear = Vector.normalize(linear)
			linear = Vector.multiply(linear, maxAcceleration)
		end
		steering.linear = linear
		return steering
	end
	return self
end

function Pursue.new(param)
	local self = {}
	self.character = param.character -- Holds the static data for the character and target
	self.target = param.target
	self.maxPrediction = param.maxPrediction or maxPrediction -- Holds the maxiumum prediction time
	
	-- Returns the desired steering output
	function self:getSteering()
		local character, target, maxPrediction = self.character, self.target, self.maxPrediction
		local direction = Vector.subtract(target, character) -- Work out the distance to target
		local distance = Vector.magnitude(direction)
		local speed = getVelocity(character) -- Work out our current speed
		speed = Vector.magnitude(speed)
		local prediction -- Check if speed is too small to give a reasonable prediction time
		if (speed <= distance / maxPrediction) then
			prediction = maxPrediction
		else -- Otherwise calculate the prediction time
			prediction = distance / speed
		end
		local newTarget = getVelocity(target) -- Put the target together
		newTarget = Vector.multiply(newTarget, prediction)
		newTarget = Vector.add(newTarget, target)
		param.target = newTarget
		local Seek = Seek.new(param) -- Delegate to seek
		return Seek:getSteering()
		
	end
	return self
end

function Steering.new(param)
	param.character = param.self or display.newGroup()
	local self = param.character
	local steeringType
	
	function self:enterFrame(event)
		local steering = steeringType:getSteering()
		local velocity = getVelocity(self)
		if (steering) then
			velocity = Vector.add(velocity, steering.linear)
			local maxSpeed = param.maxSpeed or maxSpeed
			if (Vector.magnitude(velocity) > maxSpeed) then
				velocity = Vector.normalize(velocity)
				velocity = Vector.multiply(velocity, maxSpeed)
			end
			self:setLinearVelocity(velocity.x, velocity.y)
		else
			self:setLinearVelocity(0, 0)
		end
	end
	
	function self:setSteering(input)
		Runtime:removeEventListener("enterFrame", self) -- Stop updating
		if (input == "seek") then steeringType = Seek.new(param)
		elseif (input == "arrive") then steeringType = Arrive.new(param)
		elseif (input == "pursue") then steeringType = Pursue.new(param)
		else steeringType = nil end
		if (steeringType) then Runtime:addEventListener("enterFrame", self) end -- Start updating
	end
	
	function self:setTarget(target)
		param.target = target
		if (steeringType) then steeringType.target = target end
	end
	
	physics.addBody(self, {density = param.density, friction = param.friction, bounce = param.bounce, radius = param.radius})
	
	return self
end

return Steering