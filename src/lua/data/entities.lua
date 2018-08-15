local entities = {}

entities.camera = {
	camera = {
		view = "$1",
		behavior = "$2"
	}
}

entities.man = {
	control = {
		up = "W",
		down = "S",
		left = "A",
		right = "D",
		lock_direction = "LShift",
		attack = "Space",
		show_inventory = "Tab",
		switch_item_right = "E",
		switch_item_left = "Q",
		drop_item = "R",
		interact = "Return"
	},
	interest = 1,
	position = {
		x = "$1", y = "$2",
		w = 12/16, h = 17/16
	},
	collision = {
		offx = 0,
		offy = -2.5/16,
		w = 12/16,
		h = 14/16,
		class = "regular"
	},
	movement = {
		tps = 5
	},
	animation = {

		action = nil,
		action_name = "idle",
		next_action = nil,
		frame_index = 1,

		direction = "down",
		direction_locked = false,

		time = 0,

		animations = {
			idle = {
				frames = {2},
				angles = {0},
				hitbox_frames = {false},
				base_duration = inf,
				interruptable = true
			},
			walk = {
				frames = {1, 2, 3, 2},
				angles = {0, 0, 0, 0},
				hitbox_frames = {false, false, false, false},
				base_duration = .7,
				interruptable = true
			},
			attack = {
				frames = {1, 1, 6, 6, 6, 6},
				angles = {0, 0, 0, 0, 0, 0},
				hitbox_frames = {false, false, true, true, true, true},
				base_duration = .25,
				interruptable = false,
			},
			swing_right = {
				frames = {4, 4, 5, 5, 6, 6, 6, 7, 7, 8, 8},
				angles = {90, 70, 50, 30, 10, 0, -10, -30, -50, -70, -90},
				hitbox_frames = {true, true, true, true, true, true, true, true, true, true, true}, 
				base_duration = .6,
				interruptable = false
			},
			swing_left = {
				frames = {8, 8, 7, 7, 6, 6, 6, 5, 5, 4, 4},
				angles = {-90, -70, -50, -30, -10, 0, 10, 30, 50, 70, 90},
				hitbox_frames = {true, true, true, true, true, true, true, true, true, true, true}, 
				base_duration = .6,
				interruptable = false,
			}
		}
	},
	sprite = {
		img = "man",
		framex = 2,
		framey = 1,
		framesx = 8,
		framesy = 4
	},
	hand = false
}

entities.ladder = {
	position = {
		x = "$1", y = "$2",
		w = 1, h = 1
	},
	sprite = {
		img = "$3",
		framex = 1,
		framey = 1,
		framesx = 1,
		framesy = 1
	}
}

--[[

	Types of items:
		Weapons
			ex: sword
			-- holdable
		Armor
			ex: shirt
			-- wearable
		Projectiles
			ex: arrow or magic bolt
			-- projectile
			-- or velocity?
			-- hitbox
		Consumables
			-- stack
		Usable?

]]

entities.sword = {
	held = false, -- entity holding this item
	interest = 1,
	item = {
		class = "weapon",
		stackable = false,
		consumable = false,
		wearable = false,
		projectile = false,
		holdable = {
			offx = -6/16,	-- offset to handle
			offy = 0,
			collision = {	-- collision box for while in hand
				offx = 2/16,
				offy = 0,
				w = 12/16,
				h = 5/16,
			},
			actions = {
				attack = {
					spawn = "arrow",
					duration = .2,
					hitbox = {		-- hitbox for while in hand
						hit_ids = {}, -- already affected 
						-- effects are status effects like paralysis, burns, etc
						effects = {},
						damage = {
							health = -5
						}
					},
					combo = {
						attack = "swing_right"
					}
				},
				swing_right = {
					duration = .3,
					hitbox = {		-- hitbox for while in hand
						hit_ids = {}, -- already affected 
						-- effects are status effects like paralysis, burns, etc
						effects = {},
						damage = {
							health = -5
						}
					},
					combo = {
						attack = "swing_left"
					}
				},
				swing_left = {
					duration = .3,
					hitbox = {		-- hitbox for while in hand
						hit_ids = {}, -- already affected 
						-- effects are status effects like paralysis, burns, etc
						effects = {},
						damage = {
							health = -5
						}
					},
					combo = {
						attack = "swing_right"
					}
				}
			}
		}
	},
	position = {
		x = "$1", y = "$2",
		w = 16/16, h = 5/16
	},
	collision = {
		offx = 0,
		offy = 0,
		w = 1,
		h = 5/16,
		class = "ignore"
	},
	sprite = {
		img = "sword",
		framex = 1,
		framey = 1,
		framesx = 1,
		framesy = 1
	}
}

entities.block = {
	position = {
		x = "$1", y = "$2",
		w = 1, h = 1
	},
	collision = {
		offx = 0,
		offy = 0,
		w = 1,
		h = 1,
		class = "regular"
	},
	sprite = {
		img = "block",
		framex = 1,
		framey = 1,
		framesx = 1,
		framesy = 1
	}
}

hand_positions = {
	man = {
		{--framey=1
			{-5.5/16, -2.5/16},--framex=1
			{-4.5/16, -4.5/16},--framex=2 ...
			{-3.5/16, -5.5/16},
			{-1.5/16, -5.5/16},
			{-1.5/16, -5.5/16},
			{-2.5/16, -6.5/16},
			{-3.5/16, -5.5/16},
			{-3.5/16, -5.5/16}
		},
		{--y=2
			{4.5/16, -2.5/16},
			{4.5/16, -0.5/16},
			{3.5/16, 2.5/16}, --{4.5/16, 0},
			{1.5/16, 1/16},
			{1.5/16, 1/16},
			{2.5/16, 2/16},
			{3.5/16, 1/16},
			{3.5/16, 1/16}
		},
		{--y=3
			{-1/16, -4/16},
			{1/16, -5/16},
			{4/16, -3/16},
			{4/16, -3/16},
			{4/16, -3/16},
			{4/16, -4/16},
			{4/16, -5/16},
			{4/16, -5/16}
		},
		{--y=4
			{1/16, -2/16},
			{-1/16, -3/16},
			{-4/16, -1/16},
			{-4/16, -3/16},
			{-4/16, -3/16},
			{-4/16, -2/16},
			{-4/16, -1/16},
			{-4/16, -1/16}
		}
	}
}

return entities