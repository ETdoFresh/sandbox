-- Start physics simulation
local physics = require "physics"
physics.start()

-- Set properties
physics.setGravity(0, 0) -- No downward gravity
physics.setScale(30) --30 pixel/meter (physics works best between 0.1m and 10m)
physics.setDrawMode("normal") -- drawing mode can be normal, debug, or hybrid

-- Create borders around the edges
local borderTop = display.newRect(0, 0, display.contentWidth, 1)
local borderBottom = display.newRect(0, display.contentHeight-1, display.contentWidth, 1)
local borderLeft = display.newRect(0, 0, 1, display.contentHeight)
local borderRight = display.newRect(display.contentWidth-1, 1, 1, display.contentHeight)

-- name the borders
borderTop.myName = "borderTop"
borderBottom.myName = "borderBottom"
borderLeft.myName = "borderLeft"
borderRight.myName = "borderRight"

-- add physics to the borders
local borderBody = {friction=0.4, bounce=0.2}
physics.addBody(borderTop, "static", borderBody)
physics.addBody(borderBottom, "static", borderBody)
physics.addBody(borderLeft, "static", borderBody)
physics.addBody(borderRight, "static", borderBody)

-- Create crates!
local crate1 = display.newRect(50,50,100,100)
physics.addBody( crate1, { density=3.0, friction=0.5, bounce=0.3 } )
crate1.myName = "first crate"
 
local crate2 = display.newRect(50,200,100,100)
physics.addBody( crate2, { density=3.0, friction=0.5, bounce=0.3 } )
crate2.myName = "second crate"

-- Create something that happens on collision events
local function onLocalCollision(self, event)
	if ( event.phase == "began" ) then
		print( self.myName .. ": collision began with " .. event.other.myName )
	elseif ( event.phase == "ended" ) then
		print( self.myName .. ": collision ended with " .. event.other.myName )
	end
end
crate1.collision = onLocalCollision
crate2.collision = onLocalCollision
crate1:addEventListener( "collision", crate1 )
crate2:addEventListener( "collision", crate2 )

-- Test how touch events can work with physics
local function dragBody(event)
	local body = event.target
	local stage = display.getCurrentStage()
	
	if (event.phase == "began") then
		stage:setFocus(body)
		body.isFocus = true
		body.tempJoint = physics.newJoint("touch", body, event.x, event.y)
	elseif (body.isFocus) then
		if (event.phase == "moved") then
			body.tempJoint:setTarget(event.x, event.y)
		elseif (event.phase == "ended" or event.phase == "cancelled") then
			stage:setFocus(nil)
			body.isFocus = false
			body.tempJoint:removeSelf()
		end
	end
end

crate1:addEventListener("touch", dragBody)
crate2:addEventListener("touch", dragBody)