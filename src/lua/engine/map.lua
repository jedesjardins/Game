
local Map = {}
Map.__index = Map

function Map.new(rect, options)
	local self = setmetatable({}, Map)

	return self
end

function Map:setTile(coord, val)
	
	return false
end

function Map:getTile(coord)
	
	return -1
end

function Map:setTileCol(coord, val)
	
	return false
end

function Map:getTileCol(coord)
	
	return -1
end

function Map:setFloor(val)

	return false
end

function Map:getFloor()
	
	return -1
end

function Map:getNumFloors()

	return -1
end

function Map:init()
end

function Map:render()
end

function Map:update()
end

function Map:gridFromTile(coord)
	
	return -1, -1
end

function Map:tileFromGrid(coord)
	
	return -1, -1
end

function Map:interact(rect)
	
	return nil
end

function Map:collision(rect)
	
	return {}
end

function Map:writeToFile(filename)
end

return Map


