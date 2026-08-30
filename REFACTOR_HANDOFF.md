# LMION Refactor Handoff

This repository is the development workspace for the LMION rewrite.

## Repository roles

- `Coudji/LMION_Legacy` = development workspace, research archive, old implementation reference and refactor test area.
- `Coudji/PZMOD_LMION` = clean final repository managed manually by Coudji.
- Do **not** write to `PZMOD_LMION`; Coudji copies validated Workshop content there manually.

## Architecture goal

> **Core owns opening content and stable contracts. Submods own mechanics. No submod owns the opening catalog.**

```text
Build  ─┐
Pickup ─┼─> Core
Lock   ─┘
```

Core never depends on gameplay addons. Mechanics must not hard-code concrete opening catalogs.

## Data vocabulary and inheritance

```text
defaultId     -> DefinitionDefault identity
definitionId  -> concrete LMION opening identity
entity        -> Project Zomboid GameEntity identity where applicable
extensionId   -> extension/patch identity
inherits      -> one concrete Definition -> one DefinitionDefault
```

Do not reintroduce generic top-level `id`, `kind`, or removed `class`.

DefinitionDefaults never inherit other defaults. A concrete definition inherits exactly one default or is eventually complete standalone. Technical IDs use `Wood` and `Metal`.

`DefinitionDefaults/` and `Catalog/` are pure data files; they return tables and do not register themselves.

## Current Core runtime

Workshop has a runnable B42 Core mod:

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
    │       │   ├── EntityIndex.lua
    │       │   ├── GameEntityValidation.lua
    │       │   ├── Registry.lua
    │       │   ├── Resolver.lua
    │       │   ├── TableUtils.lua
    │       │   └── Validation.lua
    │       ├── Catalog/
    │       └── DefinitionDefaults/
    └── scripts/LMION/...
```

`LMION/API.lua` exposes the API only. `LMION_Core.lua` is the runtime startup: it bootstraps built-ins, then uses `OnGameBoot` as the post-registration checkpoint.

## Live validation already completed

Coudji launched PZ with the new Workshop Core and confirmed this real in-game state on 2026-08-30:

```text
[LMION:Core] OnGameBoot registry snapshot: 23 defaults, 54 definitions, 0 extensions
```

All 54 definitions resolved and were printed, including paired definitions resolving to Left + Right GameEntities. This proves Core startup, built-in bootstrap, registry and inheritance resolution work in-game.

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
```

Registry stays private. Raw registered data is copied and Resolver produces fresh effective tables.

## Extensions

Resolution order:

```text
raw default
-> default extensions in registration order
-> concrete definition overrides
-> concrete definition extensions in registration order
-> effective definition
```

There is no priority score. At the same extension layer, later registration/load order wins. Identity fields and `inherits` cannot currently be patched.

Two **different definitions** may not claim the same GameEntity: that is an ambiguous physical identity and is an error. A mod modifying an existing opening must use `registerExtension`.

## GameEntity lookup

`Core/EntityIndex.lua` now builds:

```text
GameEntity full name -> definitionId
```

It currently indexes:

- `definition.entity` for normal mappings;
- `topology.left` and `topology.right` for true paired 1x1 doors.

The index uses effective definitions and is invalidated by every default/definition/extension registration, so third-party registrations are picked up automatically on the next lookup. `OnGameBoot` explicitly rebuilds the final normal load-time index.

Current built-ins are expected to produce **58 GameEntity mappings -> 54 definitions** because four paired definitions have two entity members.

Detailed contract: `Legacy/Research/Architecture/CoreEntityLookup.md`.

## PZ GameEntity validation

The uploaded B42.20.3 jar was inspected. `ScriptManager` exposes `getGameEntityScript(String)`.

At `OnGameBoot`, Core now checks every indexed entity using:

```lua
ScriptManager.instance:getGameEntityScript(entityId)
```

Expected next test output:

```text
[LMION:Core] GameEntity index ready: 58 entities -> 54 definitions
[LMION:Core] PZ GameEntity validation: 58/58 found
```

If an entity is missing, Core logs both the missing GameEntity and the LMION definition that references it. This validation is diagnostic for now; it does not silently delete invalid definitions.

## Verified PZ load order

Against the uploaded B42.20.3 jar:

```text
client:          shared -> client -> OnGameBoot later
dedicated server: shared -> client scanned/not executed -> server -> OnGameBoot later
```

Within a scope, PZ processes mods in `ZomboidFileSystem.getModIDs()` order and sorts files inside one mod case-insensitively.

Shared Core/content registration therefore belongs in `media/lua/shared`. Third-party content mods should depend on `LMION_Core`, then register their content from their own shared Lua files using `require "LMION/API"`.

`OnGameBoot` is a checkpoint after normal registration, not the preferred registration phase.

Detailed note: `Legacy/Research/Architecture/CoreLoadOrder.md`.

## Third-party registration

External mods organize files however they want. They do not place files inside LMION directories.

```lua
local LMION = require "LMION/API"

LMION.registerContent({
    definitions = {
        require "MyDoorMod/Definitions/FancyDoor",
    },
})
```

They may register their own defaults/definitions or patch LMION/external definitions through `registerExtension`.

## Script versus Catalog rule

```text
.txt = minimum data PZ must load/register early
.lua = LMION semantic/geometry contract
```

Do not duplicate health, sounds, recipes, pickup values, etc. in `.txt`. Do not create LMION `.txt` files for GameEntities PZ already provides.

Exact geometry may intentionally exist in both SpriteConfig and Catalog because PZ and LMION consume it at different lifecycle stages.

## Geometry/topology direction

Do not infer complex geometry with sprite-number arithmetic.

Core definitions will eventually contain exact N/W open/closed geometry. Large portals use semantic leaves A/B. True paired 1x1 doors may use Left/Right. Garages use START/MIDDLE/END and variable width.

Large gate A/B scripts remain intentionally unresolved until that new topology representation is frozen.

## Known Legacy behavior to preserve deliberately

- finalized LMION doors persist as `IsoDoor`;
- `IsoThumpable(isDoor)` is accepted as vanilla/legacy input, not a second persistent backend;
- framed doors use screwdriver pickup/replacement;
- frameless/gate-like openings use crowbar pickup and hammer replacement;
- physical tool and governing skill are separate concepts;
- LMION standards are defaults, not limitations;
- MetalBar/IronBar alternatives remain supported where reviewed.

## Next milestone

Launch PZ with the new commit and verify the two entity-index/GameEntity-validation lines. If all current mappings exist, the next Core work is to add the first exact 1x1 geometry contract and then a world-object -> LMION definition adapter, which will put us in position to rebuild generic Pickup without concrete IDs.

A fake third-party mod remains intentionally postponed until built-in Core behavior is solid.

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
