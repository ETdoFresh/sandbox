--==============================
-- Vector Class
-- Functions to operate on vectors
-- by E.T. Garcia
--==============================

local Vector =  {}

-- Returns the vector sum of v1 and v2
function Vector.add(v1, v2)
	return {x = v1.x + v2.x, y = v1.y + v2.y}
end

-- Returns the vector difference of v2 from v1
function Vector.subtract(v1, v2)
	return {x = v1.x - v2.x, y = v1.y - v2.y}
end

-- Returns the vector v1 multiplied by scaler num
function Vector.multiply(v1, num)
	return {x = v1.x * num, y = v1.y * num}
end

-- Returns the vector v1 divided by scaler num
function Vector.divide(v1, num)
	return {x = v1.x / num, y = v1.y / num}
end

-- Returns the magnitude (length) of v1
function Vector.magnitude(v1)
	return math.sqrt(v1.x * v1.x + v1.y * v1.y)
end

-- Returns the unit vector of v1
function Vector.normalize(v1)
	local magnitude = Vector.magnitude(v1)
	return {x = v1.x / magnitude, y = v1.y / magnitude}
end

-- Returns a normal vector in direction of angle
function Vector.fromAngle(degrees)
	local radians = math.rad(degrees)
	return {x = math.cos(radians), y = math.sin(radians)}
end

-- Returns a degrees from a vector
function Vector.toAngle(v1)
	return math.deg(math.atan2(-v1.y, -v1.x))
end

return Vector