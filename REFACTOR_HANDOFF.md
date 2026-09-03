# LMION Refactor Handoff

This repository is the development workspace for the LMION rewrite.

## Repository roles

- `Coudji/LMION_Legacy` = development workspace, research archive, old implementation reference and refactor test area.
- `Coudji/PZMOD_LMION` = clean final repository managed manually by Coudji.
- Never write to `PZMOD_LMION` unless Coudji explicitly reverses that rule.

## Refactor rule

> **Behavior already validated in game is the contract. Refactoring must adapt to that behavior, not redefine it.**

The functional baseline before the Pickup cleanup is:

```text
0549bfcaec05ef1d6db1ca9137ac3dbdaff3ff8f
branch: baseline-pre-refactor-0549bf
```

Use that commit as the reference when a refactor changes an established behavior.

A later smoke-tested checkpoint before the action-router experiment is:

```text
95bcd9abd26d4426c618bcc27fea3c219ab74d3e
branch: backup-main-2026-09-03-tested-pre-action-router
```

Do not preserve an abstraction merely because it reduces line count. If Garage, Simple and LargeGate require different hooks to preserve their vanilla contracts, keep those hooks family-local.

## Architecture

> **Core owns opening data and stable contracts. Common owns genuinely common plumbing. Families own topology-specific behavior.**

```text
                         Core
             definitions / geometry / topology
                          |
                          v
                       Pickup
             +------------+------------+
             |            |            |
           Simple       Garage      LargeGate
             \            |            /
              +------ Common helpers --+
```

Core knows the registered openings and exposes the information mechanics need. Pickup must not maintain a second concrete door catalog.

`Common` must not force identical behavior on different families. A helper belongs in `Common` only when its input/output contract is genuinely the same for every caller.

Current common placement helpers:

```text
LMION/Pickup/Common/
├── GhostRender.lua
├── ParcelUtils.lua
├── PlacementActionUtils.lua
├── PlacementCursorUtils.lua
└── PlacementRules.lua
```

The attempted common `MoveableToolbarRouter` / `MoveablesActionRouter` were removed after they changed the validated vanilla-toolbar behavior. Do not reintroduce a global router unless every dispatch contract is first proven equivalent.

## Function-design rule

Prefer small functions with one obvious responsibility. A reader should normally understand a function without tracing a hundred lines of unrelated hook setup.

Good family-local decomposition examples:

```text
installFaceHooks()
installInventoryHooks()
installCanPickUpHook()
installPickUpInternalHook()
installCanPlaceHook()
installPlaceHook()
```

Duplication is acceptable when two functions only look similar but have different behavioral contracts. Remove semantic duplication, not necessary specialization.

## Data vocabulary

```text
defaultId     -> DefinitionDefault identity
definitionId  -> concrete LMION opening identity
entity        -> PZ GameEntity identity
extensionId   -> extension/patch identity
inherits      -> one concrete Definition -> one DefinitionDefault
```

No generic top-level `id`, no removed `class`. Technical IDs use `Wood` and `Metal`.

DefinitionDefaults never inherit other defaults. Catalog and DefinitionDefault files are pure data and do not register themselves.

## Current Core runtime

Workshop contains a runnable B42 Core with Registry/Resolver/Validation, GameEntity reverse lookup, world-object lookup and `Core/DoorRuntime.lua` for physical door state/placement helpers.

World-object identity is:

```text
IsoDoor / IsoObject
-> getEntityScript():getFullName()
-> EntityIndex
-> definitionId
```

Do not use current sprite as the primary identity mechanism when Core can provide entity/definition identity.

Geometry remains explicit and exact; do not infer complex geometry by sprite-number arithmetic.

## Pickup families

### Simple

Simple covers one-tile openings and paired one-tile members supported by `Simple/MoveableAdapter.lua`.

Inventory right-click placement uses the dedicated LMION cursor and plan path.

Important preserved behavior:

- N/W rotation through the dedicated cursor;
- standard-frame requirement remains enforced;
- persisted HP/state is restored after placement;
- same-Z validation occurs before movable cheat bypass, matching the pre-refactor behavior.

### Garage

Garage topology is variable-length for dedicated inventory placement and fixed L3 for the vanilla toolbar.

These are intentionally different behaviors:

```text
inventory right-click -> dedicated LMION cursor -> variable width
vanilla toolbar       -> synthetic SpriteGrid -> fixed L3
```

The synthetic toolbar SpriteGrid is not the semantic garage topology. `GaragePlacement` resolves the actual START / MIDDLE* / END parcels.

`GarageToolbarAdapter` owns the Garage-specific vanilla hooks:

- N/W face mapping;
- `findInInventory`;
- `findInInventoryMultiSprite`;
- synthetic L3 SpriteGrid;
- multi-sprite placement finalization.

Do not replace those with a generic toolbar-item selection scheme unless it reproduces the validated baseline exactly.

### LargeGate

A LargeGate is handled per leaf/vantail. Each leaf uses two physical parcels.

Dedicated inventory placement is LMION-owned.

The toolbar deliberately follows the vanilla multi-sprite path. The validated toolbar contract is:

```text
part 1 parcel in inventory
    -> toolbar representative / anchor
    -> vanilla SpriteGrid ghost and rotation
    -> LargeGate placement validation resolves part 2 from inventory/floor
```

Only `partIndex == 1` creates the toolbar entry. This is not an arbitrary restriction: part 1 is the visual/geometry anchor used by the validated vanilla pipeline.

`LargeGateToolbar.lua` therefore keeps its own `findInInventory` hook instead of sharing Garage's lookup semantics.

## Placement pipelines

### Dedicated inventory placement

This path is LMION-owned:

```text
right-click Place
-> family cursor
-> family plan
-> LMION ghost
-> LMION timed action
-> family placement
-> parcel consumption
```

Garage variable width and LargeGate leaf reconstruction live here.

### Vanilla toolbar placement

This path should remain vanilla as far as practical:

```text
ISMoveableCursor
-> inventory object list + family adapter
-> vanilla facing / SpriteGrid ghost
-> family canPlace override only where required
-> vanilla walkToAndEquip
-> ISMoveablesAction
-> family completion/finalization only where required
```

LMION may adapt tools, actions, parcel lookup and finalization, but should not replace the whole toolbar pipeline merely to make the families look uniform.

## Transport state

Transport uses the generic item:

```text
Base.LMION_OpeningParcel
```

`TransportState` preserves stable opening identity plus physical state such as HP/max HP. Family placement restores that state after the physical world object is finalized.

For multi-square families, parcel source (`inventory` container or `"floor"`) is resolved while building the family plan and is authoritative during consumption.

## Load-order rule

Core registration follows the verified scope/mod ordering in `Legacy/Research/Architecture/CoreLoadOrder.md`.

For gameplay/UI cross-tree code, preserve the Legacy pattern:

```text
server cursor file
    -> loads normally in server/gameplay scope

client inventory hook
    -> do not require server/BuildingObjects cursor during early client load
    -> wait until OnGameStart
    -> install handoff only when both sides are available
```

PZ autoexecutes Lua files in each active scope; do not add an entrypoint solely to make an ordinary cursor file execute.

## Known behavior to preserve

- finalized LMION doors persist as `IsoDoor`;
- `IsoThumpable(isDoor)` accepted as source input only where supported;
- physical tool and governing skill remain separate;
- vanilla Moveables may overwrite item weight during `ReadFromWorldSprite`, so synchronize both weight fields;
- HP/max HP survive pickup and replacement;
- standard framed doors still require their frame;
- Garage toolbar places fixed L3 while inventory placement remains variable;
- LargeGate pickup/placement operates per leaf;
- LargeGate and Garage placement can resolve required secondary parcels from the nearby floor where the validated family pipeline supports it;
- special pickup/preview rendering must stay family-local when its color/model rules differ from the common green/red ghost.

## Crash-test checklist after refactor

Test both N and W when relevant.

```text
Simple
- pickup
- inventory Place
- toolbar Place where applicable
- rotation
- frame rejection
- damaged HP persists

Garage
- pickup full chain
- inventory Place at variable widths
- toolbar fixed L3
- START / MIDDLE / END split between inventory and nearby floor
- no parcel left over
- damaged HP persists

LargeGate
- pickup one leaf
- inventory Place with one parcel on floor
- toolbar ghost shows the complete leaf
- toolbar placement with part 1 in inventory and part 2 nearby on floor
- rotation
- partner leaf open/closed parity
- damaged HP persists
```

If a crash-test case fails, instrument the narrow family path first. Useful diagnostics are parcel identity, item ID, selected source, plan entries and consume result. Avoid broad logging across unrelated families.

## Git workflow

- Work only in `Coudji/LMION_Legacy` unless explicitly told otherwise.
- Workshop = clean candidate tree.
- Legacy = old code/research/history.
- Coudji manually copies validated Workshop content to `PZMOD_LMION`.
- Re-fetch `LMION_Legacy/main` before writes.
- Prefer coherent, behavior-preserving commits.

Important refs:

```text
baseline-pre-refactor-0549bf
backup-main-2026-09-03-tested-pre-action-router
backup-main-2026-09-03-refactor-complete-pre-crash-test
```
