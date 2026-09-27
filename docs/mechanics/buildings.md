# Buildings And Structural Systems

## Stability

**Verified:** Numerical stability tolerance is controlled by `data\Building\D_BuildingStability.json`. The field `MinimumUnstableStability` acts as an important failure gate. Setting it to `0`, together with high hard and anchored stability limits, allowed visually orange pieces to remain instead of collapsing.

Useful fields include:

- `BuildingTier`
- `MaxHardStability`
- `HardStabilityMaxRange`
- `MinimumUnstableStability`
- `StabilityPassMultiplier`
- `MaxAnchoredStability`
- `LowestGreenStability`
- `YellowStability`
- `HighestRedStability`

**Verified known-bad results:** Very low `StabilityPassMultiplier` values and very high failure/color thresholds caused early failure, including anchored pieces.

**Observed:** `BP_Building_Base` contains runtime support machinery around those values: `CalculateStabilityState`, `InitAnchorStability`, `PushAnchorIntoHardStability`, `ReceiveHardStability`, `RemoveHardStability`, `SetSupportedByGround`, collapse timing, color calculation, and stability audio. `BP_Building_Frame` adds lower/upper anchor references, distance to a real anchor, and soft-height calculations.

**Practical boundary:** Use the DataTable to change how much instability pieces tolerate. Investigate `BP_Building_Base` or `BP_Building_Frame` only when changing how support is discovered, propagated, removed, or displayed.

## Placement And Grid Lifecycle

**Observed from cooked exports:** Placement separates ground hits and building hits through `BP_PlayerBuildingPlacement`. Important entry points include `PerformBuildingTrace`, `ProcessGroundHit`, `ProcessBuildingHit`, and server calls for processing hits, adding buildings, and spawning new grids.

`BP_Building_Base.BuildingHitToGridRounded` sits beside class-aware helpers such as `DecideShifting`, `ShouldRotate`, directional shifts, hit-normal clamping, and `BlockLikePlacementTranslation`.

`BP_Grid_Base` exposes:

- `WorldSpaceToGridSpaceRounded`
- `WorldSpaceToGridSpaceFloored`
- `GridSpaceToWorldSpace`
- `CheckBuildingLocationFromWorldspaceRounded`
- `CanAddBuilding`
- `TryAddNewBuildingFromWorldSpace`

The base/grid size is 300 units and the base footprint is `(1,1,1)`, but child pieces add class-specific behavior. Floor uses `NewGridPlacementOffset.Z = 20`; wall and frame use `Z = -90`. Their `BlockingLines` differ. Floor, wall, and frame override rotation behavior, while beam inherits from frame.

**Observed save path:** `BP_Grid_Base` exposes serialization and record-loading functions, while `BP_IcarusGameMode` holds pending native `DatabaseBuildingGrid` records.

**Safety rule:** A preview-only transform is not a complete placement mod. Preview, server acceptance, grid registration, stability recognition, multiplayer behavior, and save/reload position must agree.

## Snow And Building Salt

**Observed:** `BP_Building_Base.SaltBuilding` applies modifier state `Building_Salted` for 30 seconds at full effectiveness. `IsBuildingSalted` checks for that state.

**Verified limitation:** Editing or adding the modifier row alone does not create a usable salting interaction. No normal caller for `SaltBuilding` was found in the inspected path.

**Open question:** Which item or interaction branch should call `SaltBuilding(Instigator)` and consume salt?
