local Dog = {}

function Dog.new( x, y, width, height )
    local newDog = display.newRect( x, y, width, height )
	
	function newDog:rollOver()
		print( self.x, self.y )
	end
	
    return newDog
end

return Dog