# LMION — Current development state

Last updated: 2026-08-25

This file is the active handoff document for meaningful runtime validation, architecture changes and current milestones. It should not duplicate every commit.

## Project direction

LMION progressively takes ownership of door gameplay rules while leaving Project Zomboid responsible for the physical mechanics it already handles well.

Working principle:

> Vanilla defines the physical opening mechanics; LMION defines the gameplay rules.

Current LMION-owned concerns include construction, naming/localization, materials, pickup/transport, placement rules, logical durability and future repair gameplay.

Do not edit TileDefinitions for LMION runtime behavior; they remain research/reference data.

## Current modules

- `LMION_Core` — shared namespace, profiles, engine-facing property application, logical durability and low-level helpers.
- `LMION_Build` — construction recipes, construction localization and large-gate construction topology.
- `LMION_Pickup` — Moveables integration for 1x1 doors and specialized transport work for multi-tile openings.
- `LMION_Debug` — Inspector, deterministic Test Zone and Lua reload/development helpers.

Build, Pickup and Debug depend on Core. Build and Pickup remain independent of each other.

## 1x1 status

The simple 1x1 path is mechanically stable enough to serve as the baseline.

Validated behavior includes:

- construction recipes across the Test Zone set;
- dedicated Pickup item identities;
- pickup/replacement through vanilla Moveables;
- frame-aware replacement where required;
- preservation of current health;
- preservation of `lmionDoorMaxHealth`;
- world-door durability adoption;
- repair above engine max through the Core logical-max model;
- 1x1 fence-gate and sliding-door support.

`LogDoor` intentionally has no Pickup/place tools in the current profile set. Sliding doors use Crowbar pickup and Hammer placement through custom Moveables tool definitions.

## Logical max-health model

Production Lua has no useful `IsoDoor:setMaxHealth()` path. LMION stores its authoritative gameplay max in object modData:

```text
lmionDoorMaxHealth
```

Current health remains the real `IsoDoor.health` and may exceed engine max.

Core APIs include:

- `Doors.setEffectiveMaxHealth(object, value)`;
- `Doors.getEffectiveMaxHealth(object)`;
- `Doors.repairHealth(object, amount)`.

LMION-owned repair/condition logic must use the logical max rather than `IsoDoor:getMaxHealth()`.

## Large-gate construction milestone

The six current large-gate families have been split into independent left/right construction leaves:

- Large Farm Gate;
- Large Wrought Iron Gate;
- Large Hardened Wooden Gate;
- Large Chain-Link Gate;
- Large Scrap Metal Gate;
- Large Wooden Gate.

For vanilla `Base.DoubleDoor`, `Base.DoubleWireGate` and `Base.DoubleFenceGate`, LMION keeps the vanilla entity as the left leaf and adds a separate right-leaf entity.

For LMION-owned large gates, explicit `...Left` and `...Right` identities are used.

### Runtime validation

All six families were constructed and tested successfully in both N and W orientations.

Validated behavior:

- each construction entry builds only its own two-segment leaf;
- correctly assembled left/right leaves synchronize opening through vanilla logic;
- synchronization survives save/load and a full cold restart in the validated Chain-Link case;
- a naturally placed vanilla large chain-link gate in a new save loaded and opened without `Invalid SpriteConfig` warnings;
- the deterministic Test Zone now spawns 83/83 entries after the six full-gate entries became twelve leaf entries.

The vanilla Destroy menu still destroys the complete linked portal. This is confirmed behavior and is currently left unchanged.

## Why the split works

Java research established that `DoubleDoor` runtime grouping is based on logical index, orientation and hardcoded geometry.

Logical members are 1..4, with the two leaves:

```text
leaf A = 1 + 2
leaf B = 3 + 4
```

`IsoDoor.getDoubleDoorObject()` does not require matching sprite family, GameEntity identity or material profile. This is why two independently constructible leaf entities can still synchronize as one vanilla portal.

`destroyDoubleDoor` follows the linked structure, which explains why the vanilla Destroy action removes the complete portal.

## SpriteConfig split implementation

The validated Build path for vanilla large gates is:

1. verify the exact original eight closed SpriteConfig tile names;
2. call `SpriteConfigScript:PreReload()` on that component only;
3. reload the vanilla entity with a four-tile left-leaf SpriteConfig body;
4. verify the resulting four-tile set exactly;
5. let the separate right-leaf entity own the other four closed tiles.

This solved the earlier duplicate-sprite startup crash.

Current bytecode research shows that `SpriteConfigScript.allTileNames` is built from declared SpriteConfig faces. TileDefinitions can provide physical runtime properties/open-state behavior but are not treated as the direct source of that list.

Do not call `GameEntityScript:PreReload()` merely to reset SpriteConfig because it clears all component scripts.

## Old-save compatibility note

Existing saves that already contain old full `Base.DoubleWireGate` objects can emit:

```text
Invalid SpriteConfig object! scripted object = DoubleWireGate
```

A new save did not emit that warning, including after traveling to and opening a naturally placed chain-link gate. Current evidence therefore points to stale serialized old-gate instances rather than a flaw in the split architecture.

Treat old-save migration as a separate compatibility task. Do not distort the new topology merely to hide those historical instances.

## Localization status

Build now includes French construction localization through `Recipes.json`.

Important B42 behavior: recipe translation lookup removes spaces from the `DisplayName` before key lookup. LMION translation keys therefore use the normalized no-space form.

Paired naming convention:

```text
English: <base> - Left Leaf / Right Leaf
French:  <base> - vantail gauche / vantail droit
```

The broader French construction-name pass has been added. Mechanical work does not need to stop for a complete manual visual audit of every translated entry.

## Large Chain-Link Gate Pickup prototype

Pickup work has started with one family only: `Large Chain-Link Gate`.

### Validated pickup behavior

- all four closed physical portal squares are targetable in Moveables mode;
- targeting either segment of one leaf, including the non-pivot/inner segment, resolves the correct leaf;
- only the selected two-segment leaf is removed;
- the other leaf remains in the world;
- Pickup produces two localized inventory parcels:

```text
Grand portail grillagé - vantail <gauche/droit> (1/2)
Grand portail grillagé - vantail <gauche/droit> (2/2)
```

Each parcel currently weighs 12.

### Validated replacement behavior

The first prototype required placing each parcel separately. That proved segment identities and orientation data were usable, and the portal synchronized after both were placed.

The current replacement logic consumes both parcels and creates both physical segments in one placement action. Once restored, vanilla synchronized opening works correctly.

### Current unresolved issue: placement preview

The visual preview is not yet validated.

Observed progression:

- initial one-segment placement path: cursor preview showed the full two-tile leaf, but clicking placed only the selected segment;
- after changing to two-segment placement: clicking correctly places both segments, but vanilla preview showed only one segment and could visually swap segment order when changing orientation;
- the latest code hooks `ISMoveableCursor.render` and explicitly draws both canonical leaf sprites for the current orientation.

That latest render fix is currently being runtime-tested. Do not describe it as solved until the test confirms it.

Preview rendering is a presentation path separate from actual placement. Do not regress the already working two-segment placement merely to satisfy cursor visuals.

### Non-blocking warning

During multi-square pickup the engine has logged:

```text
GameEntityFactory.TransferComponents> Cannot transfer components for multi-square objects
```

No concrete functional failure has been observed from it: both parcels are created and replacement works. Do not add speculative workarounds until state loss or another real bug is reproduced.

### Current scope guardrail

Large-gate Pickup currently supports only the Chain-Link prototype. Do not generalize to all six families until the complete pickup → two parcels → one-action replacement → correct preview cycle is validated in both N and W orientations.

Open-state pickup is not yet the reference path.

## Garage doors

Garage doors remain a separate multi-tile problem.

They use a different linkage model (`garageDoorIndex`, `garage.first`, `garage.prev`, `garage.next`) rather than `DoubleDoor` logical members. Do not generalize the two-members-per-leaf model to garage doors.

## Material-property safety

Project Zomboid property values are alias-backed. Unknown strings can silently resolve to another valid alias.

Engine-facing LMION writes must:

1. preserve the previous property;
2. write the requested known value;
3. read it back;
4. keep it only if the exact requested value survived;
5. otherwise restore the previous state.

## Source/workflow guardrails

- Game-loaded LMION Lua/script files must contain no `--` line comments.
- Important rationale belongs in documentation.
- `media/scripts` changes require a full game restart.
- New Lua files, load-order changes, metadata changes and stale monkey-patch closures may require a full restart.
- Lua-only changes to already-loaded files can usually be tested with LMION reload, but active cursor/action instances may retain stale state.
- Do not use speculative Java reflection as a production solution.
- Prefer source/bytecode/runtime verification over guessed engine behavior.
- Development writes may use a feature branch and then fast-forward `main`; do not create PRs unless explicitly requested.

## Documentation checkpoint rule

Update docs after meaningful milestones, not every commit:

- `CURRENT_STATE.md` for active handoff and validated/unvalidated state;
- `ARCHITECTURE.md` for module ownership/guardrails;
- `LMION_Design_Notes.md` for durable design/research conclusions;
- `README_DEV.md` for workflow and high-level status.

## Next intended milestones

1. Confirm the latest full-leaf Chain-Link placement preview fix.
2. Retest placement from both `(1/2)` and `(2/2)` parcels in N and W orientations.
3. Confirm pickup/replacement preserves the intended per-segment health/max-health semantics.
4. Generalize the validated two-parcel leaf model to the other five large-gate families.
5. Research garage-door pickup/replacement separately.
6. Build the real Repair gameplay module after multi-tile transport and material/craft rules are stable enough.

## Useful recent milestone commits

- `be8faa780e778a14af602692ae1e779df226e5e2` — validated v2 split prototype base for vanilla DoubleWireGate.
- `c2d96aba13c9b2837c04d0dbd640a59a0de57fad` — generalized construction split to all six large-gate families and localization pass.
- `a81f130908eea2dfa7b11f41d72a8d736298b7d2` — corrected B42 recipe translation key normalization.
- `2dc64db627274e94485569a372eb5217e32804f3` — first Chain-Link leaf Pickup prototype with two parcels.
- `0e7745ccdbeb150e805ff02b41d8b6f7181c5142` — place a complete leaf from both parcels in one action.
- `ba5e6b15e5258f7f96848f487690a86268e013e5` — latest placement-preview render-path experiment under runtime validation.
