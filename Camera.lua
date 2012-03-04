--================================
-- Camera Class
-- A display group that is able to
-- scroll and zoom
--================================
local Camera = {}

local screen = {width = display.contentWidth, height = display.contentHeight}
local center = {x = screen.width / 2, y = screen.height / 2}

-- Requirements
local Vector = require 'Vector'

function Camera.new(param)
	param = param or {} -- Input parameters must be a table regardless
	--================================
	-- Private Variables
	--================================
	local self = param.self or display.newGroup() -- display group
	local xMin, yMin = 0, 0 -- the min limits
	local xMax = param.xMax or self.width
	local yMax = param.yMax or self.height
	local target = param.target or {x = 0, y = 0}
	local scale = 1
	
	--================================
	-- Public Variables
	--================================
	self.x = param.x or self.x
	self.y = param.y or self.y
	self.rotation = param.rotation or self.rotation
	
	-- These functions will be replaced
	local superRemoveSelf = self.removeSelf
	
	--================================
	-- Private Functions
	--================================	
	local function followTarget(event)
		-- Get the center of the screen
		-- Calculate top left (final result) (almost)
		local newX = -(target.x * scale - center.x)
		local newY = -(target.y * scale - center.y)
		local xMin = xMin * scale
		local yMin = yMin * scale
		local xMax = xMax * scale
		local yMax = yMax * scale
		-- Limit camera top and left
		newX = math.min(newX, xMin)
		newY = math.min(newY, yMin)
		-- Limit camera bottom and right
		newX = math.max(newX, -(xMax - screen.width))
		newY = math.max(newY, -(yMax - screen.height))
		-- Move camera for this frame!
		self.x = newX
		self.y = newY
	end
	
	--================================
	-- Public Functions
	--================================
	function self:getLimits()
		local xMin = center.x / scale
		local yMin = center.y / scale
		local xMax = xMax - center.x / scale
		local yMax = yMax - center.y / scale
		return {xMin = xMin, yMin = yMin, xMax = xMax, yMax = yMax}
	end
	
	function self:refreshSize()
		xMax, yMax = self.width, self.height
	end
	
	function self:setZoom(zoom)
		scale = zoom or scale
		self.xScale, self.yScale = scale, scale
	end
	
	function self:setTarget(newTarget)
		target = newTarget or target
	end
	
	function self:removeSelf()
		Runtime:removeEventListener("enterFrame", followTarget)
		Runtime:removeEventListener("enterFrame", slowDown)
		self:removeEventListener("touch", onDrag)
		superRemoveSelf(self)
	end
	
	--================================
	-- Constructor
	--================================
	Runtime:addEventListener("enterFrame", followTarget)
	
	return self
end

function Camera.newTarget(param)
	param = param or {} -- Input parameters must be a table regardless
	--================================
	-- Private Variables
	--================================
	local self = param.self or display.newCircle(center.x, center.y, 10)
	local isFocus = false
	local prevPos, prevTime, velocity
	local xMin, yMin = 0, 0
	local xMax = self.parent.width
	local yMax = self.parent.height
	
	-- These functions will be replaced
	local superRemoveSelf = self.removeSelf
	
	--================================
	-- Private Functions
	--================================
	local function trackVelocity(event)
		if (prevPos) then 
			local timePassed = event.time - prevTime
			velocity = Vector.subtract(self, prevPos)
			velocity = Vector.divide(velocity, timePassed)
		end
		prevTime = event.time
		prevPos = {x = self.x, y = self.y}
	end
	
	local function limit(pos)
		local limit = {x = pos.x, y = pos.y}
		if (pos.x < xMin) then limit.x = xMin
		elseif (pos.x > xMax) then limit.x = xMax end
		if (pos.y < yMin) then limit.y = yMin
		elseif (pos.y > yMax) then limit.y = yMax end
		return limit
	end
	
	local function slowDown(event)
		--turn off scrolling if velocity is near zero
        if (Vector.magnitude(velocity) < .01) then
            velocity = {x = 0, y = 0}
	        Runtime:removeEventListener("enterFrame", slowDown)
		end
		local friction = 0.8
		local timePassed = event.time - prevTime
		prevTime = event.time
        velocity = Vector.multiply(velocity, friction)
        local delta = Vector.multiply(velocity, timePassed)
		if (math.abs(delta.x) > 0) then self.x = self.x + delta.x end
		if (math.abs(delta.y) > 0) then self.y = self.y + delta.y end		
		local limit = limit(self)
		if (limit.x ~= self.x) then velocity.x = 0 end
		if (limit.y ~= self.y) then velocity.y = 0 end
		self.x = limit.x
		self.y = limit.y
		return true
	end
	
	local function onDrag(event)
		local target = event.target
		if (event.phase == "began") then
			local limits = target:getLimits()
			xMin, yMin = limits.xMin, limits.yMin
			xMax, yMax = limits.xMax, limits.yMax
			display.getCurrentStage():setFocus(target)
			isFocus = true
			self.x0 = event.x
			self.y0 = event.y
			Runtime:removeEventListener("enterFrame", slowDown)
			Runtime:addEventListener("enterFrame", trackVelocity)
		elseif (isFocus) then
			if (event.phase == "moved") then
				local newPos = {x = self.x - (event.x - self.x0), y = self.y - (event.y - self.y0)}
				local limit = limit(newPos)
				self.x, self.y = limit.x, limit. y
				self.x0, self.y0 = event.x, event.y
			elseif (event.phase == "ended" or event.phase == "cancelled") then
				display.getCurrentStage():setFocus(nil)
				isFocus = false
				Runtime:removeEventListener("enterFrame", trackVelocity)
				Runtime:addEventListener("enterFrame", slowDown)
			end
		end
		return true
	end
	
	--================================
	-- Public Functions
	--================================	
	function self:removeSelf()
		self:addTouch(nil) -- Remove touch events
		superRemoveSelf(self)
	end
	
	function self:touch(event)
		onDrag(event)
	end
	
	--================================
	-- Constructor
	--================================
	self:setFillColor(0, 0, 255)
	
	return self
end

return Camera