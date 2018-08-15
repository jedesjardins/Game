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

return SystemManager