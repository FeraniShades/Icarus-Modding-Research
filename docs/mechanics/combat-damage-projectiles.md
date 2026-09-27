# Combat, Damage, And Projectiles

## Damage Types And Filtering

Damage category and target filtering are related but separate concerns.

**Observed:** `BTTask_DamageActor` exposes a clean `DamageType` to `DealFlatDamage` path using `EIcarusDamageType::Pure`. `DamageType` and `CF_Damage` provide useful enum and debug references.

**Observed:** `BP_BallisticBehaviour_FilteredDamage` and `BP_BallisticBehaviour_NoDamage` are focused projectile references when researching whether a hit should apply damage.

**Research rule:** Do not assume that changing the damage type creates friendly-fire immunity. Inspect the attack task, targetability filter, animation damage window, and final damage function.

## Projectile Mining

**Observed:** Drill-arrow mining uses `BP_BallisticBehaviour_Mining` with mining stats such as voxel permission, mining radius, resource rewards, and reward percentage.

**Verified limitation:** Normal frag payload damage does not imply voxel mining. Combining an explosive payload with mining behavior is a hypothesis, not a proven area-mining grenade.

**Open question:** Can a safe thrown area-mining tool be assembled from an existing payload/behavior donor, or does it require custom Blueprint logic?

## A Useful Trace Order

When investigating unexpected damage:

1. Identify the behavior tree task, ballistic behavior, or animation notify that opens the damage window.
2. Find target filtering such as `IgnoreFriendlyFire` or `CanTargetActorBeAttacked`.
3. Follow the call into the shared damage library.
4. Record the damage type and instigator/causer values.
5. Test direct hits, sweep hits, area hits, owned allies, hostile NPCs, players, and structures separately.
