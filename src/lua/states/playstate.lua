require(LUA_FOLDER .. 'engine.imgui')

local entities = require(LUA_FOLDER .. 'data.entities')
local systems = require(LUA_FOLDER .. 'data.systems')

local Maps = require(LUA_FOLDER .. 'data.map_types')
local map_generators = require(LUA_FOLDER .. 'data.map_generators')

local TestSystem = {
	update = function(em, events, dt, input)
		println("Update function")
		events:send({"test_event", "Ayyooo"})
	end,
	draw = function(em)
		println("Draw function")
	end,
	event = "test_event",
	receive = function(em, events, dt, message)
		println("Event function", message[1], message[2])
	end
}

local state = State.new()

function state:enter()
	local map = Maps.MultiLevelDungeon.new({0, 0, 96, 48},
		{
			seed = os.time(),
			grid_generate_func = map_generators.randomWalkRooms,
			--grid_generate_func = map_generators.allPatterns,
			tile_generate_func = map_generators.learnTilesFromPatterns
		})

	map:init()
	map:render()

	local ecs = ECS.new(map.floor.em)

	self:registerSystems(ecs)

	local view = View.new()
	view:setCenter(map.startpoint.x*TILESIZE, -map.startpoint.y*TILESIZE);
	view:setSize(TILESIZE*32,TILESIZE*24)

	ecs.em.camera_id = ecs.em:createEntity("camera", {view, "follow"})

	ecs.em.player_id = ecs.em:createEntity("man", {map.startpoint.x, map.startpoint.y})
	ecs.em:createEntity("sword", {map.startpoint.x, map.startpoint.y+2})
	--ecs.em:createEntity("sword", {map.startpoint.x, map.startpoint.y-3})
	ecs.em:createEntity("block", {map.startpoint.x+2, map.startpoint.y+2})
	--ecs.em:createEntity("block", {-2, 2})

	ecs.map = map
	map.ecs = ecs
	self.ecs = ecs
	self.map = map


	self.toggle_console = false
	self.toggle_demo = false
	self.env = createSafeEnvironment()
	self:registerConsoleFunctions()
end

function state:registerSystems(ecs)
	ecs:addSystem("controlPlayer", systems.controlPlayer)
	ecs:addSystem("controlCamera", systems.controlCamera)
	ecs:addSystem("interact", systems.interact)
	ecs:addSystem("changePosition", systems.changePosition)
	ecs:addSystem("velocity", systems.velocity)
	ecs:addSystem("lockDirection", systems.lockDirection)
	ecs:addSystem("heldItems", systems.heldItems)
	ecs:addSystem("collision", systems.collision)
	ecs:addSystem("damage", systems.damage)
	ecs:addSystem("changeAnimation", systems.changeAnimation)
	ecs:addSystem("updateSprite", systems.updateSprite)
	ecs:addSystem("basicDraw", systems.basicDraw)
end

function state:registerConsoleFunctions()

	local env = self.env

	local em = self.ecs.em
	local events = self.ecs.events

	env.reloadSystems = function()
		local package_name = LUA_FOLDER .. 'data.systems'
		package.loaded[package_name] = nil
		systems = require(package_name)
		self.ecs:clearSystems()
		self:registerSystems(self.ecs)
	end
	env[env.reloadSystems] = "()"


	env.reloadPresets = function()
		local package_name = LUA_FOLDER .. 'data.entities'
		package.loaded[package_name] = nil
		entities = require(package_name)

		self.ecs.em:addPresets(entities)
	end
	env[env.reloadPresets] = "()"


	env.createEntity = function(preset, arguments)
		return em:createEntity(preset, arguments)
	end
	env[env.createEntity] = "(string:preset, table:arguments)"


	env.getPlayerID = function() return em.player_id end
	env[env.getPlayerID] = "()"

	env.getPlayerPosition = function()
		return em:getComponent(em.player_id, "position")
	end
	env[env.getPlayerPosition] = "()"


	env.get = function(id, comp) return em:get(id, comp) end
	env[env.get] = "(number:id, [string:component_name])"


	env.deleteEntity = function(id) if id ~= em.player_id then em:deleteEntity(id) end end
	env[env.deleteEntity] = "(number:id)"


	env.highlightEntity = function(id)
		local hl = em:get(id, "highlight")
		em:addComponent(id, "highlight", not hl)
	end
	env[env.highlightEntity] = "(number:id)"


	env.pickup = function(id, id2)
		events:send(em, events, 0, {"pickup item", id, id2})
	end
	env[env.pickup] = "(number:id, number:id2)"


	env.drop = function(id, id2)
		events:send(em, events, 0, {"drop item", id, id2})
	end
	env[env.drop] = "(number:id, number:id2)"


	env.move = function(id, x, y)
		events:send(em, events, 0, {"change position", id, {x = x, y = y}})
	end
	env[env.move] = "(number:id, number:x_off, number:y_off)"


	env.listPresets = function()
		local str = ""
		local preset_names = {}

		for k, v in pairs(em.presets) do
			preset_names[#preset_names+1] = k
		end

		return table.concat(preset_names, "\n")
	end
	env[env.listPresets] = "()"
end

function state:update(dt, input)

	if input:state(KEYS["Escape"]) == KEYSTATE.PRESSED then
		return {{"switch", "menustate"}}
	end

	if input:state(KEYS["M"]) == KEYSTATE.PRESSED then
		--deepPrint("em", self.ecs.em, 0)
		return {{"switch", "map_editor", {map = self.map}}}
	end

	if input:state(KEYS["N"]) == KEYSTATE.PRESSED then
		--deepPrint("em", self.ecs.em, 0)
		return {{"push", "fadetoblackmapswitch", {ecs = self.ecs, map = self.map}}}
	end

	if input:state(KEYS["C"]) == KEYSTATE.PRESSED then
		self.toggle_console = not self.toggle_console
	end

	if input:state(KEYS["V"]) == KEYSTATE.PRESSED then
		self.toggle_demo = not self.toggle_demo
	end

	if self.toggle_console then
		Console(self.env)
	end

	if self.toggle_demo then
		Imgui.ShowDemoWindow()
	end


	local ret = self.ecs:update(dt, input)
	if ret then
		return ret
	end

	self.map:update()
end


function state:draw()
	self.ecs.em:getComponent(self.ecs.em.camera_id, "camera").view:makeTarget()
	--self.map.view:makeTarget()
	draw(self.map.floor.sprite)
	self.ecs:draw()
end

function state:exit()
	--self.map:delete()
end

return state
