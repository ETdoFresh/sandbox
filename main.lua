-- Merge Pixel Tables Together
function pixelsMerge(...)
	local merge = {}
	for i,v in ipairs(arg) do
		for j,k in pairs(v) do
			merge[j] = merge[j] or {}
			for l,m in pairs(k) do
				merge[j][l] = m
			end
		end
	end
	return merge
end

-- Rounds a number
function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function pixelAdd(pixels,x,y,id)
	id = id or 1
	pixels[x] = pixels[x] or {}
	pixels[x][y] = id
end

-- Returns an array of pixel based on the coordinates of the line given
function pixelsLine(x0,y0,x1,y1)
	local pixels = {}
	if (x0==x1 and y0==y1) then
		table.insert(pixels,{x=x0,y=y0})
		return pixels
	end
	local slope = (y1-y0)/(x1-x0)
	local inc = 1
	local id = 1
	if (math.abs(slope) <= 1) then
		if (x1 < x0) then inc = -1 end
		for x = x0, x1, inc  do
			local y = round(slope * (x - x1) + y1)
			pixelAdd(pixels,x,y,id)
			id = id + 1
		end
	elseif (math.abs(slope) > 1) then
		if (y1 < y0) then inc = -1 end
		for y = y0, y1, inc do
			local x = round((y - y1) / slope + x1)
			pixelAdd(pixels,x,y,id)
			id = id + 1
		end
	end
	return pixels
end

-- draws a white pixel to represent a pixel array
function visualize(pixels)
	for i,v in pairs(pixels) do
		for j,k in pairs(pixels[i]) do
			display.newCircle(i,j,1)
		end
	end
end

-- Returns true if two pixel arrays have a same a same pixel
function hitTestPixels(pixels1, pixels2)
	for i in pairs(pixels1) do
		for j in pairs(pixels1[i]) do
			for k in pairs(pixels2) do
				for l in pairs(pixels2[k]) do
					if (i == k and j == l) then
						return true
					end
				end
			end
		end
	end
	return false
end

-- Returns an array of pixels based on the coordinates of the rectangle
function pixelsRect(left,top,width,height,rotation)
	rotation = rotation or 0
	local pixels = {}
	local ctrX = round(width / 2 + left)
	local ctrY = round(height / 2 + top)
	local radian = rotation*math.pi/180
	local tlX = round(ctrX + (left - ctrX)*math.cos(radian) + (top - ctrY)*math.sin(radian))
	local tlY = round(ctrY - (left - ctrX)*math.sin(radian) + (top - ctrY)*math.cos(radian))
	local blX = round(ctrX + (left - ctrX)*math.cos(radian) + (top + height - ctrY)*math.sin(radian))
	local blY = round(ctrY - (left - ctrX)*math.sin(radian) + (top + height - ctrY)*math.cos(radian))
	local trX = round(ctrX + (left + width - ctrX)*math.cos(radian) + (top - ctrY)*math.sin(radian))
	local trY = round(ctrY - (left + width - ctrX)*math.sin(radian) + (top - ctrY)*math.cos(radian))
	local brX = round(ctrX + (left + width - ctrX)*math.cos(radian) + (top + height - ctrY)*math.sin(radian))
	local brY = round(ctrY - (left + width - ctrX)*math.sin(radian) + (top + height - ctrY)*math.cos(radian))
	local line1 = pixelsLine(tlX,tlY,blX,blY)
	local line2 = pixelsLine(trX,trY,brX,brY)
	for i in pairs(line1) do
		for j,k in pairs(line1[i]) do
			for l in pairs(line2) do
				for m,n in pairs(line2[l]) do
					if(k == n) then
						pixels = pixelsMerge(pixels,pixelsLine(i,j,l,m))
					end
				end
			end
		end
	end
	return pixels
end

function pixelsCirc(ctrX, ctrY, radius)
	local pixels = {}
	for i = 1, radius do
		local x = 0
		local y = i
		local p = 3 - 2* i
		while (y >= x) do
			pixelAdd(pixels,ctrX-x,ctrY-y)
			pixelAdd(pixels,ctrX-y,ctrY-x)
			pixelAdd(pixels,ctrX+y,ctrY-x)
			pixelAdd(pixels,ctrX+x,ctrY-y)
			pixelAdd(pixels,ctrX-x,ctrY+y)
			pixelAdd(pixels,ctrX-y,ctrY+x)
			pixelAdd(pixels,ctrX+y,ctrY+x)
			pixelAdd(pixels,ctrX+x,ctrY+y)
			if (p < 0) then
				p = p + 4*x + 6
				x = x + 1
			else
				p = p + 4*(x - y) + 10
				x = x + 1
				y = y - 1
			end
		end
	end
	return pixels
end

-- Create two rectangles, and see if they collide!
local rect1 = pixelsCirc(50,50,45)
local rect2 = pixelsRect(50,150,32,2,-45)
visualize(rect1)
for i in pairs(rect1) do
	for j in pairs (rect1[i]) do
		--print (i,j)
	end
end
print(hitTestPixels(rect1,rect2))