# Animals, Tames, And Mounts

## Follow Movement

Tame follow behavior combines DataTables, behavior trees, and movement-component feel.

**Verified:** Editing the relevant `D_AISetup.MovementMapping` entries, especially `Following` and sometimes `Jog`, was more reliable than inventing a custom speed stat or forcing a behavior-tree task to Sprint.

**Known-bad:** Removing expected movement states can crash `AIcarusNPCCharacter::GetMaxSpeed`. Increasing top speed without suitable acceleration, braking, or rotation can still make a tame feel slow or overshoot badly.

## Commands And Animation

**Observed:** `D_Mounts.SupportedMovementStates` can expose command buttons such as follow, stay, wander, or lie down.

**Verified limitation:** UI availability does not guarantee matching behavior or animation. A creature may expose a command but use an unsuitable animation family or obey inconsistently.

## Saddles And Riding

Rideability is not a single flag. It may require:

- mount data and AI setup rows;
- a compatible skeleton, physics asset, and animation Blueprint;
- saddle definitions and pseudo-saddle overrides;
- seat child actors;
- attachment sockets;
- enter, ride, and exit behavior.

**Verified:** Duplicate or unexpected saddle visuals can come from `OverridePseudoSaddle`, not the mount actor itself.

**Observed:** A working mammoth mount uses a mount-specific animation Blueprint and `SaddleAttachSocketName = RigSpine2`; normal mammoth NPC animation assets are not equivalent.

## Friendly Tame Damage

**Observed:** Shared melee paths often pass through `BP_AIFunctionLibrary.SweepDamage`, `CanTargetActorBeAttacked`, and `BP_AIDamageFunctionLibrary.NPC_DealDamage`.

Several attack tasks or services contain `IgnoreFriendlyFire`, including `BTS_SweepBonesDamage`, `BTTask_Basic_JumpTo_Attack`, `BTTask_PerformAction_StrikeAttack`, and `BT_Bee`. This indicates that friendly-fire filtering can be a reusable attack-task setting rather than solely a damage-type rule.

**Observed:** Some attacks use animation notifies such as `AnimNotify_ChooseDamageSource` and `AnimNotify_SetDamageEnabled`, so behavior-tree edits may not cover every melee path.

**Known-bad:** Directly inserting cooked bytecode into `CanTargetActorBeAttacked` caused an access violation after taming a baby moa. A compiled donor path or editor-authored change is safer than freehand bytecode insertion.

**Open question:** Which existing stat or tag most safely identifies both attacker and target as owned/tamed allies without protecting hostile NPCs?
