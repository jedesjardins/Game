local Map = require(LUA_FOLDER .. 'engine.new_map')

local state = State.new()

function state:enter()

	self.floor = Floor.new(0, 0, 10, 10, "grassy_cave", 0)

	self.view = View.new()
	self.view:setCenter(0, 0);
	self.view:setSize(TILESIZE*16,TILESIZE*12)
end

function state:update(dt, input)
	if input:state(KEYS["Escape"]) == KEYSTATE.PRESSED then
		return {{"pop", 1}}
	end

	if input:mouseLeft() == KEYSTATE.PRESSED then
		local vp = input:mouseViewPosition(self.view)
		local tile = {math.round(vp.x/TILESIZE), math.round(-vp.y/TILESIZE)}
	end
end

function state:draw()
	self.view:makeTarget()
	draw(self.floor.sprite)
end

function state:exit()
	--self.map:delete()
end

return state