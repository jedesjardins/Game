local State = State.new()

function State.new()
	local self = setmetatable({}, State)

	return self
end

function State:enter(arguments)
	self.curr_item = 1
	self.items = {"Play", "Options", "Exit", "aaa"}

	self.view = View.new()
	self.view:setSize(TILESIZE*32,TILESIZE*24)
	self.view:setCenter(TILESIZE*16,TILESIZE*12)

	self.text = UI_Text.new("Hello", 100)
	self.text:setPosition(TILESIZE*16,TILESIZE*12)
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
	end

	if input:state(KEYS["Down"]) == KEYSTATE.PRESSED then
		self.curr_item = math.clamp(self.curr_item + 1, 1, #self.items)
	end
end

function State:draw()
	self.view:makeTarget()
	--[[
	draw_text("EverDeeper", .1, .65, .2)
	
	for i, string in ipairs(self.items) do
		draw_text(string, .1, .55-(.1*(i-1)), .1)
	end

	draw_text(">", .05, .55-(.1*(self.curr_item-1)), .1)
	]]
	--draw_Mytext("Testg", 0, 0, .2)
	self.text:draw()
end

function State:destroy() end

return State