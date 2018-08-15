local Command = {}
Command.__index = Command

function Command:new(info)
	local o = setmetatable({}, self)

	self.init(o, info)

	return o
end

function Command:init(info)
end

function Command:Do()
end

function Command:Undo()
end

return Command