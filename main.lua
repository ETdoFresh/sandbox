-- Event handling practice!

local stage = display.currentStage

-- Boxes Group!
local boxes = display.newGroup()
function boxes:test(event)
	print("boxes: nice one!")
end

-- Box 1 Instance
local box1 = display.newRect(boxes,50,50,100,100)
box1:setFillColor(0,0,255)
function box1:touch(event)
	if (event.phase == "began") then
		self.isFocus = true
		stage:setFocus (self)
		self.parent:insert(self)
	elseif (self.isFocus and event.phase == "moved") then
		self.x, self.y = event.x, event.y
	elseif (self.isFocus and event.phase == "ended" or event.phase == "cancelled") then
		self.isFocus = false
		stage:setFocus(nil)
	end
end
function box1:msg(event)
	print("box1: loud and clear")
end


-- Box 2 Instance
local box2 = display.newRect(boxes,100,100,100,100)
box2:setFillColor(255,0,0)
function box2:touch(event)
	if (event.phase == "began") then
		self.isFocus = true
		stage:setFocus (self)
		self.parent:insert(self)
	elseif (self.isFocus and event.phase == "moved") then
		self.x, self.y = event.x, event.y
	elseif (self.isFocus and event.phase == "ended" or event.phase == "cancelled") then
		self.isFocus = false
		stage:setFocus(nil)
	end
end
function box2:msg(event)
	print("box2: affirmative")
end

box1:addEventListener("touch",box1)
box2:addEventListener("touch",box2)
boxes:addEventListener("msg",box1)
boxes:addEventListener("msg",box2)
box2:addEventListener("test",boxes)

boxes:dispatchEvent({
	name = "msg",
	target = boxes,
})

box1:dispatchEvent({
	name = "test",
	target = box1,
})

box2:dispatchEvent({
	name = "test",
	target = boxes,
})