local State = State.new()

function State.new()
	local self = setmetatable({}, State)

	return self
end

function State:enter(arguments)
	self.view = View.new()

	self.screen_size = Vec2f.new(WINDOW_STATE.screen_dimensions.x, WINDOW_STATE.screen_dimensions.y)

	self.view:setSize(self.screen_size)
	self.view:setCenter(self.screen_size.x/2, self.screen_size.y/2)

	self.curr_item = 1
	self.title = UI_Text.new("EverDeeper", Font, math.tointeger(self.screen_size.y*.2))
	self.pointer = UI_Text.new(">", Font, math.tointeger(self.screen_size.y*.1))
	self.items = {
		UI_Text.new("Play", Font, math.tointeger(self.screen_size.y*.1)),
		UI_Text.new("Options", Font, math.tointeger(self.screen_size.y*.1)),
		UI_Text.new("Exit", Font, math.tointeger(self.screen_size.y*.1))
	}

	self.title:setPosition(self.screen_size.x*.1, self.screen_size.y-self.screen_size.y*.65)
	for i, string in ipairs(self.items) do
		string:setPosition(self.screen_size.x*.1, self.screen_size.y-self.screen_size.y*(.55-(.1*(i-1))))
	end
	self.pointer:setPosition(self.screen_size.x*.05, self.screen_size.y-self.screen_size.y*(.55-(.1*(self.curr_item-1))))
end

function State:exit() end

function State:update(dt, input)
	if input:state(KEYS["Escape"]) == KEYSTATE.PRESSED then
		return {{"pop", 1}}
	end

	if input:state(KEYS["Return"]) == KEYSTATE.PRESSED then
		if self.curr_item == 1 then
			return {{"switch", "playstate"}}
		else if self.curr_item == 3 then
			return {{"pop", 1}}
		end end
	end

	if input:state(KEYS["Up"]) == KEYSTATE.PRESSED then
		self.curr_item = math.clamp(self.curr_item - 1, 1, #self.items)
		self.pointer:setPosition(self.screen_size.x*.05, self.screen_size.y-self.screen_size.y*(.55-(.1*(self.curr_item-1))))
	end

	if input:state(KEYS["Down"]) == KEYSTATE.PRESSED then
		self.curr_item = math.clamp(self.curr_item + 1, 1, #self.items)
		self.pointer:setPosition(self.screen_size.x*.05, self.screen_size.y-self.screen_size.y*(.55-(.1*(self.curr_item-1))))
	end
end

function State:draw()
	Window:setView(self.view)
	--self.view:makeTarget()

	Window:draw(self.title)
	for i, string in ipairs(self.items) do
		Window:draw(string)
	end
	Window:draw(self.pointer)
end

function State:destroy() end

return State