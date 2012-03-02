function math.round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

-- Just messing around!
function pixelsLine(x0,y0,x1,y1)
	local pixels = {}
	local slope = (y1-y0)/(x1-x0)
	if (x1>=x0 and math.abs(slope) <= 1) then
		for x = x0, x1 do
			local y = math.round((slope * x) + y0)
			table.insert(pixels,{x=x,y=y})
		end
	elseif (y1>=y0 and math.abs(slope) > 1) then
		for y = y0, y1 do
			local x = math.round((y - y0) / slope)+x0
			table.insert(pixels,{x=x,y=y})
		end
	elseif (x0>x1 and math.abs(slope) <= 1) then
		for x = x1, x0 do
			local y = math.round((slope * x) + y1)
			table.insert(pixels,{x=x,y=y})
		end
	else
		for y = y1, y0 do
			local x = math.round((y - y0) / slope)+x0
			table.insert(pixels,{x=x,y=y})
		end
	end
	return pixels
end

local myLine = pixelsLine(10,10,200,250)
for i = 1, #myLine do
	print(myLine[i].x,myLine[i].y)
	display.newCircle(myLine[i].x,myLine[i].y,3)
end