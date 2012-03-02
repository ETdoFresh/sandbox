--================================
-- Map Class
-- A display group that is able to
-- scroll and zoom
--================================
local Map = {}

-- Requirements
local Vector = require 'Vector'

function Map.new(param)
	param = param or {} -- Input parameters must be a table regardless
	--================================
	-- Private Variables
	--================================
	local map = param.self or display.newGroup()
	local viewWidth = param.viewWidth or map.width
	local viewHeight = param.viewHeight or map.height
	local isFocus = false
	local prevTime, prevPos, velocity
	
	--================================
	-- Public Variables
	--================================
	map.x = param.x or map.x
	map.y = param.y or map.y
	map.rotation = param.rotation or map.rotation
	
	-- This function will be replaced
	local superRemoveSelf = map.removeSelf
	
	--================================
	-- Private Functions
	--================================
	local function trackVelocity(event)
		if (prevPos) then 
			local timePassed = event.time - prevTime
			velocity = Vector.subtract(map, prevPos)
			velocity = Vector.divide(velocity, timePassed)
		end
		prevTime = event.time
		prevPos = {x = map.x, y = map.y}
	end
	
	local function slowDown(event)
		local friction = 0.8
		local timePassed = event.time - prevTime
		prevTime = event.time
        velocity = Vector.multiply(velocity, friction)
        local newPos = Vector.multiply(velocity, timePassed)
		newPos = Vector.add(newPos, map)
		map.x = newPos.x
		map.y = newPos.y
		
		--turn off scrolling if velocity is near zero
        if (velocity and Vector.magnitude(velocity) < .01) then
            velocity = nil
	        Runtime:removeEventListener("enterFrame", slowDown)
        end
		
		return true
	end
	
	local function onDrag(event)
		if (event.phase == "began") then
			Runtime:removeEventListener("enterFrame", slowDown)
			Runtime:addEventListener("enterFrame", trackVelocity)
			display.getCurrentStage():setFocus(map)
			isFocus = true
			map.x0 = map.x
			map.y0 = map.y
		elseif (isFocus) then
			if (event.phase == "moved") then
				local dx = event.x - event.xStart
				local dy = event.y - event.yStart
				map.x = map.x0 + dx
				map.y = map.y0 + dy
			elseif (event.phase == "ended" or event.phase == "cancelled") then
				local dx = event.x - event.xStart
				local dy = event.y - event.yStart
				map.x = map.x0 + dx
				map.y = map.y0 + dy
				Runtime:removeEventListener("enterFrame", trackVelocity)
				Runtime:addEventListener("enterFrame", slowDown)
				display.getCurrentStage():setFocus(nil)
				isFocus = false
				prevPos = nil
			end
		end
	end
	
	--================================
	-- Public Functions
	--================================
	function map:removeSelf()
		Runtime:removeEventListener("enterFrame", trackVelocity)
		Runtime:removeEventListener("enterFrame", slowDown)
		map:removeEventListener("touch", onDrag)
		superRemoveSelf(map)
	end
	
	--================================
	-- Constructor
	--================================
	map:addEventListener("touch", onDrag)
	
	return map
end

return Map