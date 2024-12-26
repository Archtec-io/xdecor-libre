-- Thanks to sofar for helping with that code.

local plate = {}
screwdriver = screwdriver or {}

local S = minetest.get_translator("xdecor")
local ALPHA_OPAQUE = minetest.features.use_texture_alpha_string_modes and "opaque" or false

-- Number of seconds an actuator (pressure plate, lever) stays active.
-- After this time, it will return to the disabled state again.
local DISABLE_ACTUATOR_AFTER = 2.0

local PRESSURE_PLATE_AREA_MIN = {x = -2, y = 0, z = -2}
local PRESSURE_PLATE_AREA_MAX = {x = 2, y = 0, z = 2}
local LEVER_AREA_MIN = {x = -2, y = -1, z = -2}
local LEVER_AREA_MAX = {x = 2, y = 1, z = 2}

local PRESSURE_PLATE_PLAYER_RADIUS = 0.8



local function door_open(pos_door, player)
	local door = doors.get(pos_door)
	if not door then
		return
	end
	door:open(player)
end

local function door_close(pos_door, player)
	local door = doors.get(pos_door)
	if not door then
		return
	end
	door:close(player)
end

-- Returns true if the door node at pos is currently next to any
-- active actuator node (lever, pressure plate)
local function door_is_actuatored(pos_door)
	local minp = vector.add(LEVER_AREA_MIN, pos_door)
	local maxp = vector.add(LEVER_AREA_MAX, pos_door)
	local levers = minetest.find_nodes_in_area(minp, maxp, "group:lever")
	for l=1, #levers do
		local lnode = minetest.get_node(levers[l])
		if minetest.get_item_group(lnode.name, "xdecor_actuator") == 2 then
			return true
		end
	end
	minp = vector.add(PRESSURE_PLATE_AREA_MIN, pos_door)
	maxp = vector.add(PRESSURE_PLATE_AREA_MAX, pos_door)
	local pressure_plates = minetest.find_nodes_in_area(minp, maxp, "group:pressure_plate")
	for p=1, #pressure_plates do
		local pnode = minetest.get_node(pressure_plates[p])
		if minetest.get_item_group(pnode.name, "xdecor_actuator") == 2 then
			return true
		end
	end
	return false
end

local function actuator_timeout(pos_actuator, actuator_area_min, actuator_area_max)
	local actuator = minetest.get_node(pos_actuator)
	-- Turn off actuator
	if minetest.get_item_group(actuator.name, "xdecor_actuator") == 2 then
		local def = minetest.registered_nodes[actuator.name]
		if def._xdecor_actuator_off then
			minetest.set_node(pos_actuator, { name = def._xdecor_actuator_off, param2 = actuator.param2 })
		end
	end

	-- Close neighboring doors that are no longer next to any active actuator
	local minp = vector.add(actuator_area_min, pos_actuator)
	local maxp = vector.add(actuator_area_max, pos_actuator)
	local doors = minetest.find_nodes_in_area(minp, maxp, "group:door")
	for d=1, #doors do
		if not door_is_actuatored(doors[d]) then
			door_close(doors[d])
		end
	end
end

local function actuator_activate(pos_actuator, actuator_area_min, actuator_area_max, player)
	local player_name = player:get_player_name()
	local actuator = minetest.get_node(pos_actuator)
	local ga = minetest.get_item_group(actuator.name, "xdecor_actuator")
	if ga == 2 then
		-- No-op if actuator is already active
		return
	elseif ga == 1 then
		local def = minetest.registered_nodes[actuator.name]
		if def._xdecor_actuator_on then
			minetest.set_node(pos_actuator, { name = def._xdecor_actuator_on, param2 = actuator.param2 })
		end
	end
	local minp = vector.add(actuator_area_min, pos_actuator)
	local maxp = vector.add(actuator_area_max, pos_actuator)
	local doors = minetest.find_nodes_in_area(minp, maxp, "group:door")
	for i = 1, #doors do
		door_open(doors[i], player)
	end
end

function plate.construct(pos)
	local timer = minetest.get_node_timer(pos)
	timer:start(0.1)
end

function plate.has_player_standing_on(pos)
	local objs = minetest.get_objects_inside_radius(pos, PRESSURE_PLATE_PLAYER_RADIUS)
	for _, player in pairs(objs) do
		if player:is_player() then
			return true, player
		end
	end
	return false
end

function plate.timer(pos)
	if not doors.get then
		return true
	end
	local ok, player = plate.has_player_standing_on(pos)
	if ok then
		actuator_activate(pos, PRESSURE_PLATE_AREA_MIN, PRESSURE_PLATE_AREA_MAX, player)
	end

	return true
end

function plate.construct_on(pos)
	local timer = minetest.get_node_timer(pos)
	timer:start(DISABLE_ACTUATOR_AFTER)
end

function plate.timer_on(pos)
	if plate.has_player_standing_on(pos) then
		-- If player is still standing on active pressure plate, restart timer
		local timer = minetest.get_node_timer(pos)
		timer:start(DISABLE_ACTUATOR_AFTER)
		return
	end

	actuator_timeout(pos, PRESSURE_PLATE_AREA_MIN, PRESSURE_PLATE_AREA_MAX)
end

function plate.register(material, desc, def)
	local groups
	if def.groups then
		groups = table.copy(def.groups)
	else
		groups = {}
	end
	groups.pressure_plate = 1
	groups.xdecor_actuator = 1
	xdecor.register("pressure_" .. material .. "_off", {
		description = def.description or (desc .. " Pressure Plate"),
		--~ Pressure plate tooltip
		_tt_help = S("Opens doors when stepped on"),
		tiles = {"xdecor_pressure_" .. material .. ".png"},
		use_texture_alpha = ALPHA_OPAQUE,
		drawtype = "nodebox",
		node_box = xdecor.pixelbox(16, {{1, 0, 1, 14, 1, 14}}),
		groups = groups,
		is_ground_content = false,
		sounds = def.sounds,
		sunlight_propagates = true,
		on_rotate = screwdriver.rotate_simple,
		on_construct = plate.construct,
		on_timer = plate.timer,
		_xdecor_actuator_off = "xdecor:pressure_"..material.."_off",
		_xdecor_actuator_on = "xdecor:pressure_"..material.."_on",
	})
	local groups_on = table.copy(groups)
	groups_on.xdecor_actuator = 2
	groups_on.pressure_plate = 2
	xdecor.register("pressure_" .. material .. "_on", {
		tiles = {"xdecor_pressure_" .. material .. ".png"},
		use_texture_alpha = ALPHA_OPAQUE,
		drawtype = "nodebox",
		node_box = xdecor.pixelbox(16, {{1, 0, 1, 14, 0.4, 14}}),
		groups = groups_on,
		is_ground_content = false,
		sounds = def.sounds,
		drop = "xdecor:pressure_" .. material .. "_off",
		sunlight_propagates = true,
		on_rotate = screwdriver.rotate_simple,
		on_construct = plate.construct_on,
		on_timer = plate.timer_on,
		_xdecor_actuator_off = "xdecor:pressure_"..material.."_off",
		_xdecor_actuator_on = "xdecor:pressure_"..material.."_on",
	})
end

plate.register("wood", "Wooden", {
	sounds = default.node_sound_wood_defaults(),
	groups = {choppy = 3, oddly_breakable_by_hand = 2, flammable = 2},
	description = S("Wooden Pressure Plate"),
})

plate.register("stone", "Stone", {
	sounds = default.node_sound_stone_defaults(),
	groups = {cracky = 3, oddly_breakable_by_hand = 2},
	description =  S("Stone Pressure Plate"),
})

xdecor.register("lever_off", {
	description = S("Lever"),
	--~ Lever tooltip
	_tt_help = S("Opens doors when pulled"),
	tiles = {"xdecor_lever_off.png"},
	use_texture_alpha = ALPHA_OPAQUE,
	drawtype = "nodebox",
	node_box = xdecor.pixelbox(16, {{2, 1, 15, 12, 14, 1}}),
	groups = {cracky = 3, oddly_breakable_by_hand = 2, lever = 1, xdecor_actuator = 1},
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),
	sunlight_propagates = true,
	on_rotate = screwdriver.rotate_simple,

	on_rightclick = function(pos, node, clicker, itemstack)
		if not doors.get then
			return itemstack
		end
		actuator_activate(pos, LEVER_AREA_MIN, LEVER_AREA_MAX, clicker)
		return itemstack
	end,
	_xdecor_itemframe_offset = -3.5,
	_xdecor_actuator_off = "xdecor:lever_off",
	_xdecor_actuator_on = "xdecor:lever_on",
})

xdecor.register("lever_on", {
	tiles = {"xdecor_lever_on.png"},
	use_texture_alpha = ALPHA_OPAQUE,
	drawtype = "nodebox",
	node_box = xdecor.pixelbox(16, {{2, 1, 15, 12, 14, 1}}),
	groups = {cracky = 3, oddly_breakable_by_hand = 2, lever = 2, xdecor_actuator = 2, not_in_creative_inventory = 1},
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),
	sunlight_propagates = true,
	on_rotate = screwdriver.rotate_simple,
	on_rightclick = function(pos, node, clicker, itemstack)
		-- Prevent placing nodes on activated lever with the place key
		-- for consistent behavior with the lever in "off" state.
		-- The player may still place nodes using [Sneak].
		return itemstack
	end,
	on_construct = function(pos)
		local timer = minetest.get_node_timer(pos)
		timer:start(DISABLE_ACTUATOR_AFTER)
	end,
	on_timer = function(pos)
		local node = minetest.get_node(pos)
		actuator_timeout(pos, LEVER_AREA_MIN, LEVER_AREA_MAX)
	end,
	drop = "xdecor:lever_off",
	_xdecor_itemframe_offset = -3.5,
	_xdecor_actuator_off = "xdecor:lever_off",
	_xdecor_actuator_on = "xdecor:lever_on",
})

-- Recipes

minetest.register_craft({
	output = "xdecor:pressure_stone_off",
	type = "shapeless",
	recipe = {"group:stone", "group:stone"}
})

minetest.register_craft({
	output = "xdecor:pressure_wood_off",
	type = "shapeless",
	recipe = {"group:wood", "group:wood"}
})

minetest.register_craft({
	output = "xdecor:lever_off",
	recipe = {
		{"group:stick"},
		{"group:stone"}
	}
})
