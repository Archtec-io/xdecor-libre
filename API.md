# API for X-Decor-libre

X-Decor-libre is mostly self-contained but it allows for limited extension with
a simple API. Not that extensibility is not the main goal of this mod.

The function documentation can be found in the respective source code files
under the header "--[[ API FUNCTIONS ]]".

These are the features:

## Add custom tool enchantments

You can register tools to be able to be enchanted at the enchanting table.

See `src/enchanting.lua` for details.

## Add custom hammers

You can add a custom hammer for repairing tools at the workbench,
using custom stats.

See `src/workbench.lua` for details.

## Add cut nodes

You can register "cut" node variants of an existing node which can
be created at the workbench.
This will add thin stairs, half stairs, panels, microcubes, etc.

See `src/workbench.lua` for details.

## Cauldron compatibility

The cauldron needs to interact with various items and nodes to
work properly. It uses ingredients and bowls for soup, and
fire nodes to get heated.

If your mod adds fire or hot nodes, bowls or food, this section
is relevant for you.

### Soup ingredients

The cauldron soup accepts a variety of food items as ingredients for the soup.
It uses a heuristic to determine which items it accepts.

It scans the part of the technical itemname after the colon for certain keywords
like 'apple', 'meat', 'potato' etc (for the full list, see `ingredients_list`
in `src/cooking.lua`).

This heuristic may sometimes fail and recognize strange items as ingredient.
To explicitly mark any item as a soup ingredient for xdecor, add the group
`xdecor_soup_ingredient = 1` to it. To explicitly tell xdecor that an item
is NOT a soup ingredient, use `xdecor_soup_ingredient = -1` instead.
The `-1` should only be used if actually necessary.

### Heater nodes

Cauldrons need a fire below to get heated. All nodes with the group `fire`
or `xdecor_cauldron_heater=1` will heat up the cauldron. You can use the latter
group if adding the `fire` group would create problems.

### Bowls

Players can use the `xdecor:bowl` item to collect soup from a cauldron.
But other mods also have their own bowls which may not be recognized by
X-Decor-libre.

The following items are recognized as bowls that can collect soup from
the cauldron:

* Items with group `xdecor_soup_bowl=1` (recommended)
* `farming:bowl` (hardcoded)
* `x_farming:bowl` (hardcoded)

If you want to make your bowl compatible with the cauldron, add the group
`xdecor_soup_bowl=1` to it. **Only use this for empty bowls!**

**Please test your bowl!**

When any such bowl is used at the cauldron, it turns into `xdecor:bowl_soup`.
If the soup is eaten, it turns into `xdecor:bowl`.
