# LMION current state / conversation handoff

Last updated: 2026-09-04

This file is the canonical handoff for continuing development after a conversation reset/limit.
Keep it short enough to read quickly, but complete enough that a new session does not need to rediscover the repository history.

## Current product direction

LMION V3 will be **one mod with all gameplay features always loaded**.

The previous goal of independently loadable gameplay submods (`Core`, `Pickup`, `Build`, later `Lock`) is abandoned.
Do not reintroduce feature toggles as a substitute: load-time hooks, SpriteGrid/script mutations and lifecycle-sensitive behavior make true runtime disablement unreliable and would recreate the same complexity.

Debug may remain a separate development tool because it is not player-facing gameplay functionality.

## Repository decision

V3 should live in a **new clean repository**, rather than moving all V1/V2 material into an `archive/` directory inside this repository.

Recommended target repository name:

```text
Coudji/LMION
```

Reason:

- this repository is already named `LMION_Legacy` and is now accurately the archaeology/reference repository;
- keeping it intact preserves Git history, old paths, research links and easy V1/V2 comparison;
- a new repository gives V3 a clean root where everything visible is current;
- it avoids a giant rename/move commit whose only purpose would be cosmetic cleanup.

Do not modify `Coudji/PZMOD_LMION` unless Coudji explicitly asks. That repository remains manually managed.

Until the new V3 repository exists, this file remains the canonical handoff. Once it exists, migrate the active handoff and selected active research there, then keep this repository as historical reference.

## V3 architecture goals

The internal source must be organized by responsibility/domain, not by historical addon packaging.
Target naming can evolve, but the intended shape is along these lines:

```text
LMION/
├─ API/
├─ Definitions/
├─ Domain/
├─ Runtime/
├─ Services/
├─ Hooks/
├─ UI/
├─ PZ/
└─ Persistence/
```

Subfolders may specialize by door family where needed.

Hard rules:

- one function = one responsibility/intention;
- one file = one identifiable responsibility;
- hooks should be small adapters and delegate business logic;
- one owner per vanilla hook/behavior boundary;
- do not copy vanilla behavior when calling the previous/original implementation is sufficient;
- LMION takes control only at the narrow point where vanilla cannot satisfy the desired behavior, then gives control back as soon as possible;
- no generic routers/managers/bridges that know every family merely to reduce line count;
- prefer a few simple specialized implementations over one huge branch-heavy abstraction;
- do not mix behavior changes with pure code moves/refactors;
- abstractions must solve an existing duplicated contract, not hypothetical future needs.

## Public addon API direction

Although LMION itself is one mod, it should remain addon-friendly for external modders.

External addons should target a small stable facade such as:

```lua
local LMION = require "LMION/API"
```

Internal modules (`Hooks`, `Runtime`, `Services`, etc.) are not public contracts and may change.

Existing V2 work worth preserving conceptually:

- explicit `definitionId`, `defaultId`, `extensionId`;
- pure data definitions/defaults;
- private Registry/Resolver internals;
- `registerDefinition`, `registerDefault`, `registerExtension`, `registerContent` style API;
- explicit semantic `doorType`.

Current supported `doorType` vocabulary:

```text
Simple
Paired
FenceGate
Sliding
LargeGate
Garage
```

Future ideas such as `LargeSliding` / `PairedSliding` are not implemented and must not drive present abstractions.

`doorType` says what an opening is. Internal consequences such as frame requirement, placement strategy, topology handling and toolbar behavior should be derived internally whenever possible.

## Repository roles

- `Legacy/Contents` — **behavioral oracle** for already validated features. Do not rewrite it; use it to recover working behavior.
- `Legacy/Research` — engine forensics and validated implementation knowledge. Treat active research as development constraints, not passive prose.
- `Workshop` — V2 refactor/candidate tree. Use it as a migration source only; newer does not automatically mean better.
- `REFACTOR_HANDOFF.md` — previous V2 refactor handoff. Historical now; do not use as the current plan.
- `V3_REPOSITORY_AUDIT.md` — current keep/migrate/archive/delete inventory.

Current `main` before V3 audit work started:

```text
6247ba9b87100bd70106c82c18330f9b00687f0d
```

This V2 head is known to have a LargeGate toolbar placement regression and is not a release/behavioral baseline.

Useful historical refs:

```text
baseline-pre-refactor-0549bf
backup-main-2026-09-03-tested-pre-action-router
```

`Legacy/Contents` still wins when V2 behavior conflicts with established validated behavior.

## Research guardrail

Before changing a PZ integration point that has already been researched, read the corresponding note first.

High-value required references:

```text
Legacy/Research/Engine/B42LuaLoadOrder.md
Legacy/Research/Engine/LoadLifecycle.md
Legacy/Research/Moveables/VanillaMoveablesBehavior.md
```

Important known lifecycle facts:

- `media/scripts` are parsed before Lua and require full restart after changes;
- normal initial Lua execution is shared, then client; server Lua comes later in SP;
- dedicated server discovers but does not execute client Lua;
- files in an active Lua tree auto-execute in case-insensitive alphabetical path order;
- shared/client code must not require server-only vanilla Lua before server phase;
- `OnLoadedTileDefinitions` is authoritative for tile/sprite-derived mutations such as SpriteGrid/property state that can be reset by tile loading;
- `OnGameBoot` is used for script/GameEntity topology mutations when appropriate;
- `LoadGridsquare` / `OnObjectAdded` are for live world-instance adoption, not script topology;
- active cursors/actions/UI can retain stale closures after Lua reload;
- after hook/load-order structure changes, use a cold restart before concluding behavior is broken.

Do not guess a lifecycle boundary if research already exists.

## Research maintenance rule

Any expensive new discovery must be written into `Legacy/Research` (or the future active V3 research location) before the related bug/work item is considered complete.

A useful research note should record:

1. question/symptom;
2. evidence/source;
3. conclusion;
4. LMION decision;
5. rejected/failed approaches;
6. lifecycle/load-order constraint;
7. addon-facing contract when relevant;
8. what would require revalidation.

Explicitly preserve failed approaches so a later session does not repeat them.

## Known gameplay contracts to preserve

These are established behaviors unless explicitly redesigned by the user:

- LMION-managed final world doors are `IsoDoor` where the established path expects that representation;
- HP/max HP survive pickup and replacement;
- standard framed doors require the correct frame;
- inventory right-click Place uses LMION-owned placement UI/cursor behavior where already established;
- vanilla Moveables toolbar should retain vanilla ghost/facing/click-drag behavior unless a narrow LMION adaptation is required;
- Garage inventory placement supports variable width;
- Garage toolbar intentionally remains fixed L3 through vanilla multisprite behavior;
- LargeGate operates per A/B leaf, each leaf containing two physical members/parcels;
- Garage and LargeGate placement can consume compatible required parcels from inventory and nearby floor where Legacy supports it;
- compatible multi-part parcels are interchangeable by part identity; no bundle/assembly identity is currently desired;
- definitions should contain explicit geometry rather than inferred sprite arithmetic for complex types.

## Current V2 LargeGate failure (historical context, not the V3 plan)

The last V2 simplification removed extra `ISMoveablesAction` and parity placement hooks to get closer to Legacy's vanilla path.
After a full restart, the toolbar ghost displayed correctly but clicking did not place the gate.
The exact cancellation boundary was not instrumented before the decision to stop V2.

Do not resume speculative patching on that V2 stack.
If LargeGate is ported to V3, recover the validated Legacy path and instrument narrow vanilla boundaries before changing behavior.

## Current audit findings

Workshop currently contains only two gameplay Mod IDs:

```text
LMION_Core
LMION_Pickup
```

`LMION_Pickup` explicitly requires `LMION_Core` in `mod.info`; this packaging is V2-only and will not be preserved in V3.

Workshop Core contains:

- a large populated Lua catalog and DefinitionDefaults tree;
- matching `media/scripts/LMION/...` GameEntity/script definitions for many door families;
- Registry/Resolver/API/index/runtime modules;
- translations;
- Garage sandbox settings.

Workshop Pickup contains:

- two validated/custom AnimSets;
- one generic `Base.LMION_OpeningParcel` script item;
- translations;
- client/server/shared Lua for UI, cursors, hooks, placement and transport.

The V2 source also contains very large files (examples: `MoveableAdapter.lua` ~21 KB, `LargeGatePlacement.lua` ~17 KB, `LargeGatePickup.lua` ~16 KB, `GaragePickup.lua` ~14 KB, `GarageToolbarAdapter.lua` ~14 KB), confirming that these runtime files should be treated as migration sources/knowledge rather than copied wholesale into V3.

## Immediate V3 plan

1. Continue the audit in `LMION_Legacy` without destructive moves.
2. Finish classifying data/scripts/assets/research into migration units.
3. Create the new clean V3 repository once the minimal seed set is identified.
4. Seed V3 with project guardrails/research first, then package skeleton.
5. Migrate data/API foundations before gameplay runtime.
6. Port one small behavior path at a time and test it before cleanup.
7. Keep `CURRENT_STATE.md` updated at meaningful checkpoints and **before/through any long operation likely to span a conversation limit**.

## Handoff discipline for future conversations

At the start of a new conversation:

1. read this file first;
2. read `V3_REPOSITORY_AUDIT.md` if doing migration work;
3. read only the research notes relevant to the subsystem being changed;
4. inspect current source before writing;
5. do not infer current project direction from stale V2 architecture docs.

During work, update this file whenever one of these changes:

- current objective;
- architectural decision;
- validated runtime behavior;
- failed approach worth avoiding;
- current broken state;
- exact next step;
- important commit/checkpoint.

The goal is that a conversation can end mid-operation without requiring Coudji to reconstruct the project history manually.
