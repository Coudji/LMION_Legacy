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
LMION/Core/EntityIndex.lua
LMION/Core/GameEntityValidation.lua
LMION/Core/ObjectLookup.lua
LMION/Core/Registry.lua
LMION/Core/Resolver.lua
LMION/Core/TableUtils.lua
LMION/Core/Validation.lua
```

`LMION_Core.lua` is the runtime startup. `API.lua` exposes the API only.

## Live tests completed

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

The only missing mappings are currently expected development gaps because their new large-gate scripts have not been created yet:

```text
Base.LargeWroughtIronGate
Base.LargeHardenedWoodenGate
```

Keep these diagnostic errors for now; do not waste time special-casing them.

The verbose `[LMION:Catalog]` line-per-definition dump has been removed from normal startup. Keep summary lines plus anomalies only.

## Public API

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
```

Registry is private. Resolver returns fresh effective data.

## Lookup contract

The uploaded B42.20.3 jar confirms:

```text
IsoObject extends GameEntity
GameEntity.getEntityScript()
GameEntityScript.getFullName()
```

World-object lookup therefore uses stable GameEntity identity:

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

`Doors.Wood.WhitePanelDoor` is now the first migrated 1x1 geometry contract:

```text
N closed fixtures_doors_01_1
N open   fixtures_doors_01_3
W closed fixtures_doors_01_0
W open   fixtures_doors_01_2
```

These values come directly from its PZ SpriteConfig.

Large portals will use explicit A/B membership. True paired 1x1 doors may use Left/Right. Garages use START/MIDDLE/END with variable width.

## Script versus Catalog

```text
.txt = minimum data PZ needs during script/GameEntity loading
.lua = LMION semantic and geometry contract
```

Do not duplicate health, sounds, recipes, pickup properties, etc. in `.txt`. Do not create LMION scripts for GameEntities PZ already provides.

The two unresolved large-gate scripts remain intentionally deferred until their A/B topology contract is frozen.

## Known Legacy behavior to preserve

- finalized LMION doors persist as `IsoDoor`;
- `IsoThumpable(isDoor)` is accepted as vanilla/legacy input, not a second persistent backend;
- framed doors use screwdriver pickup/replacement;
- frameless/gate-like openings use crowbar pickup and hammer replacement;
- physical tool and governing skill are separate concepts;
- LMION standards are defaults, not limitations;
- MetalBar/IronBar alternatives remain supported where reviewed.

## Immediate next work

Live-test the new object lookup on a real `IsoDoor`. Once confirmed, migrate exact geometry for more simple 1x1 definitions and build the first generic object/door abstraction used by Pickup.

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
