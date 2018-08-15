local State = State.new()

function State.new()
	local self = setmetatable({}, State)

	return self
end

function State:enter(arguments)
	self.curr_item = 1
	self.items = {"Play", "Options", "Exit", "aaa"}
end

function State:exit() end

function State:update(dt, input)
	if input:state(KEYS["Escape"]) == KEYSTATE.PRESSED then
		return {{"pop", 1}}
	end

	if input:state(KEYS["Return"]) == KEYSTATE.PRESSED then
		if self.curr_item == 1 then
			os.execute("mkdir World")
			os.execute("touch World/yii.lua")
			return {{"switch", "playstate"}}
		else if self.curr_item == 3 then
			return {{"pop", 1}}
		end end
	end

	if input:state(KEYS["Up"]) == KEYSTATE.PRESSED then
		self.curr_item = math.clamp(self.curr_item - 1, 1, #self.items)
	end

	if input:state(KEYS["Down"]) == KEYSTATE.PRESSED then
		self.curr_item = math.clamp(self.curr_item + 1, 1, #self.items)
	end
end

function State:draw()
	draw_text("EverDeeper", .1, .65, .2)
	
	for i, string in ipairs(self.items) do
		draw_text(string, .1, .55-(.1*(i-1)), .1)
	end

	draw_text(">", .05, .55-(.1*(self.curr_item-1)), .1)
end

function State:destroy() end

return State