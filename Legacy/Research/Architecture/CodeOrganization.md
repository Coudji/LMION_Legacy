# LMION code organization and addon boundaries

Last reviewed: 2026-08-29

This note describes the current source ownership contract. It complements `README_DEV.md`; if prose and current code disagree, inspect `main` and fix the prose.

## Dependency graph

LMION is one Workshop item containing independent Build 42 Mod IDs:

```text
LMION_Build   ─┐
LMION_Pickup  ─┼─> LMION_Core
LMION_Debug   ─┘
```

Current `mod.info` audit confirms:

```text
LMION_Core   -> no LMION addon dependency
LMION_Build  -> require=LMION_Core
LMION_Pickup -> require=LMION_Core
LMION_Debug  -> require=LMION_Core
```

No addon is allowed to require another addon. Shared semantics needed by more than one addon belong in Core.

## Core

Root:

```text
Contents/mods/LMION_Core/42/
```

Important shared modules:

```text
media/lua/shared/LMION/Core.lua
media/lua/shared/LMION/Doors.lua
media/lua/shared/LMION/Doors/
    Construction.lua
    Durability.lua
    EngineProperties.lua
    GarageTopology.lua
    Object.lua
    Placement.lua
    Registry.lua
    Representation.lua
    State.lua
media/lua/shared/LMION/Openings.lua
media/lua/shared/LMION/OpeningDefinitions/LargeGates.lua
media/lua/shared/LMION/DoorProfiles.lua
media/lua/shared/LMION/DoorProfiles/*.lua
```

Core owns:

- semantic door/opening identity;
- canonical `IsoDoor` output/finalization;
- shared state capture/restore and effective durability;
- placement/finalization primitives shared across addons;
- engine-property projection/alias safety;
- large-opening topology;
- large-gate A/B definitions;
- garage START/MIDDLE/END semantics and width policy.

Core must not know Build/Pickup UI, recipe balance, parcel UX or Debug workflows.

## Build

Root:

```text
Contents/mods/LMION_Build/42/
```

Bootstrap:

```text
media/lua/shared/LMION/Build.lua
```

It requires Core, then Build-owned modules only.

### Large-gate construction

Current files:

```text
media/lua/shared/LMION/Build/LargeGateProfiles.lua
media/lua/shared/LMION/Build/VanillaLargeGateLeafConstruction.lua
media/lua/server/LMION/BuildHook.lua
```

`VanillaLargeGateLeafConstruction.lua` is the current file name. Older documentation mentioning `VanillaLargeGateSplit.lua` is obsolete.

Core owns the A/B topology. Build owns how construction exposes/uses those leaves and construction-specific rules.

### Variable garage Build

The implementation is deliberately split by concern:

```text
shared/LMION/Build/GarageConstruction.lua
shared/LMION/Build/GarageMaterialAlternatives.lua
shared/LMION/Build/GarageLengthState.lua
shared/LMION/Build/GarageBuildCursor.lua
client/LMION/GarageBuildUI.lua
client/LMION/GarageSelectedBarRequirement.lua
server/LMION/GarageBuildCursorHook.lua
server/LMION/BuildHook.lua
```

Responsibilities:

- `GarageConstruction.lua` — supported garage IDs, width normalization, full selected-width requirements, stock/preflight/delta primitives and per-cursor FaceInfo geometry proxy.
- `GarageMaterialAlternatives.lua` — shared MetalBar/IronBar quota, mixed consumption, and truthful consumed-material metadata.
- `GarageLengthState.lua` — durable per-`BuildLogic` Lua side-table state, mirroring into `CraftRecipeData`, native variable-bar ratio/cap and cleanup of vanilla auto-overselection.
- `GarageBuildUI.lua` — length selector, selected-width requirement display, Build button/ghost integration and quick-repeat width preservation.
- `GarageSelectedBarRequirement.lua` — client validation that the manual bar selection reaches the current selected length, not merely the static L2 recipe minimum.
- `GarageBuildCursor.lua` — reusable cursor hook body. **Top-level must stay inert** because shared Lua auto-executes before the server-tree `ISBuildIsoEntity` class is available.
- `GarageBuildCursorHook.lua` — server-phase loader that requires `BuildingObjects/ISBuildIsoEntity` and installs the shared hook.
- `BuildHook.lua` — authoritative construction preflight, selected-width delta/remainder consumption, build metadata and Core finalization.

The canonical garage SpriteConfig remains the L3 source pattern. Build's per-cursor proxy maps it to `START + MIDDLE*(L-2) + END`; Build does not call Pickup for geometry or resources.

## Pickup

Root:

```text
Contents/mods/LMION_Pickup/42/
```

Bootstrap:

```text
media/lua/shared/LMION/Pickup.lua
```

It requires Core, then Pickup-owned modules only.

Important areas:

```text
shared/LMION/Pickup/Doors/*
shared/LMION/Pickup/GarageDoor*.lua
shared/LMION/Pickup/LargeGate*.lua
server/LMION/Pickup/GarageDoorCursor.lua
server/LMION/Pickup/LargeGateCursor.lua
client/LMION/Pickup/*
```

Pickup owns eligibility, tools, parcels, source-state transport and placement actions. It consumes Core topology/state primitives but does not consume Build modules.

### Garage Pickup

`GarageDoorPickup.lua` asks Core for the actual native chain. `GarageDoorPlacement.lua` owns parcel-based variable reinstallation. The historical synthetic L3 SpriteGrid remains a vanilla Moveables compatibility/discovery artifact, not LMION variable geometry.

### Large-gate Pickup

Large gates use Core A/B semantics. Pickup's one-leaf transport is independent from Build's construction representation. Older prose describing these logical leaves as generic left/right should be read as historical wording; A/B is the current large-gate vocabulary.

## Debug

Root:

```text
Contents/mods/LMION_Debug/42/
```

Debug owns Inspector, world selection, Test Zone, reload helpers and diagnostic actions. It may inspect Core/runtime state, but gameplay addons must never require Debug.

## Phase/load-order boundary

Do not confuse addon ownership with Lua phase ownership.

Verified B42 rules are documented in `Research/Engine/B42LuaLoadOrder.md`. Key consequence for current Build architecture:

```text
shared GarageBuildCursor.lua
-> definitions/install function only; no server-class top-level require

server GarageBuildCursorHook.lua
-> require BuildingObjects/ISBuildIsoEntity
-> install hook
```

Similarly, garage sprite/property validation on cold start belongs after `OnLoadedTileDefinitions`; immediate reload paths require a positive readiness probe.

## Representation boundary

All addons target Core's semantic API rather than implementing separate persistent Java backends.

```text
supported source: IsoDoor or IsoThumpable(isDoor)
LMION managed output: IsoDoor
```

Build may encounter temporary construction `IsoThumpable` objects; Pickup may ingest legacy/vanilla `IsoThumpable` doors. Neither addon owns the choice of final representation.

## Audit result — 2026-08-29

Static source/dependency audit found no architecture regression:

- declared addon dependency graph is correct;
- Build bootstrap has no Pickup/Debug dependency;
- Pickup bootstrap has no Build/Debug dependency;
- Core remains the shared semantic layer;
- Debug remains development-only;
- variable garage Build consumes Core garage semantics directly and does not depend on Pickup;
- variable garage Pickup remains self-contained and does not depend on Build;
- canonical representation ownership remains in Core.

This is a source/architecture audit, not a substitute for runtime combination testing. A useful release-confidence matrix remains `Core+Build`, `Core+Pickup`, `Core+Debug`, `Core+Build+Pickup`, plus multiplayer variable-Build validation.
