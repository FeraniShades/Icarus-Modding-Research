# Cooked Blueprint And Asset Workflow

## Choose The Inspection Layer

- Use FModel exports for broad asset references, class names, defaults, and candidate discovery.
- Use UAssetGUI JSON for detailed export/import structure and small Blueprint surgery.
- Use a direct UAssetAPI helper only when a bounded, repeatable patch has a known donor or proven serialization pattern.

## UAssetGUI Surgery

1. Keep a clean export and an edited export.
2. Compare a working sibling or donor before changing structure.
3. Make one decisive edit per experiment.
4. Keep imports, `SuperStruct`, `SuperIndex`, templates, inherited components, generated-class references, and NameMap entries consistent.
5. Import through UAssetGUI and address every missing-name or serialization error.
6. Place both `.uasset` and `.uexp` companions in the exact cooked path.
7. Re-export or read back the result.
8. Test in game.

## Direct Helper Patches

Work from clean source assets and write to a separate mod output. Never overwrite the only original.

When transplanting components or functions, compare the donor's complete compiled footprint:

- component or function export;
- SCS node and root/child links;
- generated-class fields and loaded properties;
- `FuncMap` and `Children` registration;
- dependency arrays;
- CDO defaults;
- imports and NameMap entries.

Constructing or appending one visible export is often insufficient because Unreal Editor normally generates several connected records during compilation.

## NameMap Rule

Pre-register serializer-generated names before writing new nested properties. Missing names such as `MapProperty`, `ArrayProperty`, or a new variable name can fail only after serialization has locked the NameMap.

An existing NameMap entry may be shared by many records. Renaming that entry redirects every use of the same name index, which can intentionally swap materials, meshes, paths, or cloned asset names. Inspect the entry's uses first; adding a new unused name has no effect until another record references it.

## Two Gates

- **Package gate:** write succeeds and read-back confirms the intended structure.
- **Runtime gate:** the game boots, constructs the actor, binds delegates, performs the interaction, survives cancellation/destruction, and reloads correctly.
