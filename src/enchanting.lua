screwdriver = screwdriver or {}
local S = minetest.get_translator("xdecor")
local NS = function(s) return s end
local FS = function(...) return minetest.formspec_escape(S(...)) end
local ceil, abs, random = math.ceil, math.abs, math.random
local reg_tools = minetest.registered_tools
local reg_enchantable_tools = {}
local available_tool_enchants = {}

-- Cost in Mese crystal(s) for enchanting.
local mese_cost = 1

-- Force of the enchantments.
local enchanting = {
	uses     = 1.2,  -- Durability
	times    = 0.1,  -- Efficiency
	damages  = 1,    -- Sharpness
}

local function to_percent(orig_value, final_value)
	return abs(ceil(((final_value - orig_value) / orig_value) * 100))
end

function enchanting:get_tooltip(enchant, orig_caps, fleshy)
	local bonus = {durable = 0, efficiency = 0, damages = 0}

	if orig_caps then
		bonus.durable = to_percent(orig_caps.uses, orig_caps.uses * enchanting.uses)
		local sum_caps_times = 0
		for i=1, #orig_caps.times do
			sum_caps_times = sum_caps_times + orig_caps.times[i]
		end
		local average_caps_time = sum_caps_times / #orig_caps.times
		bonus.efficiency = to_percent(average_caps_time, average_caps_time -
					      enchanting.times)
	end

	if fleshy then
		bonus.damages = to_percent(fleshy, fleshy + enchanting.damages)
	end

	local specs = {
		durable = {"#00baff", bonus.durable},
		fast    = {"#74ff49", bonus.efficiency},
		sharp   = {"#ffff00", bonus.damages},
	}

	local enchant_loc = {
		fast = S("Efficiency"),
		durable = S("Durability"),
		sharp = S("Sharpness"),
	}

	if minetest.colorize then
		--~ Tooltip in format "<enchantment name> (+<bonus>%)", e.g. "Efficiency (+5%)"
		return minetest.colorize(specs[enchant][1], S("@1 (+@2%)", enchant_loc[enchant], specs[enchant][2]))
	else
		return S("@1 (+@2%", enchant_loc[enchant], specs[enchant][2])
	end
end

local enchant_buttons = {
	fast = "image_button[3.6,0.67;4.75,0.85;bg_btn.png;fast;"..FS("Efficiency").."]",
	durable = "image_button[3.6,1.65;4.75,1.05;bg_btn.png;durable;"..FS("Durability").."]",
	sharp = "image_button[3.6,2.8;4.75,0.85;bg_btn.png;sharp;"..FS("Sharpness").."]",
}

function enchanting.formspec(pos, enchants)
	local meta = minetest.get_meta(pos)
	local formspec = [[
			size[9,8.6;]
			no_prepend[]
			bgcolor[#080808BB;true]
			listcolors[#00000069;#5A5A5A;#141318;#30434C;#FFF]
			background9[0,0;9,9;ench_ui.png;6]
			list[context;tool;0.9,2.9;1,1;]
			list[context;mese;2,2.9;1,1;]
			list[current_player;main;0.55,4.5;8,4;]
			listring[current_player;main]
			listring[context;tool]
			listring[current_player;main]
			listring[context;mese]
			image[2,2.9;1,1;mese_layout.png]
			]]
			.."tooltip[sharp;"..FS("Your weapon inflicts more damage").."]"
			.."tooltip[durable;"..FS("Your tool lasts longer").."]"
			.."tooltip[fast;"..FS("Your tool digs faster").."]"
			..default.gui_slots .. default.get_hotbar_bg(0.55, 4.5)

	if enchants then
		for e=1, #enchants do
			formspec = formspec .. enchant_buttons[enchants[e]]
		end
	end
	meta:set_string("formspec", formspec)
end

function enchanting.on_put(pos, listname, _, stack)
	if listname == "tool" then
		local stackname = stack:get_name()
		local enchants = available_tool_enchants[stackname]
		if enchants then
			enchanting.formspec(pos, enchants)
		end
	end
end

function enchanting.fields(pos, _, fields, sender)
	if not next(fields) or fields.quit then return end
	local inv = minetest.get_meta(pos):get_inventory()
	local tool = inv:get_stack("tool", 1)
	local mese = inv:get_stack("mese", 1)
	local orig_wear = tool:get_wear()
	local mod, name = tool:get_name():match("(.*):(.*)")
	local enchanted_tool = (mod or "") .. ":enchanted_" .. (name or "") .. "_" .. next(fields)

	if mese:get_count() >= mese_cost and reg_tools[enchanted_tool] then
		minetest.sound_play("xdecor_enchanting", {
			to_player = sender:get_player_name(),
			gain = 0.8
		})

		tool:replace(enchanted_tool)
		tool:add_wear(orig_wear)
		mese:take_item(mese_cost)
		inv:set_stack("mese", 1, mese)
		inv:set_stack("tool", 1, tool)
	end
end

function enchanting.dig(pos)
	local inv = minetest.get_meta(pos):get_inventory()
	return inv:is_empty("tool") and inv:is_empty("mese")
end

function enchanting.blast(pos)
	local drops = xdecor.get_inventory_drops(pos, {"tool", "mese"})
	minetest.remove_node(pos)
	return drops
end

local function allowed(tool)
	if not tool then
		return false
	end
	if reg_enchantable_tools[tool] then
		return true
	else
		return false
	end
end

function enchanting.put(_, listname, _, stack)
	local stackname = stack:get_name()
	if listname == "mese" and (stackname == "default:mese_crystal" or
			stackname == "imese:industrial_mese_crystal") then
		return stack:get_count()
	elseif listname == "tool" and allowed(stackname) then
		return 1
	end

	return 0
end

function enchanting.on_take(pos, listname)
	if listname == "tool" then
		enchanting.formspec(pos)
	end
end

function enchanting.construct(pos)
	local meta = minetest.get_meta(pos)
	meta:set_string("infotext", S("Enchantment Table"))
	enchanting.formspec(pos)

	local inv = meta:get_inventory()
	inv:set_size("tool", 1)
	inv:set_size("mese", 1)

	minetest.add_entity({x = pos.x, y = pos.y + 0.85, z = pos.z}, "xdecor:book_open")
	local timer = minetest.get_node_timer(pos)
	timer:start(0.5)
end

function enchanting.destruct(pos)
	for _, obj in pairs(minetest.get_objects_inside_radius(pos, 0.9)) do
		if obj and obj:get_luaentity() and
				obj:get_luaentity().name == "xdecor:book_open" then
			obj:remove()
			break
		end
	end
end

function enchanting.timer(pos)
	local minp = {x = pos.x - 2, y = pos.y,     z = pos.z - 2}
	local maxp = {x = pos.x + 2, y = pos.y + 1, z = pos.z + 2}

	local bookshelves = minetest.find_nodes_in_area(minp, maxp, "default:bookshelf")
	if #bookshelves == 0 then
		return true
	end

	local bookshelf_pos = bookshelves[random(1, #bookshelves)]
	local x = pos.x - bookshelf_pos.x
	local y = bookshelf_pos.y - pos.y
	local z = pos.z - bookshelf_pos.z

	if tostring(x .. z):find(2) then
		minetest.add_particle({
			pos = bookshelf_pos,
			velocity = {x = x, y = 2 - y, z = z},
			acceleration = {x = 0, y = -2.2, z = 0},
			expirationtime = 1,
			size = 1.5,
			glow = 5,
			texture = "xdecor_glyph" .. random(1,18) .. ".png"
		})
	end

	return true
end

xdecor.register("enchantment_table", {
	description = S("Enchantment Table"),
	_tt_help = S("Enchant your tools with mese crystals"),
	tiles = {
		"xdecor_enchantment_top.png",  "xdecor_enchantment_bottom.png",
		"xdecor_enchantment_side.png", "xdecor_enchantment_side.png",
		"xdecor_enchantment_side.png", "xdecor_enchantment_side.png"
	},
	groups = {cracky = 1, level = 1},
	is_ground_content = false,
	light_source = 6,
	sounds = default.node_sound_stone_defaults(),
	on_rotate = screwdriver.rotate_simple,
	can_dig = enchanting.dig,
	on_blast = enchanting.blast,
	on_timer = enchanting.timer,
	on_construct = enchanting.construct,
	on_destruct = enchanting.destruct,
	on_receive_fields = enchanting.fields,
	on_metadata_inventory_put = enchanting.on_put,
	on_metadata_inventory_take = enchanting.on_take,
	allow_metadata_inventory_put = enchanting.put,
	allow_metadata_inventory_move = function()
		return 0
	end,
})

minetest.register_entity("xdecor:book_open", {
	initial_properties = {
		visual = "sprite",
		visual_size = {x=0.75, y=0.75},
		collisionbox = {0,0,0,0,0,0},
		pointable = false,
		physical = false,
		textures = {"xdecor_book_open.png"},
		static_save = false,
	},
})

minetest.register_lbm({
	label = "recreate book entity",
	name = "xdecor:create_book_entity",
	nodenames = {"xdecor:enchantment_table"},
	run_at_every_load = true,
	action = function(pos, node)
		local objs = minetest.get_objects_inside_radius(pos, 0.9)

		for _, obj in ipairs(objs) do
			local e = obj:get_luaentity()
			if e and e.name == "xdecor:book_open" then
				return
			end
		end

		minetest.add_entity({x = pos.x, y = pos.y + 0.85, z = pos.z}, "xdecor:book_open")
	end,
})

function enchanting:register_tool(original_tool_name, def)
	local original_tool = reg_tools[original_tool_name]
	if not original_tool then
		minetest.log("error", "[xdecor] Called enchanting:register_tool for non-existing tool: "..original_too_name)
		return
	end
	local original_toolcaps = original_tool.tool_capabilities
	if not original_toolcaps then
		minetest.log("error", "[xdecor] Called enchanting:register_tool for tool without tool_capabilities: "..original_too_name)
		return
	end
	local original_damage_groups = original_toolcaps.damage_groups
	local original_groupcaps = original_toolcaps.groupcaps
	local original_basename = original_tool_name:match(".*:(.*)")
	local toolitem = ItemStack(original_tool_name)
	local original_desc = toolitem:get_short_description() or original_tool_name
	for _, enchant in ipairs(def.enchants) do
		local groupcaps = table.copy(original_groupcaps)
		local fleshy = original_damage_groups.fleshy
		local full_punch_interval = original_toolcaps.full_punch_interval
		local max_drop_level = original_toolcaps.max_drop_level
		local dig_group = def.dig_group

		if enchant == "durable" then
			groupcaps[dig_group].uses = ceil(original_groupcaps[dig_group].uses *
						     enchanting.uses)
		elseif enchant == "fast" then
			for i, time in pairs(original_groupcaps[dig_group].times) do
				groupcaps[dig_group].times[i] = time - enchanting.times
			end
		elseif enchant == "sharp" then
			fleshy = fleshy + enchanting.damages
		else
			minetest.log("error", "[xdecor] Called enchanting:register_tool with unsupported enchant: "..tostring(enchant))
			return
		end

		local arg1 = original_desc
		local arg2 = self:get_tooltip(enchant, original_groupcaps[dig_group], fleshy)
		local enchantedTool = original_tool.mod_origin .. ":enchanted_" .. original_basename .. "_" .. enchant

		local invimg = original_tool.inventory_image
		if invimg == nil or invimg == "" then
			invimg = "no_texture.png"
		else
			invimg = "("..invimg.. ")^[colorize:violet:50"
		end
		local wieldimg = original_tool.wield_image
		if wieldimg == nil or wieldimg == "" then
			wieldimg = invimg
		end
		minetest.register_tool(":" .. enchantedTool, {
			--~ Enchanted tool description, e.g. "Enchanted Diamond Sword". @1 is the original tool name, @2 is the enchantment text, e.g. "Durability (+20%)"
			description = S("Enchanted @1\n@2", arg1, arg2),
			--~ Enchanted tool description, e.g. "Enchanted Diamond Sword"
			short_description = S("Enchanted @1", arg1),
			inventory_image = invimg,
			wield_image = wieldimg,
			groups = {not_in_creative_inventory = 1},
			tool_capabilities = {
				groupcaps = groupcaps, damage_groups = {fleshy = fleshy},
				full_punch_interval = full_punch_interval,
				max_drop_level = max_drop_level
			}
		})
		if minetest.get_modpath("toolranks") then
			toolranks.add_tool(enchantedTool)
		end
	end
	available_tool_enchants[original_tool_name] = table.copy(def.enchants)
	reg_enchantable_tools[original_tool_name] = true
end

-- Register enchantments for default tools
local materials = {"steel", "bronze", "mese", "diamond"}
local tooltypes = {
	{ "axe", { "durable", "fast" }, "choppy" },
	{ "pick", { "durable", "fast" }, "cracky" },
	{ "shovel", { "durable", "fast" }, "crumbly" },
	{ "sword", { "sharp" }, nil },
}
for t=1, #tooltypes do
for m=1, #materials do
	local tooltype = tooltypes[t][1]
	local enchants = tooltypes[t][2]
	local dig_group = tooltypes[t][3]
	local material = materials[m]
	enchanting:register_tool("default:"..tooltype.."_"..material, {
		enchants = enchants,
		dig_group = dig_group,
	})
end
end

-- Recipes

minetest.register_craft({
	output = "xdecor:enchantment_table",
	recipe = {
		{"", "default:book", ""},
		{"default:diamond", "default:obsidian", "default:diamond"},
		{"default:obsidian", "default:obsidian", "default:obsidian"}
	}
})
