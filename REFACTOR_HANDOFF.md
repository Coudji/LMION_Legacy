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

Do not preserve an abstraction merely because it reduces line count. If different door types require different hooks to preserve their vanilla contracts, keep those differences behind explicit type-specific functions.

`Legacy/Contents` is the behavioral reference when the rewrite and recent refactor history disagree about an established feature.

## Refactor direction agreed on 2026-09-04

The public door model must describe what a door **is**, not expose Pickup implementation details.

Every supported definition will resolve to one explicit `doorType` from the current list:

```text
Simple
Paired
FenceGate
Sliding
LargeGate
Garage
```

Possible future ideas such as `LargeSliding` and `PairedSliding` are deliberately **not implemented or registered yet**. They only serve as architecture sanity checks: adding a new type later must not require rewriting every existing placement/pickup path.

`doorType` is the semantic discriminator. Internal consequences such as frame requirements, opening topology, placement strategy and toolbar adaptations belong to Core/Pickup internals rather than public modder data whenever they can be derived from the type.

During migration, existing fields such as `frame` may remain temporarily so behavior can be changed in small, testable commits. They must not remain a second competing source of truth once all runtimes use `doorType`.

Complex definitions still provide the data Core cannot invent, notably their concrete members/entities and explicit geometry.

## UI and placement contract

There are intentionally two placement frontends.

### Dedicated inventory placement

Right-click Place is LMION-owned:

```text
inventory item
-> LMION cursor
-> R rotation / LMION controls
-> type-specific plan
-> LMION placement
```

This path already works and must not be rewritten merely to make the toolbar look uniform.

### Vanilla toolbar placement

The left toolbar intentionally keeps the vanilla Moveables user experience:

```text
ISMoveableCursor
-> vanilla face/SpriteGrid handling
-> click-drag facing selection
-> targeted LMION adaptations where vanilla cannot represent the door
-> type-specific placement/finalization
```

The toolbar is an adapter around vanilla behavior, **not a second business-logic implementation and not a replacement LMION cursor**.

A toolbar hook may translate vanilla questions (face, SpriteGrid member, parcel lookup, action completion) into LMION data, or stop a vanilla step that is known to be wrong for that door type. It should reuse the same lower-level parcel/plan/placement logic used elsewhere whenever the behavioral contract is actually the same.

Garage remains intentionally fixed to L3 through the vanilla toolbar because of the vanilla multi-sprite path, while dedicated inventory placement remains variable-length.

## Architecture

> **Core owns opening data and stable contracts. UI adapters own integration details. Type-specific code owns only behavior that genuinely differs. Common owns genuinely common plumbing.**

```text
                         Core
              definitions / doorType / geometry
                          |
                          v
                       Pickup
                          |
             +------------+------------+
             |                         |
  Inventory placement          Vanilla toolbar adapter
     LMION cursor                click-drag / SpriteGrid
             |                         |
             +------------+------------+
                          |
                          v
                  type-specific behavior
              Simple / Paired / FenceGate
              Sliding / Garage / LargeGate
                          |
                          v
                    Common helpers
```

Core knows the registered openings and exposes the information mechanics need. Pickup must not maintain a second concrete door catalog.

A shared pipeline does **not** mean every door type executes identical code. It means common stages dispatch to small type-specific operations when a real behavioral difference exists.

`Common` must not force identical behavior on different types. A helper belongs in `Common` only when its input/output contract is genuinely the same for every caller.

Current common placement helpers:

```text
LMION/Pickup/Common/
├── GhostRender.lua
├── ParcelUtils.lua
├── PlacementActionUtils.lua
├── PlacementCursorUtils.lua
└── PlacementRules.lua
```

The attempted common `MoveableToolbarRouter` / `MoveablesActionRouter` were removed after they changed the validated vanilla-toolbar behavior. Do not reintroduce a global router whose purpose is merely to hide family differences.

## Function-design rule

Prefer small functions with one obvious responsibility. A reader should normally understand a function without tracing a hundred lines of unrelated hook setup.

A toolbar file should not simultaneously own UI discovery, parcel semantics, placement-plan construction, world placement and consumption if those responsibilities can be named and separated cleanly.

Good hook decomposition examples:

```text
installFaceHooks()
installInventoryHooks()
installCanPickUpHook()
installPickUpInternalHook()
installCanPlaceHook()
installPlaceHook()
```

Duplication is acceptable when two functions only look similar but have different behavioral contracts. Remove semantic duplication, not necessary specialization.

## Public data vocabulary

```text
defaultId     -> DefinitionDefault identity
definitionId  -> concrete LMION opening identity
doorType      -> explicit supported door behavior/type
entity        -> one PZ GameEntity identity
entities      -> named PZ GameEntity members for a composite definition
geometry      -> explicit physical sprite geometry
extensionId   -> extension/patch identity
inherits      -> one concrete Definition -> one DefinitionDefault
```

No generic top-level `id`, no removed `class`. Technical IDs use `Wood` and `Metal`.

DefinitionDefaults never inherit other defaults. Catalog and DefinitionDefault files are pure data and do not register themselves.

Do not add public fields such as `placementStrategy`, `toolbarStrategy` or `memberInteraction` merely to expose implementation choices. If `doorType` determines a rule, keep the rule internal.

## Current Core runtime

Workshop contains a runnable B42 Core with Registry/Resolver/Validation, GameEntity reverse lookup, world-object lookup and `Core/DoorRuntime.lua` for physical door state/placement helpers.

`Core/DoorTypes.lua` is the internal registry for currently supported `doorType` values and their derived characteristics. It is intentionally small; future unimplemented door ideas are not registered there.

World-object identity is:

```text
IsoDoor / IsoObject
-> getEntityScript():getFullName()
-> EntityIndex
-> definitionId
```

Do not use current sprite as the primary identity mechanism when Core can provide entity/definition identity.

Geometry remains explicit and exact; do not infer complex geometry by sprite-number arithmetic.

## Current door types

### Simple

One-tile ordinary door. Current implementation uses the single-tile Moveables plumbing.

### Paired

Two named one-tile members (`left` / `right`) with paired-frame placement semantics. The members are independent doors; paired geometry must remain explicit.

### FenceGate

One-tile fence gate. It may currently share single-tile technical plumbing with Simple, but it remains a distinct `doorType`.

### Sliding

Current one-tile sliding door. It may currently share single-tile technical plumbing with Simple, but it remains a distinct `doorType`; do not define Sliding as “Simple with no frame”.

### Garage

Garage topology is variable-length for dedicated inventory placement and fixed L3 for the vanilla toolbar.

These are intentionally different behaviors:

```text
inventory right-click -> dedicated LMION cursor -> variable width
vanilla toolbar       -> synthetic SpriteGrid -> fixed L3
```

The synthetic toolbar SpriteGrid is not the semantic garage topology. Actual placement resolves START / MIDDLE* / END parcels.

### LargeGate

A LargeGate is handled per leaf/vantail. Each leaf uses two physical parcels. Dedicated inventory placement is LMION-owned; the toolbar keeps the vanilla multi-sprite ghost/rotation path and must be able to resolve required nearby parcels according to the Legacy behavior.

## Transport state

Transport uses the generic item:

```text
Base.LMION_OpeningParcel
```

`TransportState` preserves stable opening identity plus physical state such as HP/max HP. Type-specific placement restores that state after the physical world object is finalized.

For multi-square types, parcel source must reflect the actual item that will be consumed. Do not apply speculative source corrections without reproducing the Legacy behavior that is known to work in game.

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

## Refactor sequence

Work in small behavior-preserving commits.

1. Add explicit `doorType` to the current definitions/defaults.
2. Make Core/Pickup routing use `doorType` instead of inferring type from `frame` or geometry shape.
3. Keep the working dedicated inventory placement unchanged except for routing cleanup.
4. Compare vanilla-toolbar hooks directly against `Legacy/Contents` and reduce toolbar files to targeted adapters.
5. Stabilize toolbar behavior type by type: Simple, Paired, FenceGate, Sliding, Garage, LargeGate.
6. Only after runtime behavior is stable, remove transitional public fields whose meaning is now fully derived from `doorType`.
7. Perform the full strict validation/documentation pass after the public API shape is complete.

Do not implement future `LargeSliding` / `PairedSliding` in this sequence.

## Known behavior to preserve

- finalized LMION doors persist as `IsoDoor`;
- `IsoThumpable(isDoor)` accepted as source input only where supported;
- physical tool and governing skill remain separate;
- vanilla Moveables may overwrite item weight during `ReadFromWorldSprite`, so synchronize both weight fields;
- HP/max HP survive pickup and replacement;
- standard framed doors still require their frame;
- dedicated inventory placement uses the LMION cursor and R rotation;
- vanilla toolbar placement keeps vanilla click-drag rotation;
- Garage toolbar places fixed L3 while inventory placement remains variable;
- LargeGate pickup/placement operates per leaf;
- LargeGate and Garage placement must reproduce the Legacy nearby-floor behavior where Legacy supports it;
- special pickup/preview rendering must stay type-specific when its color/model rules differ from the common green/red ghost.

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

Paired
- pickup left and right members
- inventory Place
- toolbar Place
- correct paired frame side
- damaged HP persists

FenceGate / Sliding
- pickup
- inventory Place
- toolbar Place
- rotation
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
- toolbar placement with required parcels split between inventory and nearby floor
- rotation
- partner leaf open/closed parity
- damaged HP persists
```

If a crash-test case fails, instrument the narrow type path first. Useful diagnostics are `doorType`, parcel identity, item ID, selected source, plan entries and consume result. Avoid broad logging across unrelated types.

## Git workflow

- Work only in `Coudji/LMION_Legacy` unless explicitly told otherwise.
- Workshop = clean candidate tree.
- Legacy = old code/research/history and behavioral reference.
- Coudji manually copies validated Workshop content to `PZMOD_LMION`.
- Re-fetch `LMION_Legacy/main` before writes.
- Prefer coherent, behavior-preserving commits.

Important refs:

```text
baseline-pre-refactor-0549bf
backup-main-2026-09-03-tested-pre-action-router
backup-main-2026-09-03-refactor-complete-pre-crash-test
```
