local EntityManager = require(LUA_FOLDER.."engine.ecs.entitymanager")
local SystemManager = require(LUA_FOLDER.."engine.ecs.systemmanager")
local EventManager = require(LUA_FOLDER.."engine.ecs.eventmanager")

local Engine = {}
Engine.__index = Engine

function Engine.new(em)
	local self = setmetatable({}, Engine)

	self.em = em or EntityManager.new()
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