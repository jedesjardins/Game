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
		println("Error: Entity", uid, "does not exist, set", component_type)
		return false
	end

	if not self.components[component_type] then
		self.components[component_type] = {}
	end

	self.components[component_type][uid] = data
end

function EntityManager:addComponent(uid, component_type, data)
	if not self.ids[uid] then
		println("Error: Entity", uid, "does not exist, addComponent")
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
		println("Error: Entity", uid, "does not exist, get", "no component")
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
		println("Error: Entity", uid, "does not exist, get", component_type)
		return nil
	end

	return self.components[component_type] 
		and self.components[component_type][uid]
end

function EntityManager:deleteEntity(uid)
	if not self.ids[uid] then
		println("Error: Entity", uid, "does not exist, delete")
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

return EntityManager