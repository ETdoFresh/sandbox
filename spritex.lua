module(..., package.seeall)
local sprite = require 'sprite'

imageSuffix = {  -- Different scales of sprites
	["_2"] = 2,
	--["_0.5"] = 0.5,
}

fileTypes = {	-- Different file types
	".png", ".jpg", ".jpeg", ".gif", ".bmp"
}

-- computes img.suffix and img.scale
img = { scale = 1, suffix = "" }
for i,v in pairs (imageSuffix) do
	local dNew = math.abs(1/v - display.contentScaleX)
	local dOld = math.abs(1/img.scale - display.contentScaleX)
	if (dNew < dOld) then
		img.suffix = i
		img.scale = v
	end
	if (dNew == 0) then break end
end

-- Gets the image suffix the file is supposed to have
local addImgSuffix = function (str)
	for i, v in ipairs(fileTypes) do
		if (string.find(str, v) ~= nil) then
			return string.gsub(str,v, img.suffix.."%1")
		end
	end
end

-- Sprite functions and scaled!
function newSpriteSheet(file, frameWidth, frameHeight)
	file = addImgSuffix(file)
	frameWidth = frameWidth * img.scale
	frameHeight = frameHeight * img.scale
	return sprite.newSpriteSheet(file, frameWidth, frameHeight)
end

function newSprite( spriteSet )
	local sprite = sprite.newSprite(spriteSet)
	sprite.xScale = 1/img.scale
	sprite.yScale = 1/img.scale
	return sprite
end

newSpriteSet = sprite.newSpriteSet
add = sprite.add