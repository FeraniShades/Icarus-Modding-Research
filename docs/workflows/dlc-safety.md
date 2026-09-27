# DLC Safety

Mods should not bypass paid-content ownership requirements.

## The Important Distinction

**Observed and community-confirmed:** `Metadata.RequiredFeatureLevel` is not an account ownership check. It is associated with game build or feature-level availability.

Real DLC/account gates use row handles into `D_DLCPackageData`. Common forms include:

- `RequiredFlags` in tables such as `D_Talents` and `D_ProspectList`.
- `SessionRequirement` in `D_ProcessorRecipes`.
- Other explicitly named package requirement fields where present.

Keeping `RequiredFeatureLevel` may still be useful metadata, but it must not be treated as protection against unlocking DLC content.

## Review Checklist

- Identify every DLC-exclusive item, recipe, talent, reward, deployable, creature, and world requirement touched by the mod.
- Trace acquisition paths, not only item definitions.
- Confirm the appropriate `D_DLCPackageData` row is required at the point the player unlocks, purchases, crafts, receives, or starts the content.
- Review cross-DLC recipes and decide which owned feature is the real gatekeeper.
- State DLC requirements prominently in the mod description.
- Test with an account or environment that does not own the DLC when possible.
- Run `tools/Audit-IcarusDlcSafety.ps1` and investigate warnings rather than treating the tool as proof by itself.

## Publication Rule

This project documents how to preserve ownership checks. It does not publish instructions whose purpose is to remove or evade them.
