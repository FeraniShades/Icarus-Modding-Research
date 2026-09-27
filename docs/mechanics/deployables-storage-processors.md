# Deployables, Storage, And Processors

## The Deployable Chain

A placed item commonly depends on this chain:

```text
D_ItemsStatic
  -> deployable or variant row
  -> D_DeployableSetup
  -> placed actor Blueprint
  -> inherited behavior and components
```

Storage and processing add further links:

- `Traits/D_Inventory`
- `Inventory/D_InventoryInfo`
- `D_TagQueries` or slot templates
- `Traits/D_Processing`
- `D_RecipeSets`
- `D_ProcessorRecipes`

**Verified:** A hover prompt or alteration panel proves only that some interaction wiring exists. It does not prove that the object has a valid inventory, processor, recipe set, or UI connection.

## Storage Conversion

The proven decorative-container pattern uses `BP_DeployableContainerBase`, preserves the original placed mesh override, clears an inherited skeletal-mesh override where needed, and completes the item/trait/inventory chain.

For an approachable end-to-end procedure, see [Turn a decorative deployable into storage](../recipes/decorative-item-to-storage.md).

**Verified:** Changing only the Blueprint parent can produce a container-shaped actor with no slots. Missing `Traits/D_Inventory` or the item-level `Inventory` row handle can produce an interaction prompt and alteration bonus without an inventory panel.

**Verified:** Slot validation controls what may enter an inventory, but it does not normally decide whether the inventory UI opens.

**Verified:** Adding an otherwise unused word to the asset NameMap does not create container behavior. Container behavior comes from the actual parent, template, component, and DataTable references that use those names. Renaming an existing NameMap entry can still redirect every record using that name index, which is useful for material, mesh, path, and cloned-asset swaps.

## Processor Conversion

The proven no-fuel processor foundation uses `BP_ProcessorBase`, `UMG_Processor`, an inventory compatible with the processor UI, `Traits/D_Processing`, and the correct `DefaultRecipeSet`.

**Verified:** A processing UI can open with working storage but show no recipes when the processing row points at the wrong recipe set.

**Verified:** Recipe tier and energy behavior are separate. A custom processing row can borrow a Tier 4 recipe set while keeping `RequiresEnergy = false` for a non-electric actor.

## Animated Processors

**Verified:** `BP_DeployableBase.OnProcessorStateUpdated(bool bIsActive)` is the appropriate processing-state callback for start/stop animation. Existing decoration interaction logic should not compete for the interact key.

The successful spinning-wheel pattern:

1. Let `BP_ProcessorBase` own initialization and interaction.
2. Keep the wheel's existing animation helper.
3. Override the processor-state callback.
4. Call the parent callback.
5. Feed the active state into the existing animation logic.

**Known-bad:** Preserving decorative BeginPlay and interaction registrations prevented inherited processor initialization. Appending freehand cooked exports also produced serialization and runtime failures.

## Placement Failure Diagnostic

When an item crafts but will not enter the player's hand or show a ghost preview, check `D_ItemsStatic.Meshable` early. The referenced row must exist in `D_Meshable` and provide a valid `EquipHandMesh`.

In Homestead Expanded, plausible names such as `Mesh_Generic` were absent. Restoring vanilla `Mesh_Generic_Crafting` restored placement without removing storage behavior.

## Resource-Network Devices

**Verified:** The Homestead well can combine an interactable internal reservoir, passive water generation, network storage/output, and bottle filling. These are separate responsibilities even when the player experiences them as one device.

The working design retained the reservoir interaction and the network-storage flow, used a custom low-rate water generator, and restricted the visible inventory to bottle slots. Removing the inherited fuel/ice inventory panel did not remove bottle filling or network supply.

**Research rule:** When adapting a network device, trace production, internal storage, player interaction, container slots, and network input/output independently before removing inherited components or rows.
