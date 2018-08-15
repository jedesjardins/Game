local state = State.new()

local systems = require(LUA_FOLDER .. 'data.systems')

function state:enter(blackboard)
	self.blackboard = blackboard
	self.ecs = blackboard.ecs
	self.map = blackboard.map

	self.black_tex = RenderTexture.new(self.map.w*TILESIZE, self.map.h*TILESIZE)
	self.black_tex:init(255)

	self.black_sprite = Sprite.new()
	self.black_sprite:initFromTarget(self.black_tex)

	local centerxpix = (math.ceil(self.map.w/2) - 1)*TILESIZE + TILESIZE/2
	local centerypix = (self.map.h - math.ceil(self.map.h/2))*TILESIZE + TILESIZE/2

	self.black_sprite:setOrigin(centerxpix, centerypix)
	self.black_sprite:setPosition(self.map.x, self.map.y)
end

function state:update(dt, input)

	local ecs = self.ecs
	local em = ecs.em
	local player_id = em.player_id
	local camera_id = em.camera_id
	local map = self.map

	--TODO Remove this
	map:setFloor(map:getFloor()+self.blackboard.dz)

	local hand = em:get(player_id, "hand")
	local player = em:deleteEntity(player_id)
	local camera = em:deleteEntity(camera_id)
	local item = false
	if hand then
		item = em:deleteEntity(hand)
	end

	ecs.em = map.floors[map:getFloor()].em
	em = ecs.em
	em.player_id = em:addEntity(player)
	em.camera_id = em:addEntity(camera)

	if item then
		hand = em:addEntity(item)
		em:addComponent(em.player_id, "hand", hand)
		em:addComponent(hand, "held", em.player_id)
	end

	--[[
	local pos = em:get(em.player_id, "position")
	pos.x = self.blackboard.tilex
	pos.y = self.blackboard.tiley
	map.view:setCenter(pos.x*TILESIZE, -pos.y*TILESIZE)
	map:draw()


	-- remove player related entities
	local hand = em:get(em.player_id, "hand")
	local player = em:deleteEntity(em.player_id)

	local item = false
	if hand then
		item = em:deleteEntity(hand)
	end

	-- swap all other entities with new floor
	map.objects[map.last_floor] = em:clearEntities()
	em:addEntities(map.objects[map.floor])

	-- add back in player related entities
	em.player_id = em:addEntity(player)
	if item then
		--self.ecs.components.hand[self.ecs.player_id].item = self.ecs:addEntity(item)
		hand = em:addEntity(item)
		em:addComponent(em.player_id, "hand", hand)
		em:addComponent(hand, "held", em.player_id)
	end

	--systems.updateMapCollision(self.ecs)
	--systems.updateHeldItem(self.ecs, 0)

	--TODO: Figure out inventory
	]]

	return {{'switch', 'fadebackfrommapswitch', self.blackboard}}
end

function state:draw()
	draw(self.black_sprite)
end

return state