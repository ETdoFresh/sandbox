--==============================
-- Path 
-- A path class
-- by E.T. Garcia
--==============================
local Path = {}

-- Require Vector function
local Vector = require "Vector"

function Path.new(param)
	local self = {}
	
	--==============================
	-- Private Variables
	--==============================
	local sum = {} -- An aggregate sum of distances by each point
	local gfx -- Will contain graphic
	local gfxPts -- Will contain circle for each point on curve
	local radius = 5 -- How close object has to be to get next param
	local hasChanged = false -- Updates graphic if changed
	
	--==============================
	-- Private Functions
	--==============================
	-- Returns perpendicular distance from point p0 to line defined by p1,p2
	local function perpendicularDistance(p0, p1, p2)
		if (p1.x == p2.x) then
			return math.abs(p0.x - p1.x)
		end
		local m = (p2.y - p1.y) / (p2.x - p1.x) --slope
		local b = p1.y - m * p1.x --offset
		local dist = math.abs(p0.y - m * p0.x - b)
		dist = dist / math.sqrt(m*m + 1)
		return dist
	end
	
	-- Algorithm to simplify a curve and keep major curve points
	local function DouglasPeucker(pts, epsilon)
		--Find the point with the maximum distance
		local dmax = 0
		local index = 0
		for i = 3, #pts do 
			d = perpendicularDistance(pts[i], pts[1], pts[#pts])
			if d > dmax then
				index = i
				dmax = d
			end
		end
		
		local results = {}
		
		--If max distance is greater than epsilon, recursively simplify
		if dmax >= epsilon then
			--Recursive call
			local tempPts = {}
			for i = 1, index-1 do table.insert(tempPts, pts[i]) end
			local results1 = DouglasPeucker(tempPts, epsilon)
			
			local tempPts = {}
			for i = index, #pts do table.insert(tempPts, pts[i]) end
			local results2 = DouglasPeucker(tempPts, epsilon)

			-- Build the result list
			for i = 1, #results1-1 do table.insert(results, results1[i]) end
			for i = 1, #results2 do table.insert(results, results2[i]) end
		else
			for i = 1, #pts do table.insert(results, pts[i]) end
		end
		
		--Return the result
		return results
	end
	
	-- Returns square distance (faster than regular distance)
	local function squareDistance(pointA, pointB)
		local dx = pointA.x - pointB.x
		local dy = pointA.y - pointB.y
		return dx*dx + dy*dy
	end
	
	-- Simplifies the path by eliminating points that are too close
	local function removeClutter(pts, distance)
		local newPoints = {}
		table.insert(newPoints, pts[1])
		local lastPoint = pts[1]
		
		local squareDist = distance*distance
		for i = 2, #pts do
			if (squareDistance(pts[i], lastPoint) >= squareDist) then
				table.insert(newPoints, pts[i])
				lastPoint = pts[i]
			end
		end
		return newPoints
	end
	
	-- updates the drawing
	local function update(runtime, event)
		if (hasChanged == false) then return true end
		hasChanged = false
		if (gfx) then gfx:removeSelf(); gfx = nil end
		
		-- Draw the line
		if (#self > 1) then
			gfx = display.newLine(self[1].x, self[1].y, self[2].x, self[2].y)
			for i = 3, #self do
				gfx:append(self[i].x, self[i].y)
			end
			gfx:setColor(255,255,0)
			gfx.width = 4
		end
		-- Draw the points
		if (gfxPts) then gfxPts:removeSelf(); gfxPts = nil end
		gfxPts = display.newGroup()
		for i = 1, #self do
			local pt = display.newCircle(self[i].x, self[i].y, 4)
			pt:setFillColor(255,0,0)
			gfxPts:insert(pt)
		end
	end
	
	--==============================
	-- Public Functions
	--==============================
	function self:append(point)
		hasChanged = true
		if (#self > 0) then
			local distance = Vector.subtract(point, self[#self])
			distance = Vector.magnitude(distance)
			distance = distance + sum[#sum]
			table.insert(sum, distance)
		else
			table.insert(sum, 0)
		end
		table.insert(self, point)
	end
	
	function self:removeSelf()
		Runtime:removeEventListener("enterFrame", update)
		if (gfx) then gfx:removeSelf() end
		if (gfxPts) then gfxPts:removeSelf() end
		gfx = nil
		gfxPts = nil
		self = nil
	end
	
	function self:simplify(param)
		local dist = param.dist or 10
		local iterations = param.iterations or 2
		local pts = removeClutter(self, dist)
		for i = 1, iterations do
			pts = DouglasPeucker(pts, 1)
		end
		while #self > 0 do
			table.remove(self, 1)
		end
		for i = 1, #pts do
			table.insert(self, pts[i])
		end
		hasChanged = true
	end
	
	function self:getParam(object, lastParam)
		if (lastParam) then
			local nextParam = sum[#sum]
			for i = 1, #sum do
				if (lastParam < sum[i]) then
					nextParam = sum[i]
					break
				end
			end
		end
		return 0
	end
	
	--==============================
	-- Constructor
	--==============================
	if (param.start) then
		table.insert(self, param.start)
		table.insert(sum, 0)
		hasChanged = true
	end
	Runtime:addEventListener("enterFrame", update)
	
	return self
end

return Path