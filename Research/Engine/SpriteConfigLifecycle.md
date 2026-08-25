# SpriteConfig ownership and targeted runtime reload

Status: **B42.20.3 bytecode verified + runtime validated + Git-history recovered**

This note explains why LMION's split large-gate construction path edits the existing vanilla `SpriteConfig` at `OnGameBoot` instead of simply declaring overlapping left/right entities or clearing a list opportunistically.

## The problem: one sprite cannot be owned twice casually

Build 42 `GameEntityScript` / `SpriteConfig` processing tracks which scripted entity owns each declared tile. LMION needs some vanilla four-segment large gates to become two independently craftable two-segment leaves while keeping vanilla physical DoubleDoor behavior.

The naive idea was to declare new left/right entities that reused the same vanilla closed sprites. That produced duplicate scripted-sprite ownership/startup failures.

Historical evidence: commit `9d21df0` is literally `Remove crashing split wire gate prototype`; it removes the separate `DoubleWireGateLeft`/`DoubleWireGateRight` prototype that declared the vanilla sprite rows again.

## What `allTileNames` actually represents

B42.20.3 `SpriteConfigScript` contains a mutable `allTileNames` list. Bytecode for script checking walks every declared face/layer/row/tile and appends the tile's declared name to that list.

So for LMION's purposes:

```text
SpriteConfig declared face tiles
        -> checkScripts()
        -> allTileNames
        -> scripted-sprite ownership/lookup downstream
```

This is why TileDefinitions and SpriteConfig ownership must not be conflated. TileDefinitions may still provide physical properties and state behavior for a sprite, but they are not the source LMION relies on for `SpriteConfigScript.allTileNames`.

## Failed approach: clear only `allTileNames`

An intermediate prototype tried to find vanilla `DoubleWireGate` and simply call:

```text
spriteConfig:getAllTileNames():clear()
```

at `OnGameBoot` to release ownership. That experiment appears in commit `727be52` (`Release vanilla chain-link gate sprite ownership`).

This was too shallow. `allTileNames` is derived state; the `SpriteConfig` still retained its declared faces/layers/rows and other component state. Clearing only the list did not constitute a clean, targeted redefinition of the component.

The surviving architecture does not use this shortcut.

## Why `SpriteConfigScript:PreReload()` is the correct reset

B42.20.3 bytecode for `SpriteConfigScript.PreReload()` shows that it resets the SpriteConfig component itself:

- every face slot is cleared;
- `cornerSprite` is cleared;
- `isSingleFace`, `isMultiTile`, `isValid`, `isProp` are reset;
- `allTileNames` is cleared;
- health/skill-base-health and several other SpriteConfig fields are reset;
- previous-stage data is cleared.

This gives LMION a clean SpriteConfig component that can be loaded again with only the intended leaf definition.

## Why **not** `GameEntityScript:PreReload()`

B42.20.3 `GameEntityScript.PreReload()` is much broader. Its bytecode simply clears the entity's entire `componentScripts` list.

Therefore using it merely to change SpriteConfig could discard unrelated components such as:

```text
UiConfig
CraftRecipe
other entity components
```

LMION deliberately calls `SpriteConfigScript:PreReload()` on the component being changed, not `GameEntityScript:PreReload()` on the whole entity.

## Validated vanilla-leaf rewrite

The robust prototype appears in commit `40a8443` (`Reload vanilla chain-link gate as left half`) and was later generalized.

The pattern is:

```text
1. resolve the exact vanilla GameEntityScript
2. resolve its SpriteConfig component
3. verify the expected original closed-tile set exactly
4. SpriteConfigScript:PreReload()
5. reload the same vanilla entity with a reduced SpriteConfig body
6. resolve the resulting SpriteConfig again
7. verify the new owned tile set exactly
8. let a separate LMION/right-leaf entity own the complementary sprites
```

For `DoubleWireGate`, the prototype explicitly required all eight original closed sprites before touching the component, then required exactly the four expected left-leaf sprites after reload.

## Why validate both before and after

This is defensive compatibility behavior.

### Before

If another mod, a future PZ build, or an earlier LMION operation has already changed the vanilla component, blindly reloading it could corrupt an unexpected configuration.

LMION therefore refuses the operation when the starting ownership is not the exact configuration the rewrite was designed for.

### After

A successful Lua call does not prove the resulting script state is what LMION intended. Post-validation confirms that the reduced component now owns exactly the expected sprites and no stale members survived.

For addon authors, these checks are important: they are not noisy debug assertions that can safely be deleted.

## Why keep the vanilla entity as one leaf

For the three vanilla large-gate families currently split by Build, LMION keeps the existing vanilla entity identity for one leaf and creates a separate identity for the other.

This minimizes the amount of vanilla script topology replaced while still making each leaf independently craftable. Runtime research later proved that DoubleDoor opening synchronization does not require both leaves to share the same GameEntity identity; logical `DoubleDoor` indices and geometry are sufficient.

## Lifecycle: why this runs at `OnGameBoot`

The operation needs the parsed `ScriptManager`/`GameEntityScript` objects to exist, because LMION is mutating the already-created vanilla component rather than replacing source files on disk.

The validated LMION hook runs at `Events.OnGameBoot`. At that point the vanilla scripted entities are available for targeted rewriting, while the operation still happens as part of boot-time setup rather than after ordinary gameplay has begun creating objects from the old topology.

This is a validated LMION lifecycle choice, not a claim that `OnGameBoot` is the only theoretically possible event in every PZ build. If the engine's script lifecycle changes, this timing must be revalidated.

## Old-save warning is a separate concern

During the split-gate work, old saves containing objects serialized under the previous full-gate SpriteConfig could report:

```text
Invalid SpriteConfig object! scripted object = DoubleWireGate
```

A new save did not reproduce that warning, including with a naturally placed vanilla chain-link gate after travel/load/open testing.

Current evidence therefore treats this as an old-object migration issue, not a reason to undo the new construction topology.

## Addon contract

Addon authors interacting with these entities should assume:

- LMION may mutate the vanilla large-gate `SpriteConfig` during `OnGameBoot`;
- after LMION's boot rewrite, the vanilla entity's `allTileNames` no longer represents the original full four-member portal;
- do not re-declare the same sprites under another scripted entity without coordinating ownership;
- do not call `GameEntityScript:PreReload()` merely to adjust SpriteConfig;
- if replacing/wrapping LMION's rewrite, preserve the exact before/after validation behavior;
- code that needs final post-LMION ownership should run after the LMION boot rewrite, not assume raw vanilla topology forever.

The exact set of vanilla entities that LMION rewrites may grow, so addons should prefer intentional LMION APIs/profile data over hardcoding an assumption that only `DoubleWireGate` is affected.

## Revalidation triggers

Recheck this research when:

- Project Zomboid changes `SpriteConfigScript`, `SpriteConfigManager`, or entity reload semantics;
- a new PZ build changes the vanilla tile sets;
- LMION exposes a formal addon hook around the ownership rewrite;
- another popular mod needs to co-own/rewrite the same vanilla entities;
- old-save migration becomes an explicit supported feature.
