-- Register enchanted tools.

-- Number of uses for the (normal) steel hoe from Minetest Game (as of 01/12/20224)
-- This is technically redundant because we cannot access that number
-- directly, but it's unlikely to change in future because Minetest Game is
-- unlikely to change.
local STEEL_HOE_USES = 500

-- Modifier of the steel hoe uses for the enchanted steel hoe
local STEEL_HOE_USES_MODIFIER = 3

-- Register enchantments for default tools from Minetest Game
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
	xdecor.register_enchantable_tool("default:"..tooltype.."_"..material, {
		enchants = enchants,
		dig_group = dig_group,
	})
end
end

-- Register enchanted steel hoe (more durability)
if farming.register_hoe then
	local percent = math.round((STEEL_HOE_USES_MODIFIER - 1) * 100)
	local hitem = ItemStack("farming:hoe_steel")
	local hdesc = hitem:get_short_description() or "farming:hoe_steel"
	local ehdesc, ehsdesc = xdecor.enchant_description(hdesc, "durable", percent)
	farming.register_hoe(":farming:enchanted_hoe_steel_durable", {
		description = ehdesc,
		short_description = ehsdesc,
		inventory_image = xdecor.enchant_texture("farming_tool_steelhoe.png"),
		max_uses = STEEL_HOE_USES * STEEL_HOE_USES_MODIFIER,
		groups = {hoe = 1, not_in_creative_inventory = 1}
	})

	xdecor.register_custom_enchantable_tool("farming:hoe_steel", {
		durable = "farming:enchanted_hoe_steel_durable",
	})
end
