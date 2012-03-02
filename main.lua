-- A sprite sheet with a cat
require "sprite"
local sheet1 = sprite.newSpriteSheet( "runningcat.png", 512, 256 )

local spriteSet1 = sprite.newSpriteSet(sheet1, 1, 8)
sprite.add( spriteSet1, "cat", 1, 8, 1000, 0 ) -- play 8 frames every 1000 ms

local instance1 = sprite.newSprite( spriteSet1 )
instance1.currentFrame = 5
instance1.x = display.contentWidth / 4 + 40
instance1.y = display.contentHeight - 75
instance1.xScale = .5
instance1.yScale = .5

--instance1:prepare("cat")
--instance1:play()