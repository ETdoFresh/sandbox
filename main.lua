function merge(...)
	local merge = {}
	for i,v in ipairs(arg) do
		for j,k in pairs(v) do
			merge[j] = merge[j] or {}
			for l,m in pairs(k) do
				merge[j][l] = m
				print(i,j,l)
			end
		end
	end
	for i,v in pairs(merge) do
		for j,k in pairs(v) do
			print(i,j)
		end
	end
	return merge
end

function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

-- Just messing around!
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
			pixels[x] = pixels[x] or {}
			pixels[x][y] = id
			id = id + 1
		end
	elseif (math.abs(slope) > 1) then
		if (y1 < y0) then inc = -1 end
		for y = y0, y1, inc do
			local x = round((y - y1) / slope + x1)
			pixels[x] = pixels[x] or {}
			pixels[x][y] = id
			id = id + 1
		end
	end
	visualize(pixels)
	return pixels
end

function visualize(pixels)
	for i,v in pairs(pixels) do
		for j,k in pairs(pixels[i]) do
			display.newCircle(i,j,1)
		end
	end
end

function hitTestPixels(pixels1, pixels2)
	for i = 1, #pixels1 do
		for j = 1, #pixels2 do
			if (pixels1[i].x == pixels2[j].x and pixels1[i].y == pixels2[j].y) then
				return true
			end
		end
	end
	return false
end

function pixelsRect(left,top,width,height,rotation)
	local pixels = {}
	local ctrX = round(width / 2 + left)
	local ctrY = round(height / 2 + top)
	local line1 = pixelsLine(ctrX,ctrY,left,top)
	local line2 = pixelsLine(ctrX,ctrY,left+width,top)
	local line3 = pixelsLine(ctrX,ctrY,left,top+height)
	local line4 = pixelsLine(ctrX,ctrY,left+width,top+height)
	local i,j
	table.sort(line2,line2)
	for i in pairs(line2) do
		for j in pairs(line2[i]) do
			print(i,j)
		end
	end
	print(i,j)
	return pixels
end

local rect1 = pixelsRect(0,0,10,10)
local rect2 = pixelsLine(10,5,10,30)
for i,v in pairs(rect1) do
	for j,k in pairs(v) do
		print(i,j,k,v)
	end
end
--local concat = merge(rect1,rect2)
--print(#rect1,#rect2,#concat)
