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
local Align = {}
local Face = {}
local LookWhereYoureGoing = {}
local Combine = {}

-- Default Values
local maxAcceleration = 10 -- Holds the maximum acceleration the character can travel (pix/sec)
local maxSpeed  = 150 -- Holds the maximum speed the character can travel (pix/sec)
local targetRadius = 5 -- Holds the radius for arriving at the target
local slowRadius = maxSpeed / 2 -- Holds the radius for beginning to slow down
local timeToTarget = 0.1 -- Holds the time over which to achieve target speed
local maxPrediction = 2 -- Holds the maxiumum prediction time
local maxTorque = 20 -- Holds max torque of the character
local maxRotation = 150 -- Holds max rotation of the character

local function getVelocity(object)
	local velocity = {x = 0, y = 0}
	if (object.isBodyActive) then velocity.x, velocity.y = object:getLinearVelocity()
	elseif (object.velocity) then velocity = object.velocity end
	return velocity
end

local function mapToRange(degree)
	if (degree > 180) then
		degree = degree - 360
		degree = mapToRange(degree)
	elseif (degree < -180) then
		degree = degree + 360
		degree = mapToRange(degree)
	end
	return degree
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
	local Seek = Seek.new(param)
	local self = {}
	self.character = param.character -- Holds the static data for the character and target
	self.target = param.target
	self.maxPrediction = param.maxPrediction or maxPrediction -- Holds the maxiumum prediction time
	
	-- Returns the desired steering output
	function self:getSteering()
		local character, target, maxPrediction = self.character, self.target, self.maxPrediction
		local direction = Vector.subtract(target, character) -- Work out the distance to target
		local distance = Vector.magnitude(direction)
		local speed = getVelocity(target) -- Work out our current speed
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
		Seek.target = newTarget
		return Seek:getSteering()  -- Delegate to seek
	end
	return self
end

function Align.new(param)
	local self = {}
	self.character = param.character -- Holds the static data for the character and target
	self.target = param.target
	self.maxTorque = param.maxTorque or maxTorque -- Holds max torque and rotation of the character
	self.maxRotation = param.maxRotation or maxRotation
	self.targetRadius = param.targetRadius or targetRadius -- Holds the radius for arriving at the target
	self.slowRadius = param.slowRadius or slowRadius -- Holds the radius for beginning to slow down
	self.timeToTarget = param.timeToTarget or timeToTarget -- Holds the time over which to achieve target speed
	
	function self:getSteering()
		local character, target, maxTorque = self.character, self.target, self.maxTorque
		local maxRotation, targetRadius, slowRadius = self.maxRotation, self.targetRadius, self.slowRadius
		local timeToTarget = self.timeToTarget
		local steering = {linear = {x = 0, y = 0}, angular = 0} -- Create the structure for the output
		local rotation = target.rotation - character.rotation -- Get the native direction to the target
		rotation = mapToRange(rotation) -- Map result to the (-180, 180) interval
		local rotationSize = math.abs(rotation)
		if (rotationSize < targetRadius) then return nil end -- Check if we are there, return no steering
		local targetRotation
		if (rotationSize > slowRadius) then -- If we are outside the slowRadius, then use maximum rotation
			targetRotation = maxRotation
		else -- Otherwise calculate a scaled rotation
			targetRotation = maxRotation * rotationSize / slowRadius
		end
		targetRotation = targetRotation * rotation / rotationSize -- The final target rotation combines speed and direction
		local angular = targetRotation - character.angularVelocity -- Acceleration tried to get to the target rotation
		angular = angular / timeToTarget -- Check if the acceleration is too great
		local angularAcceleration = math.abs(angular)
		if (angularAcceleration > maxTorque) then
			angular = angular / angularAcceleration
			angular = angular * maxTorque
		end
		steering.angular = angular
		return steering
	end
	return self
end

function Face.new(param)
	local self = {}
	self.character = param.character -- Holds the static data for the character and target
	self.target = param.target
	
	function self:getSteering() -- Implemented as it was in Pursue
		local character, target = self.character, self.target
		local direction = Vector.subtract(target, character) -- Work out direction to target
		if (Vector.magnitude(direction) == 0) then return nil end -- Check for zero direction, and make no change if so
		local newTarget = math.deg(math.atan2(direction.y, direction.x)) -- Put the target together
		newTarget = {rotation = newTarget}
		param.target = newTarget
		local Align = Align.new(param)
		return Align:getSteering()
	end
	return self
end

function LookWhereYoureGoing.new(param)
	local Align = Align.new(param)
	local self = {}
	self.character = param.character
	
	function self:getSteering() -- Implemented as it was in Pursue
		local character = self.character
		local velocity = getVelocity(character)
		if (Vector.magnitude(velocity) == 0) then return nil end -- Check for zero direction
		local rotation = Vector.toAngle(velocity)
		Align.target = {rotation = rotation} -- Set target based velocity
		return Align:getSteering()
	end
	return self
end

function Combine.new(param)
	local self = {}
	self.target = param.target
	local Arrive = Arrive.new(param)
	local Face = Face.new(param)
	
	function self:getSteering()	
		local target = self.target
		Arrive.target = target
		Face.target = target
		local move1 = Arrive:getSteering()
		local move2 = Face:getSteering()
		local steering = move1
		if (move1 and move2) then steering.angular = move2.angular
		elseif (move2) then steering = move2 end
		return steering
	end
	return self
end

function Steering.new(param)
	param.character = param.self or display.newGroup()
	local self = param.character
	local steeringType
	
	function self:enterFrame(event)
		local steering = steeringType:getSteering()
		if (steering) then
			-- Set Linear Velocity
			local velocity = getVelocity(self)
			velocity = Vector.add(velocity, steering.linear)
			local maxSpeed = param.maxSpeed or maxSpeed
			if (Vector.magnitude(velocity) > maxSpeed) then
				velocity = Vector.normalize(velocity)
				velocity = Vector.multiply(velocity, maxSpeed)
			end
			self:setLinearVelocity(velocity.x, velocity.y)
			-- Set Angular Velocity
			local velocity = self.angularVelocity + steering.angular
			local maxRotation = param.maxRotation or maxRotation
			if (math.abs(velocity) > maxRotation) then
				local sign = velocity / math.abs(velocity)
				velocity = sign * maxRotation
			end
			self.angularVelocity = velocity
		else
			self:setLinearVelocity(0, 0)
			self.angularVelocity = 0
		end
	end
	
	function self:setSteering(input)
		Runtime:removeEventListener("enterFrame", self) -- Stop updating
		if (input == "seek") then steeringType = Seek.new(param)
		elseif (input == "arrive") then steeringType = Arrive.new(param)
		elseif (input == "pursue") then steeringType = Pursue.new(param)
		elseif (input == "align") then steeringType = Align.new(param)
		elseif (input == "face") then steeringType = Face.new(param)
		elseif (input == "combine") then steeringType = Combine.new(param)
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