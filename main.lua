local spritex = require 'spritex'
print(display.contentScaleX)

-- A sprite sheet with a cat
for i = 1, 8 do
	local sheet1 = spritex.newSpriteSheet( "runningcat.png", 512, 256 )
	local spriteSet1 = spritex.newSpriteSet(sheet1, 1, 8)
	local spr = spritex.newSprite( spriteSet1 )
	spr.currentFrame = i
	spr.xScale = spr.xScale * 0.5
	spr.yScale = spr.yScale * 0.5
	spr.x = spr.contentWidth / 2
	spr.y = display.contentHeight - spr.contentHeight / 2
	print(spr.x, spr.y,"--")
end
