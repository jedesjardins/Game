local State = {}
State.__index = State

function State.new()
	local self = setmetatable({}, State)

	return self
end

function State.enter(arguments) end

function State.exit() end

function State:update() end

function State:draw() end

function State:destroy() end

return State