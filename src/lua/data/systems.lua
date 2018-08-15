local systems = {}
--events:send(em, events, dt, {"command", id})
--em:foreachWith({"held", "item", "position"}, function(id, components) end)

systems.controlPlayer = {
	update = function(em, events, dt, input, map)

		local ret = false

		em:foreachWith({"control"}, function(id, components)

			local control = components.control

			if input:state(KEYS[control.interact]) == KEYSTATE.PRESSED then
				-- interact
				--events:send(em, events, dt, {"interact", id})
				
				local col = em:get(id, "collision")--ecs.components.collision[id]
				local pos = em:get(id, "position")--ecs.components.position[id]

				local changefloor = map:interact({
					x=pos.x+col.offx,
					y=pos.y+col.offy,
					w=col.w, h=col.h,
					rx=pos.x,
					ry=pos.y,
					r=pos.r
				})

				if changefloor then
					ret = changefloor 
				end
			end

			if input:state(KEYS[control.show_inventory]) == KEYSTATE.PRESSED then
				-- open inventory
				println("Show Inventory")
			end

			if input:state(KEYS[control.switch_item_right]) == KEYSTATE.PRESSED then
				-- swap item to the right
			end

			if input:state(KEYS[control.switch_item_left]) == KEYSTATE.PRESSED then
				-- swap item to the left
			end

			--[[
				Movement/State stuff
			]]
			if input:state(KEYS[control.lock_direction]) == KEYSTATE.PRESSED then
				events:send(em, events, dt, {"lock direction", id})
			else if input:state(KEYS[control.lock_direction]) == KEYSTATE.RELEASED then
				events:send(em, events, dt, {"unlock direction", id})
			end end

			local movement = Vec2f.new(0, 0)
			if input:state(KEYS[control.up]) >= KEYSTATE.PRESSED then
				movement.y = movement.y + 1
			end
			if input:state(KEYS[control.down]) >= KEYSTATE.PRESSED then
				movement.y = movement.y - 1
			end
			if input:state(KEYS[control.left]) >= KEYSTATE.PRESSED then
				movement.x = movement.x - 1
			end
			if input:state(KEYS[control.right]) >= KEYSTATE.PRESSED then
				movement.x = movement.x + 1
			end

			if movement.x ~= 0 or movement.y ~= 0 then
				events:send(em, events, dt, {"move", id, movement})
			else
				events:send(em, events, dt, {"stop moving", id})
			end

			if input:state(KEYS[control.attack]) == KEYSTATE.PRESSED then
				events:send(em, events, dt, {"attack", id})
			end

		end)

		return ret
	end
}

systems.controlCamera = {
	update = function(em, events, dt, input, map)

		local interest_distance_max = 6

		em:foreachWith({"camera"}, function(id, components)
			local view = components.camera.view

			local player_pos = em:get(em.player_id, "position")

			local view_pos = {x = player_pos.x, y = player_pos.y}
			local count = 1

			em:foreachWith({"interest", "position"}, function(id, components)
				if id == em.player_id or id == em:get(em.player_id, "hand") then return end

				local position = components.position
				local distance = math.sqrt(math.pow(position.x-player_pos.x, 2) + math.pow(position.y-player_pos.y, 2))
				--local distance = math.abs(position.x-player_pos.x) + math.abs(position.y-player_pos.y)
				-- as distance gets larger, influence should increase to a maximum of 1
				local affector = components.interest * (distance/interest_distance_max) --((15-distance)/15)
				if distance < interest_distance_max then
					view_pos.x = view_pos.x + components.position.x*affector
					view_pos.y = view_pos.y + components.position.y*affector
					count = count + affector
				end
			end)
			
			local start = view:getCenter({}) 
			view:setCenter(
					math.lerp(start[1], view_pos.x*TILESIZE/count),
					math.lerp(start[2], -view_pos.y*TILESIZE/count)
				)
		end)
	end
}

systems.velocity = {
	update = function(em, events, dt, input, map)
		em:foreachWith({"velocity", "position"}, function(id, components)
			local vel = components.velocity
			local pos = components.position

			events:send(em, events, dt, {"move", id, vel})
		end)
	end
}

systems.changePosition = {
	event = {"move", "change position", "set position"},
	receive = function(em, events, dt, message)
		local command = message[1]
		local id = message[2]
		local vec = message[3]

		local position = em:get(id, "position")
		if not position then return end

		if command == "move" then
			local movement = em:get(id, "movement")
			local velocity = em:get(id, "movement")

			local tps = 0

			if not movement and not velocity then 
				return 
			else
				tps = movement.tps or 1
			end

			if position and movement then
				position.x = position.x + vec.x*dt*movement.tps
				position.y = position.y + vec.y*dt*movement.tps
			end
		else if command == "change position" then
			position.x = position.x + vec.x
			position.y = position.y + vec.y
		else if command == "set position" then
			position.x = vec.x
			position.y = vec.y
		end end end
	end
}

systems.lockDirection = {
	event = {"lock direction", "unlock direction"},
	receive = function(em, events, dt, message)
		local command = message[1]
		local id = message[2]

		local anim = em:get(id, "animation")
		
		if anim then
			if command == "lock direction" then
				anim.direction_locked = true
			else if command == "unlock direction" then
				anim.direction_locked = false
			end end
		end
	end
}

systems.interact = {
	event = {"interact"},
	receive = function(em, events, dt, message)
		local command = message[1]
		local id = message[2]

		local pos = em:get(id, "position")
		local col = em:get(id, "collision")

		em:foreachWith({"interact", "collision", "position"}, function(id2, components)
			local int = components.interact
			local pos2 = components.position
			local col2 = components.collision

			local output = {overlap = 0}
			collision_check(
				{x=pos.x+col.offx, y=pos.y+col.offy, w=col.w, h=col.h, rx=pos.x, ry=pos.y, r=pos.r},
				{x=pos2.x+col2.offx, y=pos2.y+col2.offy, w=col2.w, h=col2.h, rx=pos2.x, ry=pos2.y, r=pos2.r},
				output)

			if output.overlap ~= 0 then
				println("Interacted with", id2, int.message)
				events:send(em, events, dt, {int.message})
			end
		end)
	end
}

systems.collision = {
	event = {"item collide", "collide"},
	receive = function(em, events, dt, message)
		local command = message[1]

		if command == "item collide" then
			local eid = message[2]
			local iid = message[3]
			local item = message[4]

			if item.projectile then
				events:send(em, events, dt, {"projectile hit", iid, eid})
				events:send(em, events, dt, {"deal collision damage", eid, iid})
			else
				local held = em:get(iid, "held")
				if not held then
					events:send(em, events, dt, {"pickup item", eid, iid})
				else
					if eid ~= held then
						-- deal damage
						events:send(em, events, dt, {"deal item damage", held, iid, eid})
					end
				end
			end

		else if command == "collide" then
			local id1 = message[2]
			local col1 = message[3]
			local id2 = message[4]
			local col2 = message[5]
			local vec = message[6]

			-- if both match, move both

			if col1.class == col2.class then
				events:send(em, events, dt, {"change position", id1, Vec2f.new(vec.x/2, vec.y/2)})
				events:send(em, events, dt, {"change position", id2, Vec2f.new(-vec.x/2, -vec.y/2)})
			else if col1.class == "pushable" then
				events:send(em, events, dt, {"change position", id1, Vec2f.new(vec.x, vec.y)})
			else if col2.class == "pushable" then
				events:send(em, events, dt, {"change position", id2, Vec2f.new(-vec.x, -vec.y)})
			else if col1.class == "immobile" then
				events:send(em, events, dt, {"change position", id2, Vec2f.new(-vec.x, -vec.y)})
			else if col2.class == "immobile" then
				events:send(em, events, dt, {"change position", id1, Vec2f.new(vec.x, vec.y)})
			end end end end end
		end end
	end,
	update = function(em, events, dt, input, map)
		local qt = false

		if map then
			qt = QuadTree.new(map.x, map.y, map.w, map.h)
		else
			qt = QuadTree.new(0, 0, 50, 50)
		end

		em:foreachWith({"collision", "position"}, function(id, components)
			local pos = components.position
			local col = components.collision
			qt:insert(id, {x=pos.x+col.offx, y=pos.y+col.offy, w=col.w, h=col.h})
		end)

		em:foreachWith({"collision", "position"}, function(id, components)
			local pos = components.position
			local col = components.collision
			if col.class == "ignore" then return end

			local ids = qt:retrieve({x=pos.x+col.offx, y=pos.y+col.offy, w=col.w, h=col.h})

			for _, id2 in ipairs(ids) do
				local pos2 = em:get(id2, "position")
				local col2 = em:get(id2, "collision")

				if id ~= id2 and pos2 and col2 then
					local output = {overlap = 0}
					collision_check(
							{x=pos.x+col.offx, y=pos.y+col.offy, w=col.w, h=col.h, rx=pos.x, ry=pos.y, r=pos.r},
							{x=pos2.x+col2.offx, y=pos2.y+col2.offy, w=col2.w, h=col2.h, rx=pos2.x, ry=pos2.y, r=pos2.r},
							output)

					local overlap = output.overlap

					if overlap ~= 0 then

						local item = em:get(id, "item")
						local item2 = em:get(id2, "item")

						if item and not item2 then
							events:send(em, events, dt, {"item collide", id2, id, item})
						else if item2 and not item then
							events:send(em, events, dt, {"item collide", id, id2, item2})
						else
							if col2.class ~= "ignore" then
								events:send(em, events, dt, {"collide", id, col, id2, col2, Vec2f.new(output.x, output.y)})
								events:send(em, events, dt, {"deal collision damage", id, id2})
							end
						end end
					end
				end
			end
		end)

		if map then
			-- map collision loop
			em:foreachWith({"collision", "position"}, function(id, components)
				local pos = components.position
				local col = components.collision

				if em:get(id, "held") then return end

				local walls, effects = map:collision(
				{
					x = pos.x - col.w/2 + col.offx,
					y = pos.y - col.h/2 + col.offy,
					w = col.w,
					h = col.h
				})

				for _, wall in ipairs(walls) do
					local output = {overlap = 0}

					collision_check(
						{x=pos.x+col.offx, y=pos.y+col.offy, w=col.w, h=col.h, rx=pos.x, ry=pos.y, r=pos.r},
						wall,
						output)

					local overlap = output.overlap

					if overlap ~= 0 then
						events:send(em, events, dt, {"change position", id, Vec2f.new(output.x, output.y)})
						em:deleteComponent(id, "velocity")
					end
				end
			end)
			qt = QuadTree.new(map.x, map.y, map.w, map.h)
		end

		--[[
		em:foreachWith({"collision", "position"}, function(id, components)
			local pos = components.position
			local col = components.collision
			local ids = qt:retrieve({x=pos.x+col.offx, y=pos.y+col.offy, w=col.w, h=col.h})

			if em:get(id, "item") or em:get(id, "interact") then
				return
			end

			for _, id2 in ipairs(ids) do

				local pos2 = em:get(id2, "position")
				local col2 = em:get(id2, "collision")

				if id ~= id2 and pos2 and col2 and not em:get(id2, "interact") then

					local output = {overlap = 0}
					collision_check(
							{x=pos.x+col.offx, y=pos.y+col.offy, w=col.w, h=col.h, rx=pos.x, ry=pos.y, r=pos.r},
							{x=pos2.x+col2.offx, y=pos2.y+col2.offy, w=col2.w, h=col2.h, rx=pos2.x, ry=pos2.y, r=pos2.r},
							output)

					local overlap = output.overlap

					if overlap ~= 0 then
						local item = em:get(id2, "item")

						if item then
							if item.projectile then
								events:send(em, events, dt, {"projectile hit", id2, id})
								events:send(em, events, dt, {"deal collision damage", id, id2})
							else
								local held = em:get(id2, "held")
								if not held then
									events:send(em, events, dt, {"pickup item", id, id2})
								else
									if id ~= held then
										-- deal damage
										events:send(em, events, dt, {"deal item damage", held, id2, id})
									end
								end
							end
						else
							-- do collision things
							events:send(em, events, dt, {"collide", id, id2, Vec2f.new(output.x, output.y)})
							events:send(em, events, dt, {"deal collision damage", id, id2})
						end
					end
				end
			end
		end)
		]]

		qt:clear()
	end
}

systems.damage = {
	event = {"deal item damage", "deal collision damage"},
	receive = function(em, events, dt, message)
		local command = message[1]

		if command == "deal item damage" then
			local id = message[2]
			local item_id = message[3]
			local hit_id = message[4]

			-- println("Item Damage")
			-- get scaling etc from entity and held item etc
			-- get resistances
			-- apply damage

		else if command == "deal collision damage" then
			local id = message[2]
			local id2 = message[3]

			-- println("Collision Damage")

			-- get hitboxes
			-- apply hitboxes together
			-- get resistances
			-- apply damage

		end end
	end
}

systems.heldItems = {
	event = {"pickup item", "drop item"},
	receive = function(em, events, dt, message)
		local command = message[1]
		local id = message[2]		-- entity
		local id2 = message[3]		-- item

		if command == "pickup item" then
			if not em:get(id, "hand") then

				-- mark as held
				em:set(id2, "held", id)
				em:set(id2, "p_collision", em:get(id2, "collision"))
				em:set(id2, "p_hitbox", em:get(id2, "hitbox"))
				em:deleteComponent(id2, "collision")

				em:set(id, "hand", id2)
			end
		else if command == "drop item" then
			-- restore collision component
			em:set(id2, "collision", em:get(id2, "p_collision"))
			em:set(id2, "hitbox", em:get(id2, "p_hitbox"))

			em:get(id2, "position").z = nil

			-- remove references to each other
			em:deleteComponent(id2, "held")
			if em:get(id, "hand") == id2 then
				em:deleteComponent(id, "hand")
			end

		end end
	end,
	update = function(em, events, dt, input, map)
		em:foreachWith({"held", "item", "position"}, function(id, components)
			local eid = components.held
			local epos = em:get(eid, "position")
			local eanim = em:get(eid, "animation")

			local ipos = components.position
			local holdable = components.item.holdable

			local zoff = 0

			local framex = eanim.action.frames[eanim.frame_index]
			local framey = 0

			if eanim.direction == "right" then
				ipos.r = 0
				zoff = - 0.001
				framey = 3

			else if eanim.direction == "left" then
				ipos.r = 180
				zoff = 0.001
				framey = 4

			else if eanim.direction == "up" then
				ipos.r = 90
				zoff = 0.001
				framey = 2

			else if eanim.direction == "down" then
				ipos.r = 270
				zoff = -0.001
				framey = 1

			end end end end

			-- change rotation based on actions current frame
			ipos.r = ipos.r + eanim.action.angles[eanim.frame_index]


			local offx, offy = holdable.offx, holdable.offy
			local r = ipos.r

			local rot_offx = (offx * cos(r) - offy * sin(r))
			local rot_offy = (offx * sin(r) + offy * cos(r))

			local hand_off_x = hand_positions["man"][framey][framex][1]
			local hand_off_y = hand_positions["man"][framey][framex][2]

			-- set the position
			events:send(em, events, dt, {"set position", id, 
				{
					x = epos.x + hand_off_x - rot_offx,
					y = epos.y + hand_off_y - rot_offy
				}})

			ipos.z = epos.y-(epos.h/2)+zoff

			-- put on the collision box
			if eanim.action.hitbox_frames[eanim.frame_index] then
				em:set(id, "collision", holdable.collision)
				em:set(id, "hitbox", holdable.actions[eanim.action_name].hitbox)
			else
				em:deleteComponent(id, "collision")
				em:deleteComponent(id, "hitbox")
			end

			-- spawn things

		end)
	end
}

local directions = {
	up = {y = 1},
	down = {y = -1},
	left = {x = -1},
	right = {x = 1}
}

systems.changeAnimation = {
	event = {"move", "stop moving", "attack"},
	receive = function(em, events, dt, message)
		local command = message[1]
		local id = message[2]

		local anim = em:get(id, "animation")
		if not anim then return end

		if command == "attack" then

			local hand = em:get(id, "hand")


			if anim.action.interruptable then

				-- start attack

				-- if item has an initial attack state queue that
				-- otherwise queue the attack state

				anim.action = anim.animations.attack
				anim.action_name = "attack"
				anim.frame_index = 1
				anim.time = 0
				events:send(em, events, dt, {"change frame", id, anim.action.frames[1]})

			else
				-- queue attack combolocal hand  = em:get(id, "hand")
				if hand then 
					local item = em:get(hand, "item")

					if item 
						and item.holdable 
						and item.holdable.actions[anim.action_name] then

						anim.next_action = item.holdable.actions[anim.action_name].combo["attack"]
					end
				end
			end
		else if command == "move" then
			local vec = message[3]
			-- don't walk if velocity is sliding the player
			if vec == em:get(id, "velocity") then return end

			if not anim.direction_locked then
				local past_dir = directions[anim.direction]

				if past_dir.x ~= vec.x and past_dir.y ~= vec.y then
					-- change direction
					for direction, past_vec in pairs(directions) do
						if past_vec.x == vec.x or past_vec.y == vec.y then
							anim.direction = direction
							events:send(em, events, dt, {"change direction", id, direction})
							break
						end
					end
				end
			end
			if not anim.action or anim.action == anim.animations.idle then
				--println("Start walking")
				anim.action = anim.animations.walk
				anim.time = 0
			end
		else if command == "stop moving" then
			if anim.action == anim.animations.walk then
				--println("Stop Walking")
				anim.action = anim.animations.idle
				anim.frame_index = 1
				anim.time = 0
				events:send(em, events, dt, {"change frame", id, anim.action.frames[1]})
			end
		end end end
	end,
	update = function(em, events, dt, input)
		em:foreachWith({"animation"}, function(id, components)
			local anim = components.animation
			if not anim.action then
				anim.action = anim.animations.idle
				anim.action_name = "idle"
				anim.frame_index = 1
				anim.time = 0
			end

			local duration = anim.action.base_duration

			local hand  = em:get(id, "hand")
			if hand then
				local item = em:get(hand, "item")
				if item and item.holdable then
					if item.holdable.actions[anim.action_name] then
						duration = item.holdable.actions[anim.action_name].duration
					end
				end
			end

			local past_frame = math.ceil(anim.time / duration * #anim.action.frames)

			anim.time = anim.time + dt

			local frame = math.ceil(anim.time / duration * #anim.action.frames)

			-- if animation is finished
			if anim.time >= duration then

				if anim.next_action then
					anim.action = anim.animations[anim.next_action]
					anim.action_name = anim.next_action
					anim.next_action = nil
				else
					anim.action = anim.animations.idle
					anim.action_name = "idle"
				end

				anim.time = 0
				frame = 1
				past_frame = 0 -- ensure frame != past frame
			end

			if frame ~= past_frame and frame ~= 0 then
				anim.frame_index = frame
				events:send(em, events, dt, {"change frame", id, anim.action.frames[frame]})
			end
		end)
	end
}

local directions_to_framey = {
	down = 1,
	up = 2,
	right = 3,
	left = 4,
}

systems.updateSprite = {
	event = {"change frame", "change direction"},
	receive = function(em, events, dt, message)
		local command = message[1]
		local id = message[2]

		local sprite = em:get(id, "sprite")

		if command == "change frame" then
			local framex = message[3]

			sprite.framex = framex

		else if command == "change direction" then
			local direction =  message[3]

			sprite.framey = directions_to_framey[direction]
		end end
	end
}

systems.basicDraw = {
	draw = function(em)
		local z = 0
		local drawItems = {}
		em:foreachWith({"position", "sprite"}, function(id, components)
			local position = components.position
			local sprite = components.sprite

			if not sprite.sprite then
				sprite.sprite = Sprite.new()
				sprite.sprite:init(sprite.img..".png", sprite.framesx, sprite.framesy, true)
			end

			sprite.sprite:setFrame(sprite.framex-1, sprite.framey-1)
			sprite.sprite:setPosition(position.x*TILESIZE, -position.y*TILESIZE)
			sprite.sprite:setRotation(-(position.r or 0))

			if em:get(id, "highlight") then
				sprite.sprite:setColor(100, 255, 100, 255)
			else
				sprite.sprite:setColor(255, 255, 255, 255)
			end

			z = position.z or position.y-position.h/2

			table.insert(drawItems, {z, sprite.sprite, id})
		end)

		local sortfunc = function (a, b) return a[1] > b[1] end

		table.sort(drawItems, sortfunc)

		for _, sprite in ipairs(drawItems) do
			draw(sprite[2])
		end
	end
}

return systems