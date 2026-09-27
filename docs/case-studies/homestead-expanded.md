# Case Study: Homestead Expanded

Homestead Expanded turns decorative DLC objects into useful storage and processing furniture while preserving their original appearance and intended theme.

## Verified Storage Conversions

- Honey pots store honey-related goods.
- Vintage jars store jarred foods and jam.
- Cheese variants store cheese and can provide preservation behavior.
- Hanging meat variants store meats and can provide preservation behavior.

The repeatable pattern combined a container-capable Blueprint parent, the original mesh override, inventory trait wiring, inventory-info rows, item-level inventory handles, and tag-query slot validation.

## Verified Processor Conversions

- Butter churn variants craft butter and store output.
- The spinning wheel processes fabric recipes and animates during processing.
- The sewing machine can expose a Tier 4 recipe set through a custom non-electric processing row.

## Important Failures That Became Rules

- Parent conversion without the complete inventory chain produced an interactable object with no inventory grid.
- Changing only one parent index left container behavior incomplete; both class inheritance references needed to agree.
- A wrong recipe set produced a complete processor UI with an empty recipe panel.
- Preserving decorative interaction and lifecycle registrations blocked inherited processor setup.
- Missing or guessed `D_Meshable` rows prevented hand/ghost placement even though crafting and placed Blueprint files looked correct.
- Creation-time alteration bonuses may not appear on objects crafted before the mod changed their role.

## Design Principle

Each object family should keep its own visual Blueprint and footprint. Shared conversion helpers are useful only after sibling variants have been compared and a safe template family is established.
