local rope = {}
local S = minetest.get_translator("xdecor")

local ropesounds = default.node_sound_leaves_defaults()

-- Code by Mirko K. (modified by Temperest, Wulfsdad, kilbith and Wuzzy) (License: GPL).
function rope.place(itemstack, placer, pointed_thing)
	if pointed_thing.type == "node" then
		-- Use pointed node's on_rightclick function first, if present
		if placer and not placer:get_player_control().sneak then
			local node = minetest.get_node(pointed_thing.under)
			if minetest.registered_nodes[node.name] and minetest.registered_nodes[node.name].on_rightclick then
				return minetest.registered_nodes[node.name].on_rightclick(pointed_thing.under, node, placer, itemstack) or itemstack
			end
		end
		local pos = pointed_thing.above
		-- Check protection
		if minetest.is_protected(pos, placer:get_player_name()) and
				not minetest.check_player_privs(placer, "protection_bypass") then
			minetest.record_protection_violation(pos, placer:get_player_name())
			return itemstack
		end

		local oldnode = minetest.get_node(pos)
		local stackname = itemstack:get_name()

		local start_pos = table.copy(pos)
		local ropes_placed = false
		while oldnode.name == "air" and not itemstack:is_empty() do
			local newnode = {name = stackname, param1 = 0}
			minetest.set_node(pos, newnode)
			if not minetest.is_creative_enabled(placer:get_player_name()) then
				itemstack:take_item()
			end
			pos.y = pos.y - 1
			oldnode = minetest.get_node(pos)
		end
		-- Play placement sound manually
		if rope_placed then
			minetest.sound_play(ropesounds.place, {pos=start_pos}, true)
		end
	end

	return itemstack
end

function rope.remove(pos, oldnode, digger, rope_name)
	local num = 0
	local below = {x = pos.x, y = pos.y, z = pos.z}
	local digger_inv = digger:get_inventory()

	while minetest.get_node(below).name == rope_name do
		minetest.remove_node(below)
		below.y = below.y - 1
		num = num + 1
	end

	if num == 0 then return end

	-- Play dig sound manually
	minetest.sound_play(ropesounds.dug, {pos=pos}, true)

	local creative = minetest.is_creative_enabled(digger:get_player_name())
	if not creative or not digger_inv:contains_item("main", rope_name) then
		if creative then
			num = 1
		end
		local item = rope_name.." "..num
		local leftover = digger_inv:add_item("main", rope_name.." "..num)
		if not leftover:is_empty() then
			minetest.add_item(pos, leftover)
		end
	end

	return true
end

xdecor.register("rope", {
	description = S("Rope"),
	drawtype = "plantlike",
	walkable = false,
	climbable = true,
	groups = {snappy = 3, flammable = 3},
	tiles = {"xdecor_rope.png"},
	inventory_image = "xdecor_rope_inv.png",
	wield_image = "xdecor_rope_inv.png",
	selection_box = xdecor.pixelbox(8, {{3, 0, 3, 2, 8, 2}}),
	on_place = rope.place,

	on_punch = function(pos, node, puncher, pointed_thing)
		local player_name = puncher:get_player_name()

		if not minetest.is_protected(pos, player_name) or
			minetest.get_player_privs(player_name).protection_bypass then
			rope.remove(pos, node, puncher, "xdecor:rope")
		else
			minetest.record_protection_violation(pos, player_name)
		end
	end,
	sounds = ropesounds,
})

-- Recipes

minetest.register_craft({
	output = "xdecor:rope",
	recipe = {
		{"farming:string"},
		{"farming:string"},
		{"farming:string"}
	}
})
