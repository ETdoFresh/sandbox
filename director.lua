local director = {}

local loadPercent = 0
local function update()
	loadPercent = loadPercent+1
	coroutine.yield()
end

director.co = coroutine.create(update)

return director