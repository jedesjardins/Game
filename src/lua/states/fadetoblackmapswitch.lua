local state = State.new()

function state:enter(blackboard)
	
	self.blackboard = blackboard
	self.ecs = blackboard.ecs
	self.map = blackboard.map
	self.timetoblack = 0.15
	self.timeelapsed = 0

	local view = self.ecs.em:getComponent(self.ecs.em.camera_id, "camera").view

	local vx, vy = table.unpack(view:getSize({}))
	self.fade_tex = RenderTexture.new(math.floor(vx), math.floor(vy))
	self.fade_tex:init(0)

	self.fade_sprite = Sprite.new()
	self.fade_sprite:initFromTarget(self.fade_tex)
	self.fade_sprite:setOrigin(math.floor(vx/2), math.floor(vy/2))
	self.fade_sprite:setPosition(table.unpack(view:getCenter({})))
end

function state:update(dt, input)
	self.timeelapsed = self.timeelapsed + dt
	local alpha = (self.timeelapsed/self.timetoblack)*255

	self.fade_tex:init(math.floor(math.clamp(alpha, 0, 255)))
	self.fade_sprite:initFromTarget(self.fade_tex)

	if alpha > 255 then return {{'switch',
								'switchfloors', 
								self.blackboard}} end

end

function state:draw()
	draw(self.fade_sprite)
end

return state