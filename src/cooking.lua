local cauldron, sounds = {}, {}
local S = minetest.get_translator("xdecor")

-- Add more ingredients here that make a soup.
local ingredients_list = {
	"apple", "mushroom", "honey", "pumpkin", "egg", "bread", "meat",
	"chicken", "carrot", "potato", "melon", "rhubarb", "cucumber",
	"corn", "beans", "berries", "grapes", "tomato", "wheat"
}

cauldron.cbox = {
	{0,  0, 0,  16, 16, 0},
	{0,  0, 16, 16, 16, 0},
	{0,  0, 0,  0,  16, 16},
	{16, 0, 0,  0,  16, 16},
	{0,  0, 0,  16, 8,  16}
}

function cauldron.stop_sound(pos)
	local spos = minetest.hash_node_position(pos)
	if sounds[spos] then
		minetest.sound_stop(sounds[spos])
	end
end

function cauldron.idle_construct(pos)
	local timer = minetest.get_node_timer(pos)
	timer:start(10.0)
	cauldron.stop_sound(pos)
end

function cauldron.boiling_construct(pos)
	local spos = minetest.hash_node_position(pos)
	sounds[spos] = minetest.sound_play("xdecor_boiling_water", {
		pos = pos,
		max_hear_distance = 5,
		gain = 0.8,
		loop = true
	})

	local meta = minetest.get_meta(pos)
	meta:set_string("infotext", S("Cauldron (active) - Drop foods inside to make a soup"))

	local timer = minetest.get_node_timer(pos)
	timer:start(5.0)
end

function cauldron.filling(pos, node, clicker, itemstack)
	local inv = clicker:get_inventory()
	local wield_item = clicker:get_wielded_item():get_name()

	do
		if wield_item == "bucket:bucket_empty" and node.name:sub(-6) ~= "_empty" then
			local bucket_item
			if node.name:sub(-11) == "river_water" then
				bucket_item = "bucket:bucket_river_water 1"
			else
				bucket_item = "bucket:bucket_water 1"
			end
			if itemstack:get_count() > 1 then
				if inv:room_for_item("main", bucket_item) then
					itemstack:take_item()
					inv:add_item("main", bucket_item)
				else
					minetest.chat_send_player(clicker:get_player_name(),
						S("No room in your inventory to add a bucket of water."))
					return itemstack
				end
			else
				itemstack:replace(bucket_item)
			end
			minetest.set_node(pos, {name = "xdecor:cauldron_empty", param2 = node.param2})

		elseif minetest.get_item_group(wield_item, "water_bucket") == 1 and node.name:sub(-6) == "_empty" then
			local newnode
			if wield_item == "bucket:bucket_river_water" then
				newnode = "xdecor:cauldron_idle_river_water"
			else
				newnode = "xdecor:cauldron_idle"
			end
			minetest.set_node(pos, {name = newnode, param2 = node.param2})
			itemstack:replace("bucket:bucket_empty")
		end

		return itemstack
	end
end

function cauldron.idle_timer(pos)
	local below_node = {x = pos.x, y = pos.y - 1, z = pos.z}
	if not minetest.get_node(below_node).name:find("fire") then
		return true
	end

	local node = minetest.get_node(pos)
	if node.name:sub(-11) == "river_water" then
		node.name = "xdecor:cauldron_boiling_river_water"
	else
		node.name = "xdecor:cauldron_boiling"
	end
	minetest.set_node(pos, node)
	return true
end

-- Ugly hack to determine if an item has the function `minetest.item_eat` in its definition.
local function eatable(itemstring)
	local item = itemstring:match("[%w_:]+")
	local on_use_def = minetest.registered_items[item].on_use
	if not on_use_def then return end

	return string.format("%q", string.dump(on_use_def)):find("item_eat")
end

function cauldron.boiling_timer(pos)
	local node = minetest.get_node(pos)
	local objs = minetest.get_objects_inside_radius(pos, 0.5)

	if not next(objs) then
		return true
	end

	local ingredients = {}
	for _, obj in pairs(objs) do
		if obj and not obj:is_player() and obj:get_luaentity().itemstring then
			local itemstring = obj:get_luaentity().itemstring
			local food = itemstring:match(":([%w_]+)")

			for _, ingredient in ipairs(ingredients_list) do
				if food and (eatable(itemstring) or food:find(ingredient)) then
					ingredients[#ingredients + 1] = food
					break
				end
			end
		end
	end

	if #ingredients >= 2 then
		for _, obj in pairs(objs) do
			obj:remove()
		end

		minetest.set_node(pos, {name = "xdecor:cauldron_soup", param2 = node.param2})
	end

	local node_under = {x = pos.x, y = pos.y - 1, z = pos.z}

	if not minetest.get_node(node_under).name:find("fire") then
		local newnode
		if node.name:sub(-11) == "river_water" then
			newnode = "xdecor:cauldron_idle_river_water"
		else
			newnode = "xdecor:cauldron_idle"
		end
		minetest.set_node(pos, {name = newnode, param2 = node.param2})
	end

	return true
end

function cauldron.take_soup(pos, node, clicker, itemstack)
	local inv = clicker:get_inventory()
	local wield_item = clicker:get_wielded_item()
	local item_name = wield_item:get_name()

	if item_name == "xdecor:bowl" or item_name == "farming:bowl" then
		if wield_item:get_count() > 1 then
			if inv:room_for_item("main", "xdecor:bowl_soup 1") then
				itemstack:take_item()
				inv:add_item("main", "xdecor:bowl_soup 1")
			else
				minetest.chat_send_player(clicker:get_player_name(),
					S("No room in your inventory to add a bowl of soup."))
				return itemstack
			end
		else
			itemstack:replace("xdecor:bowl_soup 1")
		end

		minetest.set_node(pos, {name = "xdecor:cauldron_empty", param2 = node.param2})
	end

	return itemstack
end

xdecor.register("cauldron_empty", {
	description = S("Cauldron"),
	groups = {cracky=2, oddly_breakable_by_hand=1},
	on_rotate = screwdriver.rotate_simple,
	tiles = {"xdecor_cauldron_top_empty.png", "xdecor_cauldron_sides.png"},
	sounds = default.node_sound_metal_defaults(),
	infotext = S("Cauldron (empty)"),
	collision_box = xdecor.pixelbox(16, cauldron.cbox),
	on_rightclick = cauldron.filling,
	on_construct = function(pos)
		cauldron.stop_sound(pos)
	end,
})

xdecor.register("cauldron_idle", {
	description = S("Cauldron with Water (idle)"),
	groups = {cracky=2, oddly_breakable_by_hand=1, not_in_creative_inventory=1},
	on_rotate = screwdriver.rotate_simple,
	tiles = {"xdecor_cauldron_top_idle.png", "xdecor_cauldron_sides.png"},
	sounds = default.node_sound_metal_defaults(),
	drop = "xdecor:cauldron_empty",
	infotext = S("Cauldron (idle)"),
	collision_box = xdecor.pixelbox(16, cauldron.cbox),
	on_rightclick = cauldron.filling,
	on_construct = cauldron.idle_construct,
	on_timer = cauldron.idle_timer,
})

xdecor.register("cauldron_idle_river_water", {
	description = S("Cauldron with River Water (idle)"),
	groups = {cracky=2, oddly_breakable_by_hand=1, not_in_creative_inventory=1},
	on_rotate = screwdriver.rotate_simple,
	tiles = {"xdecor_cauldron_top_idle_river_water.png", "xdecor_cauldron_sides.png"},
	sounds = default.node_sound_metal_defaults(),
	drop = "xdecor:cauldron_empty",
	infotext = S("Cauldron (idle)"),
	collision_box = xdecor.pixelbox(16, cauldron.cbox),
	on_rightclick = cauldron.filling,
	on_construct = cauldron.idle_construct,
	on_timer = cauldron.idle_timer,
})

xdecor.register("cauldron_boiling", {
	description = S("Cauldron with Water (active)"),
	groups = {cracky=2, oddly_breakable_by_hand=1, not_in_creative_inventory=1},
	on_rotate = screwdriver.rotate_simple,
	drop = "xdecor:cauldron_empty",
	infotext = S("Cauldron (active) - Drop foods inside to make a soup"),
	damage_per_second = 2,
	tiles = {
		{
			name = "xdecor_cauldron_top_anim_boiling_water.png",
			animation = {type = "vertical_frames", length = 3.0}
		},
		"xdecor_cauldron_sides.png"
	},
	sounds = default.node_sound_metal_defaults(),
	collision_box = xdecor.pixelbox(16, cauldron.cbox),
	on_rightclick = cauldron.filling,
	on_construct = cauldron.boiling_construct,
	on_timer = cauldron.boiling_timer,
	on_destruct = function(pos)
		cauldron.stop_sound(pos)
	end,
})

xdecor.register("cauldron_boiling_river_water", {
	description = S("Cauldron with River Water (active)"),
	groups = {cracky=2, oddly_breakable_by_hand=1, not_in_creative_inventory=1},
	on_rotate = screwdriver.rotate_simple,
	drop = "xdecor:cauldron_empty",
	infotext = S("Cauldron (active) - Drop foods inside to make a soup"),
	damage_per_second = 2,
	tiles = {
		{
			name = "xdecor_cauldron_top_anim_boiling_river_water.png",
			animation = {type = "vertical_frames", length = 3.0}
		},
		"xdecor_cauldron_sides.png"
	},
	sounds = default.node_sound_metal_defaults(),
	collision_box = xdecor.pixelbox(16, cauldron.cbox),
	on_rightclick = cauldron.filling,
	on_construct = cauldron.boiling_construct,
	on_timer = cauldron.boiling_timer,
	on_destruct = function(pos)
		cauldron.stop_sound(pos)
	end,
})



xdecor.register("cauldron_soup", {
	description = S("Cauldron with Soup (active)"),
	groups = {cracky = 2, oddly_breakable_by_hand = 1, not_in_creative_inventory = 1},
	on_rotate = screwdriver.rotate_simple,
	drop = "xdecor:cauldron_empty",
	infotext = S("Cauldron (active) - Use a bowl to eat the soup"),
	damage_per_second = 2,
	tiles = {
		{
			name = "xdecor_cauldron_top_anim_soup.png",
			animation = {type = "vertical_frames", length = 3.0}
		},
		"xdecor_cauldron_sides.png"
	},
	sounds = default.node_sound_metal_defaults(),
	collision_box = xdecor.pixelbox(16, cauldron.cbox),
	on_rightclick = cauldron.take_soup,
	on_destruct = function(pos)
		cauldron.stop_sound(pos)
	end,
})

-- Craft items

minetest.register_craftitem("xdecor:bowl", {
	description = S("Bowl"),
	inventory_image = "xdecor_bowl.png",
	wield_image = "xdecor_bowl.png",
	groups = {food_bowl = 1, flammable = 2},
})

minetest.register_craftitem("xdecor:bowl_soup", {
	description = S("Bowl of soup"),
	inventory_image = "xdecor_bowl_soup.png",
	wield_image = "xdecor_bowl_soup.png",
	groups = {not_in_creative_inventory=1},
	stack_max = 1,
	on_use = minetest.item_eat(30, "xdecor:bowl")
})

-- Recipes

minetest.register_craft({
	output = "xdecor:bowl 3",
	recipe = {
		{"group:wood", "", "group:wood"},
		{"", "group:wood", ""}
	}
})

minetest.register_craft({
	output = "xdecor:cauldron_empty",
	recipe = {
		{"default:iron_lump", "", "default:iron_lump"},
		{"default:iron_lump", "", "default:iron_lump"},
		{"default:iron_lump", "default:iron_lump", "default:iron_lump"}
	}
})
