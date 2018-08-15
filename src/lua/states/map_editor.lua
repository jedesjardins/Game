local state = State.new()

--local Map = require(LUA_FOLDER .. 'data.map_types')
local Command = require(LUA_FOLDER .. 'engine.command')

function state:enter(blackboard)

	self.map = blackboard.map

	local view = View.new()

	self.x = self.map.x
	self.y = self.map.y

	view:setCenter(self.x*TILESIZE, -self.y*TILESIZE)
	view:setSize(TILESIZE*self.map.w, TILESIZE*self.map.w*0.75)

	self.view = view

	self.current_tile = false

	self.collision = false
	self.paint = true
		self.last_x = false
		self.last_y = false
		self.last_val = false
	self.scale = 1
	self.fill = true

	self.past_commands = List.new()
	self.next_commands = List.new()
end

local SetTileCommand = Command:new()

function SetTileCommand:init(info)
	local map = info[1]
	local tilex = info[2]
	local tiley = info[3]
	local tilez = info[4]
	local after = info[5]
	local fill = info[6]
	local before = map:getTile{tilex, tiley, tilez}

	println("before:", before, "after:", after)

	self.Do = function(this)
		println("do set tile")
		map:setTile({tilex, tiley, tilez}, after, fill)
	end

	self.Undo = function(this)
		map:setTile({tilex, tiley, tilez}, before, fill)
	end
end

local SetTileAndColCommand = Command:new()

function SetTileAndColCommand:init(info)
	local map = info[1]
	local tilex = info[2]
	local tiley = info[3]
	local tilez = info[4]
	local afterTile = info[5]
	local afterCol = info[6]
	local beforeTile = map:getTile{tilex, tiley, tilez}
	local beforeCol = map:getTileCol{tilex, tiley, tilez}

	self.Do = function(this)
		map:setTile({tilex, tiley, tilez}, afterTile)
		map:setTileCol({tilex, tiley, tilez}, afterCol)
	end

	self.Undo = function(this)
		map:setTile({tilex, tiley, tilez}, beforeTile)
		map:setTileCol({tilex, tiley, tilez}, beforeCol)
	end
end

local ChangeFloorCommand = Command:new()

function ChangeFloorCommand:init(info)
	local map = info[1]
	local before = info[2]
	local after = info[3]

	self.Do = function(this)
		map:setFloor(after)
	end

	self.Undo = function(this)
		map:setFloor(before)
	end
end

function state:pushCommand(command)
	self.past_commands:pushright(command)
	if self.past_commands:size() > 20 then
		self.past_commands:popleft()
	end

	if self.next_commands:size() > 0 then
		self.next_commands = nil
		self.next_commands = List:new()
	end
end

function state:redoCommand()
	local command = self.next_commands:popleft()
	if command then
		command.Do()
		self.past_commands:pushright(command)
	end
end

function state:undoCommand()
	local command = self.past_commands:popright()
	if command then
		command.Undo() 
		self.next_commands:pushleft(command)
	end
end

function state:update(dt, input)

	if input:state(KEYS["Escape"]) == KEYSTATE.PRESSED then
		return {{"pop", 1}}
	end

	if input:state(KEYS["Return"]) == KEYSTATE.PRESSED then
		self.map:writeToFile("floor.lua")
	end

	if (input:mouseLeft() == KEYSTATE.PRESSED or (self.paint and input:mouseLeft() >= KEYSTATE.PRESSED))
		and self.current_tile then
		-- output map and tiles
		local vp = input:mouseViewPosition(self.view)
		local tile = {math.round(vp.x/TILESIZE), math.round(-vp.y/TILESIZE)}


		local command = false

		if self.last_x ~= tile[1]
			or self.last_y ~= tile[2]
			or self.last_val ~= self.current_tile then

			if self.collision then
				local x = self.current_tile%self.map.floor.spritesheet.w
				local y = math.floor(self.current_tile/self.map.floor.spritesheet.w)
				local col = self.map.floor.spritesheet.col[y+1][x+1]

				command = SetTileAndColCommand:new{self.map, tile[1], tile[2], self.map:getFloor(), self.current_tile, col}
			else
				command = SetTileCommand:new{self.map, tile[1], tile[2], self.map:getFloor(), self.current_tile, self.fill and not self.collision}
			end
			
			command.Do()

			self:pushCommand(command)

			self.last_x = tile[1]
			self.last_y = tile[2]
			self.last_val = self.current_tile
		end

	end

	if input:state(KEYS["LControl"]) >= KEYSTATE.PRESSED and input:state(KEYS["Z"]) == KEYSTATE.PRESSED then

		if input:state(KEYS["LShift"]) >= KEYSTATE.PRESSED then
			state:redoCommand()
		else
			state:undoCommand()
		end
	end

	if input:state(KEYS["W"]) >= KEYSTATE.PRESSED then
		self.y = self.y + 0.5
	end
	if input:state(KEYS["S"]) >= KEYSTATE.PRESSED then
		self.y = self.y - 0.5
	end
	if input:state(KEYS["A"]) >= KEYSTATE.PRESSED then
		self.x = self.x - 0.5
	end
	if input:state(KEYS["D"]) >= KEYSTATE.PRESSED then
		self.x = self.x + 0.5
	end

	self.view:setCenter(self.x*TILESIZE, -self.y*TILESIZE)


	if Imgui.Begin("Map Editor") then

		if Imgui.BeginMenuBar() then
			if Imgui.BeginMenu("File", true) then
				if Imgui.MenuItem("Export", "", false, true) then
					println("Implement Export")
				end
				if Imgui.MenuItem("Load", "", false, true) then
					println("Implement Import")
				end

				Imgui.EndMenu()
			end

			if Imgui.BeginMenu("Edit", true) then
				if Imgui.MenuItem("Undo", "Ctrl+Z", false, true) then
					state:undoCommand()
				end
				if Imgui.MenuItem("Redo", "Ctrl+Shift+Z", false, true) then
					state:redoCommand()
				end

				Imgui.EndMenu()
			end

			Imgui.EndMenuBar()
		end

		Imgui.Text("Current Floor:")
		if Imgui.ListBoxHeader("", self.map:getNumFloors(), 4) then
			for f = 1, self.map:getNumFloors() do
				if Imgui.Selectable(tostring(f), self.map:getFloor() == f) and self.map:getFloor() ~= f then
					local command = ChangeFloorCommand:new{self.map, self.map:getFloor(), f}
					command.Do()
					self:pushCommand(command)
				end
			end
			Imgui.ListBoxFooter()
		end

		Imgui.Text("Tile:")
		for y = 0, 5 do
			for x = 0, 3 do
				self.map.floor.spritesheet.sprite:setFrame(x, y)
				Imgui.PushID(""..x.." "..y)
				if Imgui.ImageButton(self.map.floor.spritesheet.sprite) then
					self.current_tile = y*4 + x
				end
				Imgui.PopID()
				Imgui.SameLine(0, -1)
			end
			Imgui.NewLine()
		end

		self.collision = Imgui.Checkbox("Tile Collision", self.collision)
		if Imgui.IsItemHovered() then Imgui.Tooltip("Collision behavior will be overwritten with spritesheet defined behavior") end
		self.paint = Imgui.Checkbox("Paint tiles", self.paint)
		if not self.collision then
			self.fill = Imgui.Checkbox("Fill related tiles", self.fill)
			if Imgui.IsItemHovered() then
				Imgui.Tooltip("Fills all tiles with matching surrounding collision patterns with the same value")
			end
		end
		self.scale = Imgui.SliderInt("Zoom", self.scale, 1, 4)
		self.view:setSize(TILESIZE*self.map.w/self.scale, TILESIZE*self.map.w*0.75/self.scale)
	end	
	Imgui.End()
end


function state:draw()
	self.view:makeTarget()
	draw(self.map.floor.sprite)
end

function state:exit()
	--self.map:delete()
end

return state