# Case Study: Building Stability

## Goal

Allow much larger structures without ordinary stability collapse while preserving the game's building system.

## Result

**Verified:** The successful approach was a narrow `D_BuildingStability` edit. No `BP_Building_Base` surgery was required.

A promising near-infinite profile used:

```text
BuildingTier = 8
MaxHardStability = 1000000
HardStabilityMaxRange = 1000000
MinimumUnstableStability = 0
StabilityPassMultiplier = 1
MaxAnchoredStability = 1000000
LowestGreenStability = 0
YellowStability = 0
HighestRedStability = 0
```

This is a tested research profile, not a universal recommendation for every balance target.

## Lessons

- `MinimumUnstableStability` was more important to actual collapse than the displayed color alone.
- A very low pass multiplier did not mean “nearly no stability loss”; it caused anchored failures in testing.
- Color thresholds can be visually misleading when the collapse gate has changed.
- Clay brick rows should preserve their `NewFrontiers` feature metadata.
- The Blueprint support network should be left intact unless the design explicitly changes anchor propagation or height logic.

## Future Research

- Separate visual stability feedback from the actual failure threshold.
- Determine exactly where each DataTable field enters `CalculateStabilityState`.
- Test whether a balanced high-rise profile can raise height limits without making all materials equivalent.
