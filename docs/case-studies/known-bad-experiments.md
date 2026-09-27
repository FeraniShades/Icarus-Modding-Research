# Known-Bad Experiments And Useful Dead Ends

Failed tests are retained because they narrow the search space and prevent repetition.

## Weather Vane As Lightning Rod

Changing the parent class, default references, and projection component allowed crafting and ghost preview but not final placement. Lightning-rod behavior is not a safe parent-swap graft; additional placement validation, component ownership, or DataTable wiring participates.

## Direct Friendly-Fire Bytecode

Freehand UAssetAPI bytecode insertion into `CanTargetActorBeAttacked` crashed after taming a baby moa. Future attempts should use compiled Blueprint editing or a complete donor function transplant.

## Foliage And FLOD

Nulling FLOD static meshes crashed. Generated-map counter edits were ineffective or unstable. Truffle/material experiments produced hover oddities without removing all target plants. Keep valid mesh references and prefer bounded density or culling experiments.

## Mining Grenade

Combining a frag payload with mining behavior was not established as safe. Projectile damage and voxel mining are separate responsibilities.

## Weather And Fire Assumptions

Direct lava resistance did not stop ignition. Modifier rows did not create a salting interaction. In both cases, similarly themed effects were controlled by separate runtime paths.

## Cooked Component Grafting

Adding component exports and SCS nodes can write and read back correctly while remaining invisible to the runtime actor. Generated-class properties, loaded fields, dependencies, delegate bindings, and compiled bytecode may all be required.
