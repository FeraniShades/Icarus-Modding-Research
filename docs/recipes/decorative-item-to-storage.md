# Turn A Decorative Deployable Into Storage

This recipe is based on the verified Honey Pot, Cheese, Hanging Meat, and Vintage Jar conversions from Homestead Expanded.

## What This Recipe Changes

A decorative placed object becomes an ordinary interactive container while retaining its original visible mesh and variant footprint. An optional slot filter can limit the container to themed items such as honey, cheese, meat, or jarred goods.

The conversion has two halves:

1. DataTables define that the item owns an inventory and what that inventory accepts.
2. The placed Blueprint inherits the container interaction behavior that opens the inventory UI.

Completing only one half produces a convincing but incomplete result.

## Before Editing

1. Copy the clean `.uasset` and `.uexp` files into a working or backup folder.
2. Export the decorative Blueprint to JSON with UAssetGUI.
3. Export a working, structurally similar container as a donor. `BP_AlienFossil_Pottery01` was a useful small static-mesh reference; `BP_DeployableContainerBase` is the behavior parent.
4. Compare at least two decorative variants before assuming they are identical.
5. Test one variant before converting the whole family.

Do not copy numeric import or export indexes from this guide. They are local references whose values depend on each asset.

## Part One: Complete The DataTable Chain

Choose one consistent inventory row name, such as `Honey_Pot`, and connect all three layers.

### 1. Item Row

In `D_ItemsStatic`, update the placed item's row so it:

- points `Inventory.RowName` at the intended inventory trait row;
- uses an interactable suitable for deployables rather than `Deployable_NoInteract`;
- includes the generated tag `Traits.Inventory`;
- includes `Item.Deployable.Storage` when matching the normal storage pattern.

Keep the original deployable handle and other unrelated item values unless the design requires a change.

### 2. Inventory Trait

In `Traits/D_Inventory`, add or reuse the matching row. It must point to the intended row in `Inventory/D_InventoryInfo`.

This layer is easy to overlook. `D_InventoryInfo` by itself does not make the item own an inventory.

### 3. Inventory Information

In `Inventory/D_InventoryInfo`, add or reuse the inventory definition. For a simple container, verify:

- `InventoryID.Value` matches a normal general container pattern;
- `StartingSlots` is the intended base capacity;
- `SlotTemplate.RowName` is empty for unrestricted diagnostic testing, or points to a valid filter after the container works.

Alterations can grant extra slots at creation time, so the in-game total may be larger than `StartingSlots`.

### 4. Optional Item Filter

Use a valid slot template or `D_TagQueries` row to restrict accepted items. Add this after the inventory opens successfully. A slot filter normally controls what can enter the inventory; it does not make the inventory UI appear.

### 5. Preserve Variant Routing

Keep `Traits/D_Deployable` and `D_DeployableSetup` routing each cosmetic variant to its corresponding child Blueprint and preview mesh. Storage behavior can be shared while each variant retains its own appearance and footprint.

## Part Two: Give The Blueprint Container Behavior

The child Blueprint must inherit from `BP_DeployableContainerBase_C`, not only display an interaction prompt.

In the UAssetGUI JSON conversion:

1. Add or reuse imports for the `BP_DeployableContainerBase` package, generated class, and class default object.
2. Point both generated-class inheritance fields, `SuperStruct` and `SuperIndex`, at `BP_DeployableContainerBase_C`.
3. Point the child class default object's `TemplateIndex` at `Default__BP_DeployableContainerBase_C`.
4. Keep the class dependencies and inherited component templates consistent with the new parent.
5. Preserve the decorative Blueprint's existing `DeployableSM` override. This is what keeps the original static mesh.
6. If the inherited container skeletal mesh appears as a crate, add a child `DeployableSK` override whose `SkeletalMesh` value is null or `0`, following a known-good donor such as the pottery container.
7. Ensure every newly used property, variable, class, and package name exists in `NameMap` before import.

Changing only `SuperIndex` is not sufficient. The Cheese test showed an interact prompt and alteration panel, but no container behavior, until `SuperStruct` also pointed at the container parent.

## What NameMap Does And Does Not Do

The NameMap is the asset's indexed name ledger. Adding `DeployableSK` or `SkeletalMesh` lets UAssetGUI serialize records that refer to those names.

Renaming an existing, actively referenced NameMap entry can change every record using that shared index. This is a useful shortcut for replacing materials, meshes, package paths, and cloned asset names. It can also change more references than intended, so inspect all uses first. See [Change materials, textures, and mesh references](materials-textures-and-meshes.md).

Adding a name alone does not create a component, change inheritance, or grant storage behavior. Renaming a `D_DeployableBase`-looking string in the NameMap is not a safe parent conversion. The corresponding imports, class references, templates, handlers, dependencies, and defaults must agree.

An error such as `Attempt to serialize dummy FName 'DeployableSK'` means the edited structure refers to a name that was never registered. Add the exact missing name to `NameMap`, then retry the import.

## Import And Test

1. Import the edited JSON into a clean copied `.uasset` with UAssetGUI.
2. Keep the matching `.uexp` beside it when the asset uses one.
3. Re-export or inspect the saved asset to confirm the intended parent, template, mesh overrides, and NameMap entries survived.
4. Merge or package the mod and confirm the edited asset and all three DataTable links reached the installed output.
5. Craft a new copy of the object for the first test. Creation-time alteration bonuses may not be applied retroactively to old objects.
6. Test placement preview, visible mesh, interaction, inventory capacity, item transfer, slot rejection, pickup/replacement, save/reload, and every cosmetic variant.

## Symptom Guide

| Result | Most useful next check |
| --- | --- |
| Interaction prompt appears, but pressing interact does nothing | Verify both `SuperStruct` and `SuperIndex`, the parent class import, and inherited container initialization. |
| Player inventory or alterations appear, but no device inventory | Verify `D_ItemsStatic.Inventory`, `Traits/D_Inventory`, and `D_InventoryInfo` as a complete chain. |
| A large crate appears instead of the decoration | The container parent's skeletal mesh is still winning; preserve `DeployableSM` and add a known-good blank `DeployableSK` override. |
| UAssetGUI reports a dummy FName | Add the exact property, variable, class, or package name to `NameMap`; do not guess a substitute spelling. |
| Inventory opens but rejects everything | Temporarily remove the slot template, then repair the referenced tag query or allowed item tags. |
| Capacity differs from `StartingSlots` | Test a newly crafted object and account for alteration or talent bonuses. |
| One variant has the wrong mesh or footprint | Restore that variant's own static-mesh override and setup routing; do not assume every sister asset uses the same mesh suffix. |
| Game crashes during startup | Revert to the last importable parent-swap asset and inspect newly added exports, handlers, dependencies, and component cycles. |

## Bulk Variants

Automation becomes reasonable only after one variant works and sibling comparison shows a regular structure. A converter should validate, rather than merely replace text:

- expected generated-class and class-default-object names;
- the original `DeployableSM` handler and mesh;
- both container-parent fields;
- the blank `DeployableSK` export and handler;
- required imports and NameMap entries;
- matching `Exports` and `DependsMap` counts;
- output names and variant-specific mesh mappings.

Keep the known-good first variant as the template and make the helper fail loudly when a sister differs.

## Evidence

**Verified:** This pattern produced working filtered inventories for three Honey Pots, five Cheese variants, six Hanging Meat variants, and seven Vintage Jars while preserving their original visuals.

**Observed:** Existing old objects may lack alterations applied when the object became storage. Newly crafted copies received the expected bonus.
