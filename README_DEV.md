# Let Me In... Or Not — Development & handoff

Last updated: 2026-08-27

This is the **single authoritative development/handoff document** for LMION. Read it at the start of a new development session, then inspect current `main` and the relevant note under `Research/`.

> **Vanilla defines the physical opening mechanics; LMION defines the gameplay rules.**

LMION should reuse Project Zomboid opening/closing, collision, synchronization, sprite-state behavior and object mechanics whenever practical. LMION owns construction, naming/localization, material rules, Pickup/transport identity, placement requirements, logical durability and future repair/access-control gameplay.

`newtiledefinitions.tiles` / TileDefinitions are research/reference data. Do not edit them as an LMION runtime solution.

## Documentation map

- `README.md` — short public project overview.
- `README_DEV.md` — this file: architecture, validated state, guardrails and next work.
- `Research/` — detailed engine evidence, reverse engineering, failed hypotheses and lifecycle constraints.
- `DOOR_CATALOG.md` / `DOOR_CATALOG_VALUES.md` — working catalog data. **Do not modify them unless the current task explicitly concerns the catalog.**

## Repository / module structure

One Workshop item contains several Build 42 Mod IDs:

```text
Contents/mods/
├── LMION_Core/
├── LMION_Build/
├── LMION_Pickup/
└── LMION_Debug/
```

Dependencies:

```text
LMION_Build   ─┐
LMION_Pickup  ─┼─> LMION_Core
LMION_Debug   ─┘
```

Build and Pickup remain independent. Gameplay modules do not depend on Debug.

### `LMION_Core`

Core owns shared gameplay primitives only:

- LMION namespace/logging/module registration;
- opening gameplay profiles;
- profile -> GameEntity/SpriteConfig mapping;
- alias-safe engine property mutation;
- shared placement/persistence helpers;
- authoritative logical max health in `modData.lmionDoorMaxHealth`;
- durability adoption for world doors;
- low-level repair capped by LMION logical max.

Core does **not** own construction UX, Pickup UX or future Repair UX.

### `LMION_Build`

Build owns construction/crafting, progression, requirements, localization and large-gate construction topology/SpriteConfig ownership split.

The three vanilla large-gate bases (`Base.DoubleDoor`, `Base.DoubleWireGate`, `Base.DoubleFenceGate`) keep vanilla ownership for the left leaf and use a separate entity for the right leaf. Runtime-derived split profiles are installed both at Lua load and `OnGameBoot` so hot reload does not lose them.

### `LMION_Pickup`

Pickup owns transport/reinstallation of passable openings:

- eligibility;
- tool/skill requirements;
- inventory/world parcel identity;
- health/logical-max preservation;
- placement rules;
- specialized multi-tile transport.

General design rule:

> **If it opens and the player can pass through it, Pickup owns its transport behavior.**

### `LMION_Debug`

Debug owns Inspector, world selection/highlighting, deterministic Test Zone, Lua reload helpers and temporary validation actions. Debug must never become a gameplay dependency.

## Current validated state

### Simple / 1x1 openings

The 1x1 path is the stable baseline.

Runtime-validated behavior includes:

- vanilla Moveables Pickup/replacement;
- frame-aware placement where required;
- open 1x1 Pickup canonicalized back to closed N/W transport identity;
- current health preservation;
- `lmionDoorMaxHealth` preservation;
- paired Left/Right doors restricted to matching DoubleDoor1/2 frame sides;
- 1x1 fence gates and sliding doors on the shared Pickup architecture;
- correct LMION transport weight after Pickup;
- inventory tooltip durability display as `PV : current / max` in French and `HP : current / max` in English.

The durability tooltip intentionally shows **no percentage**.

Current profile-specific facts:

- `LogDoor` intentionally has no Pickup/place tools;
- normal wooden and metal doors use screwdriver for both Pickup and Place (hinge unscrew/rescrew semantics);
- sliding doors and gates use Crowbar for Pickup and Hammer for placement through custom Moveables tool definitions.

The simple 1x1 transport item still visually/naming-wise behaves like a Moveable door rather than an explicitly packaged parcel. That presentation choice remains optional polish.

### Large-gate construction

Six current large-gate families are split into independent left/right construction leaves:

- Large Farm Gate;
- Large Wrought Iron Gate;
- Large Hardened Wooden Gate;
- Large Chain-Link Gate;
- Large Scrap Metal Gate;
- Large Wooden Gate.

All six were runtime-tested in N/W construction orientations. Correctly assembled leaves resume vanilla synchronized DoubleDoor opening.

### Large-gate Pickup

Design identity:

```text
one leaf = two physical IsoDoor segments = two parcels = one placement action
```

Closed-leaf transport is runtime-validated across all six current large-gate families:

- either physical segment can be targeted;
- only the selected two-segment leaf is removed;
- two parcels `(1/2)` and `(2/2)` are produced;
- **the two parcels are dropped on the ground**, vanilla-style;
- both parcels are required for replacement;
- placement can consume required parcels from player inventory and/or nearby ground;
- N/W rotation works before replacement;
- restored leaves resume synchronized opening/closing;
- each segment preserves exact current health and `lmionDoorMaxHealth`.

Current transport weight is **2 × 12 kg = 24 kg per leaf**. Weight no longer blocks placement because floor parcels are directly consumable.

Open-state large-gate Pickup has also been runtime-validated on the reference mechanism: the full four-member gate closes through vanilla before the selected leaf is removed; obstruction correctly blocks the forced close/Pickup; restored placement is closed and durability survives.

See `Research/Moveables/LargeGateLeaves.md` and `Research/Moveables/VanillaMoveablesBehavior.md`.

A non-blocking engine warning can occur during multi-square Pickup:

```text
GameEntityFactory.TransferComponents> Cannot transfer components for multi-square objects
```

No concrete state-loss bug has been reproduced from it. Do not add a workaround without a reproduced failure.

### Garage-door Pickup

Garage doors use their own three-member topology, separate from DoubleDoor large gates.

Supported families:

- Industrial Garage Door;
- Green Garage Door;
- White Garage Door;
- Grey Garage Door;
- Rolling Garage Door;
- Red Window Garage Door;
- Rolling Window Garage Door.

Design identity:

```text
one garage = three physical IsoDoor segments = three 20 kg parcels = one placement action
```

Runtime-validated behavior:

- closed Pickup/replacement works across all seven families in N/W;
- open-state Pickup works on the reference path;
- Pickup creates **three parcels on the ground**;
- placement can consume required parcels from inventory and/or nearby ground;
- rotation works;
- replacement is closed;
- synchronized garage opening/closing resumes normally;
- each physical segment preserves exact current health and `lmionDoorMaxHealth`;
- displayed/effective parcel weight is correctly **20 kg per segment**.

Garage parcels from identical doors are intentionally **interchangeable physical parts**. Runtime testing with two identical garages confirmed:

- six mixed parcels still allow rebuilding one complete garage while consuming only one Part1 + Part2 + Part3;
- a damaged Part1 from one garage and damaged Part3 from another can be combined;
- the rebuilt garage correctly inherits the durability carried by those individual parcels.

There is therefore no hidden bundle identity. Do not add one unless a future gameplay requirement explicitly needs it.

Inventory tooltips expose each transported part's logical durability as:

```text
PV : current / max
```

This is especially important because interchangeable parts may have different durability.

Current total garage transport weight is **3 × 20 kg = 60 kg**. This remains plausible for a steel sectional garage door and does not prevent replacement because the parcels can remain on the ground around the player.

Detailed behavior: `Research/Moveables/GarageDoorTopology.md`, `Research/Moveables/GarageDoorValidation.md`, `Research/Moveables/VanillaMoveablesBehavior.md`.

## Pickup presentation / fidelity

Pickup presentation now has a stable runtime-validated baseline:

- screwdriver Pickup/Place uses `LMION_ScrewdriverHinge` -> vanilla `Bob_IdleMakingLow`, with the real screwdriver in hand;
- crowbar Pickup uses `LMION_CrowbarPickupLow` -> vanilla `Bob_IdleLeverOpenLow`, with the real crowbar kept one-handed;
- Hammer Place uses vanilla `Build` with the real hammer;
- metal Scrap whose actual ScrapDefinition requires `Base.BlowTorch` is forced onto vanilla `BlowTorch` / `BlowTorchFloor` with the real usable torch in hand;
- vanilla still owns Scrap requirements, welding protection, duration, consumption, sound lifecycle and yields.

The previous visual bug where metal garage/gate Scrap could show `Disassemble + Screwdriver` is fixed and runtime validated.

### Audio QA rule

A major false diagnostic was traced to Debug/Cheat **Invisible** mode. With Invisible enabled, some sounds such as blowtorch work and door weapon hits can be inaudible even in a completely unmodded solo game, while other sounds such as hammering may still play.

> **Disable Invisible before any sound validation.**

With Invisible disabled, no current generic defect is reproduced for blowtorch or door-hit audio. Do not re-open those investigations unless silence is reproduced with Invisible off.

### Remaining presentation polish

1. **Action duration** — current vanilla formula includes `rawWeight * 2`, making heavy LMION doors/garages much slower to Pickup/place than desired. Keep real item weights; solve timing separately.
2. **Material-specific tool sounds** — current crowbar Pickup uses the wooden barricade crowbar event for both wood and metal, and Hammer Place uses configured `Hammering` for both. Metal-specific alternatives are optional polish and should only be implemented after suitable vanilla events are auditioned in game.
3. **Build presentation audit** — construction timed-action sounds/animations remain a separate subsystem to review if a concrete issue is observed.
4. Optional: explicit package naming/visual presentation for simple 1x1 transported doors.

A temporary metal-Hammer sound experiment (`SmithingHammerHit` pulses plus an `ISMoveablesAction.update()` wrapper) was not validated and has been removed. Do not resurrect that exact approach without new evidence.

See `Research/Moveables/AnimationCandidates.md` and `Research/Moveables/VanillaMoveablesBehavior.md`.

## Core technical guardrails

### Logical max health

B42 exposes `IsoDoor:setHealth()` but no usable public production-Lua setter for engine max health. LMION therefore stores the authoritative gameplay maximum in:

```text
lmionDoorMaxHealth
```

Current `IsoDoor.health` may legitimately exceed engine `getMaxHealth()`. LMION repair/condition code must use `Doors.getEffectiveMaxHealth()`.

Existing-world adoption is conservative: intact matching doors at engine max are raised to configured LMION max; already-damaged doors preserve exact current health; adopted doors are not repeatedly migrated.

See `Research/Engine/DoorHealth.md`.

### Engine-facing property aliases

PZ `PropertyContainer` values are alias-backed. Unknown strings can silently resolve to another alias. Engine-facing writes must use:

```text
preserve old -> write requested -> exact readback -> keep or restore
```

See `Research/Engine/PropertyAliases.md`.

### SpriteConfig ownership

`SpriteConfigScript.allTileNames` is derived from declared faces and participates in global sprite ownership.

When reducing vanilla large-gate ownership:

1. validate original tile set;
2. call `SpriteConfigScript:PreReload()` on that component only;
3. reload the intended SpriteConfig;
4. verify exact resulting ownership.

Do not call `GameEntityScript:PreReload()` just to reset SpriteConfig.

See `Research/Engine/SpriteConfigLifecycle.md`.

### Load timing

- Lua load — runtime/hot-reload profiles.
- `OnGameBoot` — scripted entities and large-gate ownership adjustments.
- `OnLoadedTileDefinitions` — reapply runtime sprite/tile mutations.
- `LoadGridsquare` — adopt existing world doors.
- `OnObjectAdded` — adopt newly created doors.

Do not move code between phases for tidiness without checking engine state.

## Development workflow / hard rules

- Work directly on `main` unless explicitly asked otherwise or a rollback branch materially reduces risk.
- Inspect current code + relevant Research before modifying an unfamiliar subsystem.
- Prefer Java/API/vanilla-source/runtime verification over guessing.
- Avoid speculative Java/reflection calls in production/Debug; Kahlua Debug Mode may surface exceptions despite `pcall`.
- Prefer strong engine structures/properties over sprite-name guessing where possible.
- Lua comments: `--[[ ... ]]`. PZ `media/scripts`: `/* ... */`.
- `media/scripts` changes require full restart.
- AnimSet XML changes require full game restart for validation.
- New Lua files/load-order changes/stale monkey-patch closures may also require full restart.
- Do not add speculative abstractions/workarounds without a reproduced need.
- **Do not modify the door catalog unless the current task explicitly concerns it.**

## Instructions for future development / AI sessions

1. Start by reading this file and `Research/README.md`, then inspect current `main`.
2. Use the repository as the handoff; reconstruct state from code/Git/Research before asking the user to rebrief.
3. Update `README_DEV.md` and/or focused Research when architecture, validation or engine conclusions materially change.
4. Document durable decisions, not every commit.
5. Preserve the reason for engine/lifecycle workarounds in Research.
6. Current code + runtime validation outrank stale prose; fix documentation when they disagree.
7. For sound QA, verify Debug/Cheat Invisible is disabled before concluding that audio is broken.

## Known compatibility note

Old saves containing pre-split full `Base.DoubleWireGate` instances may emit:

```text
Invalid SpriteConfig object! scripted object = DoubleWireGate
```

A new save did not reproduce this. Treat old-save migration separately rather than distorting current topology.

## Next intended milestones

Pickup mechanics and core presentation are sufficiently validated to avoid more topology/presentation redesign without a reproduced issue.

Recommended next Pickup tasks:

1. define/fix Pickup/Place duration without changing real transport weights;
2. optionally revisit material-specific crowbar/hammer sounds after auditioning candidate vanilla events;
3. audit Build presentation only if a concrete issue is reproduced;
4. optionally package-style presentation for simple 1x1 items.

A future `LMION_Repair` gameplay module remains planned after transport/material/craft rules are stable enough. Core should keep only low-level logical-health primitives.

Potential locksmith/access-control systems remain future scope and must not distort the current transport architecture prematurely.
