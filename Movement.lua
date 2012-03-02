local Movement = {}

function randomBinomial()
	return math.random() - math.random()
end

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

function Movement.new(param)
	local self = display.newRect(0,0,60,30)
	physics.addBody( self, { density=1, friction=0.2, bounce=0.2 } )
	self.x = param.x or self.width / 2
	self.y = param.y or self.height / 2
	self.rotation = param.rotation or 0 -- orientation
	--velocity defined by self:getLinearVelocity()
	--rotation defined by self:getAngularVelocity()	
	self.maxAcceleration = param.maxAcceleration or 5
	self.maxAngularAcceleration = param.maxAngularAcceleration or 20
	self.maxSpeed = param.maxSpeed or 100 -- speed is pixels per frame (based on 30 fps)
	self.maxRotation = param.maxRotation or 360 -- angle is degree per frame
	self.movementType = seek
	self.target = param.target
	self.targetRadius = param.targetRadius or 1
	self.framesToTarget = param.framesToTarget or 5
	
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
		-- get steering vector
		local steering = self.movementType(self, self.target)
		-- and the velocity and angularVelocity
		self.velocity = Vector.multiply(steering.linear, time)
		self.angularVelocity = steering.angular * time
	end
	
	Runtime:addEventListener("enterFrame", self)
	
	function self:delete()
		Runtime:removeEventListener("enterFrame", self)
		self:removeSelf()
	end
	
	return self
end

return Movement