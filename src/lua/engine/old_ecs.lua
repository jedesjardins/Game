
local function deepcopy(val, scratch)
	if type(val) == "table" then
		local t = {}
		for k, v in pairs(val) do
			t[k] = deepcopy(v, scratch)
		end
		return t
	else if type(val) == "string" then
		if #val > 1 and string.sub(val, 1, 1) == "$" then
			local index = tonumber(string.sub(val, 2))
			if not scratch[index] then 
				print("Entity requires at least "..tostring(index).. " arguments to create.")
			end
			return scratch[index]
		else
			return val
		end
	else
		return val
	end end
end

local EntityManager = {}
EntityManager.__index = EntityManager

function EntityManager.new()
	local self = setmetatable({}, EntityManager)

	-- contains list of entities, list of components
	self.currUid = 1	-- next uid to use
	self.openUids = {}	-- list of unused ids, "holes" in the id list

	self.ids = {}		-- table of valid ids
	self.components = {} -- table of component lists

	self.presets = nil

	return self
end

function EntityManager:addPresets(entities)
	self.presets = {}
	for name, components in pairs(entities) do
		self.presets[name] = components
	end
end

function EntityManager:getNextID()
	-- get a unique uid
	local uid = 0
	local openUids = self.openUids
	if(#openUids ~= 0) then
		uid = openUids[#openUids]
		openUids[#openUids] = nil
	else
		uid = self.currUid
		self.currUid = self.currUid + 1
	end

	self.ids[uid] = true

	return uid
end

function EntityManager:createEntity(presetname, arguments)
	local preset = self.presets[presetname]
	if not preset then
		println("Error: Preset", presetname, "does not exist")
		return nil
	end

	local entity = deepcopy(preset, arguments)

	return self:addEntity(entity)
end

local function addComponentUnprotected(em, uid, component_type, data)
	em.components[component_type] = em.components[component_type] or {}
	em.components[component_type][uid] = data
end

function EntityManager:addEntity(entity)
	local uid = self:getNextID()

	-- for each component in entity, store it
	for component_type, data in pairs(entity) do
		addComponentUnprotected(self, uid, component_type, data)
	end

	return uid
end

function EntityManager:deleteComponent(uid, component_type)
	self:set(uid, component_type, nil)
end

function EntityManager:set(uid, component_type, data)
	if not self.ids[uid] then
		println("Error: Entity", uid, "does not exist")
		return false
	end

	if not self.components[component_type] then
		self.components[component_type] = {}
	end

	self.components[component_type][uid] = data
end

function EntityManager:addComponent(uid, component_type, data)
	if not self.ids[uid] then
		println("Error: Entity", uid, "does not exist")
		return false
	end

	addComponentUnprotected(self, uid, component_type, data)
	return true
end

function EntityManager:get(uid, component_type)
	if component_type then
		return self:getComponent(uid, component_type)
	else
		return self:getEntity(uid)
	end
end

function EntityManager:getEntity(uid)
	if not self.ids[uid] then
		println("Error: Entity", uid, "does not exist")
		return nil
	end

	local entity = {}

	for component_type, list in pairs(self.components) do
		entity[component_type] = list[uid]
	end

	return entity
end

function EntityManager:getComponent(uid, component_type)
	if not self.ids[uid] then
		println("Error: Entity", uid, "does not exist")
		return nil
	end

	return self.components[component_type] 
		and self.components[component_type][uid]
end

function EntityManager:deleteEntity(uid)
	if not self.ids[uid] then
		println("Error: Entity", uid, "does not exist")
		return nil
	end

	local entity = {}
	self.ids[uid] = nil

	for component_type, list in pairs(self.components) do
		entity[component_type] = list[uid]
		list[uid] = nil
	end

	return entity
end

function EntityManager:addEntities(entities)
	local max_id = 0
	for uid, components in pairs(entities) do
		self.ids[uid] = true
		if uid > max_id then max_id = uid end
		for component_type, data in pairs(components) do
			addComponentUnprotected(self, uid, component_type, data)
		end
	end

	self.currUid = max_id + 1

	for uid = 1, max_id do
		if not self.ids[uid] then
			self.openUids[#self.openUids+1] = uid
		end
	end
end

function EntityManager:clearEntities()
	local entities = {}

	for uid, valid in pairs(self.ids) do
		entities[uid] = self:deleteEntity(uid)
	end

	return entities
end

function EntityManager:foreachWith(component_types, func)
	local components = {}
	local o_component_type = component_types[1]
	local component_type = false
	local has_all = true

	for id, comp in pairs(self.components[o_component_type] or {}) do
		components[o_component_type] = comp

		if comp then
			for i = 2, #component_types do
				local component_type = component_types[i]

				component = self.components[component_type]
					and self.components[component_type][id]

				if not component then
					has_all = false
					break
				end	

				components[component_type] = component
			end

			if has_all then
				func(id, components)
			end
			has_all = true
		end
	end
end



local SystemManager = {}
SystemManager.__index = SystemManager

function SystemManager.new()
	local self = setmetatable({}, SystemManager)

	self.update_systems = {}
	self.draw_systems = {}

	return self
end

function SystemManager:addUpdateSystem(system_name, update_function)
	local systems = self.update_systems
	systems[#systems+1] = update_function
end

function SystemManager:addDrawSystem(system_name, draw_function)
	local systems = self.draw_systems
	systems[#systems+1] = draw_function
end

function SystemManager:clearSystems()
	self.update_systems = {}
	self.draw_systems = {}
end



local EventManager = {}
EventManager.__index = EventManager

function EventManager.new()
	local self = setmetatable({}, EventManager)

	self.receivers = {}

	return self
end

function EventManager:register(event, receiver_name, receive_function)

	if type(event) == "string" then
		event = {event}
	end

	local list = false
	for _, event_type in pairs(event) do
		list = self.receivers[event_type] or {}

		list[#list+1] = receive_function

		self.receivers[event_type] = list
	end
end

function EventManager:send(em, events, dt, message)
	local event = message[1]

	for _, receive in ipairs(self.receivers[event] or {}) do
		receive(em, events, dt, message)
	end
end

function EventManager:clearReceivers()
	self.receivers = {}
end



local Engine = {}
Engine.__index = Engine

function Engine.new()
	local self = setmetatable({}, Engine)

	self.em = EntityManager.new()
	self.sm = SystemManager.new()
	self.events = EventManager.new()

	return self
end

function Engine:update(dt, input)
	for index, func in ipairs(self.sm.update_systems) do
		local ret = func(self.em, self.events, dt, input, self.map)

		if ret then
			return ret 
		end
	end
end

function Engine:draw()
	for index, func in ipairs(self.sm.draw_systems) do
		func(self.em)
	end
end

function Engine:addSystem(system_name, system)

	if system.update then
		--println("Add update system", system_name)
		self.sm:addUpdateSystem(system_name, system.update)
	end

	if system.draw then
		--println("Add draw system", system_name)
		self.sm:addDrawSystem(system_name, system.draw)
	end

	if system.event and system.receive then
		--println("Add event listener", system_name)
		self.events:register(system.event, system_name, system.receive)
	end
end

function Engine:clearSystems()
	self.sm.update_systems = {}
	self.sm.draw_systems = {}
	self.events.receivers = {}
end

return Engine



--[====[

local ECS = {}
ECS.__index = ECS

local comp_mt = {
	__index = function(comp, key)
		local t = {}
		rawset(comp, key, t)
		return  t
	end
}

local function deepcopy(val, scratch)
	if type(val) == "table" then
		local t = {}
		for k, v in pairs(val) do
			t[k] = deepcopy(v, scratch)
		end
		return t
	else if type(val) == "string" then
		if #val > 1 and string.sub(val, 1, 1) == "$" then
			local index = tonumber(string.sub(val, 2))
			if not scratch[index] then 
				print("Entity requires at least "..tostring(index).. " arguments to create.")
			end
			return scratch[index]
		else
			return val
		end
	else
		return val
	end end
end

function ECS.new()
	local self = setmetatable({}, ECS)

	self.currUid = 1
	self.openUids = {}
	self.deleteUids = {}
	self.presets = {}
	self.components = {}
	self.beginsystems = {}
	self.systems = {}
	self.endsystems = {}
	self.drawsystems = {}

	setmetatable(self.components, comp_mt)
	return self
end

function ECS:requireAllBut(all, but)
	if #all == 0 then return {} end
	
	but = but or {}

	local entities = {}
	local first_require = self.components[all[1]]

	for uid, _ in pairs(first_require) do
		local include = true

		-- check components to have
		for i = 2, #all do
			if not self.components[all[i]][uid] then
				include = false
				break
			end
		end

		if include then
			-- check components not to have
			for i = 1, #but do 
				if self.components[but[i]][uid] then
					include = false
					break
				end
			end

			if include then table.insert(entities, uid) end
		end
	end

	return entities
end


function ECS:requireAll(...)
	local argc = select("#", ...)

	if argc < 1 then return {} end

	for i = 1, argc do
		local comp = select(i, ...)
		if #comp < 1 then return {} end
	end

	local entities = {}
	local first_require = self.components[select(1, ...)]

	for uid, _ in pairs(first_require) do
		local is_present = true

		for i = 2, argc do
			if not self.components[select(i, ...)][uid] then
				is_present = false
				break
			end
		end

		if is_present then table.insert(entities, uid) end
	end
	
	return entities
end

function ECS:addPresets(entities)
	for name, components in pairs(entities) do
		self.presets[name] = components
		self.presets[name].name = name
	end
end

function ECS:addEntity(preset, scratch)

	if type(preset) == "string" then
		local entity = self.presets[preset]
		if not entity then
			Debug:writeln("ECS","No entity", preset)
			return nil
		end

		return self:copyEntityFromTable(entity, scratch)

	else if type(preset) == "table" then	
		return self:addEntityFromTable(preset)
	end end
end

function ECS:addEntityFromTable(entity)
	-- get a unique uid
	local uid = 0
	if(#self.openUids ~= 0) then
		uid = self.openUids[#self.openUids]
		self.openUids[#self.openUids] = nil
	else
		uid = self.currUid
		self.currUid = self.currUid + 1
	end

	-- for each component in entity, store it
	for comp, values in pairs(entity) do
		local components = self.components[comp]
		components[uid] = values
	end

	return uid
end

function ECS:copyEntityFromTable(entity, scratch)
	-- get a unique uid
	local uid = 0
	if(#self.openUids ~= 0) then
		uid = self.openUids[#self.openUids]
		self.openUids[#self.openUids] = nil
	else
		uid = self.currUid
		self.currUid = self.currUid + 1
	end

	-- for each component in entity, store it
	for comp, values in pairs(entity) do
		local components = self.components[comp]
		components[uid] = deepcopy(values, scratch or {})
	end

	return uid
end

function ECS:addComponent(id, name, comp, scratch)
	self.components[name][id] = deepcopy(comp, scratch or {})
end

function ECS:getEntity(uid)
	local entity = {}

	for componentname, datalist in pairs(self.components) do
		entity[componentname] = datalist[uid]
	end

	return entity
end

function ECS:removeEntity(uid)
	-- delete is done at the end of update
	table.insert(self.deleteUids, uid)
end

function ECS:addEntities(entities)

	local max_id = 0

	for id, data in pairs(entities) do
		if id > max_id then max_id = id end
		for compName, compData in pairs(data) do
			self.components[compName][id] = compData
		end
	end

	self.currUid = max_id + 1

	for id = 1, max_id do
		if not entities[id] then
			self.openUids[#self.openUids+1] = id
		end
	end
end

function ECS:clearEntities()

	local entities = {}

	for name, component in pairs(self.components) do
		for uid, v in pairs(component) do
			entities[uid] = entities[uid] or {}
			entities[uid][name] = component[uid]

			component[uid] = nil
		end
	end

	self.currUid = 1
	self.openUids = {}

	return entities
end

function ECS:addBeginSystem(func)
	table.insert(self.beginsystems, func)
end

function ECS:addSystem(func)
	table.insert(self.systems, func)
end

function ECS:addEndSystem(func)
	table.insert(self.endsystems, func)
end

function ECS:addDrawSystem(func)
	table.insert(self.drawsystems, func)
end

function ECS:removeSystem(name)
	self.systems[name] = nil
end

function ECS:clearSystems()
	for name, func in pairs(self.systems) do
		self.systems[name] = nil
	end
end

function ECS:update(dt, input)

	for index, func in ipairs(self.beginsystems) do
		local ret = func(self, dt, input)
		if ret then return ret end
	end

	for index, func in ipairs(self.systems) do
		func(self, dt, input)
	end

	for index, func in ipairs(self.endsystems) do
		func(self, dt, input)
	end

	self:clearDeleteQueue()

	return ret
end

function ECS:clearDeleteQueue()
	for _, uid in ipairs(self.deleteUids) do
		self.openUids[#self.openUids+1] = uid

		for name, components in pairs(self.components) do
			components[uid] = nil
		end
	end

	self.deleteUids = {}
end

function ECS:draw()
	for index, func in ipairs(self.drawsystems) do
		func(self)
	end
end

return ECS

]====]
