# Change Materials, Textures, And Mesh References

Ferani's illustrated walkthroughs cover two related jobs:

- [Landing Pad material variant walkthrough](walkthroughs/landing-pad-material-variant-walkthrough.pdf) follows a functional deployable through DataTables, Blueprint cloning, mesh and material discovery, and the final child-parent correction needed to retain behavior.
- [Texture replacement walkthrough](walkthroughs/texture-replacement-walkthrough.pdf) follows a Homestead Silo through static meshes, material instances, texture maps, image editing, Unreal Engine 4.27.2 cooking, and renamed texture references.

Both PDFs are the original authored documents and include screenshots throughout.

## Choose An Override Strategy

### Replace The Vanilla Asset

Keep the original asset name and cooked path. The modded file overrides the game's version wherever that asset is used.

This is simple, but its scope may be wider than expected because every object referencing the vanilla asset receives the replacement.

### Create A New Asset

Give the cooked asset a new name and path, then update every mesh, material, Blueprint, or DataTable reference that should use it.

This takes more wiring but limits the visual change to the intended object or variant.

## NameMap Reference Swaps

NameMap entries are indexed strings used by records elsewhere in a cooked asset. When an existing material, texture, mesh, package path, class name, or asset name is stored through one NameMap entry, editing that entry changes every record in the asset that points at the same name index.

That makes NameMap editing a powerful way to:

- rename a cloned Blueprint and its generated-class names;
- redirect an existing material or texture reference;
- point a Blueprint at a renamed mesh;
- update every occurrence that intentionally shares one name entry.

It also creates a broad-change risk. Before saving, check how often the entry is used and whether every occurrence should change. Some references that look identical may occupy separate NameMap entries, while unrelated records may deliberately share one entry.

Adding a new word to the NameMap does not create a component, property, import, inheritance relationship, or behavior. It merely makes that name available for records to use. Renaming an existing, actively referenced entry can change behavior or appearance because the connected records now resolve a different name.

## Safe Procedure

1. Preserve a clean `.uasset` and every companion `.uexp` or `.ubulk` file.
2. Use FModel or another asset browser to trace the visible object from Blueprint or mesh to material instance and texture.
3. Decide whether the change should override the vanilla asset globally or use a new name for a bounded variant.
4. If using a new asset, recreate the correct cooked path and update both short names and full package paths where they appear.
5. Keep texture dimensions and map roles consistent. Albedo, normal, and packed RMA maps may use different resolutions.
6. Cook replacement textures with Unreal Engine 4.27.2 and keep all generated companion files.
7. In UAssetGUI, inspect every occurrence before changing a shared NameMap entry.
8. Save, recalculate nodes when names or exports changed, and read the asset back before packaging.
9. Test every object that used the original shared material or mesh, not only the intended target.

## Landing Pad Lesson

The dark landing-pad material and mesh swap worked visually, but a sibling Blueprint with a new name was not accepted by the gameplay check that expected the player landing pad. Converting the new Blueprint into a child of the functional player pad preserved the behavior while allowing visual overrides.

**Verified:** A successful visual clone does not prove that gameplay recognizes the clone as the same functional type.
