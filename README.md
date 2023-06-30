## X-Decor-libre [`xdecor`] ##

[![ContentDB](https://content.minetest.net/packages/Wuzzy/xdecor/shields/downloads/)](https://content.minetest.net/packages/Wuzzy/xdecor/)

X-Decor-libre is a libre Minetest mod which adds various decorative blocks
as well as simple gimmicks.

This is a libre version (free software, free media) of the X-Decor mod for Minetest.
It is the same as X-Decor, except with all the non-free files replaced and with
bugfixes. There are no new features.

## Special nodes

Most blocks in this mod are purely decorative, but there are also many special
blocks with special features:

* Workbench: Storage, crafting, cutting and repairing
    * Storage: 16 item slots for item storage
    * Craft: 3×3 crafting grid
    * Cut: Put a full cube-shaped block to create new shapes
    * Repair: Put a damaged tool and a hammer and wait for it to be repaired
* Enchanting table: Upgrade your tools with mese crystals
* Ender Chest: Interdimensional inventory that is the same no matter
               where you put the ender chest
* Mailbox: Lets you receive items from other players
* Item Frame: You can place an item into it to show it off
* Trampoline: Jump on it to bounce off. No fall damage
* Cauldron: For cooking soups
    * Recipe: Pour water in, light a fire below it and throw
      in some food items. Collect the soup with a bowl
* Chessboard: Play Chess against another player or the computer
* Lever: Pull the lever to activate doors next to it
* Pressure Plate: Step on it to activate doors next to it

### X-Decor-libre vs X-Decor

X-Decor is a popular mod in Minetest but it is (as the time of writing this text)
non-free software, there are various files under proprietary licenses.

The purpose of this repository is to provide the community a fully-free fork of
X-Decor with clearly documented licenses and to fix bugs. No new features are
planned.

#### List of changes
The following bugs of X-Decor (as of 30/06/2023) are fixed:

* Changed packed ice recipe to avoid recipe collision with Ethereal
* Changed prison door recipe colliding with Minetest Game's Iron Bar Door
* Beehives no longer show that the bees are busy when they're not
* Fixed incorrect/incomplete node sounds
* Renamed "Empty Shelf" to "Plain Shelf"
* Fix poorly placed buttons in enchantment screen
* Fix broken texture of cut Permafrost with Moss nodes
* Fix awkward lantern rotation
* Lanterns can no longer attach to sides
* Fix item stacking issues of curtains
* Made several strings translatable
* Translation updates

#### List of replaced files

This is the list of non-free files in the original X-Decor mod
(as of commit 8b614b3513f2719d5975c883180c011cb7428c8d)
that X-Decor-libre replaces:

* `textures/xdecor_candle_hanging.png`
* `textures/xdecor_radio_back.png`
* `textures/xdecor_radio_front.png`
* `textures/xdecor_radio_side.png`
* `textures/xdecor_radio_top.png`
* `textures/xdecor_rooster.png`
* `textures/xdecor_speaker_back.png`
* `textures/xdecor_speaker_front.png`
* `textures/xdecor_speaker_side.png`
* `textures/xdecor_speaker_top.png`
* `sounds/xdecor_enchanting.ogg`

(see `LICENSE` file for licensing).

### Technical information
X-Decor-libre is a fork of X-Decor, from <https://github.com/minetest-mods/xdecor>,
forked at Git commit ID 8b614b3513f2719d5975c883180c011cb7428c8d.

Note the technical mod name of X-Decor-libre is the same as for X-Decor: `xdecor`.
This is because this mod is meant to be a drop-in-replacement.

The original readme of X-Decor can be found at `OLD_README.md`.
