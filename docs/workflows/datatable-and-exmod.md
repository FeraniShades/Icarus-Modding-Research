# DataTable And EXMOD Workflow

## DataTable-First Changes

Use DataTables for scalar values, recipes, item links, stats, modifiers, AI mappings, talents, inventory definitions, processor definitions, and deployable setup when runtime behavior already exists.

1. Identify the likely table and target row.
2. Compare current vanilla data with the mod row.
3. Follow every row handle to confirm the chain.
4. Change only the required rows and fields.
5. Preserve array entries unless deletion is intentional.
6. Validate JSON syntax and inspect the changed paths.
7. Merge, verify the installed package, and test in game.

## Raw DataTable Versus EXMOD

Raw DataTable JSON commonly contains top-level `RowStruct`, `Defaults`, `GenerateEnum`, and `Rows`.

An EXMOD wrapper uses entries with `Rows[].CurrentFile` and `File_Items`. The objects inside `File_Items` are the row objects themselves; do not paste the entire raw DataTable object there.

Every EXMOD row needs a `Name`. Valid JSON can still fail compilation when a row is unnamed.

Do not rely on raw-table `Defaults` surviving inside an EXMOD. When uniform scalar values are required, write them explicitly on each affected row.

## High-Risk Fields

- Arrays, because omitted entries may be interpreted as deleted.
- Row handles, because a plausible row name may not exist.
- Variant-group rows, because replacing the group with one child can break fan-out behavior.
- Meshable and deployable references, because a broken link may silently prevent hand placement.
- Processing and inventory IDs, because the UI or inherited Blueprint may expect a specific type.

## Verification

- JSON parses.
- Every edited row has a name.
- Referenced rows exist in their target tables.
- Untouched rows and array members remain present.
- The merged and installed package contains the current version.
- The behavior is tested from a freshly created item when creation-time modifiers are involved.
