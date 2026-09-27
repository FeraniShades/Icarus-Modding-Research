# Environment, Heat, Fire, Foliage, And UI

## Heat And Auras

**Verified:** `D_Thermal` can provide heat directly. Important fields include inner/outer radius, temperature change, falloff, and `bStartsEnabled`.

**Verified:** A thermal row without `bStartsEnabled = true` produced no heat in the tested bed conversion.

**Verified:** Aura effects may require explicit Blueprint grant/remove logic in addition to `D_GrantedAuras`, `D_ModifierStates`, and stats. Creating a custom stat does nothing unless some runtime path reads it.

## Fire And Lava

Direct lava damage, burning damage over time, ignition, flammability, and persistent `OnFire` state are separate paths.

**Verified:** `BaseFireDamageResistanceWhileInLava_% = 100` stopped direct lava damage but did not stop the actor from catching fire.

**Open question:** Is broad fire immunity safest at the flammability check, the ignition call, or modifier application?

## Cosmetic Foliage

Icarus uses several visual layers: procedural `LandscapeGrassType`, FLOD/FISM instances, harvestable actors, materials, and generated map placements.

**Verified:** Setting `GrassDensity` to zero in cooked `LGT_*` assets removed broad procedural ground foliage in tested biomes.

**Known-bad:** Nulling a FLOD static mesh crashed in `UStaticMesh::GetBounds`. Generated map edits were unstable, and material/truffle experiments did not remove all Dangerous Horizons ground plants.

## UI Layer Map

**Verified:** `/Game/UI/Popups/UMG_TooltipInworld` controls the common in-world hover card used by deployables, loose ground items, windows/doors, resources, and carcasses.

**Verified:** `/Game/UI/HUD/UMG_FocusedItemInfo` controls the lower-right display for the held item. It is separate from the in-world tooltip.

Likely separate families include inventory item popups, true buildable repair overlays, bed/coziness projections, mount/tame panels, crafting UI, and inventory context menus.

**Research rule:** Use a reversible, obvious visual test to identify the live widget, then restore it before shipping. Widget defaults can be overridden or hidden by runtime `Update...` functions, so a layout edit that serializes correctly may still remain invisible.
