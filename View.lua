module(..., package.seeall)

local dispWidth = display.contentWidth
local dispHeight = display.contentHeight

-- View Class
function new(View)
	-- Create Instance
	local self = display.newGroup()
	
	-- Private Variables
	local rotation = 0
	local x = 0
	local y = 0
	local width = dispWidth
	local height = dispHeight
	local xScale = 1
	local yScale = 1
	local tween = nil
	
	-- Private Touch Variables
	local x0, y0
	local startX, startY
	
	local function nextTween(input)
		if (tween) then transition.cancel(tween) end
		if (input) then 
			for i=1, self.numChildren do
				tween = transition.to(self[i], input)
			end
		end
	end
	
	function self:resetView()
		nextTween(({time = 200, x=x, y=y, xScale=xScale, yScale=yScale, rotation=rotation}))
	end
	
	function self:orientation(event)
		local newRotation = 0
		local newHeight = dispHeight
		if (event.type == "landscapeLeft") then 
			newRotation = -90
			newHeight = newHeight/2
		elseif (event.type == "landscapeRight") then
			newRotation = 90
			newHeight = newHeight/2
		end
		self:setView(nil,nil,dispWidth,newHeight,newRotation,200)
	end
	
	function self:zoomInTowards(x,y,zoom,zTime)
		zoom = zoom/100 or 2
		zTime = zTime or 1000
		if (x and y) then
			local newWidth = self.width/zoom
			local newHeight = self.height/zoom
			local newX = x - newWidth/2
			local newY = y - newHeight/2
			newX = math.max(newX,0)
			newY = math.max(newY,0)
			newX = math.min(newX,self.width-newWidth)
			newY = math.min(newY,self.height-newHeight)
			self:setView(newX, newY, newWidth, newHeight, nil, zTime)
		end
	end
	
	function self:setView(newX,newY,newWidth,newHeight,newRotation,duration)
		rotation = newRotation or rotation
		-- Get the scale of the image
		if (newWidth and newHeight) then
			-- Stretch landscape
			if (math.abs(rotation) == 90) then
				xScale = dispHeight / newWidth
				yScale = dispWidth / newHeight
				width = newHeight
				height = newWidth
			-- Stretch portrait
			else
				xScale = dispWidth / newWidth
				yScale = dispHeight / newHeight
				width = newWidth
				height = newHeight
			end
		end
		x = newX or x
		y = newY or y
		local scaledX, scaledY
		if (rotation == -90) then
			scaledX = -y*yScale
			scaledY = dispHeight - (-x*xScale)
		elseif (rotation == 90) then
			scaledX = dispWidth - (-y*yScale)
			scaledY = -x*xScale
		else
			scaledX = -x*xScale
			scaledY = -y*yScale
		end
		if (duration) then
			print(duration, scaledX, scaledY, xScale, yScale, rotation)
			nextTween({time = duration, x=scaledX, y=scaledY, xScale=xScale, yScale=yScale, rotation=rotation})
		else
			for i=1, self.numChildren do
				self[i].x = scaledX
				self[i].y = scaledY
				self[i].xScale = xScale
				self[i].yScale = yScale
				self[i].rotation = rotation
			end
		end
	end
	
	function self:touch(event)
		local nX = event.x/xScale
		local nY = event.y/yScale
		if (rotation == -90) then 
			nX = (dispHeight-event.y)/xScale
			nY = (event.x)/yScale
		elseif (rotation == 90) then 
			nX = (event.y-dispWidth)/yScale
			nY = (-event.x)/xScale
		end
		nX, nY = math.floor(nX), math.floor(nY)		
		if (event.phase == "began") then
			x0 = nX
			y0 = nY
			startX = x
			startY = y
		elseif (event.phase == "moved") then
			local newX = startX - nX + x0
			local newY = startY - nY + y0
			self:setView(newX, newY)
		end
	end
	
	return self 
end