# LMION Refactor Handoff

This repository is the development workspace for the LMION rewrite.

## Repository roles

- `Coudji/LMION_Legacy` = development workspace, research archive, old implementation reference and refactor test area.
- `Coudji/PZMOD_LMION` = clean final repository managed manually by Coudji.
- Never write to `PZMOD_LMION` unless Coudji explicitly reverses that rule.

## Architecture

> **Core owns opening content and stable contracts. Submods own mechanics. No submod owns the opening catalog.**

```text
Build  ─┐
Pickup ─┼─> Core
Lock   ─┘
```

Mechanics must not hard-code concrete opening catalogs.

## Data vocabulary

```text
defaultId     -> DefinitionDefault identity
definitionId  -> concrete LMION opening identity
entity        -> PZ GameEntity identity
extensionId   -> extension/patch identity
inherits      -> one concrete Definition -> one DefinitionDefault
```

No generic top-level `id`, no `kind`, no removed `class`. Technical IDs use `Wood` and `Metal`.

DefinitionDefaults never inherit other defaults. Catalog and DefinitionDefault files are pure data and do not register themselves.

## Current Core runtime

Workshop contains a runnable B42 Core with Registry/Resolver/Validation, GameEntity reverse lookup, world-object lookup and `Core/DoorRuntime.lua` for physical door state/placement helpers.

Live Core state remains:

```text
23 defaults
54 definitions
58 GameEntity mappings -> 54 definitions
56/58 PZ GameEntities found
```

The expected missing scripts are still:

```text
Base.LargeWroughtIronGate
Base.LargeHardenedWoodenGate
```

Keep those diagnostic errors for now.

## Public Core direction

Core exposes registration/resolution, GameEntity/world-object lookup, and the door runtime helpers needed by mechanics. Registry stays private. Resolver returns fresh effective data.

World-object identity is:

```text
IsoDoor / IsoObject
-> getEntityScript():getFullName()
-> EntityIndex
-> definitionId
```

Do not use current sprite as the primary identity mechanism.

## Load-order rule that must not be forgotten

Core registration follows the verified scope/mod ordering in `Legacy/Research/Architecture/CoreLoadOrder.md`.

For gameplay/UI cross-tree code, preserve the **Legacy garage pattern**:

```text
server cursor file
    -> loads normally in server/gameplay scope

client inventory hook
    -> DO NOT require server/BuildingObjects cursor during early client load
    -> wait until OnGameStart
    -> install handoff only when both sides are available
```

This matters because `BuildingObjects/ISMoveableCursor` can be unavailable during early client loading. A rewritten Pickup experiment reproduced that failure on 2026-08-31 and was replaced with the Legacy pattern.

PZ autoexecutes Lua files in each active scope; do not add an entrypoint solely to make an ordinary cursor file execute.

## Geometry pilots

```text
Doors.Wood.WhitePanelDoor
N closed fixtures_doors_01_1
N open   fixtures_doors_01_3
W closed fixtures_doors_01_0
W open   fixtures_doors_01_2

Doors.Wood.WhiteRestroomStallDoor
N closed fixtures_doors_02_21
N open   fixtures_doors_02_23
W closed fixtures_doors_02_20
W open   fixtures_doors_02_22
```

Geometry is explicit and exact; do not infer complex geometry by sprite-number arithmetic.

## Rewritten Pickup slice

Workshop contains `LMION_Pickup` with capability-driven simple 1x1 support. Pickup does not own concrete DoorProfiles.

Current compatible pilots should produce:

```text
[LMION:Pickup] simple 1x1 registry ready: 2 definitions, 8 sprites
```

Transport uses one generic item:

```text
Base.LMION_OpeningParcel
```

Placement now follows the proven garage architecture rather than patching `ISMoveableCursor` globally:

```text
server/LMION/Pickup/SimpleDoorCursor.lua
client/LMION/Pickup/PlacementHandoff.lua
```

Client handoff installs at `OnGameStart`. The dedicated cursor disables mouse rotation and uses `R` / `Rotate building` for N/W.

Detailed design/test note: `Legacy/Research/Architecture/PickupRewrite.md`.

## Known Legacy behavior to preserve

- finalized LMION doors persist as `IsoDoor`;
- `IsoThumpable(isDoor)` accepted as source input only;
- framed doors: screwdriver pickup/replacement;
- frameless/gate-like: crowbar pickup, hammer replacement;
- physical tool and governing skill remain separate;
- vanilla Moveables may overwrite item weight during `ReadFromWorldSprite`, so synchronize both weight fields;
- LMION standards are defaults, not limitations;
- MetalBar/IronBar alternatives remain supported where reviewed.

## Immediate next test

With Workshop Core + Pickup enabled, use `WhiteRestroomStallDoor` first.

Expected:

```text
boot -> simple 1x1 registry line
OnGameStart -> simple-door Place handoff line
pickup -> one generic parcel
Place -> dedicated ghost preview
R -> N/W
valid frame -> functioning IsoDoor
health survives
```

Do not add paired/large/garage rewrite code until this simple vertical slice is sound.

## Git workflow

- Work only in `Coudji/LMION_Legacy` unless explicitly told otherwise.
- Workshop = clean candidate tree.
- Legacy = old code/research/history.
- Coudji manually copies validated Workshop content to `PZMOD_LMION`.
- Re-fetch `LMION_Legacy/main` before writes.
- Prefer coherent commits.

Pre-reorganization backup:

```text
backup/main-before-workshop-refactor-20260830
```
