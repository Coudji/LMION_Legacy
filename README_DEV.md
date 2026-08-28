# Let Me In... Or Not — Development & handoff

Last updated: 2026-08-28

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
- door identity independent from Java representation;
- normalized door state capture/restore;
- shared placement/persistence helpers;
- effective max-health abstraction across `IsoDoor` / `IsoThumpable`;
- low-level repair primitives.

Core does **not** own construction UX, Pickup UX or future Repair UX.

Recognizing a world door must not silently alter its durability. World/map objects keep vanilla engine durability by default. A future sandbox option may explicitly apply LMION profile durability, but that is a separate opt-in policy.

### `LMION_Build`

Build owns construction/crafting, progression, requirements and localization.

Build-created doors keep the physical Java representation produced by the engine. Build only supplies the gameplay durability/stat values that Build itself owns; Core applies them through the appropriate representation adapter.

### `LMION_Pickup`

Pickup owns transport/reinstallation of passable openings:

- eligibility;
- tool/skill requirements;
- inventory/world parcel identity;
- exact state preservation around transport;
- placement rules;
- specialized multi-tile transport.

General design rule:

> **If it opens and the player can pass through it, Pickup owns its transport behavior.**

Pickup does not decide durability. It captures the actual source state through Core and restores it later.

### `LMION_Debug`

Debug owns Inspector, world selection/highlighting, deterministic Test Zone, Lua reload helpers and temporary validation actions. Debug must never become a gameplay dependency.

## Core door representation model

Project Zomboid has two valid physical representations for a door:

```text
Door
├── IsoDoor
└── IsoThumpable(isDoor)
```

Typical runtime ownership:

```text
world/map-authored door      -> IsoDoor
vanilla/player-built door    -> IsoThumpable
LMION_Build-built door       -> engine-created representation, normally IsoThumpable
```

LMION gameplay identity must not depend on one universal concrete class.

Core helpers own the class-specific differences:

```text
Doors.isIsoDoor(object)
Doors.isThumpableDoor(object)
Doors.isDoorObject(object)
Doors.getDoorRepresentation(object)
Doors.captureDoorState(object)
Doors.restoreDoorState(object, state)
Doors.getEffectiveMaxHealth(object)
Doors.restoreEffectiveMaxHealth(object, ...)
```

Do not normalize every door to `IsoDoor` merely to simplify callers.

## Current validated state

### Simple / 1x1 openings

The 1x1 path is the stable baseline.

Runtime-validated behavior includes:

- vanilla Moveables Pickup/replacement;
- frame-aware placement where required;
- open 1x1 Pickup canonicalized back to closed N/W transport identity;
- current health preservation;
- effective max-health preservation;
- paired Left/Right doors restricted to matching DoubleDoor1/2 frame sides;
- 1x1 fence gates and sliding doors on the shared Pickup architecture;
- correct LMION transport weight after Pickup;
- inventory tooltip durability display as `PV : current / max` in French and `HP : current / max` in English.

The durability tooltip intentionally shows **no percentage**.

Current profile-specific facts:

- `LogDoor` intentionally has no Pickup/place tools;
- normal wooden and metal doors use screwdriver for both Pickup and Place;
- sliding doors and gates use Crowbar for Pickup and Hammer for placement through custom Moveables tool definitions.

### Large-gate construction

Six current large-gate families are split into independent A/B construction leaves:

- Large Farm Gate;
- Large Wrought Iron Gate;
- Large Hardened Wooden Gate;
- Large Chain-Link Gate;
- Large Scrap Metal Gate;
- Large Wooden Gate.

All six were runtime-tested in N/W construction orientations. Correctly assembled leaves resume vanilla synchronized DoubleDoor opening.

Logical topology is stable across facing:

```text
N: A={1,2}, B={3,4}
W: A={4,3}, B={2,1}
```

True paired 1x1 doors retain Left/Right semantics; large gates use A/B leaves.

### Large-gate durability / representation validation

Reference `DoubleWireGate` runtime tests established:

```text
world/map gate
-> IsoDoor
-> 100/100 observed
-> lmionDoorMaxHealth unset

vanilla-built gate at MetalWelding 3
-> IsoThumpable
-> 900/900
-> lmionDoorMaxHealth unset
```

The vanilla entity uses `skillBaseHealth = 300`; construction health is derived from actual relevant skill. A level-0 test produced 0/0, which is vanilla behavior, not LMION corruption.

Opening/closing both representations preserves health. Deliberately damaged members also preserve damage through open/close recreation.

### Large-gate Pickup

Design identity:

```text
one leaf = two physical DoubleDoor segments = two parcels = one placement action
```

Closed-leaf transport is runtime-validated:

- either physical segment can be targeted;
- only the selected two-segment leaf is removed;
- two parcels `(1/2)` and `(2/2)` are produced;
- the two parcels are dropped on the ground, vanilla-style;
- both parcels are required for replacement;
- placement can consume required parcels from player inventory and/or nearby ground;
- N/W rotation works before replacement;
- exact segment health/effective max survive replacement and rotation;
- correctly reassembled portals resume vanilla DoubleDoor synchronization.

Current transport weight is **2 × 12 kg = 24 kg per leaf**.

#### Physical representation survives transport

Important vanilla behavior: Moveables placement creates an `IsoDoor` for sprites carrying `doorN`/`doorW`, even when the original world object was an `IsoThumpable` door.

LMION now compensates using the transported source representation:

```text
IsoDoor source
-> Pickup
-> placement
-> IsoDoor

IsoThumpable source
-> Pickup
-> vanilla temporary IsoDoor
-> Core restores IsoThumpable
```

Runtime validation confirmed a constructed `IsoThumpable` large gate remains `IsoThumpable` after replacement, including after N/W rotation, with health preserved.

#### Open-state Pickup and placement

Open-state Pickup no longer closes the full gate first.

Validated behavior:

```text
open gate
-> pickup selected A/B leaf directly
-> untouched partner remains in its current open state
-> parcels still use canonical closed transport identity
```

Open/closed state is not serialized into the parcels.

At placement, the environment decides:

```text
no matching partner      -> place closed
matching partner closed  -> place closed
matching partner open    -> place open
incoherent partner       -> refuse reconnection
```

LMION never forces the existing partner to change state merely to allow replacement.

This is important because the partner's alternative footprint may be blocked by a vehicle, crate or other object. If the new leaf's required target geometry is blocked, the Moveables cursor becomes invalid/red and clicking refuses placement. Runtime testing confirmed this collision behavior.

A previously tested closed/open hybrid caused broken DoubleDoor movement/geometry and is explicitly unsupported.

Once both leaves are placed correctly in one coherent state, vanilla synchronization resumes normally.

See `Research/Moveables/LargeGateLeaves.md` and especially `Research/Moveables/LargeGateOpenPickup.md`.

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
one garage = three physical segments = three 20 kg parcels = one placement action
```

Runtime-validated behavior:

- closed Pickup/replacement works across all seven families in N/W;
- open-state Pickup works on the reference path;
- Pickup creates three parcels on the ground;
- placement can consume required parcels from inventory and/or nearby ground;
- rotation works;
- replacement is closed;
- synchronized garage opening/closing resumes normally;
- each physical segment preserves exact current health/effective max;
- displayed/effective parcel weight is correctly 20 kg per segment.

Garage parcels from identical doors are intentionally interchangeable physical parts. There is no hidden bundle identity.

Detailed behavior: `Research/Moveables/GarageDoorTopology.md`, `Research/Moveables/GarageDoorValidation.md`, `Research/Moveables/VanillaMoveablesBehavior.md`.

## Pickup presentation / fidelity

Pickup presentation has a stable runtime-validated baseline:

- screwdriver Pickup/Place uses `LMION_ScrewdriverHinge` -> vanilla `Bob_IdleMakingLow`, with the real screwdriver in hand;
- crowbar Pickup uses `LMION_CrowbarPickupLow` -> vanilla `Bob_IdleLeverOpenLow`, with the real crowbar one-handed;
- Hammer Place uses vanilla `Build` with the real hammer;
- metal Scrap whose actual ScrapDefinition requires `Base.BlowTorch` is forced onto vanilla `BlowTorch` / `BlowTorchFloor` with the real usable torch in hand;
- vanilla still owns Scrap requirements, welding protection, duration, consumption, sound lifecycle and yields.

### Audio QA rule

Debug/Cheat **Invisible** mode can suppress some sounds even in unmodded solo gameplay.

> **Disable Invisible before any sound validation.**

### Action-duration balancing

Current Pickup/Place actions are intentionally left as-is during active development. Runtime testing after the door-representation refactor found them much faster than the earlier implementation; the old path had become frustratingly slow during repeated development cycles.

This is **not yet a final gameplay-balance decision**. A meaningful action time can be desirable because dismantling/reinstalling a heavy opening exposes the player to danger, and transporting doors/gates is expected to be an occasional operation rather than a constant action.

Do not currently reintroduce a simple `rawWeight -> duration` scaling, especially the earlier/vanilla-style `rawWeight * 2`, without testing normal gameplay rather than repetitive debug workflows. Real parcel/item weight and action duration are separate balance concerns.

If rapid iteration later needs an explicit shortcut, prefer a Debug-only fast-action aid rather than a gameplay sandbox option.

### Remaining presentation polish

1. optional material-specific tool sounds after auditioning suitable vanilla events;
2. audit Build presentation only if a concrete issue is reproduced;
3. optional package-style presentation for simple 1x1 transported doors;
4. revisit Pickup/Place duration only during a dedicated gameplay-balance pass.

## Core technical guardrails

### Effective max health

`IsoThumpable` exposes native `setMaxHealth()`; Core stores its max in the engine.

`IsoDoor` exposes `getMaxHealth()` but no useful public `setMaxHealth()`. `modData.lmionDoorMaxHealth` is therefore only a fallback when LMION intentionally needs a logical max the engine cannot represent.

Do not create this override merely because Core recognizes a door.

Current ownership policy:

```text
world/map door
-> vanilla durability by default

vanilla construction
-> vanilla durability

LMION_Build construction
-> Build supplies initial durability

Pickup
-> preserves actual source state, never decides durability
```

### DoubleDoor recreation

Vanilla may remove/recreate DoubleDoor members 2/3 during opening/closing. A Java object reference is not persistent state.

Pickup currently owns transition detection/timing for large gates, but state semantics are Core:

```text
Doors.captureDoorState(old member)
-> vanilla transition/recreation
-> Doors.restoreDoorState(new member, snapshot)
```

Do not duplicate state-copy logic inside each gameplay module.

### Engine-facing property aliases

PZ `PropertyContainer` values are alias-backed. Unknown strings can silently resolve to another alias. Engine-facing writes must use:

```text
preserve old -> write requested -> exact readback -> keep or restore
```

See `Research/Engine/PropertyAliases.md`.

### Load timing

- Lua load — runtime/hot-reload profiles and hooks.
- `OnGameBoot` — scripted entities when applicable.
- `OnLoadedTileDefinitions` — reapply runtime sprite/tile mutations such as large-gate SpriteGrids/open Moveables aliases.

Do not move code between phases for tidiness without checking engine state.

## Development workflow / hard rules

- Work directly on `main` when explicitly requested for the current task.
- Inspect current code + relevant Research before modifying an unfamiliar subsystem.
- Prefer Java/API/vanilla-source/runtime verification over guessing.
- Runtime testing by the user is authoritative for gameplay behavior.
- Avoid speculative Java/reflection calls in production/Debug; Kahlua Debug Mode may surface exceptions despite `pcall`.
- Prefer strong engine structures/properties over sprite-name guessing where possible.
- Lua comments: `--[[ ... ]]`. PZ `media/scripts`: `/* ... */`.
- `media/scripts` changes require full restart.
- New shared Lua files/load-order changes/stale monkey-patch closures may require full restart.
- Do not add speculative abstractions/workarounds without a reproduced need.
- **Do not modify the door catalog unless the current task explicitly concerns it.**

## Instructions for future development / AI sessions

1. Start by reading this file and `Research/README.md`, then inspect current `main`.
2. Use the repository as the handoff; reconstruct state from code/Git/Research before asking the user to rebrief.
3. Update `README_DEV.md` and/or focused Research when architecture, validation or engine conclusions materially change.
4. Document durable decisions, discoveries and rejected engine paths so they are not repeatedly rediscovered.
5. Current code + runtime validation outrank stale prose; fix documentation immediately when they disagree.
6. Do not revive these rejected large-gate approaches without new evidence:
   - normalize all transported doors to `IsoDoor`;
   - close the full gate before open Pickup;
   - force an existing partner leaf to change state at placement;
   - allow a closed/open hybrid and hope the next toggle repairs it.
7. Do not treat Pickup/Place action duration as an urgent defect. Current timings are acceptable for development; revisit them only in a gameplay-balance pass and do not tie them blindly to transport weight.
8. For sound QA, verify Debug/Cheat Invisible is disabled before concluding that audio is broken.

## Known compatibility note

Old saves containing earlier large-gate representations may need separate migration handling. Treat old-save migration separately rather than distorting the current validated topology.

## Next intended milestones

Large-gate transport/topology is currently runtime-validated enough that further redesign should require a reproduced issue.

Recommended next Pickup tasks:

1. optionally revisit material-specific crowbar/hammer sounds after auditioning candidate vanilla events;
2. audit Build presentation only if a concrete issue is reproduced;
3. optionally package-style presentation for simple 1x1 items.

Action-duration balancing is deliberately deferred until a dedicated gameplay-balance pass.

A future `LMION_Repair` gameplay module remains planned after transport/material/craft rules are stable enough. Core should keep only low-level logical-health primitives.

Potential locksmith/access-control systems remain future scope and must not distort the current transport architecture prematurely.
