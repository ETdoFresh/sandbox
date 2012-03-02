function math.round(num, idp)
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
	if (math.abs(slope) <= 1) then
		if (x1 < x0) then inc = -1 end
		for x = x0, x1, inc  do
			local y = math.round(slope * (x - x1) + y1)
			table.insert(pixels,{x=x,y=y})
		end
	elseif (math.abs(slope) > 1) then
		if (y1 < y0) then inc = -1 end
		for y = y0, y1, inc do
			local x = math.round((y - y1) / slope + x1)
			table.insert(pixels,{x=x,y=y})
		end
	end
	visualize(pixels)
	return pixels
end

function visualize(pixels)
	for i = 1, #pixels do
		--print(pixels[i].x,pixels[i].y)
		display.newCircle(pixels[i].x,pixels[i].y,1)
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
	local ctrX = math.round(width / 2 + left)
	local ctrY = math.round(height / 2 + top)
	local line1 = pixelsLine(ctrX,ctrY,left,top)
	local line2 = pixelsLine(ctrX,ctrY,left+width,top)
	local line3 = pixelsLine(ctrX,ctrY,left,top+height)
	local line4 = pixelsLine(ctrX,ctrY,left+width,top+height)
	--print(#line1,#line2,#line3,#line4)
	local minLen = math.min(#line1,#line2,#line3,#line4)
	for i = 1, minLen do
		local l1 = #line1 - i + 1
		local l2 = #line2 - i + 1
		local l3 = #line3 - i + 1
		local l4 = #line4 - i + 1
		pixelsLine(line1[l1].x,line1[l1].y,line2[l2].x,line2[l2].y)
		pixelsLine(line1[l1].x,line1[l1].y,line3[l3].x,line3[l3].y)
		pixelsLine(line4[l4].x,line4[l4].y,line2[l2].x,line2[l2].y)
		pixelsLine(line4[l4].x,line4[l4].y,line3[l3].x,line3[l3].y)
	end
end

pixelsRect(5,5,1,25)
pixelsLine(10,5,10,30)