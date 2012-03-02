module(..., package.seeall)

-- Debug Static Class

-- Public variables
fps = 0

-- Private Variables
local dispHeight = display.contentHeight
local prevTime = 0
local maxFpsCount = 60
local prevFps = {}
local prevFpsCount = 1
local gfx = nil

-- Take an average of a table
local function average(tbl)
	local sum = 0
	for i = 1, #tbl do
		sum = sum + tbl[i]
	end
	return math.floor(sum/#tbl)
end

-- Updates FPS
local function trackFps(event)
	local curTime = system.getTimer() -- current running time
	local dt = curTime - prevTime -- difference since last called
	prevTime = curTime -- prep for next call
	
	local curFps = math.floor(1000/dt) -- 1000/(milliseconds per frame) = fps
	
	prevFps[prevFpsCount] = curFps -- add fps to array
	prevFpsCount = prevFpsCount + 1 -- inc array ctr
	if (prevFpsCount > maxFpsCount) then prevFpsCount = 1 end -- reset array ctr after max
	local minFps = average(prevFps) -- get average of array
	fps = minFps
end

-- Start FPS
function start()
	prevTime = system.getTimer()
	Runtime:addEventListener("enterFrame", trackFps)
end

-- End FPS
function stop()
	Runtime:removeEventListener("enterFrame", trackFps)
end

function addGfx(x,y,size)
	size = size or 20
	local textGrp = display.newGroup()
	local box = display.newRect(textGrp, 0,0, 200, 100)
	box:setFillColor(64,64,64)
	box.x, box.y = 0, 0
	local devText = display.newText(textGrp, "Dev: "..system.getInfo("platformName"), 0,0, native.systemFontBold,size)
	devText.x, devText.y = 0, -36
	local procText = display.newText(textGrp, "Proc: "..system.getInfo("architectureInfo"), 0,0, native.systemFontBold,size)
	procText.x, procText.y = 0, -12
	local fpsText = display.newText(textGrp, "FPS: 100", 0,0, native.systemFontBold,size)
	fpsText.x, fpsText.y = 0, 12
	local tMemText = display.newText(textGrp, "TM: 10000", 0,0, native.systemFontBold,size)
	tMemText.x, tMemText.y = 0, 36
	textGrp.enterFrame = function (event) 
		fpsText.text = "FPS: "..fps
		tMemText.text = "TM: "..(math.floor(system.getInfo("textureMemoryUsed")/1024)).."K"
	end
	textGrp.x = x or textGrp.contentWidth/2
	textGrp.y = y or dispHeight - textGrp.contentHeight/2
	Runtime:addEventListener("enterFrame", textGrp)
	gfx = textGrp
end

function removeGfx()
	gfx:removeSelf()
	gfx = nil
end

start()