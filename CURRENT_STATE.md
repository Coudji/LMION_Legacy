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
- the deterministic Test Zone spawns 83/83 entries after the six full-gate entries became twelve leaf entries.

The vanilla Destroy menu still destroys the complete linked portal. This is confirmed behavior and is currently left unchanged.

## Why the split works

Java research established that `DoubleDoor` runtime grouping is based on logical index, orientation and hardcoded geometry.

`IsoDoor.getDoubleDoorIndex()` reads the member identity encoded by the sprite. `IsoDoor.getDoubleDoorObject()` then resolves linked members from orientation/open state, geometry and requested logical index. Matching GameEntity identity is not required.

For the validated `DoubleWireGate` closed sprites, logical indices are orientation-dependent:

```text
LEFT LEAF
N: Part1=1, Part2=2
W: Part1=4, Part2=3

RIGHT LEAF
N: Part1=3, Part2=4
W: Part1=2, Part2=1
```

This mapping is required for rotated replacement to reconstruct linked vanilla DoubleDoor members rather than merely two adjacent `IsoDoor` objects.

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

Build includes French construction localization through `Recipes.json`.

Important B42 behavior: recipe translation lookup removes spaces from the `DisplayName` before key lookup. LMION translation keys therefore use the normalized no-space form.

Paired naming convention:

```text
English: <base> - Left Leaf / Right Leaf
French:  <base> - vantail gauche / vantail droit
```

## Large Chain-Link Gate Pickup prototype — validated closed-leaf cycle

Pickup work currently targets one family only: `Large Chain-Link Gate` / `DoubleWireGate`.

### Validated pickup behavior

- all four closed physical portal squares are targetable in Moveables mode;
- targeting either segment of one leaf resolves the correct leaf;
- only the selected two-segment leaf is removed;
- the other leaf remains in the world;
- Pickup produces two localized inventory parcels:

```text
Grand portail grillagé - vantail <gauche/droit> (1/2)
Grand portail grillagé - vantail <gauche/droit> (2/2)
```

Each parcel currently weighs 12.

### Runtime SpriteGrid bridge

The original DoubleWireGate sprites are not authored with the SpriteGrid metadata that generic Moveables expects. LMION therefore creates runtime `IsoSpriteGrid` objects for left/right leaves in N and W orientations and attaches them to the relevant global `IsoSprite` instances.

The grids must be installed twice:

1. at Lua load for hot reloads;
2. again on `Events.OnLoadedTileDefinitions` because normal tile-definition loading can rebuild sprite state after the first install.

The second install is required for reliable cold-start behavior.

The SpriteGrid provides vanilla Moveables grouping, two-square targeting/footprint and inventory multisprite behavior. Pickup itself still creates two parcels by temporarily treating each physical source segment as non-multisprite while calling vanilla internal pickup code.

### Validated replacement behavior

Replacement requires both parcels and places both physical `IsoDoor` segments in one action.

LMION does **not** rely on generic vanilla multisprite placement for the final reconstruction. That path failed after rotation because ordinary SpriteGrid anchor assumptions do not match DoubleDoor's orientation-dependent logical indices.

The current placement path:

- resolves leaf + facing;
- requires both parcel item types;
- computes Part1/Part2 target squares;
- validates each square through vanilla `canPlaceMoveableInternal()`;
- calls vanilla `placeMoveableInternal()` separately for each physical segment while temporarily disabling multisprite recursion;
- removes both parcel items;
- leaves opening/link synchronization to vanilla DoubleDoor mechanics.

Validated runtime result:

- left leaf: original orientation works;
- left leaf: N/W rotation works;
- right leaf: original orientation works;
- right leaf: N/W rotation works;
- both parcels are consumed in one placement action;
- restored leaves resume vanilla synchronized opening.

### Validated preview behavior

Generic vanilla `renderSpriteGrid()` is not visually correct for these sprites.

A controlled diagnostic established that one member of each leaf already contains the complete visible leaf artwork, while the other member is only a technical/partial visual sprite. Drawing both members duplicates part of the gate.

The complete visual member is asymmetric between the two leaves:

```text
left leaf  -> Part1
right leaf -> Part2
```

LMION therefore keeps both members in the logical SpriteGrid but overrides the large-gate preview renderer to:

- draw both footprint squares;
- draw only the configured complete visual member;
- leave all non-large-gate Moveables rendering on vanilla behavior.

This preview is now runtime-validated in both N and W orientations for both Chain-Link leaves.

### Important failed hypotheses

The following were explicitly tested and should not be rediscovered from scratch:

- installing SpriteGrid only at initial Lua load is insufficient;
- a valid SpriteGrid alone does not make generic vanilla multisprite placement correct for rotated DoubleDoor leaves;
- the duplicate preview was not caused by a second hidden cursor renderer;
- the duplicate preview was not fixed by changing ghost alpha;
- separated member rendering showed that one member already contains the complete visual leaf, explaining the duplication.

Full technical rationale is recorded in `LMION_Design_Notes.md`.

### Non-blocking warning

During multi-square pickup the engine can log:

```text
GameEntityFactory.TransferComponents> Cannot transfer components for multi-square objects.
```

No concrete functional failure has been observed from it in the validated closed-leaf cycle. Do not add speculative workarounds unless state loss is reproduced.

### Current scope guardrail

Large-gate Pickup currently supports only the Chain-Link prototype. Do not generalize blindly to all six families. Reuse the validated architecture, but inspect each family's logical-index geometry and sprite artwork before assuming the same preview `visualPartIndex` pattern.

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
- During active prototype development, work directly on `main`; use a temporary branch only when it materially helps rollback. Do not create PRs unless explicitly requested.

## Documentation checkpoint rule

Update docs after meaningful milestones, not every commit:

- `CURRENT_STATE.md` for active handoff and validated/unvalidated state;
- `ARCHITECTURE.md` for module ownership/guardrails;
- `LMION_Design_Notes.md` for durable design/research conclusions;
- `README_DEV.md` for workflow and high-level status.

## Next intended milestones

1. Confirm per-segment health / logical-max preservation through the now-working Chain-Link leaf pickup cycle.
2. Generalize the validated two-parcel leaf architecture to the other five large-gate families, checking each family's sprite artwork and index geometry.
3. Research garage-door pickup/replacement separately.
4. Build the real Repair gameplay module after multi-tile transport and material/craft rules are stable enough.

## Useful recent milestone commits

- `e87e24d` — corrected west-facing DoubleDoor logical/index geometry.
- `40f044b` — aligned explicit west-facing placement with DoubleDoor indices.
- `1409e02` — rendered only the complete visual member for the right Chain-Link leaf preview.
- `3b53e98` — applied the opposite complete visual member for the left Chain-Link leaf.
- `71adc6c` / `8701371` / `3e97186` — cleaned validated Moveables/preview/placement prototype code.
- `bc65e2f` — documented the validated runtime SpriteGrid and explicit-placement architecture.
