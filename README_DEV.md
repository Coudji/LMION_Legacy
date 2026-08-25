# Let Me In... Or Not — Development

## Current modules

The Build 42 project contains four internal Mod IDs:

- `LMION_Core`
- `LMION_Build`
- `LMION_Pickup`
- `LMION_Debug`

Build, Pickup and Debug depend on Core. Build and Pickup remain independent of each other, and normal gameplay modules do not depend on Debug.

A future real repair feature should remain a separate gameplay module depending on Core. Core owns only the low-level logical-health primitives.

## Current development state

The simple 1x1 door path is stable enough to serve as the baseline. Current work has moved into multi-tile large gates.

Validated 1x1 behavior includes:

- construction recipes for the Test Zone door set;
- dedicated Pickup item identities;
- frame-aware replacement where appropriate;
- current-health preservation through pickup/replacement;
- LMION logical max-health preservation through pickup/replacement;
- world-door durability adoption;
- alias-safe engine-facing material application;
- 1x1 fence gates and sliding doors using the shared Pickup path.

The six large-gate families are now split into independent construction leaves:

- Large Farm Gate;
- Large Wrought Iron Gate;
- Large Hardened Wooden Gate;
- Large Chain-Link Gate;
- Large Scrap Metal Gate;
- Large Wooden Gate.

Each is exposed as a left and right leaf. All six were runtime-tested in both N and W orientations and opening synchronization works through vanilla `DoubleDoor` behavior.

The Test Zone now contains 83 explicit entries.

## Large-gate split implementation

For vanilla `Base.DoubleDoor`, `Base.DoubleWireGate` and `Base.DoubleFenceGate`, Build keeps the vanilla entity as the left leaf and introduces a separate right-leaf entity.

At `OnGameBoot`, Build:

1. validates the exact original eight closed SpriteConfig tile names;
2. resets only the vanilla SpriteConfig component with `PreReload()`;
3. reloads that component with the four left-leaf tiles;
4. verifies the resulting four-tile ownership set.

This avoids duplicate scripted-sprite ownership while preserving vanilla physical `DoubleDoor` behavior supplied by the engine/tile definitions.

For LMION-owned large gates, the previous full-gate identity has been replaced by explicit `Left` and `Right` entities.

Runtime validation established that correctly placed leaves synchronize opening even when the two sides have different GameEntity identities. Vanilla grouping is based on `DoubleDoor` indices and geometry, not family/entity equality.

The vanilla Destroy action intentionally still destroys the complete linked portal. LMION does not override that behavior at this stage.

## Large-gate Pickup prototype

The active Pickup prototype targets `Large Chain-Link Gate` first.

Validated:

- targeting either of the two squares of a leaf identifies the correct leaf;
- targeting the non-pivot/inner segment also works;
- only the targeted leaf is removed, not the full four-segment portal;
- pickup creates two inventory parcels for the leaf: `(1/2)` and `(2/2)`;
- French parcel names are working;
- replacement consumes both parcels and recreates both physical segments in one action;
- both left and right leaves place correctly in their original orientation and after N/W rotation;
- after both segments are restored, vanilla synchronized opening works again;
- placement/pickup preview is clean in both orientations for both leaves.

The preview requires a specialized visual path because `DoubleWireGate` is not authored like ordinary two-tile furniture. One SpriteGrid member already contains the complete visible leaf while the other is only a partial technical visual member. The complete visual member is asymmetric: left uses Part1, right uses Part2. The logical SpriteGrid still retains both members.

A non-blocking engine warning has also been observed during multi-square pickup:

```text
GameEntityFactory.TransferComponents> Cannot transfer components for multi-square objects
```

Pickup/replacement still functions despite the warning. Do not build a workaround until a concrete state-loss bug is proven.

Full research and failed hypotheses are recorded in `Research/Moveables/LargeGateLeaves.md`.

## Localization status

Build has a French `Recipes.json` covering the construction entries. B42 recipe localization lookup normalizes `DisplayName` by removing spaces before looking up the recipe key, so LMION keys follow that form.

Large-gate display naming uses:

```text
English: <base> - Left Leaf / Right Leaf
French:  <base> - vantail gauche / vantail droit
```

The broader French construction-name pass has been added, but final in-game confirmation of every entry can happen progressively rather than blocking mechanical work.

## Development workflow

Enable `LMION_Debug` while developing. Use the in-game LMION Lua reload for edits to already-loaded Lua files when practical.

A full game/server restart is required after:

- `media/scripts` changes;
- adding new GameEntity/item definitions;
- adding brand-new Lua files when the active loader will not discover them;
- load-order or metadata changes;
- stale monkey-patch closures that cannot be safely replaced.

A Lua reload can update an already-loaded file, but an active cursor/action instance may still hold old state. If a hot reload appears to do nothing, re-enter the mode first; if behavior still remains stale, restart the game before concluding the code path is wrong.

Avoid speculative Java calls in production or Debug. Debug Mode can surface Java/Kahlua runtime exceptions even inside `pcall`.

Game-loaded LMION Lua/script files must remain free of `--` line comments. Keep rationale in the repository documentation.

Detailed lifecycle rationale is recorded in `Research/Engine/LoadLifecycle.md`.

## Engine research conclusions currently relied upon

### DoubleDoor grouping

`IsoDoor.getDoubleDoorIndex()` maps a double-door member to logical indices 1..4. Open sprites 5..8 map back to the same logical members.

The physical/logical leaf mapping is orientation-dependent for the validated Chain-Link sprites; do not reduce it to fixed `{1,2}` / `{3,4}` pairs. See `Research/Moveables/LargeGateLeaves.md`.

`IsoDoor.getDoubleDoorObject()` locates linked members by geometry/orientation/index and does not require matching GameEntity identity, sprite family or materials.

This is the basis for independent LMION construction/pickup leaves while retaining vanilla synchronization.

### SpriteConfig lifecycle

`SpriteConfigScript.allTileNames` is built from actual declared face tiles. Runtime ownership reassignment must use `SpriteConfigScript:PreReload()` before reloading a reduced component body. Reusing a component without clearing it can leave stale tile ownership and cause duplicate-sprite failures.

Do not call `GameEntityScript:PreReload()` just to reset SpriteConfig because it clears all component scripts.

Detailed evidence and failed ownership prototypes are in `Research/Engine/SpriteConfigLifecycle.md`.

### Logical durability

LMION keeps the authoritative gameplay max in:

```text
lmionDoorMaxHealth
```

because B42.20.3 exposes `IsoDoor:setHealth()` but no public `IsoDoor:setMaxHealth()`. Current health may exceed the engine max and LMION repair logic must use the logical max.

Detailed API evidence, migration rules and addon implications are in `Research/Engine/DoorHealth.md`.

### Engine property aliases

Engine sprite/object properties are alias-backed. Unknown values can silently resolve to alias id `0` rather than preserving the requested string. LMION therefore verifies exact readback after engine-facing writes and restores the old property on mismatch.

Detailed bytecode evidence is in `Research/Engine/PropertyAliases.md`.

## Inspector / Debug

The LMION Inspector remains focused on facts useful to door systems: class, square, sprite/entity identity, orientation/open state, health, logical max, locks, materials and multi-door grouping/link data.

The deterministic Test Zone is an explicit fixture. Do not replace it with runtime scanning/discovery heuristics.

## Documentation workflow

The documentation intentionally separates current state from technical archaeology:

- `CURRENT_STATE.md` — active handoff and validated/unvalidated state;
- `ARCHITECTURE.md` — module ownership and hard structural rules;
- `LMION_Design_Notes.md` — durable gameplay/design decisions;
- `README_DEV.md` — practical workflow and high-level implementation status;
- `Research/` — detailed engine evidence, lifecycle constraints, failed approaches and addon-facing contracts.

Do not delete a research explanation merely because the final implementation becomes simple. Expensive engine discoveries are part of the project's long-term technical material and may later feed a public wiki.

## Next gameplay milestone

1. Validate per-segment health/logical-max preservation through the working Chain-Link leaf pickup cycle.
2. Generalize the proven two-parcel leaf model to the other five large-gate families, checking each family's sprite/index/visual authoring rather than assuming the Chain-Link mapping.
3. Move to garage-door transport as a separate multi-tile system rather than forcing the DoubleDoor model onto it.
4. Build the real Repair gameplay module after multi-tile transport and material/craft rules are sufficiently stable.
