
local StateManager = {}
StateManager.stack = {}

local state = require(LUA_FOLDER .. 'states.menustate')

state:enter()

table.insert(StateManager.stack, state)

function StateManager:update(dt, input)
	local actions = self.stack[#self.stack]:update(dt, input) or {}
	-- action
	--	1 = stack action
	--	2 = state
	-- 	3 = blackboard table
	for _, action in ipairs(actions) do

		if action[1] == "switch" then
			table.remove(self.stack):exit()

			local state = require(LUA_FOLDER .. 'states.'..action[2])
			state:enter(action[3])
			table.insert(self.stack, state)

		else if action[1] == "push" then
			local state = require(LUA_FOLDER .. 'states.'..action[2])
			state:enter(action[3])
			table.insert(StateManager.stack, state)

		else if action[1] == "pop" then
			for i=1, action[2] or 1 do
				table.remove(self.stack):exit()
			end

		else if action[1] == "pop_all" then
			-- pop all states
			
		else if action[1] == "pop_all_but" then
			-- pop all states except the last action[2]
		end end end end end
	end

	self:draw()

	return #self.stack > 0
end

function StateManager:draw()
	for _, state in ipairs(self.stack) do
		state:draw()
	end
end

return StateManager