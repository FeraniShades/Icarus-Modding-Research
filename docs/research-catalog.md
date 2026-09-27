# Research Catalog

This catalog shows where accumulated knowledge lives and how mature each subject currently is.

| Subject | Strongest evidence | Main page | Current state |
| --- | --- | --- | --- |
| Building stability thresholds | In-game tests and DataTable comparison | [Buildings](mechanics/buildings.md) | Verified working mod pattern |
| Building placement and grids | Cooked exports and community research | [Buildings](mechanics/buildings.md) | Strong system map; graph/native details open |
| Building snow and salting | Blueprint inspection | [Buildings](mechanics/buildings.md) | Modifier path observed; interaction missing |
| Decorative storage conversion | Repeated Homestead tests | [Practical recipe](recipes/decorative-item-to-storage.md) and [deployable mechanics](mechanics/deployables-storage-processors.md) | Verified repeatable pattern |
| Materials, textures, and mesh swaps | Landing Pad and Homestead Silo walkthroughs | [Practical recipe and illustrated PDFs](recipes/materials-textures-and-meshes.md) | Verified authored workflows |
| Crafting processor conversion | Butter churn and spinning wheel tests | [Deployables](mechanics/deployables-storage-processors.md) | Verified, including animation callback |
| Inventory filtering | Honey, jars, cheese, meat, nesting box | [Deployables](mechanics/deployables-storage-processors.md) | Verified tag-query pattern |
| Inventory-driven visuals | Nesting box event tests | [Nesting box](case-studies/chicken-nesting-box.md) | Verified add/remove and occupancy rules |
| Resource-network devices | Homestead well tests | [Deployables](mechanics/deployables-storage-processors.md) | Verified combined storage/network behavior |
| Heat and granted auras | Heated animal bed tests | [Environment](mechanics/environment-and-ui.md) | Verified thermal and BP-trigger distinction |
| Lava, fire, and ignition | Resistance tests and BP references | [Environment](mechanics/environment-and-ui.md) | Direct lava protection verified; ignition open |
| Procedural foliage | Cooked LGT tests | [Environment](mechanics/environment-and-ui.md) | Broad density removal verified; other layers open |
| UI ownership | Screenshot-backed widget tests | [Environment](mechanics/environment-and-ui.md) | Several UI families positively identified |
| Tame follow movement | AISetup and in-game tests | [Animals](mechanics/animals-tames-mounts.md) | Reliable DataTable tuning established |
| Mount commands and saddles | DataTable/BP comparisons and mount work | [Animals](mechanics/animals-tames-mounts.md) | Partial command and full conversion lessons |
| Friendly tame damage | BP/BT export analysis and failed patch | [Animals](mechanics/animals-tames-mounts.md) | Intercept candidates mapped; safe patch open |
| Damage types and filtering | Blueprint and task exports | [Combat](mechanics/combat-damage-projectiles.md) | File map established |
| Projectile mining | Ballistic comparison | [Combat](mechanics/combat-damage-projectiles.md) | Drill-arrow baseline known; grenade route open |
| DLC ownership safety | DataTable evidence and community confirmation | [DLC safety](workflows/dlc-safety.md) | Gate locations established; audit tool available |
| DataPak relationships | Local full-table index | [DataTable workflow](workflows/datatable-and-exmod.md) | Builder/search tools working locally |
| Cooked asset editing | UAssetGUI and UAssetAPI experiments | [Cooked assets](workflows/cooked-assets.md) | Package/runtime verification model established |
| Weekly update tracking | Changelog and snapshot tooling | [Testing and release](workflows/testing-and-release.md) | Repeatable workflow available |

## Categories We Intentionally Keep Separate

- **Mechanics** explains how a system appears to work.
- **Workflows** explains how to investigate or modify it safely.
- **Case studies** preserve the experimental path and mistakes.
- **Tools** automate local research without publishing game data.
- **Showcase** explains what finished projects do for players.
- **Sources** records where evidence and ideas originated.

This separation lets one discovery appear in several useful contexts without copying the full experiment log everywhere.
