local state = State.new()

local entities = require(LUA_FOLDER .. 'data.entities')
local systems = require(LUA_FOLDER .. 'data.systems')

local Map = require(LUA_FOLDER .. 'engine.map')

function state:enter()

	self.ecs = ECS:new()
	self.ecs:addPresets(entities)

	self.ecs:addBeginSystem(systems.controlPlayer)	-- update
	self.ecs:addSystem(systems.updatePosition)		-- event
	-- add system.updateQuadTree to re bin the quad tree -- event
	self.ecs:addSystem(systems.updateLock)			-- event
	self.ecs:addSystem(systems.updateState)			-- update?
	self.ecs:addSystem(systems.updateHeldItem)		-- event
	self.ecs:addSystem(systems.updateCollision)		-- event, something moved?
	self.ecs:addSystem(systems.updateMapCollision)	-- event
	self.ecs:addSystem(systems.updateEffects)		-- update
	self.ecs:addSystem(systems.ignore)				-- who cares
	self.ecs:addSystem(systems.updateAnimation)		-- update
	self.ecs:addEndSystem(systems.lifetime)			-- update
	self.ecs:addDrawSystem(systems.draw)			-- update

	self.map = Map.new(0, 0, 80, 60)

	self.map.view = View.new()
	self.map.view:setCenter(0, 0);
	self.map.view:setSize(TILESIZE*40,TILESIZE*30)

	self.map.ecs = self.ecs
	self.ecs.map = self.map

	self.ecs.player_id = self.ecs:addEntity("man", {self.map.entrance[1], self.map.entrance[2]})
	local id2 = self.ecs:addEntity("sword", {self.map.entrance[1]-1, self.map.entrance[2]})
	local id3 = self.ecs:addEntity("sword", {self.map.entrance[1], self.map.entrance[2]-1})

	--[[
	local id2 = self.ecs:addEntity("block", {-4, 0})
	local id3 = self.ecs:addEntity("sword", {2, -1})

	local id4 = self.ecs:addEntity("man", {-2, 0})
	self.ecs.components.control[id4] = nil
	]]
end

function state:update(dt, input)
	if input:state(KEYS["Escape"]) == KEYSTATE.PRESSED then
		return {{"pop", 1}}
	end

	if input:state(KEYS["I"]) == KEYSTATE.PRESSED then
		self.map:init()
	end

	if input:state(KEYS["R"]) == KEYSTATE.PRESSED then
		--self.map:runStep()
	end

	if input:state(KEYS["F"]) == KEYSTATE.PRESSED then
		self.map:swapFloor()
	end

	local ret = self.ecs:update(dt, input)
	if ret then
		return ret
	end
	self.map:update()
end

function state:draw()
	self.map.view:makeTarget()
	draw(self.map.map_sprite)
	self.ecs:draw()
	draw_text("HP: 250", 0, 0, 1, .1)
end

function state:exit()
	self.map:delete()
end

return state
