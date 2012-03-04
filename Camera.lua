--================================
-- Camera Class
-- A display group that is able to
-- scroll and zoom
--================================
local Camera = {}

-- Requirements
local Vector = require 'Vector'

function Camera.new(param)
	param = param or {} -- Input parameters must be a table regardless
	--================================
	-- Private Variables
	--================================
	local self = param.self or display.newGroup()
	local xMin = param.xMin or 0
	local yMin = param.yMin or 0
	local xMax = param.xMax or self.width
	local yMax = param.yMax or self.height
	local scale = 1
	local isFocus = false
	local prevTime, prevPos, velocity, focusTime
	local tween = {x = nil, y = nil}
	
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
	local function trackVelocity(event)
		if (prevPos) then 
			local timePassed = event.time - prevTime
			velocity = Vector.subtract(self, prevPos)
			velocity = Vector.divide(velocity, timePassed)
		end
		prevTime = event.time
		prevPos = {x = self.x, y = self.y}
		-- Lose focus after a certain amount of time (in case it gets stuck, like on android systems after mutlitouch)
		if (event.time - focusTime > 1000) then
			self:dispatchEvent{name = "touch", phase = "cancelled"}
		end
		-- Remove listener if not focused
		if (not(isFocus)) then Runtime:removeEventListener("enterFrame", trackVelocity) end
	end
		
	local function slowDown(event)
		-- Remove listener if focused
		if (isFocus) then Runtime:removeEventListener("enterFrame", slowDown) end
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

		if (not(tween.x)) then
			if (self.x > xMin) then
				velocity.x = 0
				tween.x = transition.to(self, {time = 400, x = 0, transition=easing.outQuad, onComplete = function() tween.x = nil end})
			elseif (self.x < display.contentWidth - xMax * scale) then
				velocity.x = 0
				tween.x = transition.to(self, {time = 400, x = display.contentWidth - xMax * scale, transition=easing.outQuad, onComplete = function() tween.x = nil end})
			end
		end
		if (not(tween.y)) then
			if (self.y > 0) then
				velocity.y = 0
				tween.y = transition.to(self, {time = 400, y = 0, transition=easing.outQuad, onComplete = function() tween.y = nil end})
			elseif (self.y < display.contentHeight - yMax * scale) then
				velocity.y = 0
				tween.y = transition.to(self, {time = 400, y = display.contentHeight - yMax * scale, transition=easing.outQuad, onComplete = function() tween.y = nil end})
			end
		end
		
		return true
	end
	
	local function onDrag(event)
		focusTime = system.getTimer()
		if (event.phase == "began") then
			Runtime:removeEventListener("enterFrame", slowDown)
			Runtime:addEventListener("enterFrame", trackVelocity)
			display.getCurrentStage():setFocus(self, event.id)
			isFocus = true
			self.x0, self.y0 = event.x, event.y
			if (tween.x) then transition.cancel(tween.x) end
			if (tween.y) then transition.cancel(tween.y) end
			tween.x = nil
			tween.y = nil
		elseif (isFocus) then
			if (event.phase == "moved") then
				local dx = event.x - self.x0
				local dy = event.y - self.y0
				self.x0, self.y0 = event.x, event.y
				if (self.x > 0 or self.x < display.contentWidth - xMax * scale) then dx = dx / 4 end
				if (self.y > 0 or self.y < display.contentHeight - yMax * scale) then dy = dy / 4 end				
				self.x = self.x + dx
				self.y = self.y + dy
			elseif (event.phase == "ended" or event.phase == "cancelled") then
				display.getCurrentStage():setFocus(nil)
				isFocus = false
				prevPos = nil
				Runtime:removeEventListener("enterFrame", trackVelocity)
				Runtime:addEventListener("enterFrame", slowDown)
			end
		end
	end
	
	--================================
	-- Public Functions
	--================================
	function self:refreshSize()
		mapWidth = self.width
		mapHeight = self.height
	end
	
	function self:giveControl()
		self:addEventListener("touch", onDrag)
	end
	
	function self:scale(newScale)
		-- Get center view point
		local newX = (self.x - display.contentWidth / 2)
		local newY = (self.y - display.contentHeight / 2)
		-- Set back to normal scale
		newX = newX / scale
		newY = newY / scale
		-- calculate new Scale
		scale = newScale or scale
		-- Scale center view point
		newX = newX * scale
		newY = newY * scale
		-- Get new top left point
		newX = newX + display.contentWidth / 2
		newY = newY + display.contentHeight / 2
		-- Get yo limits right
		if (newX > 0) then newX = 0
		elseif (newX < display.contentWidth - xMax * scale) then newX = display.contentWidth - xMax * scale end
		if (newY > 0) then newY = 0
		elseif (newY < display.contentHeight - yMax * scale) then newY = display.contentHeight - yMax * scale end
		transition.to(self, {time = 500, x = newX, y = newY, xScale = scale, yScale = scale})
	end
	
	function self:removeSelf()
		Runtime:removeEventListener("enterFrame", trackVelocity)
		Runtime:removeEventListener("enterFrame", slowDown)
		self:removeEventListener("touch", onDrag)
		superRemoveSelf(self)
	end
	
	--================================
	-- Constructor
	--================================
	self:addEventListener("touch", onDrag)
	
	return self
end

return Camera