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
	local mapWidth = param.mapWidth or map.width
	local mapHeight = param.mapHeight or map.height
	local isFocus = false
	local prevTime, prevPos, velocity, focusTime
	local scale = 1
	local dimension = {width = mapWidth, height = mapHeight}
	local tween = {x = nil, y = nil}
	
	--================================
	-- Public Variables
	--================================
	map.x = param.x or map.x
	map.y = param.y or map.y
	map.rotation = param.rotation or map.rotation
	
	-- These functions will be replaced
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
		-- Lose focus after a certain amount of time (in case it gets stuck, like on android systems after mutlitouch)
		if (event.time - focusTime > 1000) then
			map:dispatchEvent{name = "touch", phase = "cancelled"}
		end
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
		if (math.abs(delta.x) > 0) then map.x = map.x + delta.x end
		if (math.abs(delta.y) > 0) then map.y = map.y + delta.y end

		if (not(tween.x)) then
			if (map.x > 0) then
				velocity.x = 0
				tween.x = transition.to(map, {time = 400, x = 0, transition=easing.outQuad, onComplete = function() tween.x = nil end})
			elseif (map.x < display.contentWidth - dimension.width) then
				velocity.x = 0
				tween.x = transition.to(map, {time = 400, x = display.contentWidth - dimension.width, transition=easing.outQuad, onComplete = function() tween.x = nil end})
			end
		end
		if (not(tween.y)) then
			if (map.y > 0) then
				velocity.y = 0
				tween.y = transition.to(map, {time = 400, y = 0, transition=easing.outQuad, onComplete = function() tween.y = nil end})
			elseif (map.y < display.contentHeight - dimension.height) then
				velocity.y = 0
				tween.y = transition.to(map, {time = 400, y = display.contentHeight - dimension.height, transition=easing.outQuad, onComplete = function() tween.y = nil end})
			end
		end
		
		return true
	end
	
	local function onDrag(event)
		focusTime = system.getTimer()
		if (event.phase == "began") then
			Runtime:removeEventListener("enterFrame", slowDown)
			Runtime:addEventListener("enterFrame", trackVelocity)
			display.getCurrentStage():setFocus(map, event.id)
			isFocus = true
			map.x0, map.y0 = event.x, event.y
			if (tween.x) then transition.cancel(tween.x) end
			if (tween.y) then transition.cancel(tween.y) end
			tween.x = nil
			tween.y = nil
		elseif (isFocus) then
			if (event.phase == "moved") then
				local dx = event.x - map.x0
				local dy = event.y - map.y0
				map.x0, map.y0 = event.x, event.y
				if (map.x > 0 or map.x < display.contentWidth - dimension.width) then dx = dx / 2 end
				if (map.y > 0 or map.y < display.contentHeight - dimension.height) then dy = dy / 2 end				
				map.x = map.x + dx
				map.y = map.y + dy
			elseif (event.phase == "ended" or event.phase == "cancelled") then
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
	function map:refreshSize()
		mapWidth = map.width
		mapHeight = map.height
	end
	
	function map:removeControl()
		Runtime:removeEventListener("enterFrame", trackVelocity)
		Runtime:removeEventListener("enterFrame", slowDown)
		map:removeEventListener("touch", onDrag)
	end
	
	function map:giveControl()
		map:addEventListener("touch", onDrag)
	end
	
	function map:scale(newScale)
		-- Get center view point
		local newX = (map.x - display.contentWidth / 2)
		local newY = (map.y - display.contentHeight / 2)
		-- Set back to normal scale
		newX = newX / scale
		newY = newY / scale
		-- calculate new Scale
		scale = newScale or scale
		dimension.width = mapWidth * scale 
		dimension.height = mapHeight * scale
		-- Scale center view point
		newX = newX * scale
		newY = newY * scale
		-- Get new top left point
		newX = newX + display.contentWidth / 2
		newY = newY + display.contentHeight / 2
		-- Get yo limits right
		if (newX > 0) then newX = 0
		elseif (newX < display.contentWidth - dimension.width) then newX = display.contentWidth - dimension.width end
		if (newY > 0) then newY = 0
		elseif (newY < display.contentHeight - dimension.height) then newY = display.contentHeight - dimension.height end
		map:removeControl()
		-- stop transitions
		if (tween.x) then transition.cancel(tween.x) end
		if (tween.y) then transition.cancel(tween.y) end
		-- make new transitions
		transition.to(map, {time = 500, x = newX, y = newY, xScale = scale, yScale = scale, onComplete = function()
			map:giveControl()
		end})
	end
	
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