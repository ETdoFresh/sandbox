local myText = display.newText("0", 0, 0, native.systemFont, 32)
local isTouching = false
local isWaiting = false
myText.x = display.contentWidth / 2
myText.y = display.contentHeight / 2
myText.val = 0

function myCoroutine()
	for i = 1, 50000 do
		myText.text = myText.text + 1
		myText.val = myText.val + 1
		coroutine.yield()
	end
end

function onCoroutine(event)
	if (not isTouching) then
		coroutine.resume(co)
		timer.performWithDelay(5, onCoroutine)
		isWaiting = false
	else
		isWaiting = true
	end
end

function onTouch(event)
	if event.phase == "began" then
		isTouching = true
		myText.val = myText.text/1
	elseif event.phase == "moved" then
		myText.text = myText.val + (event.yStart - event.y)
		if myText.text/1 < 0 then myText.text = "0" end
		print(event.y, event.yStart)
	elseif event.phase == "ended" then
		isTouching = false
		if (isWaiting) then
			onCoroutine(nil)
		end
	end
end

co = coroutine.create(myCoroutine)
timer.performWithDelay(5, onCoroutine)
Runtime:addEventListener("touch", onTouch)
