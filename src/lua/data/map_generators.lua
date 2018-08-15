local generators = {}

local function generateGrid(grid, w, h, random)
	for j = 0, h-1 do
		grid[j] = {}
		for i = 0, w-1 do
			grid[j][i] = (i == 0 or i == w-1 or j == 0 or j == h-1)
							and 0 or 1
		end
	end
end

local function wallswithin(grid, x, y, d)
	local wallcount = 0

	for j=y-d, y+d do
		for i=x-d,x+d do

			if not grid[j] or not grid[j][i] or grid[j][i] == 0 then
				wallcount = wallcount + 1
			end
		end
	end

	return wallcount
end

local function step(grid, w, h, birthlimit, deathlimit)
	local newgrid = {}

	for j=0, h-1 do
		newgrid[j] = {}
		for i, val in pairs(grid[j] or {}) do
			if (i == 0)
				or (j == 0)
				or (i == w-1)
				or (j == h-1) then
				newgrid[j][i] = 0
			else
				local wallcount = wallswithin(grid, i, j, 1)
				local alivecount = 9 - wallcount

				if grid[j][i] == 0 then
					newgrid[j][i] = alivecount >= (birthlimit or 4) and 1 or 0
				else
					newgrid[j][i] = alivecount <= (deathlimit or 2) and 0 or 1
				end
			end
		end
	end

	return newgrid
end

local function pad(grid, d)
	local newgrid = {}

	d = d or 1

	for y, row in pairs(grid) do
		if not newgrid[y] then newgrid[y] = {} end
		for x, val in pairs(row) do

			newgrid[y][x] = val

			for j = y-d, y+d do

				if not newgrid[j] then newgrid[j] = {} end

				for i = x-d, x+d do
					if not grid[j] or grid[j][i] ~= 1 then
						newgrid[j][i] = 0
					end
				end
			end
		end
	end

	return newgrid
end

local function isValid(floor, x, y, w, h, random)

	local edgedistance = random:random(1, 8)

	local nearedge = x >= edgedistance and x < (w - 1 - edgedistance)
		and y >= edgedistance and y < (h - 1 - edgedistance)

	local inpreviousroom = floor[y] and floor[y][x]

	return nearedge and not inpreviousroom
end

local function placeCave(floor, w, h, minsize, random)
	local grid = {}
	for j=0, h-1 do
		grid[j] = {}
	end

	local directions = {
		{x = -1},
		{x = 1},
		{y = -1},
		{y = 1}
	}

	local numroomcells, targetroommin = 0, minsize--self.w * self.h * 0.05

	local x = random:random(1, w - 2)
	local y = random:random(1, h - 2)


	local attempts = 0

	while not isValid(floor, x, y, w, h, random) and attempts < w * h do
		x = random:random(1, w - 2)
		y = random:random(1, h - 2)
		attempts = attempts + 1
	end

	--TODO: x and y should be checked they aren't in or adjacent to previous rooms
	grid[y][x] = 1
	numroomcells = numroomcells + 1

	local dir = {}

	while (numroomcells < targetroommin 
		or random:random() < 1 - math.pow(((numroomcells-minsize)/1000), 2))
		and attempts < 10000 do

		--choose direction
		if random:random() < .5 then
			dir = directions[random:random(1,4)]
		end

		local nextx = x + (dir.x or 0)
		local nexty = y + (dir.y or 0)

		while not isValid(floor, nextx, nexty, w, h, random) and attempts < 10000 do
			dir = directions[random:random(1,4)]
			nextx = x + (dir.x or 0)
			nexty = y + (dir.y or 0)
			attempts = attempts + 1
		end

		x, y = nextx, nexty

		if grid[y][x] ~= 1 then
			numroomcells = numroomcells + 1
		end

		grid[y][x] = 1
	end

	return grid, numroomcells
end

local function randomWalkRooms(floor, w, h, random)
	local smooth = random:random(1, 3)

	local numfloorcells, targetfloormin = 0, w * h * 0.4

	-- Create each rooms' table
	--for r = 1, 2 do

	local attempts = 0

	while numfloorcells < targetfloormin and attempts < 100 do

		grid, size = placeCave(floor, w, h, 5, random)
		attempts = attempts + 1

		numfloorcells = numfloorcells + size

		if size > 5 then
			grid = pad(grid, 2)

			for j, row in pairs(grid) do
				for i, val in pairs(row) do
					if not floor[j] then floor[j] = {} end

					floor[j][i] = val
				end
			end
		end
	end

	for i=1, smooth or 1 do
		floor = step(floor, w, h, birthlimit, deathlimit)
	end
end

generators.randomWalkRooms = randomWalkRooms

local function allPatterns(floor, w, h, seed)

	for j = 0, h-1 do
		floor[j] = {}
	end

	for index = 0, 255 do
		local i = index%16
		local j = math.floor(index/16)

		local x = i*3 + 1
		local y = j*3 + 1

		floor[y-1][x-1] = ((index & 128) == 0) and 0 or 1
		floor[y-1][x] = ((index & 64) == 0) and 0 or 1
		floor[y-1][x+1] = ((index & 32) == 0) and 0 or 1
		floor[y][x-1] = ((index & 16) == 0) and 0 or 1

		floor[y][x] = 0

		floor[y][x+1] = ((index & 8) == 0) and 0 or 1
		floor[y+1][x-1] = ((index & 4) == 0) and 0 or 1
		floor[y+1][x] = ((index & 2) == 0) and 0 or 1
		floor[y+1][x+1] = ((index & 1) == 0) and 0 or 1
	end

	for index = 0, 255 do
		local i = index%16
		local j = math.floor(index/16)

		local x = (i+16)*3 + 1
		local y = j*3 + 1

		floor[y-1][x-1] = ((index & 128) == 0) and 0 or 1
		floor[y-1][x] = ((index & 64) == 0) and 0 or 1
		floor[y-1][x+1] = ((index & 32) == 0) and 0 or 1
		floor[y][x-1] = ((index & 16) == 0) and 0 or 1

		floor[y][x] = 1

		floor[y][x+1] = ((index & 8) == 0) and 0 or 1
		floor[y+1][x-1] = ((index & 4) == 0) and 0 or 1
		floor[y+1][x] = ((index & 2) == 0) and 0 or 1
		floor[y+1][x+1] = ((index & 1) == 0) and 0 or 1
	end
end

generators.allPatterns = allPatterns

local function getBetterPattern(grid, i, j)
	local pattern = 0
	local value = grid[j][i]

	pattern = pattern | (((grid[j-1] and grid[j-1][i-1] or 0) == value) and 1 or 0) << 7
	pattern = pattern | (((grid[j-1] and grid[j-1][i] or 0) == value) and 1 or 0) << 6
	pattern = pattern | (((grid[j-1] and grid[j-1][i+1] or 0) == value) and 1 or 0) << 5
	pattern = pattern | (((grid[j] and grid[j][i-1] or 0) == value) and 1 or 0) << 4
	pattern = pattern | (((grid[j] and grid[j][i+1] or 0) == value) and 1 or 0) << 3
	pattern = pattern | (((grid[j+1] and grid[j+1][i-1] or 0) == value) and 1 or 0) << 2
	pattern = pattern | (((grid[j+1] and grid[j+1][i] or 0) == value) and 1 or 0) << 1
	pattern = pattern | (((grid[j+1] and grid[j+1][i+1] or 0) == value) and 1 or 0) << 0

	pattern = pattern | (1 << (value + 8))

	return pattern
end

local function getPattern(grid, x, y)
	local pattern = {}

	for j = y-1, y+1 do
		for i = x-1, x+1 do

			pattern[#pattern+1] = grid[j] and grid[j][i] or 0
		end
	end

	return table.concat(pattern)
end

local function getBetterPattern(grid, i, j)
	local pattern = 0
	local value = grid[j][i]
	pattern = pattern | (((grid[j-1] and grid[j-1][i-1] or 0) == value) and 1 or 0) << 7
	pattern = pattern | (((grid[j-1] and grid[j-1][i] or 0) == value) and 1 or 0) << 6
	pattern = pattern | (((grid[j-1] and grid[j-1][i+1] or 0) == value) and 1 or 0) << 5
	pattern = pattern | (((grid[j] and grid[j][i-1] or 0) == value) and 1 or 0) << 4
	pattern = pattern | (((grid[j] and grid[j][i+1] or 0) == value) and 1 or 0) << 3
	pattern = pattern | (((grid[j+1] and grid[j+1][i-1] or 0) == value) and 1 or 0) << 2
	pattern = pattern | (((grid[j+1] and grid[j+1][i] or 0) == value) and 1 or 0) << 1
	pattern = pattern | (((grid[j+1] and grid[j+1][i+1] or 0) == value) and 1 or 0) << 0

	pattern = pattern | (1 << (value + 8))

	return pattern
end

local function learnTilesFromMap(grid, tile, w, h, random)

	-- load in file

	local map = loadfile("floor.lua")()

	-- learn patterns from it
	local patterns = {}
	for j = 1, #map.grid do
		for i = 1, #map.grid[j] do
			patterns[getPattern(map.grid, i, j)] = map.tile[j][i]
		end
	end

	-- apply patterns to this grid
	for j = 0, h-1 do
		tile[j] = {}
		for i = 0, w-1 do
			tile[j][i] = patterns[getPattern(grid, i, j)] or 0
		end
	end
end

generators.learnTilesFromMap = learnTilesFromMap

local function learnTilesFromPatterns(grid, tile, w, h, random)

	-- load in file

	local patterns = require(LUA_FOLDER .. 'data.patterns')--loadfile("patterns.lua")()

	-- apply patterns to this grid
	for j = 0, h-1 do
		tile[j] = {}
		for i = 0, w-1 do
			local pattern = getBetterPattern(grid, i, j)
			tile[j][i] = patterns[pattern] or 0
		end
	end
end

generators.learnTilesFromPatterns = learnTilesFromPatterns

return generators