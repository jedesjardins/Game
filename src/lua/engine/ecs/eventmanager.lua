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

return EventManager 