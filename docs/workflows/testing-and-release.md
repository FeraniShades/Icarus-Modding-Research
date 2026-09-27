# Testing, Merging, Packaging, And Updates

## Test Matrix

For each change, test the narrow feature and its lifecycle:

- newly created object versus an object saved before the mod;
- placement preview and final placement;
- interaction open, close, cancel, pickup, destroy, and reload;
- empty, partially occupied, and full inventory;
- single player and multiplayer when authority matters;
- mod installed alone and in the intended merged set;
- save/reload and, where appropriate, removal of the mod.

## Merge Verification

1. Confirm the source mod contains the changed files at the correct path.
2. Merge using Icarus Mod Manager.
3. Check `LastMergedMods.txt` when available.
4. Check the installed package timestamp under `Content\Paks\mods`.
5. List the package with UnrealPak when behavior suggests stale or missing files.

A correct source folder does not prove that the installed package was refreshed.

## Weekly Update Review

Icarus updates frequently. Record each relevant changelog with:

- update number and date;
- systems named by the developers;
- likely DataTables and asset families;
- mods that touch those areas;
- regression tests to rerun;
- confirmed data changes after refreshing Data.pak.

When a mod suddenly fails after an update, compare current vanilla rows before blaming the Blueprint. A renamed or missing row handle can break placement, recipes, meshes, or inventory without producing an obvious error.

## Release Hygiene

- Package only active mod files.
- Move failed attempts and backups outside the release folder.
- Remove temporary widget tests, donor assets, and diagnostic global overrides.
- Run the DLC audit.
- Verify the package listing.
- Provide requirements, conflicts, removal warnings, and a concise test list.
