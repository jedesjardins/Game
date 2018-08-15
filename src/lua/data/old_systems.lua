local systems = {}

local function switch_in(ecs, inventory, index)
	local id = inventory.items[index]

	ecs.components.position[id] = ecs.components.p_position[id]
	ecs.components.h_hitbox[id] = ecs.components.hitbox[id]

	if ecs.components.holdable[id] then
		ecs.components.hitbox[id] = ecs.components.holdable[id].hitbox
	end
end

local function switch_out(ecs, inventory)
	local id = inventory.items[inventory.curr_index]
	ecs.components.p_position[id] = ecs.components.position[id]
	ecs.components.position[id] = nil
	ecs.components.hitbox[id] = ecs.components.h_hitbox[id]
end

function systems.controlPlayer(ecs, dt, input)
	local entities = ecs:requireAll("control")

	for _, id in ipairs(entities) do
		local control = ecs.components.control[id]
		local movement = ecs.components.movement[id]
		local state = ecs.components.state[id]
		local inventory = ecs.components.inventory[id]

		--[[
			INTERACTION
		]]
		if input:state(KEYS[control.interact]) == KEYSTATE.PRESSED then
			-- how do

			local col = ecs.components.collision[id]
			local pos = ecs.components.position[id]

			local changefloor = ecs.map:interact({
				x=pos.x+col.offx,
				y=pos.y+col.offy,
				w=col.w, h=col.h,
				rx=pos.x,
				ry=pos.y,
				r=pos.r
			})

			if changefloor then
				return changefloor 
			end
		end

		--[[
			ITEM STUFF
		]]
		-- show inventory
		if input:state(KEYS[control.inventory]) == KEYSTATE.PRESSED then
			print("Show inventory")
			print("\tsize: ", #inventory.items)
			print("\tcurr index", inventory.curr_index, inventory.items[inventory.curr_index])
		end
 
		--switch items
		if input:state(KEYS["Q"]) == KEYSTATE.PRESSED then
			if #inventory.items > 1 then
				local current_index = inventory.curr_index

				switch_out(ecs, inventory)

				local next_index = (current_index - 1 >= 1 and current_index - 1) or #inventory.items

				--print(current_index, next_index)

				switch_in(ecs, inventory, next_index)

				inventory.curr_index = next_index

				ecs.components.hand[id].item = inventory.items[inventory.curr_index]
			end
		end
		if input:state(KEYS["E"]) == KEYSTATE.PRESSED then
			if #inventory.items > 1 then
				local current_index = inventory.curr_index

				switch_out(ecs, inventory)

				local next_index = (current_index + 1 <= #inventory.items and current_index + 1) or 1

				--print(current_index, next_index)

				switch_in(ecs, inventory, next_index)

				inventory.curr_index = next_index

				ecs.components.hand[id].item = inventory.items[inventory.curr_index]
			end
		end

		--[[
			Toss Item
		]]
		if input:state(KEYS[control.drop_item]) == KEYSTATE.PRESSED then
			local item_id = ecs.components.hand[id].item

			if item_id then

				-- Handle inventory
				if #inventory.items > 1 then
					for index=1, #inventory.items do
						if index == inventory.curr_index then 
							inventory.items[index] = nil
						end

						if not inventory.items[index] then
							inventory.items[index] = inventory.items[index+1]
							inventory.items[index+1] = nil
						end
					end

					if not inventory.items[inventory.curr_index] then
						inventory.curr_index = inventory.curr_index - 1
					end

					ecs.components.hand[id].item = inventory.items[inventory.curr_index]

					switch_in(ecs, inventory, inventory.curr_index)
				else
					-- delete from hand and inventory
					ecs.components.hand[id].item = nil
					inventory.items[inventory.curr_index] = nil
				end

				ecs.components.collision[item_id] = ecs.components.p_collision[item_id]	-- restore collision
				ecs.components.hitbox[item_id] = ecs.components.h_hitbox[item_id]
				ecs.components.held[item_id] = nil

				item_position = ecs.components.position[item_id]

				local x, y = 0, 0

				--TODO: Fix distances that items are thrown from
				if state.direction == "down" then
					y = -6
					item_position.y = item_position.y - 1
				else if state.direction == "up" then
					y = 6
					item_position.y = item_position.y + 1
				else if state.direction == "right" then
					x = 6
					item_position.x = item_position.x + 1
				else if state.direction == "left" then
					x = -6
					item_position.x = item_position.x - 1
				end end end end

				ecs.components.movement[item_id] = {
														dx = 0, dy = 0,	-- instantaneous movement controls in tiles/second
														mx = x, my = y,	-- momentum in tiles/second
														is_moving = false
													}
			end
		end

		--[[
			Movement
		]]
		local new_directions = {}
		local was_moving = movement.dx ~= 0 or movement.dy ~= 0
		local is_moving = false
		local direction_changed = true

		movement.dx, movement.dy = 0, 0

		if input:state(KEYS[control.up]) >= KEYSTATE.PRESSED then
			movement.dy = movement.dy + movement.tps*dt/1000
			is_moving = true
			table.insert(new_directions, "up")

			if state.direction == "up" then
				direction_changed = false
			end
		end
		if input:state(KEYS[control.down]) >= KEYSTATE.PRESSED then
			movement.dy = movement.dy - movement.tps*dt/1000
			is_moving = true
			table.insert(new_directions, "down")

			if state.direction == "down" then
				direction_changed = false
			end
		end
		if input:state(KEYS[control.left]) >= KEYSTATE.PRESSED then
			movement.dx = movement.dx - movement.tps*dt/1000
			is_moving = true
			table.insert(new_directions, "left")

			if state.direction == "left" then
				direction_changed = false
			end
		end
		if input:state(KEYS[control.right]) >= KEYSTATE.PRESSED then
			movement.dx = movement.dx + movement.tps*dt/1000

			is_moving = true
			table.insert(new_directions, "right")

			if state.direction == "right" then
				direction_changed = false
			end
		end
		if input:state(KEYS[control.lock_direction]) >= KEYSTATE.PRESSED then
			table.insert(new_directions, state.direction)

			direction_changed = false
		end

		--[[
			State stuff
		]]

		if direction_changed and #new_directions > 0 then
			state.direction = new_directions[1]
		end

		state.action_queue = {}
		if is_moving then
			movement.is_moving = true
			table.insert(state.action_queue, "walk")
		else
			movement.is_moving = false
			table.insert(state.action_queue, "stand")
		end

		if input:state(KEYS[control.attack]) == KEYSTATE.PRESSED then
			table.insert(state.action_queue, "attack")
		end
	end
end

function systems.updatePosition(ecs, dt, input)
	local entities = ecs:requireAll("movement", "position")

	local friction = 20

	for _, id in ipairs(entities) do
		local pos = ecs.components.position[id]
		local movement = ecs.components.movement[id]
		pos.x = pos.x + movement.dx + movement.mx*dt/1000
		pos.y = pos.y + movement.dy + movement.my*dt/1000
		pos.z = pos.y - pos.h/2

		local nx = math.abs(movement.mx)-(friction*dt/1000)
		local ny = math.abs(movement.my)-(friction*dt/1000)

		movement.mx = nx > 0 and nx*math.sign(movement.mx) or 0
		movement.my = ny > 0 and ny*math.sign(movement.my) or 0

		if movement.dx ~= 0 or movement.dy ~= 0 or movement.mx ~= 0 or movement.my ~= 0 then 
			movement.is_moving = true
		else
			movement.is_moving = false
		end
		
	end	
end

function systems.updateLock(ecs, dt, input)
	local entities = ecs:requireAll("lock", "position")

	for _, id in ipairs(entities) do
		local lock = ecs.components.lock[id]
		local position = ecs.components.position[id]

		local target = ecs.components.position[lock.id]

		position.x = target.x + lock.offx
		position.y = target.y + lock.offy
	end
end

function systems.updateState(ecs, dt, input)
	local entities = ecs:requireAll("state")

	for _, id in ipairs(entities) do
		local state = ecs.components.state[id]

		-- set the starting state
		if not state.action then
			state.action_name = "stand"
			state.action = state.actions[state.action_name]
			state.action.duration = (hold and hold.actions[state.action_name] and hold.actions[state.action_name].duration) 
						or state.actions[state.action_name].base_duration
		end

		state.start = false

		
		-- held item action info
		local hold = ecs.components.hand[id] 
					and ecs.components.hand[id].item
					and ecs.components.holdable[ecs.components.hand[id].item]

		state.time = state.time + dt/1000
		-- end action, start next
		if state.time > state.action.duration then
			state.action_name = state.action.next_action or state.action.stop
			state.action.next_action = nil
			state.action = state.actions[state.action_name]
			state.action.duration = (hold and hold.actions[state.action_name] and hold.actions[state.action_name].duration) 
						or state.actions[state.action_name].base_duration

			state.start = true
			state.has_shot = false
			-- reset hitbox
			if hold then
				ecs.components.hitbox[ecs.components.hand[id].item].hit_ids = {}
			end

			state.time = 0
		end

		--set new actions
		for _, action_name in ipairs(state.action_queue) do
			if hold 
			   and hold.actions[state.action_name] 
			   and hold.actions[state.action_name].combos[action_name] then

				state.action.next_action = hold.actions[state.action_name].combos[action_name]
											   or state.action.next_action
											   or action_name

			-- no held item, combos
			else if state.action.combos then
				state.action.next_action = state.action.combos[action_name] or state.action.next_action
			end end

			if state.action.interruptable and state.action_name ~= action_name then
				state.action_name = action_name
				state.action = state.actions[action_name]
				state.start = true
				state.has_shot = false
				state.action.duration = (hold and hold.actions[state.action_name] and hold.actions[state.action_name].duration) 
						or state.actions[state.action_name].base_duration

				-- reset hitbox
				if hold then
					ecs.components.hitbox[ecs.components.hand[id].item].hit_ids = {}
				end
				state.time = 0
			end
		end
	end
end

function systems.updateHeldItem(ecs, dt, input)
	local entities = ecs:requireAll("hand", "position", "state")

	for _, id in ipairs(entities) do
		hand = ecs.components.hand[id]
		if hand.item then
			local position = ecs.components.position[id]
			local state = ecs.components.state[id]
			local item_position = ecs.components.position[hand.item]
			local item_holdable = ecs.components.holdable[hand.item]

			local framey = false

			if not item_holdable then item_holdable = {offx = 0, offy = 0, actions = {}} end

			local dx, dy, dr = 0, 0

			if state.direction == "down" then
				framey = 1
				item_position.r = 270
				item_position.z = position.z + 1/16

				dy = -10*dt/1000
				dr = 270
			else if state.direction == "up" then
				framey = 2
				item_position.r = 90
				item_position.z = position.z - 1/16

				dy = 10*dt/1000
				dr = 90
			else if state.direction == "right" then
				framey = 3
				item_position.r = 0
				item_position.z = position.z - 1/16

				dx = 10*dt/1000
				dr = 0
			else if state.direction == "left" then
				framey = 4
				item_position.r = 180
				item_position.z = position.z + 1/16

				dx = -10*dt/1000
				dr = 180
			end end end end

			-- rotate item
			local duration = state.action.duration
			local percent = (state.time%duration)/duration
			local frameindex = math.floor(percent * #state.action.frames) + 1

			item_position.r = item_position.r + state.action.angles[frameindex]

			-- rotate around hold point
			local offx, offy = item_holdable.offx, item_holdable.offy
			local r = item_position.r

			local rot_offx = (offx * cos(r) - offy * sin(r))
			local rot_offy = (offx * sin(r) + offy * cos(r))


			local framex = state.action.frames[frameindex]

			local hand_off_x = hand_positions["man"][framey][framex][1]
			local hand_off_y = hand_positions["man"][framey][framex][2]

			item_position.x = position.x + hand_off_x - rot_offx
			item_position.y = position.y + hand_off_y - rot_offy

			if state.action.hitboxs[frameindex] and item_holdable then
				ecs.components.collision[hand.item] = item_holdable.collision
			else
				ecs.components.collision[hand.item] = nil
			end

			if frameindex == state.action.spawn_frame and not state.has_shot
				and item_holdable
				and item_holdable.actions[state.action_name] 
				and item_holdable.actions[state.action_name].spawn then

				state.has_shot = true

				local p_id = ecs:addEntity(item_holdable.actions[state.action_name].spawn, 
					{item_position.x, item_position.y, dr, dx, dy})

				local ignore = {
					ids = {},
					time = .5
				}

				ignore.ids[id] = true

				if ecs.components.hitbox[p_id] then ecs.components.hitbox[p_id].hit_ids[id] = true end

				ecs.components.ignore[p_id] = ignore
			end
		end
	end
end

function systems.updateCollision(ecs, dt, input)
	local entities = ecs:requireAll("position", "collision")

	for _, id in ipairs(entities) do

		local pos = ecs.components.position[id]
		local col = ecs.components.collision[id]
		local mov = ecs.components.movement[id]
		local item = ecs.components.item[id]
		local hand = ecs.components.hand[id]
		local inventory = ecs.components.inventory[id]
		
		if not item and col ~= nil then

			for _, id2 in ipairs(entities) do
			--for j = i + 1, #entities do
				--local id2 = entities[j]

				if id ~= id2 and ecs.components.held[id2] ~= id then
					local pos2 = ecs.components.position[id2]
					local col2 = ecs.components.collision[id2]
					local mov2 = ecs.components.movement[id2]
					local item2 = ecs.components.item[id2]

					if pos2 and col2 then
						--local does_collide, correction_vect = collision.collide(p1, p2)
						local output = {}
						collision_check(
								{x=pos.x+col.offx, y=pos.y+col.offy, w=col.w, h=col.h, rx=pos.x, ry=pos.y, r=pos.r},
								{x=pos2.x+col2.offx, y=pos2.y+col2.offy, w=col2.w, h=col2.h, rx=pos2.x, ry=pos2.y, r=pos2.r},
								output)

						local overlap = output.overlap
						local correction_vect = {x = output.x, y = output.y}
							

						if overlap and overlap ~= 0 then

							-- pickup item or resolve 
							if item2 then
								-- handle projectile

								if not(ecs.components.ignore[id2]
								   and ecs.components.ignore[id2].ids[id]) then

									-- handle projectile
									if ecs.components.projectile[id2] then

										local projectile = ecs.components.projectile[id2]

										-- stop it's motion 
										if mov2 then
											mov2.dx = 0
											mov2.dy = 0
											mov2.mx = 0
											mov2.my = 0
										end

										-- delete it
										if projectile.delete_on_collision then
											ecs.components.lifetime[id2] = .05
											ecs.components.collision[id2] = nil

										else
											-- lock it to the thing it hit
											if projectile.lock_on_collision then
												-- lockon code
												--ecs.components.collision[id2] = nil
												ecs.components.lock[id2] = {
													id = id, offx = pos2.x - pos.x, offy = pos2.y - pos.y
												}
											end

											-- it can be picked up, after a bit of time, or delete it
											if projectile.can_pickup then
												ecs.components.projectile[id2] = nil
												local ignore = {
													ids = {},
													time = .5
												}
												ignore.ids[id] = true

												ecs.components.ignore[id2] = ignore
											else
												ecs.components.collision[id2] = nil
												ecs.components.lifetime[id2] = 2
											end

											
										end
									-- try to pickup item
									else
										-- put in inventory
										if inventory and #inventory.items < inventory.max_items
											and not ecs.components.held[id2] then

											table.insert(inventory.items, id2)		-- put in inventory
											ecs.components.held[id2] = id			-- mark as held
											ecs.components.p_collision[id2] = col2	-- save collision box
											ecs.components.collision[id2] = nil		-- delete current collision box

											-- put in hand
											if hand and not hand.item then
												hand.item = id2 -- put in hand
												-- use special in hand hitbox
												if ecs.components.holdable[id2] then
													ecs.components.h_hitbox[id2] = ecs.components.hitbox[id2]
													ecs.components.hitbox[id2] = ecs.components.holdable[id2].hitbox
												end
											else
												-- if you don't put it in your hand, 
												-- remove the position component so it doesn't interact
												ecs.components.p_position[id2] = pos2
												ecs.components.position[id2] = nil
											end


										end
									end
								end
							else if mov and (mov.is_moving) -- or mov.mx ~= 0 or mov.my ~= 0)
								and mov2 and (mov2.is_moving) then --or mov2.mx ~= 0 or mov2.my ~= 0) then
								-- move both
								pos.x = pos.x + (correction_vect.x)/2
								pos.y = pos.y + (correction_vect.y)/2

								if math.sign(correction_vect.x) ~= math.sign(mov.mx) then mov.mx = 0 end
								if math.sign(correction_vect.y) ~= math.sign(mov.my) then mov.my = 0 end
								--mov.mx, mov.my = 0, 0

								pos2.x = pos2.x - (correction_vect.x)/2
								pos2.y = pos2.y - (correction_vect.y)/2

								if math.sign(correction_vect.x) == math.sign(mov2.mx) then mov2.mx = 0 end
								if math.sign(correction_vect.y) == math.sign(mov2.my) then mov2.my = 0 end
								--mov2.mx, mov2.my = 0, 0
							else if mov and (mov.is_moving) then -- or mov.mx ~= 0 or mov.my ~= 0) then
								-- move id
								pos.x = pos.x + (correction_vect.x)
								pos.y = pos.y + (correction_vect.y)

								if math.sign(correction_vect.x) ~= math.sign(mov.mx) then mov.mx = 0 end
								if math.sign(correction_vect.y) ~= math.sign(mov.my) then mov.my = 0 end
								--mov.mx, mov.my = 0, 0

							else if mov2 and (mov2.is_moving) then -- or mov2.mx ~= 0 or mov2.my ~= 0) then

								pos2.x = pos2.x - (correction_vect.x)
								pos2.y = pos2.y - (correction_vect.y)

								if math.sign(correction_vect.x) == math.sign(mov2.mx) then mov2.mx = 0 end
								if math.sign(correction_vect.y) == math.sign(mov2.my) then mov2.my = 0 end
								--mov2.mx, mov2.my = 0, 0
							else
								-- move id
								pos.x = pos.x + (correction_vect.x)/2
								pos.y = pos.y + (correction_vect.y)/2

								pos2.x = pos2.x - (correction_vect.x)/2
								pos2.y = pos2.y - (correction_vect.y)/2
							end end end end

							--[[
								HITBOXES
							]]
							local hitbox = ecs.components.hitbox[id]
							local hitbox2 = ecs.components.hitbox[id2]

							
							--[[
								HITBOX 1
							]]
							-- id hits id2, id is an entity, id2 can be an item or entity
							-- don't apply damage or anything to items? (durability?)
							if hitbox and not hitbox.hit_ids[id2] then
								local has_effect = false

								-- apply damage types
								for damagetype, amount in pairs(hitbox.damage) do 
									local comp = ecs.components[damagetype][id2]

									if comp then
										comp.amount = (comp.amount - amount >= 0 and comp.amount - amount) or 0
										if not has_effect and amount < 0 then
											has_effect = true
										end
									end
								end

								-- buildup effects
								local effects = ecs.components.effects[id2]
								if effects then
									for effecttype, buildup in pairs(hitbox.effects) do
										-- add effect to component
										if not effects[effecttype] then
											print(id2, "new effect", effecttype)
											effects[effecttype] = {
												damage = {},
												source = 0,
												amount = 0
											}
										end
										-- apply buildup
										effects[effecttype].amount = effects[effecttype].amount + buildup
										if not has_effect and next(effects[effecttype].damage) then
											has_effect = true
										end
									end
								end

								if has_effect then
									-- flash it
									ecs.components.sprite[id2].flash = 4*dt

									-- recoil -- items don't recoil
									if not ecs.components.item[id2] then
										local dx = pos2.x - pos.x
										local dy = pos2.y - pos.y

										if mov2 then
											mov2.mx = math.clamp(math.abs(dx/dy), 0, 1) * math.sign(dx) * 6
											mov2.my = math.clamp(math.abs(dy/dx), 0, 1) * math.sign(dy) * 6
										end
									end
								end
							end

							
							--[[
								HITBOX 2
							]]
							-- id2 hits id, id2 can be an item or entity, id has to be entity
							if hitbox2 and not hitbox2.hit_ids[id] 
								and ecs.components.held[id2] ~= id then -- this checks if id2 wasn't picked up by id

								-- mark as hit if id2 is an item
								if ecs.components.item[id2] then
									ecs.components.hitbox[id2].hit_ids[id] = true
								end
								
								local has_effect = false
								
								-- apply damage types
								for damagetype, amount in pairs(hitbox2.damage or {}) do 
									local comp = ecs.components[damagetype][id]

									if comp then
										-- TODO: resistances?
										comp.amount = math.clamp(comp.amount + amount, 0, comp.max)
										if not has_effect and amount < 0 then
											has_effect = true
										end
									end
								end

								-- buildup effects
								local effects = ecs.components.effects[id]
								if effects then
									for effecttype, buildup in pairs(hitbox2.effects) do
										-- add effect to component
										if not effects[effecttype] then
											print(id, "new effect", effecttype)
											effects[effecttype] = {
												damage = {},
												source = 0,
												amount = 0
											}
										end
										-- apply buildup
										effects[effecttype].amount = effects[effecttype].amount + buildup
										if not has_effect and next(effects[effecttype].damage) then
											has_effect = true
										end
									end
								end

								if has_effect then
									-- flash it
									ecs.components.sprite[id].flash = 4*dt

									-- knockback
									if mov then
										-- if it's an item, calculate the movement based on the holder, otherwise use the items pos
										local t_pos = ecs.components.position[ecs.components.held[id2]] or pos2

										local dx = pos.x - t_pos.x
										local dy = pos.y - t_pos.y

										mov.mx = math.clamp(math.abs(dx/dy), 0, 1) * math.sign(dx) * 6
										mov.my = math.clamp(math.abs(dy/dx), 0, 1) * math.sign(dy) * 6
									end
								end
							end
						end
					end
				end
			end
		end
	end
end

function systems.updateMapCollision(ecs, dt, input)
	local entities = ecs:requireAll("position", "collision")

	for _, id in ipairs(entities) do
		local pos = ecs.components.position[id]
		local col = ecs.components.collision[id]
		local mov = ecs.components.movement[id]
		local proj = ecs.components.projectile[id]

		local walls, effects = ecs.map:collision(
			{
				x = pos.x - col.w/2 + col.offx,
				y = pos.y - col.h/2 + col.offy,
				w = col.w,
				h = col.h
			})

		for _, wall in ipairs(walls) do
			local output = {}

			collision_check(
				{x=pos.x+col.offx, y=pos.y+col.offy, w=col.w, h=col.h, rx=pos.x, ry=pos.y, r=pos.r},
				wall,
				output)

			local overlap = output.overlap
			local correction_vect = {x = output.x, y = output.y}

			if overlap and overlap ~= 0 then
				pos.x = pos.x + (correction_vect.x)
				pos.y = pos.y + (correction_vect.y)

				if mov then
					if math.sign(correction_vect.x) ~= math.sign(mov.mx) then mov.mx = 0 end
					if math.sign(correction_vect.y) ~= math.sign(mov.my) then mov.my = 0 end
				end

				if proj then

					if mov then
						mov.dx, mov.dy = 0, 0
					end

					if proj.delete_on_collision then
						ecs.components.lifetime[id2] = .05
						ecs.components.collision[id2] = nil

					else

						-- it can be picked up, after a bit of time, or delete it
						if proj.can_pickup then
							ecs.components.projectile[id] = nil
						else
							ecs.components.collision[id] = nil
							ecs.components.lifetime[id] = 2
						end

					end
				end
			end
		end
	end
end

function systems.updateEffects(ecs, dt, input)
	local entities = ecs:requireAll("effects")

	for _, id in ipairs(entities) do
		local effects = ecs.components.effects[id]
		local dampen = {}

		-- inter effect actions occur here
		for effecttype, effect in pairs(effects) do
			for effectedtype, scale in pairs(inter_effects[effecttype] or {}) do
				if effects[effectedtype] then
					dampen[effectedtype] = math.clamp(effects[effectedtype].amount + (effect.amount*scale*dt/1000), 0, 200)
					if dampen[effectedtype] ~= effects[effectedtype].amount then
						--print(id, effecttype, "dampens", effectedtype, dampen[effectedtype], effects[effectedtype].amount)
					end
				end
			end
		end

		for effecttype, effect in pairs(effects) do

			--if dampen[effecttype] then print(effecttype, dampen[effecttype], effect.amount) end

			effect.amount = math.clamp((dampen[effecttype] or effect.amount) + ((effect.source or 0)*dt/1000), 0, 200)

			--print(id, effecttype, effect.amount)

			if effect.amount >= 100 then
				--print(id, "is effected by", effecttype, effect.amount)
				-- add to hibox
				if not ecs.components.hitbox[id] then
					ecs.components.hitbox[id] = {
						hit_ids = {},
						effects = {},
						damage = {}
					}
				end

				--TODO: How much of an effect should be translated?
				local susceptibility = .5
				ecs.components.hitbox[id].effects[effecttype] = effect.amount*susceptibility

				-- maybe damage should be calculated in it's own system so that fire can be affected by water, and electricity by water etc?
				for damagetype, amount in pairs(effect.damage) do
					damage_comp = ecs.components[damagetype][id]
					if damage_comp then
						damage_comp.amount = math.clamp(damage_comp.amount + amount*dt/1000, 0, damage_comp.max)
					end
				end
			else
				-- remove from hitbox
				-- maybe have effect.amount shrink here so something that isn't quite on fire can lose it's buildup (if there is no source)
				if ecs.components.hitbox[id] then

				end
			end
		end
	end
end

function systems.updateHunger(ecs, dt, input)
	-- Should food drain at a uniform rate?
	-- how do different actions 
	-- if food is 0, deal x damage/second
end

function systems.updateHealth(ecs, dt, input)
	-- Should food drain at a uniform rate?
	-- how do different actions
	-- if health is 0 then 
end

function systems.ignore(ecs, dt, input)
	local entities = ecs:requireAll("ignore")

	for _, id in ipairs(entities) do
		local ignore = ecs.components.ignore[id]

		ignore.time = ignore.time - dt/1000;

		if ignore.time < 0 then
			ecs.components.ignore[id] = nil
		end
	end
end

function systems.lifetime(ecs, dt, input)
	local entities = ecs:requireAll("lifetime")

	for _, id in ipairs(entities) do
		ecs.components.lifetime[id] = ecs.components.lifetime[id] - dt/1000

		if ecs.components.lifetime[id] < 0 then
			ecs:removeEntity(id)
		end
	end
end

function systems.updateAnimation(ecs, dt, input)
	local entities = ecs:requireAll("sprite")

	for _, id in ipairs(entities) do
		local sprite = ecs.components.sprite[id]
		local state = ecs.components.state[id]

		if state then 
			local duration = state.action.duration
			local percent = (state.time%duration)/duration
			local frameindex = math.floor(percent * #state.action.frames) + 1

			sprite.framex = state.action.frames[frameindex]

			sprite.framey = state.direction_to_y[state.direction]

			sprite.totalframesx = state.action.framesw
			sprite.totalframesy = 4

			sprite.flash = (sprite.flash == nil and 0) or (sprite.flash - dt >= 0 and sprite.flash - dt) or 0
		else
			sprite.flash = 0
		end
	end
end

function systems.draw(ecs, viewport)
	local entities = ecs:requireAll("position", "sprite")

	local drawItems = {}

	for _, id in ipairs(entities) do
		local position = ecs.components.position[id]
		local sprite = ecs.components.sprite[id]

		position.z = position.y + position.h/2

		if not sprite.sprite then
			sprite.sprite = Sprite.new()
		end

		sprite.sprite:init(sprite.img..".png", sprite.totalframesx, sprite.totalframesy, true)
		sprite.sprite:setFrame(sprite.framex-1, sprite.framey-1)
		sprite.sprite:setPosition(position.x*TILESIZE, -position.y*TILESIZE)
		sprite.sprite:setRotation(-position.r)

		table.insert(drawItems, {position.z, sprite.sprite})
		--draw(sprite.sprite)
	end

	local sortfunc = function (a, b) return a[1] > b[1] end

	table.sort(drawItems, sortfunc)

	for _, sprite in ipairs(drawItems) do
		draw(sprite[2])
	end
end

function systems.drawHitbox(ecs, viewport)
	local entities = ecs:requireAll("position", "collision")
	println(#entities)

	local texturename = ""
	local vp_rect = Rect.new()
	local out_rect = Rect.new()
	vp_rect.x = viewport.x
	vp_rect.y = viewport.y
	vp_rect.w = viewport.w
	vp_rect.h = viewport.h

	for _, id in ipairs(entities) do
		local position = ecs.components.position[id]
		local collision = ecs.components.collision[id]

		texturename = "hitbox.png"

		local px = collision.offx
		local py = collision.offy

		local r = position.r

		out_rect.x = px*cos(r) - py*sin(r) + position.x
		out_rect.y = px*sin(r) + py*cos(r) + position.y
		out_rect.w = collision.w
		out_rect.h = collision.h
		out_rect.r = r

		draw_sprite(texturename, vp_rect, out_rect, 1, 1, 1, 1)
	end
end

function systems.drawUI(ecs, drawcontainer)
	-- assume id == 1 is the player id
	local player_id = 4

	local health = ecs.components.health[player_id]

	if health.amount < health.max/2 then
		local di = DrawItem:new(5)
		local sprite = di.data.uisprite

		sprite.texturename = "fire.png"
		drawcontainer:add(di)
	end
end

return systems