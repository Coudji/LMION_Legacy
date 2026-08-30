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

Workshop contains a runnable B42 Core with:

```text
LMION/API.lua
LMION/Core/Bootstrap.lua
LMION/Core/BuiltinContent.lua
LMION/Core/Diagnostics.lua
LMION/Core/DoorRuntime.lua
LMION/Core/EntityIndex.lua
LMION/Core/GameEntityValidation.lua
LMION/Core/ObjectLookup.lua
LMION/Core/Registry.lua
LMION/Core/Resolver.lua
LMION/Core/TableUtils.lua
LMION/Core/Validation.lua
```

`LMION_Core.lua` is the runtime startup. `API.lua` exposes the API only.

## Live Core tests completed

In-game bootstrap/resolution is validated:

```text
23 defaults
54 definitions
0 extensions
```

Reverse indexing is also live-tested:

```text
58 GameEntity mappings -> 54 definitions
56/58 GameEntities found in PZ ScriptManager
```

The only missing mappings are expected development gaps because their new large-gate scripts have not been created yet:

```text
Base.LargeWroughtIronGate
Base.LargeHardenedWoodenGate
```

Keep these diagnostic errors for now; do not waste time special-casing them.

The verbose `[LMION:Catalog]` line-per-definition dump was removed. Keep summary lines plus anomalies only.

## Public Core API

```lua
local LMION = require "LMION/API"

LMION.registerDefault(...)
LMION.registerDefinition(...)
LMION.registerExtension(...)
LMION.registerContent(...)

LMION.getEffectiveDefault(defaultId)
LMION.getEffectiveDefinition(definitionId)
LMION.getDefinitionIdByEntity(entityId)
LMION.getEffectiveDefinitionByEntity(entityId)

LMION.getEntityIdForObject(object)
LMION.getDefinitionIdForObject(object)
LMION.getEffectiveDefinitionForObject(object)

LMION.isDoorObject(object)
LMION.captureDoorState(object)
LMION.restoreDoorState(object, state)
LMION.canPlaceDoorAt(square, facing, frame, pairedFrameSide)
LMION.finalizePlacedDoor(object, definition, facing)
```

Registry is private. Resolver returns fresh effective data.

## Lookup contract

The uploaded B42.20.3 jar confirms:

```text
IsoObject extends GameEntity
GameEntity.getEntityScript()
GameEntityScript.getFullName()
```

World-object lookup uses stable GameEntity identity:

```text
IsoDoor / IsoObject
-> getEntityScript():getFullName()
-> EntityIndex
-> definitionId
```

Do not use current sprite as the primary identity mechanism.

Different definitions cannot claim the same GameEntity. A mod modifying an existing definition must use `registerExtension`.

Detailed lookup doc: `Legacy/Research/Architecture/CoreEntityLookup.md`.

## Extensions and load order

Resolution order:

```text
raw default
-> default extensions in registration order
-> concrete definition overrides
-> concrete definition extensions in registration order
-> effective definition
```

No priority score. Later same-layer registration/load order wins.

Verified B42.20.3 Lua loading:

```text
client: shared -> client -> OnGameBoot later
server: shared -> client scanned/not executed -> server -> OnGameBoot later
```

Detailed load-order doc: `Legacy/Research/Architecture/CoreLoadOrder.md`.

## Geometry

Geometry is explicit and exact. Never infer complex geometry through sprite-number arithmetic.

Current 1x1 geometry pilots:

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

Values come directly from verified PZ SpriteConfig scripts.

Large portals will use explicit A/B membership. True paired 1x1 doors may use Left/Right. Garages use START/MIDDLE/END with variable width.

## First rewritten Pickup slice

Workshop now also contains:

```text
Workshop/Contents/mods/LMION_Pickup/42/
```

Pickup no longer owns `DoorProfiles`, garage families or large-gate profiles. The first implementation discovers compatible simple 1x1 definitions from Core capabilities.

Current requirements for the first slice are exact N/W geometry, one pickup/replacement package, zero break chance, understood tool/skill semantics and simple topology.

The current geometry pilots therefore give an expected boot line:

```text
[LMION:Pickup] simple 1x1 registry ready: 2 definitions, 8 sprites
```

Pickup uses one generic transport item:

```text
Base.LMION_OpeningParcel
```

The parcel keeps the definition identity and primitive door state in modData while its world sprite identifies the exact closed face for vanilla Moveables inventory selection.

Detailed design/test note: `Legacy/Research/Architecture/PickupRewrite.md`.

## Pickup placement UX

For LMION parcels in vanilla Moveables Place mode:

```text
mouse drag -> does not rotate
R / Rotate building -> toggles N <-> W
```

This deliberately preserves the garage-style rotation UX the user preferred instead of vanilla click-drag facing selection.

Core exact geometry supplies the actual sprites; Pickup only controls the mechanic/cursor behavior.

## Script versus Catalog

```text
.txt = minimum data PZ needs during script/GameEntity/item loading
.lua = LMION semantic and geometry contract
```

Do not duplicate health, sounds, recipes, pickup properties, etc. in opening `.txt`. Do not create LMION opening scripts for GameEntities PZ already provides.

Pickup's generic `LMION_OpeningParcel` item script is a legitimate engine-load-time item registration, not opening semantic duplication.

The two unresolved large-gate scripts remain intentionally deferred until their A/B topology contract is frozen.

## Known Legacy behavior to preserve

- finalized LMION doors persist as `IsoDoor`;
- `IsoThumpable(isDoor)` is accepted as vanilla/legacy input, not a second persistent backend;
- framed doors use screwdriver pickup/replacement;
- frameless/gate-like openings use crowbar pickup and hammer replacement;
- physical tool and governing skill are separate concepts;
- vanilla Moveables may overwrite item weight during `ReadFromWorldSprite`; synchronize both item weight fields afterward;
- LMION standards are defaults, not limitations;
- MetalBar/IronBar alternatives remain supported where reviewed.

## Immediate next test

Enable Workshop `LMION_Core` + `LMION_Pickup` and test the simple 1x1 pipeline before adding more families.

Recommended first target is `WhiteRestroomStallDoor` because its pickup requirement is Woodwork 0 + screwdriver.

Verify:

```text
pickup through vanilla Moveables
-> one LMION parcel
-> correct weight
-> placement preview
-> R toggles N/W
-> matching frame required
-> placed result functions as a door
-> health survives pickup/replacement
```

Then test WhitePanelDoor when Woodwork 3 is available.

Fix real B42 integration issues first. Do not migrate paired, large-gate or garage logic until this simple pipeline is sound.

Fake third-party content remains postponed until built-in Core behavior is solid.

## Git workflow

- Work in `Coudji/LMION_Legacy` development `main` unless told otherwise.
- Workshop is the clean candidate mod tree.
- Research/history stays under Legacy.
- Coudji manually copies validated Workshop content into `PZMOD_LMION`.
- Re-fetch `LMION_Legacy/main` before writes.
- Prefer coherent commits.

Pre-reorganization backup:

```text
backup/main-before-workshop-refactor-20260830
```
