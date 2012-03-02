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
	
	--==============================
	-- Public Functions
	--==============================
	function self:append(point)
		if (#self > 0) then
			hasChanged = true
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
		Runtime:removeEventListener("enterFrame", self)
		if (gfx) then gfx:removeSelf() end
		self = nil
	end
	
	function self:enterFrame(event)
		if (hasChanged == false) then return true end
		hasMoved = false
		if (gfx) then gfx:removeSelf() end
		
		if (#self > 1) then
			gfx = display.newLine(self[1].x, self[1].y, self[2].x, self[2].y)
			for i = 3, #self do
				gfx:append(self[i].x, self[i].y)
			end
			gfx:setColor(255,255,0)
			gfx.width = 12
		end
	end
	
	function self:simplify()
		local pts = DouglasPeucker(self, 1)
		pts = DouglasPeucker(pts, 1)
		while #self > 0 do
			table.remove(self, 1)
		end
		for i = 1, #pts do
			table.insert(self, pts[i])
		end
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
	end
	Runtime:addEventListener("enterFrame", self)
	
	return self
end

return Path