
local spritesheets = require(LUA_FOLDER..'data.spritesheets')

local Map = require(LUA_FOLDER..'engine.map')
local EntityManager = require(LUA_FOLDER..'engine.ecs.entitymanager')
local entities = require(LUA_FOLDER .. 'data.entities')

local map_types = {}


local Floor = Map.new()
Floor.__index = Floor
map_types.Floor = Floor

local function generateGrid(grid, w, h, seed)
	for j = 0, h-1 do
		grid[j] = {}
		for i = 0, w-1 do
			grid[j][i] = (i == 0 or i == w-1 or j == 0 or j == h-1)
							and 0 or 1
		end
	end
end

local function generateTile(grid, tile, w, h, seed)
	for j = 0, h-1 do
		tile[j] = {}
		for i = 0, w-1 do
			tile[j][i] = grid[j][i]
		end
	end
end

--[[
	Options:
		seed
		spritesheet_name,
		grid_generate_func,
		tile_generate_func
]]
function Floor.new(rect, options)

	local self = setmetatable({}, Floor)
	options = options or {}

	self.x = rect[1]
	self.y = rect[2]
	self.w = rect[3]
	self.h = rect[4]

	self.seed = options.seed or 0
	self.random = Random.new()
	self.random:seed(self.seed)


	self.grid_generate = options.grid_generate_func or generateGrid -- generate defined above
	self.tile_generate = options.tile_generate_func or generateTile

	self.spritesheet = spritesheets[options.spritesheet_name or "grassy_cave"]
	if not self.spritesheet.sprite then
		self.spritesheet.sprite = Sprite.new()
		self.spritesheet.sprite:init(self.spritesheet.file, self.spritesheet.w, self.spritesheet.h, false)
	end

	self.texture = RenderTexture.new(self.w*TILESIZE, self.h*TILESIZE)
	self.texture:init(255)

	self.sprite = Sprite.new()

	self.grid = {}
	self.tiles = {}

	self.em = EntityManager.new()
	self.em:addPresets(entities)

	return self
end

function Floor:init()

	local grid = self.grid
	local tiles = self.tiles

	self.grid_generate(self.grid, self.w, self.h, self.random)

	for j = 0, self.h - 1 do
		self.grid[j] = self.grid[j] or {}

		for i = 0, self.w - 1 do
			self.grid[j][i] = self.grid[j][i] or 0
		end
	end
end

function Floor:render(rerender)


	local grid = self.grid
	local tiles = self.tiles

	if not rerender then self.tile_generate(grid, tiles, self.w, self.h, self.random) end

	local sprite_info = self.spritesheet
	local sprite = sprite_info.sprite

	for i=0, self.w-1 do
		for j=0, self.h-1 do
			sprite:setPosition(i*TILESIZE, (self.h-1-j)*TILESIZE)

			local frame = tiles[j][i]
			local framex = frame % sprite_info.w
			local framey = math.floor(frame/sprite_info.w)

			sprite:setFrame(framex, framey)
			self.texture:draw(sprite)
		end
	end

	local centerxpix = (math.ceil(self.w/2) - 1)*TILESIZE + TILESIZE/2
	local centerypix = (self.h - math.ceil(self.h/2))*TILESIZE + TILESIZE/2

	self.sprite:initFromTarget(self.texture)
	self.sprite:setOrigin(centerxpix, centerypix)
	self.sprite:setPosition(self.x*TILESIZE, -self.y*TILESIZE)
end

function Floor:reRender(coord)
	if coord then

		local gridx, gridy = self:gridFromTile(coord)
		local sprite_info = self.spritesheet
		local sprite = sprite_info.sprite

		local frame = self.tiles[gridy] and self.tiles[gridy][gridx]
		if not frame then return end
		local framex = frame % sprite_info.w
		local framey = math.floor(frame/sprite_info.w)

		sprite:setPosition(gridx*TILESIZE, (self.h-1-gridy)*TILESIZE)
		sprite:setFrame(framex, framey)
		self.texture:draw(sprite)
	else
		self:render(true)
	end
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

local function fillAllPattern(tiles, grid, w, h, pattern, val)
	for j = 1, h-2 do
		for i = 1, w-2 do
			if getPattern(grid, i, j) == pattern then
				tiles[j][i] = val
			end
		end
	end
end

function Floor:setTile(coord, val, fill)
	local gridx, gridy = self:gridFromTile(coord)

	if self.tiles[gridy] and self.tiles[gridy][gridx] then
		if fill then
			local pattern = getPattern(self.grid, gridx, gridy)

			fillAllPattern(self.tiles, self.grid, self.w, self.h, pattern, val)
			self:reRender()
		else
			self.tiles[gridy][gridx] = val
			self:reRender(coord)
		end

		return true
	else
		return false
	end
end

function Floor:getTile(coord)
	local gridx, gridy = self:gridFromTile(coord)

	return self.tiles[gridy] and self.tiles[gridy][gridx]
end

function Floor:setTileCol(coord, val)
	local gridx, gridy = self:gridFromTile(coord)

	if self.grid[gridy] and self.grid[gridy][gridx] then
		self.grid[gridy][gridx] = val
		return true
	else
		return false
	end
end

function Floor:getTileCol(coord)
	local gridx, gridy = self:gridFromTile(coord)

	return self.grid[gridy] and self.grid[gridy][gridx]
end

function Floor:gridFromTile(coord)

	local gridx = coord[1] + math.floor((self.w-1)/2)-self.x
	local gridy = coord[2] + math.floor((self.h - 1)/2)-self.y

	return gridx, gridy
end

function Floor:tileFromGrid(coord)

	local tilex = coord[1] - math.floor((self.w - 1)/2)+self.x
	local tiley = coord[2] - math.floor((self.h - 1)/2)+self.y

	return tilex, tiley
end

function Floor:interact(rect)
	local directions = {
		up = {y = 1},
		down = {y = -1},
		left = {x = -1},
		right = {x = 1}
	}

	local mintx, minty = math.round(rect.x), math.round(rect.y)
	local maxtx, maxty = math.round(rect.x + rect.w), math.round(rect.y + rect.h)

	local mingx, mingy = self:gridFromTile{mintx, minty}
	local maxgx, maxgy = self:gridFromTile{maxtx, maxty}

	println("TODO: change floors")
	--[[
	local z = self.floor
	local ladder = true

	for j = mingy, maxgy do
		for i = mingx, maxgx do
			ladder = self.ladders[z] and self.ladders[z][j] and self.ladders[z][j][i]
			if ladder == "up" then
				if z == 0 then
					println("Exit")
				end

				self:moveUpLevel()
				local tilex, tiley = self:tileFromGrid(i, j)

				return {{'push',
						'fadetoblackmapswitch',
						{map = self, em = self.em, tilex = tilex, tiley = tiley}}}

			else if ladder == "down" then
				self:moveDownLevel()

				local tilex, tiley = self:tileFromGrid(i, j)

				return {{'push',
						'fadetoblackmapswitch',
						{map = self, em = self.em, tilex = tilex, tiley = tiley}}}
			end end
		end
	end
	]]
end

function Floor:collision(rect)
	local mintx, minty = math.round(rect.x), math.round(rect.y)
	local maxtx, maxty = math.round(rect.x + rect.w), math.round(rect.y + rect.h)

	local mingx, mingy = self:gridFromTile{mintx, minty}
	local maxgx, maxgy = self:gridFromTile{maxtx, maxty}

	-- find walls -- horizontal slices of tiles that are collideable
	local walls = {}
	for j = mingy, maxgy do
		local currentwall = {}

		for i = mingx, maxgx do
			if self.grid[j] and self.grid[j][i] == 0 then
				table.insert(currentwall, {i, j})
			else 
				if #currentwall > 0 then
					table.insert(walls, currentwall)
				end

				currentwall = {}
			end
		end

		if #currentwall > 0 then
			table.insert(walls, currentwall)
		end
	end

	-- merge tiles in walls into colliding boxes
	local colliders = {}
	for _, wall in ipairs(walls) do
		-- create the collision box
		local collisionbox = {}

		collisionbox.x, collisionbox.y = self:tileFromGrid{wall[1][1], wall[1][2]}

		collisionbox.h = 1
		collisionbox.w = #wall
		collisionbox.r = 0

		table.insert(colliders, collisionbox)
	end

	return colliders
end

function Floor:writeToFile(filename)
	--[[
	file = io.open(filename, "w")

	file:write("local map = {\n")

		file:write("grid = {\n")
		for j = 0, self.h - 1 do
			file:write("\t{")
			for i = 0, self.w - 1 do
				file:write(self.grid[j][i], ", ")
			end
			file:write("},\n")
		end
		file:write("},\n")

		file:write("tile = {\n")
		for j = 0, self.h - 1 do
			file:write("\t{")
			for i = 0, self.w - 1 do
				file:write(self.tiles[j][i], ", ")
			end
			file:write("},\n")
		end
		file:write("}\n")

	file:write("}\n return map")

	file:close()
	]]

	local patterns = {}
	local pattern = 0
	for j = 0, self.h-1 do
		for i = 0, self.w-1 do
			pattern = getBetterPattern(self.grid, i, j)

			if patterns[pattern] and patterns[pattern] ~= self.tiles[j][i] then

			else
				patterns[pattern] = self.tiles[j][i]
			end
		end
	end


	file = io.open("patterns.lua", "w")

	file:write("local patterns = {}\n")

	for pattern, tile in pairs(patterns) do
		file:write("patterns['", pattern, "'] = ", tile, "\n")
	end

	file:write("\nreturn patterns")
	file:close()
end










local MultiLevelDungeon = Map.new()
MultiLevelDungeon.__index = MultiLevelDungeon
map_types.MultiLevelDungeon = MultiLevelDungeon

--[[
	Options:
		seed
		spritesheet_name,
		grid_generate_func,
		tile_generate_func
]]
function MultiLevelDungeon.new(rect, options)
	local self = setmetatable({}, MultiLevelDungeon)
	options = options or {}

	self.x, self.y = rect[1], rect[2]
	self.w, self.h = rect[3], rect[4]

	local floors = {}
	local ladders = {}

	self.seed = options.seed or 0
	self.random = Random.new()
	self.random:seed(self.seed)


	for i = 1, self.random:random(1, 5) do
		floors[i] = Floor.new(rect,
			{
				seed = (options.seed or 0) + i,
				spritesheet_name = options.spritesheet_name,
				grid_generate_func = options.grid_generate_func,
				tile_generate_func = options.tile_generate_func
			})
		ladders[i] = {}
	end

	self.ladders = ladders
	self.floors = floors
	self.floorNum = 1
	self.floor = floors[self.floorNum]
	return self
end

local function fill(floor_obj, grid, x, y, room)
	local frontier = {}
	local floor = floor_obj.grid

	table.insert(frontier, {x, y})

	local directions = {
		{x = -1},
		{x = 1},
		{y = -1},
		{y = 1}
	}

	while #frontier > 0 do
		local x, y = table.unpack(table.remove(frontier))

		grid[y] = grid[y] or {}
		if floor[y][x] == 1 and not grid[y][x] then
			room.size = room.size + 1
			grid[y][x] = room
			room.points[y] = room.points[y] or {}
			room.points[y][x] = true

			for _, dir in pairs(directions) do
				local j = y + (dir.y or 0)
				local i = x + (dir.x or 0)

				grid[j] = grid[j] or {}

				if floor[j][i] == 1 and not grid[j][i] then
					table.insert(frontier, {i, j})
				end
			end
		end
	end
end

local function findRooms(floor_obj, grid, roomslist, floornum)
	local floor = floor_obj.grid
	for j = 0, floor_obj.h - 1 do
		grid[j] = grid[j] or {}
		for i = 0, floor_obj.w - 1 do
			if floor[j][i] == 1
				and not grid[j][i] then

				table.insert(roomslist, {label = #roomslist+1, floor = floornum, size = 0, edges = {}, points = {}})
				fill(floor_obj, grid, i, j, roomslist[#roomslist])
			end
		end
	end
end

local function findLadderEdges(floor, next_floor, edges, topFloornum)
	for j, row in pairs(floor) do
		for i, toproom in pairs(row) do
			bottomroom = next_floor[j] and next_floor[j][i]

			if bottomroom then
				local k = topFloornum
				edges[k][toproom] = toproom
				edges[k+1][bottomroom] = bottomroom

				local point = {x=i, y=j}

				toproom.edges[bottomroom] = toproom.edges[bottomroom] or {}
				bottomroom.edges[toproom] = bottomroom.edges[toproom] or {}

				toproom.edges[bottomroom].type = "ladder"
				bottomroom.edges[toproom].type = "ladder"

				table.insert(toproom.edges[bottomroom], {x=i,y=j,z=k})
				table.insert(bottomroom.edges[toproom], {x=i,y=j,z=k+1})
			end
		end
	end
end

-- unnecessary, now saved in room.points
local function getRoomPoints(floor, targetroom)
	local points = {}

	for j, row in pairs(floor) do
		for i, room in pairs(row) do
			if room == targetroom then
				table.insert(points, {x=i,y=j})
			end
		end
	end

	return points
end

local function breadthfirstEdgeSearch(floor, edges, startroom, depth)
	local queue = List.new()
	local opened = {}
	local finished = {}
	local paths = {}
	local results = {}

	local directions = {
		{x = -1},
		{x = 1},
		{y = -1},
		{y = 1}
	}

	-- create frontier from rooms points
	for j, row in pairs(startroom.points) do
		for i, val in pairs(row) do
			local point = {x=i, y=j}
			queue:pushright(point)
			paths[point] = {}
			opened[point.y] = opened[point.y] or {}
			opened[point.y][point.x] = true
		end
	end

	edges[startroom] = edges[startroom] or {}
	edges[startroom].edges = edges[startroom].edges or {}

	while queue:size() > 0 do
		local subroot = queue:popleft()

		if floor[subroot.y]
			and floor[subroot.y][subroot.x]
			and floor[subroot.y][subroot.x] ~= startroom
			and not edges[startroom].edges[endroom] then
			--success, found a room

			local endroom = floor[subroot.y][subroot.x]

			edges[startroom].edges[endroom] = paths[subroot]
			edges[startroom].edges[endroom].type = "hallway"
		else
			if #paths[subroot] <= depth then
				for _, dir in pairs(directions) do
					local j = subroot.y + (dir.y or 0)
					local i = subroot.x + (dir.x or 0)

					if not (finished[j] and finished[j][i]) then
						opened[j] = opened[j] or {}
						opened[j][i] = true

						local point = {x=i, y=j}
						queue:pushright(point)
						paths[point] = {}

						for k, nextpoint in ipairs(paths[subroot]) do
							table.insert(paths[point], nextpoint)
						end

						table.insert(paths[point], subroot)
					end
				end
			end
		end
		finished[subroot.y] = finished[subroot.y] or {}
		finished[subroot.y][subroot.x] = true
	end
end

local function findHallwayEdges(floor, edges)
	local finishedrooms = {}

	for j, row in pairs(floor) do
		for i, room in pairs(row) do
			if not finishedrooms[room] then

				breadthfirstEdgeSearch(floor, edges, room, 2)
				finishedrooms[room] = true
			end
		end
	end
end

local function solidifyEdge(map, edges, path)
	local points = true
	local pointIndex = true
	local point = true

	for parent, paths in pairs(path) do
		for _, child in ipairs(paths) do
			points = edges[parent.floor][parent].edges[child]

			if points.type == "ladder" then
				pointIndex = map.random:random(1, #points)
				point = points[pointIndex]

				local tpointx, tpointy = map:tileFromGrid({point.x, point.y})
				tile_point = {x = tpointx, y = tpointy}

				map.ladders[parent.floor][point.y] = map.ladders[parent.floor][point.y] or {}
				map.ladders[child.floor][point.y] = map.ladders[child.floor][point.y] or {}

				if parent.floor < child.floor then
					map.floors[parent.floor].em:createEntity("ladder",
						{tile_point.x, tile_point.y, "ladder_down"})
					map.floors[child.floor].em:createEntity("ladder",
						{tile_point.x, tile_point.y, "ladder_up"})
					map.ladders[parent.floor][point.y][point.x] = "down"
					map.ladders[child.floor][point.y][point.x] = "up"
				else
					map.floors[parent.floor].em:createEntity("ladder",
						{tile_point.x, tile_point.y, "ladder_up"})
					map.floors[child.floor].em:createEntity("ladder",
						{tile_point.x, tile_point.y, "ladder_down"})
					map.ladders[parent.floor][point.y][point.x] = "up"
					map.ladders[child.floor][point.y][point.x] = "down"
				end

			else if points.type == "hallway" then
				for _, point in ipairs(points) do
					local floor = map.floors[parent.floor].grid
					if floor[point.y][point.x] == 0 then
						floor[point.y][point.x] = 1
					end
				end
			end end
		end
	end
end

local function createPath(map, edges)
	local stack = List.new()
	local finished = {}

	local startroom = next(edges[1])
	local path = {start = startroom}
	path[startroom] = {}

	stack:pushright({startroom, nil})

	local endroom = next(edges[#map.floors])
	for room, _ in pairs(edges[#map.floors]) do
		if room.size > endroom.size then 
			endroom = room
		end
	end

	while stack:size() > 0 do
		local room, parent = table.unpack(stack:popright())

		if not finished[room] then
			if parent then
				path[parent][#path[parent]+1] = room
			end

			if room ~= endroom then
				local nextedges = List.new()

				for nextroom, info in pairs(edges[room.floor][room].edges) do
					if not finished[nextroom] then
						path[nextroom] = path[nextroom] or {}

						if info.type == "ladder" then
							nextedges:pushright({nextroom, room})
						else if info.type == "hallway" then
							nextedges:pushleft({nextroom, room})
						end end
					end
				end

				for room_info in nextedges:iter() do
					stack:pushright(room_info)
				end
			end
		end
		finished[room] = true
	end

	solidifyEdge(map, edges, path)

	return startroom, endroom
end

function MultiLevelDungeon:init()
	-- initialize starting floors
	for index, floor in ipairs(self.floors) do
		floor:init()
	end

	-- find rooms
	--local roomgrid = self:findRooms()
	local roomgrid = {}
	local roomslist = {}
	local edges = {}
	for index, floor in ipairs(self.floors) do
		edges[index] = {}
		roomgrid[index] = {}
		findRooms(floor, roomgrid[index], roomslist, index)
	end

	-- find edges
	--local edges = {}
	--self:findLadderEdges(roomgrid, edges)
	--self:findHallwayEdges(roomgrid, edges)
	for i = 1, #self.floors-1 do
		local floor = roomgrid[i]
		local next_floor = roomgrid[i+1]

		findLadderEdges(floor, next_floor, edges, i)
		findHallwayEdges(floor, edges[i])
	end

	findHallwayEdges(roomgrid[#roomgrid], edges[#roomgrid])

	-- create the path
	local startroom, endroom = createPath(self, edges)

	-- place entrance
	local starty, startrow = next(startroom.points)
	local startx = next(startrow)

	while self.ladders[1][starty] and self.ladders[1][starty][startx] do
		starty, startrow = next(startroom.points, starty)
		startx = next(startrow, startx)
	end

	local tstartx, tstarty = self:tileFromGrid({startx, starty})

	self.startpoint = {x=tstartx, y=tstarty}
	self.floors[1].em:createEntity("ladder",
		{tstartx, tstarty, "ladder_up"})
	self.ladders[1][starty] = self.ladders[1][starty] or {}
	self.ladders[1][starty][startx] = "up"


	-- place exit
end

function MultiLevelDungeon:render()
	-- draw features that floors can't know about
	for i = 1, #self.floors do
		self.floors[i]:render()
	end
end

function MultiLevelDungeon:setTile(coord, val, fill)
	local floor = self.floors[coord[3]]
	return floor and floor:setTile(coord, val, fill) or false
end

function MultiLevelDungeon:getTile(coord)
	local floor = self.floors[coord[3]]
	return floor:getTile(coord)
end

function MultiLevelDungeon:setTileCol(coord, val)
	local floor = self.floors[coord[3]]
	return floor and floor:setTileCol(coord, val, fill) or false
end

function MultiLevelDungeon:getTileCol(coord)
	local floor = self.floors[coord[3]]
	return floor:getTileCol(coord)
end

function MultiLevelDungeon:setFloor(val)
	self.floorNum = math.clamp(val, 1, #self.floors)
	self.floor = self.floors[self.floorNum]
end

function MultiLevelDungeon:getFloor()
	return self.floorNum
end

function MultiLevelDungeon:getNumFloors()
	return #self.floors
end

function MultiLevelDungeon:update()
	-- update animated tiles
end

function MultiLevelDungeon:gridFromTile(coord)

	local tilex, tiley = coord[1], coord[2]

	local gridx = tilex + math.floor((self.w-1)/2)-self.x
	local gridy = tiley + math.floor((self.h - 1)/2)-self.y

	return gridx, gridy
end

function MultiLevelDungeon:tileFromGrid(coord)

	local gridx, gridy = coord[1], coord[2]

	local tilex = gridx - math.floor((self.w - 1)/2)+self.x
	local tiley = gridy - math.floor((self.h - 1)/2)+self.y

	return tilex, tiley
end

function MultiLevelDungeon:interact(rect)
	local directions = {
		up = {y = 1},
		down = {y = -1},
		left = {x = -1},
		right = {x = 1}
	}

	local mintx, minty = math.round(rect.x), math.round(rect.y)
	local maxtx, maxty = math.round(rect.x + rect.w), math.round(rect.y + rect.h)

	local mingx, mingy = self:gridFromTile{mintx, minty}
	local maxgx, maxgy = self:gridFromTile{maxtx, maxty}

	local z = self.floorNum
	local ladder = true

	for j = mingy, maxgy do
		for i = mingx, maxgx do
			ladder = self.ladders[z] and self.ladders[z][j] and self.ladders[z][j][i]
			if ladder == "up" then
				if z == 1 then
					println("Exit")
				end

				return {{'push',
						'fadetoblackmapswitch',
						{map = self, ecs = self.ecs, dz = -1}}}

			else if ladder == "down" then

				return {{'push',
						'fadetoblackmapswitch',
						{map = self, ecs = self.ecs, dz = 1}}}
			end end
		end
	end
end

function MultiLevelDungeon:collision(rect)
	return self.floor:collision(rect)
end

function MultiLevelDungeon:writeToFile(filename)
	self.floor:writeToFile(filename)
end

return map_types
