# Let Me In... Or Not — Development & handoff

Last updated: 2026-08-29

This is the **single authoritative development/handoff document** for LMION. Read it at the start of a new development session, then inspect current `main` and the relevant note under `Research/`.

> **Vanilla defines the physical opening mechanics; LMION defines the gameplay rules.**

LMION should reuse Project Zomboid opening/closing, collision, synchronization, sprite-state behavior and object mechanics whenever practical. LMION owns construction, naming/localization, material rules, Pickup/transport identity, placement requirements, logical durability and future repair/access-control gameplay.

A second architectural rule is now explicit:

> **LMION-managed doors have one canonical physical representation: `IsoDoor`.**

This does not mean LMION ignores `IsoThumpable(isDoor)`. Core must recognize and read it as an engine/source/legacy representation. It means LMION does not preserve it as a second persistent backend after LMION creates or reinstalls a door.

`newtiledefinitions.tiles` / TileDefinitions are research/reference data. Do not edit them as an LMION runtime solution.

## Documentation map

- `README.md` — short public project overview.
- `README_DEV.md` — this file: architecture, validated state, guardrails and next work.
- `Research/` — detailed engine evidence, reverse engineering, failed hypotheses and lifecycle constraints.
- `Research/Architecture/DoorObjectAbstraction.md` — canonical door-representation decision and rationale.
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
- semantic door identity independent from engine input class;
- canonical `IsoDoor` finalization;
- normalized door state capture/restore;
- shared placement/persistence helpers;
- effective max-health abstraction;
- low-level repair primitives;
- future shared access/lock state primitives.

Core does **not** own construction UX, Pickup UX or future Repair UX.

Recognizing a world door must not silently alter its durability. World/map objects keep vanilla engine durability by default. A future sandbox option may explicitly apply LMION profile durability, but that is a separate opt-in policy.

### `LMION_Build`

Build owns construction/crafting, progression, requirements and localization.

Build does not decide Java representation. `ISBuildIsoEntity` may create temporary `IsoThumpable` door objects; Build finds the completed LMION EntityScript object and asks Core to finalize it. The final LMION-built door is `IsoDoor`.

Build only supplies the gameplay durability/stat values that Build itself owns; Core applies them after canonicalization.

Garage doors use the same canonical representation but convert earlier through their SpriteConfig `OnCreate` callback because native GarageDoor mechanics are `IsoDoor`-specific.

### `LMION_Pickup`

Pickup owns transport/reinstallation of passable openings:

- eligibility;
- tool/skill requirements;
- inventory/world parcel identity;
- exact gameplay-state preservation around transport;
- placement rules;
- specialized multi-tile transport.

General design rule:

> **If it opens and the player can pass through it, Pickup owns its transport behavior.**

Pickup does not decide durability. It captures the actual source state through Core and restores it later.

Pickup deliberately does **not** transport the source Java representation. A supported source `IsoThumpable(isDoor)` is accepted, but LMION reinstallation ends as `IsoDoor`.

### `LMION_Debug`

Debug owns Inspector, world selection/highlighting, deterministic Test Zone, Lua reload helpers and temporary validation actions. Debug must never become a gameplay dependency.

## Core door representation model

Project Zomboid may expose a semantic door through either class:

```text
engine/source door
├── IsoDoor
└── IsoThumpable(isDoor)
```

Typical engine state before LMION ownership:

```text
world/map-authored door      -> IsoDoor
world/map-authored gate      -> IsoDoor
world/map-authored garage    -> IsoDoor
player-built engine door     -> commonly IsoThumpable
```

LMION's persistent invariant is different:

```text
LMION-created/finalized/reinstalled door -> IsoDoor
```

Canonicalization occurs only at explicit LMION boundaries. LMION does **not** scan a save and blindly convert every `IsoThumpable`, nor does it target non-door thumpables.

Core still exposes input/diagnostic helpers:

```text
Doors.isIsoDoor(object)
Doors.isThumpableDoor(object)
Doors.isDoorObject(object)
Doors.getDoorRepresentation(object)   # informational only
Doors.isCanonicalDoor(object)
Doors.ensureCanonicalDoor(object, options)
Doors.captureDoorState(object)
Doors.restoreDoorState(object, state)
Doors.getEffectiveMaxHealth(object)
Doors.restoreEffectiveMaxHealth(object, ...)
Doors.finalizePlacedDoor(object, options)
```

Do not use `getDoorRepresentation()` to restore a source class after LMION placement. Source representation is no longer gameplay state.

### Why canonical `IsoDoor`

The earlier refactor successfully proved that LMION could preserve both representations. That policy was technically valid, but it creates a long-term architectural cost: future features can require two genuinely different backends even behind one Core API.

Examples:

```text
max health
IsoThumpable -> native setMaxHealth()
IsoDoor      -> logical LMION max when native max cannot be set

future locks/access
IsoThumpable -> native padlock/code facilities exist
IsoDoor      -> no equivalent complete API
```

LMION is intended to be the authoritative door framework and an addon target. It is better for Core to fill missing gameplay capabilities on one canonical physical representation than for every future feature to maintain two physical implementations.

This policy change keeps the benefits of the refactor: Core still owns identity/state/topology, Build and Pickup remain independent, and addons target LMION rather than raw PZ class differences.

See `Research/Architecture/DoorObjectAbstraction.md`.

## Current validated state

The transport/topology behavior below was runtime-validated before the 2026-08-28 canonical-representation migration. Those tests remain valid engine/topology research, but representation-specific expectations must now follow the canonical policy. A focused revalidation matrix is listed later in this document.

### Simple / 1x1 openings

The 1x1 path is the stable baseline.

Previously runtime-validated behavior includes:

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

New expected representation behavior:

```text
LMION_Build 1x1
-> temporary engine object may be IsoThumpable
-> Core finalization
-> IsoDoor

Pickup of legacy/vanilla-built IsoThumpable 1x1
-> accepted as source
-> reinstall
-> IsoDoor
```

### Large-gate construction

Six current large-gate families are split into independent A/B construction leaves:

- Large Farm Gate;
- Large Wrought Iron Gate;
- Large Hardened Wooden Gate;
- Large Chain-Link Gate;
- Large Scrap Metal Gate;
- Large Wooden Gate.

All six were runtime-tested in N/W construction orientations before canonicalization. Correctly assembled leaves resume vanilla synchronized DoubleDoor opening.

Logical topology is stable across facing:

```text
N: A={1,2}, B={3,4}
W: A={4,3}, B={2,1}
```

True paired 1x1 doors retain Left/Right semantics; large gates use A/B leaves.

### Large-gate durability / engine-input research

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

Opening/closing both engine representations preserved health during that research. Deliberately damaged members also preserved damage through open/close recreation.

These observations remain useful because Pickup/Core may still encounter `IsoThumpable` sources, but new LMION-managed output is canonical `IsoDoor`.

### Large-gate Pickup

Design identity:

```text
one leaf = two physical DoubleDoor segments = two parcels = one placement action
```

Previously runtime-validated transport behavior:

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

#### Canonical representation after transport

The previous representation-preservation implementation was runtime validated, including keeping constructed large gates as `IsoThumpable` after Pickup/replacement. That result is now historical evidence, **not the desired output**.

Current expected behavior:

```text
IsoDoor source
-> Pickup
-> placement
-> IsoDoor

IsoThumpable source
-> Pickup
-> source state captured
-> placement
-> IsoDoor
```

Old development parcels may still carry `lmionDoorSourceRepresentation`; Pickup intentionally ignores it.

#### Open-state Pickup and placement

Open-state Pickup does not close the full gate first.

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

Core's canonical placement finalizer applies explicit open sprite/state without calling the collective DoubleDoor toggle. This preserves the validated geometry strategy while changing only the final Java representation policy.

See `Research/Moveables/LargeGateLeaves.md` and especially `Research/Moveables/LargeGateOpenPickup.md`.

A non-blocking engine warning can occur during multi-square Pickup:

```text
GameEntityFactory.TransferComponents> Cannot transfer components for multi-square objects
```

No concrete state-loss bug has been reproduced from it. Do not add a workaround without a reproduced failure.

### Garage doors

Garage doors use native variable-length topology, separate from DoubleDoor large gates:

```text
START + MIDDLE * N + END
```

The three normalized GarageDoor values are semantic roles, not a fixed three-member count. Minimum native/LMION length is L2. LMION applies a default L12 gameplay safety limit that can currently be lifted; L12 is not claimed to be a Project Zomboid engine maximum.

Supported families:

- Industrial Garage Door;
- Green Garage Door;
- White Garage Door;
- Grey Garage Door;
- Rolling Garage Door;
- Red Window Garage Door;
- Rolling Window Garage Door.

Transport identity:

```text
one physical member = one 20 kg parcel
_Part1 = Start
_Part2 = repeatable Middle
_Part3 = End
```

Runtime-validated Pickup/reinstallation behavior:

- Pickup traverses the actual native garage chain rather than assuming L3;
- one parcel is created per physical member, so repeated Middle members create repeated `_Part2` parcels;
- open-state Pickup works on the reference path;
- placement can consume compatible same-family parcels from inventory and/or nearby ground;
- inventory right-click `Place` hands the exact garage parcel to LMION's dedicated variable-width cursor before vanilla fixed-SpriteGrid placement takes ownership;
- width can be changed with the configurable garage width keys and N/W rotation works;
- variable physical placement works and consumes only the Start/Middle(s)/End used by the selected plan;
- replacement is closed;
- synchronized garage opening/closing resumes normally;
- each physical segment preserves exact current health/effective max;
- displayed/effective parcel weight is correctly 20 kg per segment.

Garage parcels from identical families are intentionally interchangeable physical parts. There is no hidden bundle identity.

#### Garage placement entry-point contract

The two UI controls labelled `Place` are intentionally **not equivalent**:

```text
inventory right-click Place
-> exact InventoryItem known
-> LMION dedicated cursor/action
-> variable Start + Middle*N + End placement

left Moveables sidebar Place
-> generic vanilla Moveables Place catalogue
-> historical synthetic L3 SpriteGrid
-> fixed L3 placement
```

The sidebar L3 result is accepted behavior, not a pending bug. A previous attempt to hand the sidebar into the variable cursor was reverted because reliable support would require coupling to central `ISMoveableCursor` selection/validation/cycling state for very little gameplay benefit.

Do not reintroduce global `ISMoveableCursor:isValid()` handoffs, rotate/TAB interception or a hybrid Moveables state machine merely to make both entry points variable.

The synthetic L3 SpriteGrid remains only where vanilla Moveables still needs it for discovery/pickup/item-facing behavior and the vanilla sidebar path. It is **not** LMION variable reinstallation geometry.

Detailed placement contract: `Research/Moveables/GarageDoorPlacementEntryPath.md` and `Research/Moveables/GarageDoorVariableWidthDesign.md`.

#### Garage representation and OnCreate

Deep B42.20.3 JAR inspection plus B42.20.4 runtime proved that `IsoThumpable` is not a complete GarageDoor implementation. `IsoDoor` owns the complete native garage toggle/obstruction/sprite mechanics.

Garage SpriteConfigs therefore use:

```text
OnCreate = LMION.Doors.onCreateGarage
```

B42.20.4 trace validation established for all three members of a freshly built L3 White Garage Door:

```text
OnCreate enter       -> IsoThumpable
OnCreate replacement -> IsoDoor
OnCreate return      -> IsoDoor
Build post-scan      -> same IsoDoor
```

So `OnCreate` is confirmed sufficient for garage representation conversion. The Build post-scan does not need a second garage conversion; it applies common Build state.

A construction-conversion regression also showed why transient lock state must not be copied blindly: restoring the complete temporary `IsoThumpable` snapshot produced a newly built locked garage. Fresh LMION construction now explicitly clears `locked` / `lockedByKey` during canonicalization.

Under the global canonical policy, garages are no longer a representation exception. They are an **early-timing exception** because their temporary `IsoThumpable` is unsafe to leave as the completed object.

Build variable-width construction has **not** been implemented yet. Current Build garage recipes/creation remain the separate fixed-L3 construction path; future Build variable width must consume Core topology semantics without depending on Pickup.

Detailed behavior: `Research/Engine/GarageThumpableInteraction.md`, `Research/Moveables/GarageDoorTopology.md`, `Research/Moveables/GarageDoorValidation.md`, `Research/Moveables/VanillaMoveablesBehavior.md`.

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

Current Pickup/Place actions are intentionally left as-is during active development. Runtime testing after the earlier representation refactor found them much faster than the first implementation; the old path had become frustratingly slow during repeated development cycles.

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

Core must still read both possible engine/source representations.

`IsoThumpable` exposes native `setMaxHealth()`, so legacy/vanilla-built source state can be captured accurately.

`IsoDoor` exposes `getMaxHealth()` but no useful public `setMaxHealth()`. `modData.lmionDoorMaxHealth` is therefore the logical fallback when a canonical LMION `IsoDoor` needs an effective max the engine cannot represent.

Do not create this override merely because Core recognizes a world door.

Current ownership policy:

```text
world/map door
-> vanilla durability by default

legacy/vanilla IsoThumpable source
-> Core reads actual state when needed

LMION_Build construction
-> Build supplies initial durability
-> Core applies it to canonical IsoDoor

Pickup
-> preserves actual source health/effective max, never decides durability
-> restores it onto canonical IsoDoor
```

A future sandbox option remains planned:

```text
World Door Durability
- Vanilla          (default)
- LMION Profiles
```

Do not implement it by silently mutating recognized world doors under the default policy.

### DoubleDoor recreation

Vanilla may remove/recreate DoubleDoor members during opening/closing. A Java object reference is not persistent state.

Pickup currently owns transition detection/timing for large gates, but state semantics are Core:

```text
Doors.captureDoorState(old member)
-> vanilla transition/recreation
-> Doors.restoreDoorState(new member, snapshot)
```

Do not duplicate state-copy logic inside each gameplay module. The snapshot may record source representation for diagnostics, but representation is no longer restored as a gameplay choice.

### Canonicalization scope

`Doors.ensureCanonicalDoor()` is an LMION ownership-boundary primitive, not a world scanner.

Valid uses include:

- finalizing an LMION_Build temporary door;
- early garage `OnCreate` finalization;
- finalizing an LMION_Pickup placement.

Do not attach it to generic world-load events to mutate every `IsoThumpable` in a save. Non-door `IsoThumpable` objects are outside LMION's scope entirely.

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

## Canonical migration runtime validation — next required pass

Shared Lua/load-order code changed during this migration. **Use a full game restart before testing.**

The next runtime pass should establish:

1. **Fresh LMION 1x1 door** — inspect final class `IsoDoor`; verify correct current/effective max health; verify unlocked; open/close normally.
2. **Fresh LMION large gate** — inspect all constructed members as `IsoDoor`; verify synchronized native DoubleDoor opening; verify expected durability.
3. **Fresh LMION garage** — all three members of the current fixed-L3 Build path are `IsoDoor`; unlocked; synchronized open/close; correct durability.
4. **World/map IsoDoor Pickup** — pickup/reinstall/rotate; final `IsoDoor`; health/effective max preserved.
5. **Legacy or vanilla-built IsoThumpable door/gate Pickup** — source may be `IsoThumpable`; after LMION reinstall final object must be `IsoDoor`; health/effective max preserved. This class change is intentional.
6. **Open large-gate leaf Pickup/reconnect** — partner remains untouched; target state follows partner; blocked target still refuses placement; final placed members are `IsoDoor`.

Do not claim the canonical migration runtime-validated until this pass succeeds. Previous representation-preservation tests are historical evidence, not validation of the new output invariant.

## Development workflow / hard rules

- User-facing delivery goes to `main`. Development may use another branch, but final changes must be fast-forwarded/merged back to `main`; clearly name any branch kept as a safety/development snapshot.
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
6. **Do not restore persistent source-representation preservation.** `IsoThumpable(isDoor)` is a valid input, but LMION-created/reinstalled output is canonical `IsoDoor`. The old preservation policy worked technically and was intentionally rejected to avoid two future gameplay backends.
7. Do not revive these rejected large-gate approaches without new evidence:
   - close the full gate before open Pickup;
   - force an existing partner leaf to change state at placement;
   - allow a closed/open hybrid and hope the next toggle repairs it.
8. Do not revive `garage = IsoThumpable`. B42.20.3 bytecode and B42.20.4 runtime prove native GarageDoor mechanics are incomplete there.
9. For garage Pickup reinstallation, preserve the validated entry split: inventory right-click `Place` is variable LMION placement; left Moveables sidebar `Place` is intentionally vanilla L3. Do not hook central Moveables hot paths merely to unify them.
10. Do not treat Pickup/Place action duration as an urgent defect. Current timings are acceptable for development; revisit them only in a gameplay-balance pass and do not tie them blindly to transport weight.
11. For sound QA, verify Debug/Cheat Invisible is disabled before concluding that audio is broken.

## Known compatibility / migration note

LMION does not prioritize preserving other mods' private door representations. LMION is designed as the authoritative door framework; compatibility patches can target LMION's documented Core API.

Existing old-save/vanilla `IsoThumpable` doors are not automatically mutated on load. They remain valid input objects. Once such a supported door is picked up and reinstalled through LMION, it becomes canonical `IsoDoor`.

Treat any future bulk save migration as a separate feature rather than hiding it inside world-load recognition.

## Next intended milestones

First: complete the canonical-representation runtime validation matrix above and fix only reproduced regressions.

Pickup variable-width garage transport/reinstallation is now a validated baseline. Do not redesign its inventory/sidebar entry behavior without a reproduced issue or an explicit new requirement.

Build variable-width garage construction remains separate future work and must preserve the Core-orchestrated addon independence rule: Build and Pickup consume Core semantics, never each other.

After that, large-gate transport/topology should again be considered stable enough that further redesign requires a reproduced issue.

Recommended later tasks:

1. implement/design variable-width Garage Build UX, frozen width and material scaling when that chantier is selected;
2. optional material-specific crowbar/hammer sounds after auditioning candidate vanilla events;
3. audit Build presentation only if a concrete issue is reproduced;
4. optional package-style presentation for simple 1x1 items;
5. dedicated gameplay-balance pass for Pickup/Place duration;
6. design the future world-door durability sandbox policy;
7. proceed toward `LMION_Repair` and locksmith/access-control modules on top of the canonical Core door model.

Future Locks/Repair/addons should target LMION's semantic/Core APIs and canonical `IsoDoor` world contract rather than reintroducing `IsoDoor`/`IsoThumpable` feature forks.
