local Map = {}
Map.__index = Map

--[[

	Types of map:
		infinitely scrolling randomly generated
		small room
		dungeon

	TODO
		multiple floors
			How/where is the current floor tracked in a multi floor dungeon?
				In the map.
					The map has a reference to ecs so it can copy over player and inventory.
				How is traversing floors different than going into a building?
					The whole dungeon is generated at the start. Inside buildings are not.
					Have several map classes. 
						Infinite scrolling map has fixed view that generates new sections of the
							map when it nears the edge of the generated area.
						Dungeon Map has fixed view that generates whole dungeon when entered.
						Building Map has fixed view that generates whole building when entered.
							Floors can go up or down.
					How do you transition Maps? In states?
						Overworld State
						Dungeon State
						Building State
						Generic World State:
							Enter:
								passed location, different Map types interpret differently
								try to load map and objects, if not saved, generate it
							Exit:
								save map and objects, not the sprite though (I don't think)

			Does the map know what the current floor is?
				Dungeon/Building maps do. See above.

			How is the Layer tracked for objects?
				Layer is stored in the object. Object collisions check that the layer is the same

				Layer transition behavior? (Ground -> stairs -> Overpass)
					object should interact with other objects on the same layer
					objects on transition layer should interact with both


		generating
			Dungeon
				-- determine the number of floors, floor size, difficulty, etc

				-- carve rooms/caves (not connected) out of each floor

				-- create a graph where rooms are the nodes
					color each room differently (walls 0, rooms positive integers)

				-- determine start room (top floor) and goal room (bottom floor)

				-- determine all possible edges

				-- edge rules:
					adjacent rooms can be joined with a hallway
					stacked rooms can be joined with a ladder
					rooms on the same floor can be connected with a skyway
					there can only be one skyway per floor


				-- start solidifying edges to eventually create a path from start to finish
					This will be ~DAG~ that spans all rooms
				
				-- edge solidifying rules
					initially create a path from start to finish with a higher liklihood of going down
					start solidifying edges to edge rooms in depth first manner with
						a chance to stop solidifying on that branch (variable length limbs)
						You need to check if edges are valid before solidifying them. If an edge is 
						invalidated remove it.
						If there are disconnected rooms after depth first edge traversal forcefully connect them
					if you try to solidify an edge to an already connected room make it a soft edge
						can put a locked door or ability requirement to get through
					do this until all rooms are connected

					determine difficulty to get to each room (rooms at end of branch or whatever)
						items found inside are a result of the difficulty to get there





					Start with the starting room and starting difficulty.
					choose an edge
						edges are chosen on 
					solidify the edge, add it to solidified list
					set the difficulty of the next room slightly higher
					recurse

				-- ease of pathfinding to the goal determines the boss/prize 


				


			Building

		rendering
			Drawing order
				map layer 1
				objects layer 1
				map effects layer 1(fog)
				map layer 2
				objects layer 2
				layer effect (low alpha if below)

			tilesheet with multipletiles (obvious)
			different tilesheets for different areas

		switching floors
			todo:
				redraw floor
				remove (save?) entities not related to player


			solution:
				push fadetoblack
				pop fadetoblack
					push blackscreen (loading)
					push changefloor, old floor, new floor
						change the floor
						move over the entities
				pop changefloor
				pop blackscreen
					push fadetomap

]]

--[[
	Initialization/update Functions
]]

local sprite_map = 
{
	blank = {0, 0},
	grass = {1, 0},
	ladder_down = {2, 0},
	ladder_up = {3, 0},
	chest = {3, 1},
	block = {2, 4},
	upper_left_wall = {0, 1},
	upper_middle_wall = {1, 1},
	upper_right_wall = {2, 1},
	middle_left_wall = {0, 2},
	middle_middle_wall = {1, 2},
	middle_right_wall = {2, 2},
	lower_left_wall = {0, 3},
	lower_middle_wall = {1, 3},
	lower_right_wall = {2, 3},
	lower_left_wall = {0, 3},
	inner_left_wall = {0, 4},
	inner_right_wall = {1, 4}
}

function Map.new(tilex, tiley, tilew, tileh)
	local self = setmetatable({}, Map)

	self.spritesheet = Sprite.new()
	self.spritesheet:init("tiles.png", 4, 6, false)

	self.viewtype = "follow"

	self.x, self.y = tilex, tiley
	self.w, self.h = tilew, tileh

	self:init()

	return self
end

local function copy(floor)
	ret = {}
	for y, row in pairs(floor) do
		ret[y] = {}
		for x, val in pairs(row) do
			ret[y][x] = val
		end
	end
	return ret
end

function Map:setTile(tilex, tiley, tilez, val)
	local gridx, gridy = self:gridFromTile(tilex, tiley)

	local tiles = self.tiles[tilez]

	if tiles and tiles[gridy] then
		tiles[gridy][gridx] = val
		self:render()
	end
end

function Map:getTile(tilex, tiley, tilez)
	local gridx, gridy = self:gridFromTile(tilex, tiley)
	return self.tiles[tilez] and self.tiles[tilez][gridy] and self.tiles[tilez][gridy][gridx]
end

function Map:init()
	local seed = 1--os.time()
	math.randomseed(seed)
	-- self.grid = self:generateSimpleArray(self.x, self.y, self.w, self.h)
	-- wall chance, birth limit, death limit, steps
	--self.grid = self:generateCells(.45, 5, 4, 2)
	--self.grid = self:randomWalk()

	self.floor = 0
	self.floornum = 5
	self.floors = {}
	self.tiles = {}
	self.objects = {}
	self.ladders = {}

	-- create each floor
	for i = 0, self.floornum-1 do
		self.floors[i] = self:randomWalkRooms(seed+i, math.random(1, 3))
		self.tiles[i] = copy(self.floors[i])
		self.objects[i] = {}
		self.ladders[i] = {}
	end

	-- fine rooms
	local roomgrid = self:findRooms()

	-- find edges
	local edges = {}
	self:findLadderEdges(roomgrid, edges)
	self:findHallwayEdges(roomgrid, edges)

	local startroom, endroom = self:createPath(edges)

	local entrance = true

	for j = 0, self.h-1 do
		for i = 0, self.w-1 do
			local room = roomgrid[0] and roomgrid[0][j] and roomgrid[0][j][i]
			if room == startroom 
				and not (self.ladders[0][j] and self.ladders[0][j][i])
				then
				entrance = {x = i, y = j, z = 0}
			end
		end
	end

	self.ladders[0][entrance.y] = {}
	self.ladders[0][entrance.y][entrance.x] = "up"

	self.entrance = table.pack(self:tileFromGrid(entrance.x, entrance.y))

	local exit = true

	for j = 0, self.h-1 do
		for i = 0, self.w-1 do
			local room = roomgrid[self.floornum-1] and roomgrid[self.floornum-1][j] and roomgrid[self.floornum-1][j][i]
			if room == endroom 
				and not (self.ladders[self.floornum-1][j] and self.ladders[self.floornum-1][j][i])
				then
				exit = {x = i, y = j, z = self.floornum-1}
			end
		end
	end

	self.floors[exit.z][exit.y][exit.x] = 4

	self.grid = self.floors[self.floor]
	self:render()
end

function Map:render()
	if self.map_tex then
		self.map_tex:delete()
	end
	self.map_tex = RenderTexture.new(self.w*TILESIZE, self.h*TILESIZE)
	self.map_tex:init(255)

	local tiles = self.tiles[self.floor]

	for i=0, self.w-1 do
		for j=0, self.h-1 do
			self.spritesheet:setPosition(i*TILESIZE, (self.h-1-j)*TILESIZE)

			local frame = tiles[j][i]
			local framex = frame % 4
			local framey = math.floor(frame/4)
			if frame > 2 then
				println(frame, framey)
			end

			self.spritesheet:setFrame(framex, framey)
			self.map_tex:draw(self.spritesheet)
			--[[
			if framex == 4 then 
				self.spritesheet:setFrame(1, 0)
				self.map_tex:draw(self.spritesheet)

				frame = sprite_map["chest"]

				self.spritesheet:setFrame(table.unpack(frame))
				self.map_tex:draw(self.spritesheet)
			else
				self.spritesheet:setFrame(framex, 0)
				self.map_tex:draw(self.spritesheet)
			end
			]]
		end
	end

	local directions = {
		up = {y = 1},
		down = {y = -1},
		left = {x = -1},
		right = {x = 1}
	}

	for j, row in pairs(self.ladders[self.floor] or {}) do
		for i, laddertype in pairs(row) do

			frame = sprite_map["ladder_"..laddertype]

			self.spritesheet:setFrame(table.unpack(frame))
			self.spritesheet:setPosition(i*TILESIZE, (self.h-1-j)*TILESIZE)
			self.map_tex:draw(self.spritesheet)
		end
	end

	local centerxgrid = math.ceil(self.w/2) - 1
	self.centerxpix = centerxgrid*TILESIZE + TILESIZE/2

	local centerygrid = self.h - math.ceil(self.h/2)
	self.centerypix = centerygrid*TILESIZE + TILESIZE/2

	self.map_sprite = Sprite.new()
	self.map_sprite:initFromTarget(self.map_tex)
	self.map_sprite:setOrigin(self.centerxpix, self.centerypix)
	self.map_sprite:setPosition(self.x*TILESIZE, -self.y*TILESIZE)
end

function Map:moveDownLevel()
	--print(self.floor)
	self.last_floor = self.floor
	self.floor = math.clamp(self.floor+1, 0, self.floornum-1)
	--println("->", self.floor)
	self.grid = self.floors[self.floor]
end

function Map:moveUpLevel()
	--print(self.floor)
	self.last_floor = self.floor
	self.floor = math.clamp(self.floor-1, 0, self.floornum-1)
	--println("->", self.floor)
	self.grid = self.floors[self.floor]
end

function Map:swapFloor(next_floor)
	if self.floor == next_floor then return end
	self.floor = math.clamp(next_floor, 0, self.floornum-1)
	self.grid = self.floors[self.floor]
	self:render()
end

function Map:runStep()

	local function wallswithin(grid, x, y, d)
		local wallcount = 0
		for j=y-d, y+d do
			for i=x-d,x+d do
				--if i ~= x or j ~= y then
					if not grid[j] or grid[j][i] == 0 then
						wallcount = wallcount + 1
					end
				--end
			end
		end

		return wallcount
	end

	local function step(grid)
		local newgrid = {}

		for j=0, self.h-1 do
			newgrid[j] = {}
			for i=0, self.w-1 do
				if (i == 0)
					or (j == 0)
					or (i == self.w-1)
					or (j == self.h-1) then
					newgrid[j][i] = 0
				else
					local wallcount = wallswithin(grid, i, j, 1)
					local alivecount = 9 - wallcount

					if grid[j][i] == 0 then
						newgrid[j][i] = alivecount >= (self.birthlimit or 4) and 1 or 0
					else
						newgrid[j][i] = alivecount <= (self.deathlimit or 2) and 0 or 1
					end
				end
			end
		end

		return newgrid
	end

	self.grid = step(self.grid)

	self:render()
end

function Map:update()
	if self.viewtype == "follow" then
		local pos = self.em:get(self.em.player_id, "position")--components.position[self.em.player_id]
		self.view:setCenter(pos.x*TILESIZE, -pos.y*TILESIZE)
	end
end

--[[
	Helper Functions
]]

function Map:getTileDims(x, y, tilew, tileh)
	local minx, maxx = math.floor(x - tilew/2) + 1, math.floor(x + tilew/2)
	local miny, maxy = math.floor(y - tileh/2) + 1, math.floor(y + tileh/2)

	return minx, maxx, miny, maxy
end

function Map:gridFromTile(tilex, tiley)
	local gridx = tilex + math.floor((self.w-1)/2)-self.x
	local gridy = tiley + math.floor((self.h - 1)/2)-self.y
	return gridx, gridy
end

function Map:tileFromGrid(gridx, gridy)
	local tilex = gridx - math.floor((self.w - 1)/2)+self.x
	local tiley = gridy - math.floor((self.h - 1)/2)+self.y
	return tilex, tiley
end

function Map:interact(rect) --x, y, direction)

	local directions = {
		up = {y = 1},
		down = {y = -1},
		left = {x = -1},
		right = {x = 1}
	}

	local mintx, minty = math.round(rect.x), math.round(rect.y)
	local maxtx, maxty = math.round(rect.x + rect.w), math.round(rect.y + rect.h)

	local mingx, mingy = self:gridFromTile(mintx, minty)
	local maxgx, maxgy = self:gridFromTile(maxtx, maxty)

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
end

function Map:collision(rect)
	local mintx, minty = math.round(rect.x), math.round(rect.y)
	local maxtx, maxty = math.round(rect.x + rect.w), math.round(rect.y + rect.h)

	local mingx, mingy = self:gridFromTile(mintx, minty)
	local maxgx, maxgy = self:gridFromTile(maxtx, maxty)

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

		collisionbox.x, collisionbox.y = self:tileFromGrid(wall[1][1], wall[1][2])

		collisionbox.h = 1
		collisionbox.w = #wall
		collisionbox.r = 0

		table.insert(colliders, collisionbox)
	end

	return colliders
end

--[[
	Dungeon Pathfinding
]]

function Map:solidifyEdge(edges, path)

	local points = true
	local pointIndex = true
	local point = true

	for parent, paths in pairs(path) do
		for _, child in ipairs(paths) do
			points = edges[parent.floor][parent].edges[child]

			if points.type == "ladder" then
				pointIndex = math.random(#points)
				point = points[pointIndex]


				self.ladders[parent.floor][point.y] = self.ladders[parent.floor][point.y] or {}
				self.ladders[child.floor][point.y] = self.ladders[child.floor][point.y] or {}

				if parent.floor < child.floor then
					--parent is ladder down
					--child is ladder up
					self.ladders[parent.floor][point.y][point.x] = "down"
					self.ladders[child.floor][point.y][point.x] = "up"
					
				else
					--parent is ladder up
					--child is ladder down
					self.ladders[parent.floor][point.y][point.x] = "up"
					self.ladders[child.floor][point.y][point.x] = "down"
				end
			else if points.type == "hallway" then
				for _, point in ipairs(points) do
					if self.floors[point.z][point.y][point.x] == 0 then
						self.floors[point.z][point.y][point.x] = 1
					end
				end
			end end
		end
	end
end

function Map:createPath(edges)

	local stack = List.new()
	local finished = {}
	-- tree of edges

	-- depth first connect all rooms
	local startroom = next(edges[0])
	local path = {start = startroom}
	path[startroom] = {}
					-- room, parent
	stack:pushright({startroom, nil})

	local endroom = next(edges[self.floornum-1])
	for room, _ in pairs(edges[self.floornum-1]) do
		if room.size > endroom.size then
			endroom = room
		end
	end

	while stack:size() > 0 do
		local room, parent = table.unpack(stack:popright())

		if not finished[room] then	--TODO: add small chance to loop here
			if parent then
				path[parent][#path[parent]+1] = room
			end

			if room ~= endroom then
				-- look at all adjacent edges
				-- sort so ladders are more likely
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
				-- push them all to the stack
				
				for room_info in nextedges:iter() do
					stack:pushright(room_info)
				end

			end
		end

		finished[room] = true
	end

	self:solidifyEdge(edges, path)

	return startroom, endroom
end

function Map:breadthfirstEdgeSearch(roomgrid, edges, startroom, startpoints, depth)
	
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



	local z = true

	for i, point in ipairs(startpoints) do
		z = point.z
		queue:pushright(point)
		paths[point] = {}
		opened[point.y] = opened[point.y] or {}
		opened[point.y][point.x] = true
	end

	edges[z] = edges[z] or {}
	edges[z][startroom] = edges[z][startroom] or {}
	edges[z][startroom].edges = edges[z][startroom].edges or {}

	-- breadthfirst search 
	while queue:size() > 0 do
		local subroot = queue:popleft()

		if roomgrid[z]
			and roomgrid[z][subroot.y]
			and roomgrid[z][subroot.y][subroot.x]
			and roomgrid[z][subroot.y][subroot.x] ~= startroom
			and not edges[z][startroom].edges[endroom] then

			--success! Found a room
			--add room and the path to it to

			local endroom = roomgrid[z][subroot.y][subroot.x]



			edges[z][startroom].edges[endroom] = paths[subroot]
			edges[z][startroom].edges[endroom].type = "hallway"
		else
			if #paths[subroot] <= depth then

				for _, dir in pairs(directions) do

					local j = subroot.y + (dir.y or 0)
					local i = subroot.x + (dir.x or 0)

					-- if adjacent tile hasn't been seen yet, or the new path would be shorter
					if not (finished[j] and finished[j][i]) 
						and j >= 0 and j < self.h
						and i >= 0 and i < self.w
						then
						
						-- if adjacent tile isn't in the open set yet
						if not (opened[j] and opened[j][i]) then
							-- push onto frontier
							opened[j] = opened[j] or {}
							opened[j][i] = true
							-- record path
							local point = {x = i, y = j, z = z}
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
		end

		finished[subroot.y] = finished[subroot.y] or {}
		finished[subroot.y][subroot.x] = true
	end
end

function Map:getRoomPoints(roomgrid, targetroom, floornum)
	local points = {}

	for j, row in pairs(roomgrid[floornum]) do
		for i, room in pairs(row) do
			if room == targetroom then
				table.insert(points, {x = i, y = j, z = floornum})
			end
		end
	end

	return points
end

function Map:findHallwayEdges(roomgrid, edges)

	local finishedrooms = {}

	for k=0, self.floornum-1 do
		for j, row in pairs(roomgrid[k]) do
			for i, room in pairs(row) do

				if not finishedrooms[room] then

					-- i, j, k is a point in room
					-- find all points in the room push them as frontier
					local roompoints = self:getRoomPoints(roomgrid, room, k)

					self:breadthfirstEdgeSearch(roomgrid, edges, room, roompoints, 2)
					finishedrooms[room] = true
				end
			end
		end
	end
end

function Map:findLadderEdges(roomgrid, edges)
	for k=0, self.floornum-1 do
		edges[k] = edges[k] or {}
	end

	-- exclude bottom floor, only connect rooms down
	for k=0, self.floornum-2 do
		for j=0, self.h-1 do
			for i=0, self.w-1 do
				local toproom = roomgrid[k] and roomgrid[k][j] and roomgrid[k][j][i]
				local bottomroom = roomgrid[k+1] and roomgrid[k+1][j] and roomgrid[k+1][j][i]

				if toproom and bottomroom then
					--track rooms
					edges[k][toproom] = toproom
					edges[k+1][bottomroom] = bottomroom

					local point = {
						x = i, y = j
					}

					toproom.edges = toproom.edges or {}
					bottomroom.edges = bottomroom.edges or {}

					toproom.edges[bottomroom] = toproom.edges[bottomroom] or {}
					bottomroom.edges[toproom] = bottomroom.edges[toproom] or {}

					toproom.edges[bottomroom].type = "ladder"
					bottomroom.edges[toproom].type = "ladder"

					table.insert(toproom.edges[bottomroom], {x = i, y = j, z = k})
					table.insert(bottomroom.edges[toproom], {x = i, y = j, z = k+1})
				end
			end
		end
	end
end

local function fill(floor, grid, sx, sy, room)
	local frontier = {}

	--room.size = 0

	table.insert(frontier, {sx, sy})

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

function Map:findRooms()
	local grids = {}
	local rooms = {}
	local labelindex = 1

	for f = 0, self.floornum-1 do
		grids[f] = {}
		for j = 0, self.h-1 do
			grids[f][j] = grids[f][j] or {}

			for i = 0, self.w-1 do

				if self.floors[f][j][i] == 1
					and not grids[f][j][i] then

					table.insert(rooms, {label = labelindex, floor = f, size = 0})
					fill(self.floors[f], grids[f], i, j, rooms[#rooms])
					labelindex = labelindex + 1
				end
			end
		end
	end

	return grids
end

--[[

	DUNGEON GENERATION

]]

--[[
	binaryDungeon: binary splits of dungeon to place rooms
]]



--[[
	randomWalkRooms: more mature drunkards walk

	algorithm:
		runs multiple drunkards walks of a minimum result size of 5
		each run is dissallowed from coming within 2 tiles of other walks
		if a run takes over 10000 attempts to place a block it fails and retrys
		rooms are placed repeatedly until 40% of the grid is filled

]]

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

local function isValid(floor, x, y, w, h)

	local edgedistance = math.random(1, 8)

	local nearedge = x >= edgedistance and x < (w - 1 - edgedistance)
		and y >= edgedistance and y < (h - 1 - edgedistance)

	local inpreviousroom = floor[y] and floor[y][x]

	return nearedge and not inpreviousroom
end

local function placeCave(floor, w, h, minsize)
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

	local x = math.random(1, w - 2)
	local y = math.random(1, h - 2)


	local attempts = 0

	while not isValid(floor, x, y, w, h) and attempts < w * h do
		x = math.random(1, w - 2)
		y = math.random(1, h - 2)
		attempts = attempts + 1
	end

	--TODO: x and y should be checked they aren't in or adjacent to previous rooms
	grid[y][x] = 1
	numroomcells = numroomcells + 1

	local dir = {}

	while (numroomcells < targetroommin 
		or math.random() < 1 - math.pow(((numroomcells-minsize)/1000), 2))
		and attempts < 10000 do

		--choose direction
		if math.random() < .5 then
			dir = directions[math.random(1,4)]
		end

		local nextx = x + (dir.x or 0)
		local nexty = y + (dir.y or 0)

		while not isValid(floor, nextx, nexty, w, h) and attempts < 10000 do
			dir = directions[math.random(1,4)]
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

function Map:randomWalkRooms(seed, smooth)
	math.randomseed(seed)

	local floor = {}

	local numfloorcells, targetfloormin = 0, self.w * self.h * 0.4

	-- Create each rooms' table
	--for r = 1, 2 do

	local attempts = 0

	while numfloorcells < targetfloormin and attempts < 100 do

		grid, size = placeCave(floor, self.w, self.h, 5)
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
		floor = step(floor, self.w, self.h, birthlimit, deathlimit)
	end

	for j=0, self.h-1 do
		if not floor[j] then floor[j] = {} end
		for i=0, self.w-1 do
			if not floor[j][i] then floor[j][i] = 0 end
		end
	end

	return floor
end

--[[
	randomWalk: drunkards walk
]]

function Map:randomWalk()
	math.randomseed(os.time())

	-- initialize everything 
	local grid = {}
	for j=0, self.h-1 do
		grid[j] = {}
		for i=0, self.w-1 do
			grid[j][i] = 0
		end
	end



	local x = math.random(1, self.w - 2)
	local y = math.random(1, self.h - 2)
	local numcells, targetnum = 0, self.w * self.h * 0.3

	local directions = {
		{x = -1},
		{x = 1},
		{y = -1},
		{y = 1}
	}

	grid[y][x] = 1
	numcells = numcells + 1

	while numcells < targetnum do

		--choose direction
		local valid = false
		while not valid do
			local dir = directions[math.random(1,4)]
			local nextx = x + (dir.x or 0)
			local nexty = y + (dir.y or 0)

			if nextx > 0 and nextx < self.w - 1
				and nexty > 0 and nexty < self.h - 1 
				then

				local function distance(c1, c2)
					return math.abs(c2[1]-c1[1]) + math.abs(c2[2]-c1[2])
				end

				local d1 = distance({x, y}, {self.x, self.y})
				local d2 = distance({nextx, nexty}, {self.x, self.y})

				if (d2 > d1 and math.random() < .8) or d1 >= d2 then

					x = nextx
					y = nexty

					valid = true
				end

			end
		end

		if grid[y][x] == 0 then
			numcells = numcells + 1
		end

		grid[y][x] = 1
	end

	return grid
end

--[[
	generateCells: basic cellular automata
]]

function Map:generateCells(wallchance, birthlimit, deathlimit, steps)
	math.randomseed(os.time())
	local grid = {}
	for j=0, self.h-1 do
		grid[j] = {}
		for i=0, self.w-1 do
			grid[j][i] = (math.random() < wallchance and 0) or 1
		end
	end

	local function wallswithin(grid, x, y, d)
		local wallcount = 0
		for j=y-d, y+d do
			for i=x-d,x+d do
				--if i ~= x or j ~= y then
					if not grid[j] or grid[j][i] == 0 then
						wallcount = wallcount + 1
					end
				--end
			end
		end

		return wallcount
	end

	local function step(grid)
		local newgrid = {}

		for j=0, self.h-1 do
			newgrid[j] = {}
			for i=0, self.w-1 do
				if (i == 0)
					or (j == 0)
					or (i == self.w-1)
					or (j == self.h-1) then
					newgrid[j][i] = 0
				else
					local wallcount = wallswithin(grid, i, j, 1)
					local alivecount = 8 - wallcount

					if grid[j][i] == 0 then
						newgrid[j][i] = alivecount >= birthlimit and 1 or 0
					else
						newgrid[j][i] = alivecount <= deathlimit and 0 or 1
					end
				end
			end
		end

		return newgrid
	end

	for i = 1, steps do
		grid = step(grid)
	end

	return grid
end

return Map

