# Case Study: Chicken Nesting Box

## Goal

Turn the unfinished decorative nesting box into an egg-storage animal bed with a visible stored egg, then use that foundation for future hatching behavior.

## Verified Foundation

- Reparenting the copied box to `BP_Chicken_Coop_Base` plus the complete inventory DataTable chain produced a working one-slot, egg-filtered inventory.
- Animals continued to recognize the object as a bed.
- The dormant `Egg_GEN_VARIABLE` component is a separate hidden egg mesh and can be controlled directly.

## Proxy-Mesh Dead End

Several attempts recreated `BP_DeployableBase` inventory-proxy structures, including generated-class fields and a vanilla tag query. They serialized and loaded but never changed the egg visibility.

**Lesson:** Newly invented SCS hierarchy and class fields may still lack compiled runtime behavior that an original donor receives from Unreal Editor. Package integrity did not prove proxy traversal.

## Direct Event Path

**Verified:** A child override of `ItemAdded` could show the egg directly. `ItemRemovedVerbose` could hide it, but partial-stack movement revealed that removal events also fire when the slot remains occupied.

The correct occupancy-aware route uses the callback's first parameter as `UInventory*` and calls `GetAllItems()` directly. Treating it as `UInventoryComponent*` caused a crash when `GetInventory` was invoked.

## Durable Lessons

- Verify callback parameter types from the actual delegate, not a plausible class name.
- Inventory removal means quantity changed, not necessarily that the slot is empty.
- Reuse proven child callbacks and existing compiled components before inventing cooked component hierarchies.
- Test partial stacks, full removal, and save/reload separately.

## Open Work

- Confirm occupied visual state after save/reload.
- Add a short timer that consumes an egg safely.
- Spawn a chick only after timer and persistence behavior are proven.
- Investigate chicken attraction or sitting as a separate GOAP/animal-bed problem.
