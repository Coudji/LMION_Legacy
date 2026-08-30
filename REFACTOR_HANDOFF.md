# LMION Refactor Handoff

This repository is the development workspace for the LMION rewrite.

## Repository roles

- `Coudji/LMION_Legacy` = development workspace, research archive, old implementation reference and refactor test area.
- `Coudji/PZMOD_LMION` = clean final repository managed manually by Coudji.

Do **not** write to `PZMOD_LMION` during development. Coudji copies validated Workshop content there manually.

## Workspace

```text
LMION_Legacy/
├── Legacy/      # old code, research, docs and historical reference
└── Workshop/    # clean rewrite candidate used for live testing
```

Old Legacy code is reference material only. Rebuild behavior deliberately in Workshop.

## Architecture goal

> **Core owns opening content and stable contracts. Submods own mechanics. No submod owns the opening catalog.**

```text
Build  ─┐
Pickup ─┼─> Core
Lock   ─┘
```

Core never depends on gameplay addons. Build, Pickup and Lock do not depend on one another and must work with Core individually.

Mechanics must not hard-code concrete opening IDs.

## Current vocabulary

```text
defaultId     -> DefinitionDefault identity
definitionId  -> concrete LMION opening identity
entity        -> Project Zomboid GameEntity identity where applicable
extensionId   -> extension/patch identity
inherits      -> one concrete Definition -> one DefinitionDefault
```

Do not reintroduce generic top-level `id`, generic `kind`, or removed `class`.

Technical IDs use `Wood` and `Metal`; some physical folders still use `Wooden` for navigation.

## Data contract

`DefinitionDefaults/` and `Catalog/` are pure data files. They return tables and do not register themselves.

DefinitionDefaults never inherit other defaults. A concrete definition inherits exactly one default or is eventually complete standalone.

Current merge/resolution order:

```text
raw default
-> default extensions in registration order
-> concrete definition overrides
-> concrete definition extensions in registration order
-> effective definition
```

At the same extension layer, last registered wins. There is no LMION priority score.

Detailed data API: `Legacy/Research/Architecture/CoreDataAPI.md`.

## First runnable Core runtime

Workshop now contains a real Core mod descriptor and runtime entry point:

```text
Workshop/Contents/mods/LMION_Core/42/
├── mod.info
└── media/
    ├── lua/shared/
    │   ├── LMION_Core.lua
    │   └── LMION/
    │       ├── API.lua
    │       ├── Core/
    │       │   ├── Bootstrap.lua
    │       │   ├── BuiltinContent.lua
    │       │   ├── Diagnostics.lua
    │       │   ├── Registry.lua
    │       │   ├── Resolver.lua
    │       │   ├── TableUtils.lua
    │       │   └── Validation.lua
    │       ├── Catalog/
    │       └── DefinitionDefaults/
    └── scripts/LMION/...
```

`LMION/API.lua` now only defines the public API. It does **not** bootstrap content as a side effect.

`media/lua/shared/LMION_Core.lua` is the runtime startup file. It bootstraps built-in content through the same API third-party mods use, then installs an `OnGameBoot` diagnostic checkpoint.

Current public API includes:

```lua
LMION.registerDefault(...)
LMION.registerDefinition(...)
LMION.registerExtension(...)
LMION.registerContent(...)

LMION.getEffectiveDefault(...)
LMION.getEffectiveDefinition(...)
LMION.getRegisteredDefaultIds()
LMION.getRegisteredDefinitionIds()
LMION.getRegistrationStats()
```

Registry remains private raw storage. Resolver always returns fresh effective data. No effective cache exists yet.

## Verified PZ load order

Load-order behavior was checked against the uploaded B42.20.3 jar.

Client:

```text
shared
client
OnGameBoot later
```

Dedicated server:

```text
shared
client scanned but not executed
server
OnGameBoot later
```

Within each scope, PZ processes active mods in `ZomboidFileSystem.getModIDs()` order and sorts files inside each mod case-insensitively before execution.

Core content registration that must exist client + server therefore belongs in `shared`.

Third-party content mods should depend on `LMION_Core`, then register their content from their own `media/lua/shared` files using `require "LMION/API"`.

`OnGameBoot` is treated as a final checkpoint after normal Lua registration, not as the preferred normal registration phase.

Detailed engine/runtime note: `Legacy/Research/Architecture/CoreLoadOrder.md`.

## Current launch diagnostic

On Core bootstrap the game should print a count similar to:

```text
[LMION:Core] built-in bootstrap complete: 23 defaults, 54 definitions, 0 extensions
```

At `OnGameBoot`, after normal mod Lua loading, Core prints a final registry snapshot and each resolved concrete definition:

```text
[LMION:Core] OnGameBoot registry snapshot: ...
[LMION:Catalog] Doors.Metal.WhiteMetalDoor -> Base.WhiteMetalDoor
...
```

This verbose dump is temporary development diagnostics. It exists so the next milestone can be proven by simply starting PZ before rebuilding gameplay mechanics.

## Third-party registration

External mods do not place files inside LMION folders and do not mirror LMION's tree.

Example shared integration:

```lua
local LMION = require "LMION/API"

LMION.registerContent({
    definitions = {
        require "MyDoorMod/Definitions/FancyDoor",
    },
})
```

They may register new defaults/definitions or modify existing ones with `registerExtension`.

Duplicate identities are errors. Re-registering an existing definition is not an override mechanism.

## Extensions

Example:

```lua
LMION.registerExtension({
    extensionId = "MyMod.WhiteMetalDoorChanges",
    target = {
        type = "definition",
        id = "Doors.Metal.WhiteMetalDoor",
    },
    patch = {
        durability = {
            health = 600,
        },
    },
})
```

No priority field exists. PZ/mod registration order decides conflicts; later same-layer writes win.

Identity fields and `inherits` cannot currently be patched.

## Script versus Catalog rule

```text
.txt = minimum data PZ must load/register early
.lua = LMION semantic/geometry contract
```

Do not duplicate health, sounds, recipes, pickup values, etc. in `.txt` files.

Do not create LMION scripts for GameEntities PZ already provides.

Some exact geometry will intentionally exist both in PZ `SpriteConfig` and LMION definitions because they serve different consumers/lifecycles.

## Geometry/topology direction

Do not infer complex geometry with sprite arithmetic.

Core definitions will eventually contain exact N/W open/closed geometry.

Large portals use semantic leaves A/B. True paired 1x1 doors may use Left/Right when meaningful. Garages use START/MIDDLE/END and variable width.

Large gate A/B scripts remain intentionally unresolved until the new topology representation is frozen.

## Known Legacy behavior to preserve deliberately

- finalized LMION doors persist as `IsoDoor`;
- `IsoThumpable(isDoor)` is accepted as vanilla/legacy input, not a second persistent backend;
- framed doors use screwdriver pickup/replacement;
- frameless/gate-like openings use crowbar pickup and hammer replacement;
- physical tool and governing skill are separate concepts;
- LMION standards are defaults, not limitations;
- MetalBar/IronBar alternatives are supported where reviewed.

## Current implementation limits

Not yet rebuilt:

- GameEntity/world-object -> definition lookup indexes
- exact Catalog geometry
- topology runtime abstraction
- canonical `IsoDoor` helpers
- Pickup mechanics
- Build mechanics
- Lock mechanics
- complete standalone-definition validation
- automated new-Core integration tests

## Immediate next milestone

First, launch PZ with Workshop `LMION_Core` enabled and verify the bootstrap + `OnGameBoot` registry dump.

If that works, next build the lookup layer mechanics actually need, starting with GameEntity -> concrete definition. Then add exact geometry for one simple 1x1 opening before rebuilding Pickup.

A fake third-party mod is intentionally postponed until Core itself has proven it can boot and expose its built-in catalog in-game.

## Git workflow

- Work in `Coudji/LMION_Legacy` development `main` unless Coudji says otherwise.
- Workshop is the clean candidate mod tree.
- Research/history stays under Legacy.
- Coudji manually copies validated Workshop content into `PZMOD_LMION`.
- **Never write to `PZMOD_LMION` unless Coudji explicitly reverses that rule.**
- Re-fetch `LMION_Legacy/main` before writes because Coudji may push between turns.
- Prefer coherent commits over chains of trivial fixes.

Pre-reorganization backup:

```text
backup/main-before-workshop-refactor-20260830
```
