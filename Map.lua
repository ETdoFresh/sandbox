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
	
	--================================
	-- Public Variables
	--================================
	map.x = param.x or map.x
	map.y = param.y or map.y
	map.rotation = param.rotation or map.rotation
	map.tween = {x = nil, y = nil}
	
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

		if (not(map.tween.x)) then
			if (map.x > 0) then
				velocity.x = 0
				map.tween.x = transition.to(map, {time = 400, x = 0, transition=easing.outQuad, onComplete = function() map.tween.x = nil end})
			elseif (map.x < display.contentWidth - mapWidth) then
				velocity.x = 0
				map.tween.x = transition.to(map, {time = 400, x = display.contentWidth - mapWidth, transition=easing.outQuad, onComplete = function() map.tween.x = nil end})
			end
		end
		if (not(map.tween.y)) then
			if (map.y > 0) then
				velocity.y = 0
				map.tween.y = transition.to(map, {time = 400, y = 0, transition=easing.outQuad, onComplete = function() map.tween.y = nil end})
			elseif (map.y < display.contentHeight - mapHeight) then
				velocity.y = 0
				map.tween.y = transition.to(map, {time = 400, y = display.contentHeight - mapHeight, transition=easing.outQuad, onComplete = function() map.tween.y = nil end})
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
			if (map.tween.x) then transition.cancel(map.tween.x) end
			if (map.tween.y) then transition.cancel(map.tween.y) end
			map.tween.x = nil
			map.tween.y = nil
		elseif (isFocus) then
			if (event.phase == "moved") then
				local dx = event.x - map.x0
				local dy = event.y - map.y0
				map.x0, map.y0 = event.x, event.y
				if (map.x > 0 or map.x < display.contentWidth - mapWidth) then dx = dx / 2 end
				if (map.y > 0 or map.y < display.contentHeight - mapHeight) then dy = dy / 2 end				
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