local rect = display.newRect(50,50,100,100)
print(rect.x,rect.y)

print(rect.x,rect.y)
rect.enterFrame = function (event) 
	local x,y = rect.x,rect.y
	rect.width = rect.width+1
	rect:setReferencePoint(display.TopLeftReferencePoint)
	rect.x,rect.y = x,y
	print(rect.x)
end
Runtime:addEventListener("enterFrame",rect)