-- Tile definitions for cut nodes of glass nodes:
-- * Woodframed Glass (this mod)
-- * Glass (Minetest Game)
-- * Obsidian Glass (Minetest Game)
-- This is done so the glass nodes still look nice
-- when cut.
-- If we would only use the base glass tile, most
-- cut nodes look horrible because there are no
-- clear contours.

local template_suffixes = {	
	stair = {
		"_split.png",
		".png",
		"_stairside.png^[transformFX",
		"_stairside.png",
		".png",
		"_split.png",
	},
	stair_inner = {
		"_stairside.png^[transformR270",
		".png",
		"_stairside.png^[transformFX",
		".png",
		".png",
		"_stairside.png",
	},
	stair_outer = {
		"_stairside.png^[transformR90",
		".png",
		"_outer_stairside.png",
		"_stairside.png",
		"_stairside.png^[transformR90",
		"_outer_stairside.png",
	},
	halfstair = {
		"_cube.png",
		".png",
		"_stairside.png^[transformFX",
		"_stairside.png",
		"_split.png^[transformR90",
		"_cube.png",
	},
	slab = {
		".png",
		".png",
		"_split.png",
	},
	cube = { "_cube.png" },
	thinstair = { "_split.png" },
	micropanel = { "_split.png" },
	panel = {
		"_split.png",
		"_split.png",
		"_cube.png",
		"_cube.png",
		"_split.png",
	},
}

local generate_tilenames = function(prefix, default_texture)
	if not default_texture then
		default_texture = prefix
	end
	local cuts = {}
	for t, tiles in pairs(template_suffixes) do
		cuts[t] = {}
		for i=1, #tiles do
			if tiles[i] == ".png" then
				cuts[t][i] = default_texture .. tiles[i]
			else
				cuts[t][i] = prefix .. tiles[i]
			end
		end
	end
	return cuts
end

xdecor.glasscuts = {
	["xdecor:woodframed_glass"] = generate_tilenames("xdecor_woodframed_glass"),
	["default:glass"] = generate_tilenames("stairs_glass", "default_glass"),
	["default:obsidian_glass"] = generate_tilenames("stairs_obsidian_glass", "default_obsidian_glass"),
}
