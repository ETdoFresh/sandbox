local nGroup = display.newGroup()

local dW = display.contentWidth
local dH = display.contentHeight

local bgRect = display.newRect(nGroup,0,0,dW,dH)
local nRect1 = display.newRect(nGroup,50,50,50,50)
local nRect2 = display.newRect(nGroup,200,100,50,50)
local nRect3 = display.newRect(nGroup,250,420,50,50)
bgRect:setFillColor(32,32,32)
nRect1:setFillColor(255,0,0)
nRect2:setFillColor(0,255,0)
nRect3:setFillColor(0,0,255)

local View = require 'View'
local view = View:new()
view:insert(nGroup)

Runtime:addEventListener("orientation", view)
nRect1:addEventListener("touch", nRect1)
nGroup:addEventListener("touch", view)

nRect1.touch = function (self,event)
	if (event.phase == "began") then
		nRect1:setReferencePoint(display.TopLeftReferencePoint)
		view:setView(nRect1.x, nRect1.y, nRect1.width+50, nRect1.height+50, nil, 2000)
		nRect1:setReferencePoint(display.CenterLeftReferencePoint)
	end
end