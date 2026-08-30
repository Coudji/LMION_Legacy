# LMION Refactor Handoff

This repository is the development workspace for the LMION rewrite.

## Repository roles

- `Coudji/LMION_Legacy` = development workspace, research archive, old implementation reference and refactor test area.
- `Coudji/PZMOD_LMION` = clean final repository managed manually by Coudji.

Do **not** write to `PZMOD_LMION` during development. Coudji copies validated Workshop content there manually.

## Workspace layout

```text
LMION_Legacy/
├── Legacy/      # old implementation, research, technical docs and historical reference
└── Workshop/    # clean LMION rewrite under active development
```

`Workshop/` contains only candidate real mod files. Research, experiments, notes and historical material stay under `Legacy/` except this root handoff.

The old implementation is a reference, not code to migrate wholesale.

## Architecture goal

> **Core owns opening content and stable contracts. Submods own mechanics. No submod owns the opening catalog.**

```text
Build  ─┐
Pickup ─┼─> Core
Lock   ─┘
```

Core never depends on gameplay addons. Build, Pickup and Lock do not depend on one another and must each work with Core when enabled alone.

Mechanic addons must not hard-code concrete door catalogs. They ask Core for the properties of registered openings.

## Current data vocabulary

```text
defaultId     -> LMION DefinitionDefault identity
definitionId  -> concrete LMION opening identity
entity        -> Project Zomboid GameEntity identity where applicable
extensionId   -> identity of an extension/patch
inherits      -> one concrete Definition -> one DefinitionDefault
```

Do not reintroduce generic top-level `id`, generic `kind`, or the removed `class` field.

Technical material naming uses `Wood` and `Metal`, not `Wooden`/`Metallic` for IDs/categories. Existing physical folder names may still contain `Wooden`; do not rename folders casually while other work is in progress.

## DefinitionDefaults

DefinitionDefaults are reusable property sets, not concrete openings.

Rules:

- DefinitionDefaults never inherit other DefinitionDefaults.
- A concrete definition either inherits exactly one default or is eventually complete standalone.
- No silent fallback chain exists.
- Concrete overrides are more specific than inherited default values.

Current defaults already encode reviewed construction/pickup values, tool tags and MetalBar/IronBar alternatives. User deletions/renames are authoritative; do not recreate pruned defaults automatically.

## Pure Catalog/data files

Files under `Workshop/.../LMION/DefinitionDefaults/` and `Catalog/` only return data.

They do not register themselves and do not know about Registry/API implementation details.

Example:

```lua
return {
    definitionId = "Doors.Metal.WhiteMetalDoor",
    entity = "Base.WhiteMetalDoor",
    inherits = "Doors.Metal.Base",
}
```

## First Core implementation

The first data API implementation now lives under:

```text
Workshop/Contents/mods/LMION_Core/42/media/lua/shared/LMION/
├── API.lua
├── Core/
│   ├── Bootstrap.lua
│   ├── BuiltinContent.lua
│   ├── Registry.lua
│   ├── Resolver.lua
│   ├── TableUtils.lua
│   └── Validation.lua
├── Catalog/
└── DefinitionDefaults/
```

Detailed contract: `Legacy/Research/Architecture/CoreDataAPI.md`.

### Public API

Third-party mods and future LMION addons use:

```lua
local LMION = require "LMION/API"
```

Current public operations:

```lua
LMION.registerDefault(...)
LMION.registerDefinition(...)
LMION.registerExtension(...)
LMION.registerContent(...)
LMION.getEffectiveDefault(...)
LMION.getEffectiveDefinition(...)
```

Registry is private internal storage. It stores raw copied defaults, definitions and extensions. Resolver creates effective copies; it does not mutate the registered data.

Built-in LMION content is explicitly listed in `Core/BuiltinContent.lua` and registered through the same public API used by third-party content. There is no automatic filesystem/catalog scan.

## Third-party registration

A modder may organize their own files however they want. They explicitly register data with Core.

```lua
local LMION = require "LMION/API"

LMION.registerContent({
    definitions = {
        require "MyDoorMod/Definitions/FancyDoor",
    },
})
```

Third-party mods may register their own defaults and make their concrete definitions inherit those defaults.

Duplicate `defaultId` or `definitionId` values are errors. Re-registering a LMION definition is not the override mechanism.

## Extensions and load order

Existing defaults/definitions are changed through `registerExtension`.

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

There is **no priority score**.

Resolution is:

```text
raw default
-> default extensions in registration/load order
-> concrete definition overrides
-> concrete definition extensions in registration/load order
-> effective definition
```

Within the same extension layer, the last registered/loaded patch wins for fields both patches write. This follows PZ mod load-order expectations instead of inventing an LMION priority contest.

Concrete-definition values remain more specific than changes made only to their inherited default.

Extensions cannot currently change identities or `inherits`.

## Merge rule

Named tables merge recursively. Lists are replaced in full. Scalars replace. An explicit `{}` clears/replaces an existing table. Raw Registry data is never mutated during resolution.

No cache exists yet, so extensions registered later are reflected by the next resolution automatically.

## Explicit geometry rule

Do not infer complex opening geometry using sprite-number arithmetic.

Core definitions should eventually describe exact open/closed N/W geometry and, for large portals, explicit A/B leaf membership.

Some geometry will intentionally duplicate `SpriteConfig`:

```text
.txt = what PZ must load/register early
.lua = what LMION guarantees to mechanics through its API
```

This duplication is acceptable because the consumers and lifecycle are different.

## PZ entity scripts

Current Workshop `.txt` scripts are minimal and formatted as normal multiline ZedScript for editor tooling.

Do not create an LMION `.txt` merely for a GameEntity PZ already provides. Scripts exist only where LMION must register a missing GameEntity and contain only engine-loading information such as `SpriteConfig`/faces and required frame flags.

Health, sounds, materials, recipes, pickup data and other LMION semantics belong in the Lua catalog/defaults, not duplicated in the `.txt`.

Large gate A/B scripts remain intentionally unresolved until the new topology representation is frozen.

## Known Legacy behavior to preserve deliberately

- LMION-owned/finalized doors persist as `IsoDoor`.
- `IsoThumpable(isDoor)` is acceptable legacy/vanilla input, not a second LMION persistent backend.
- Large portals use semantic leaves A/B; true paired 1x1 double doors may use Left/Right when meaningful.
- Garages use START / MIDDLE / END topology and variable width; old fixed L12 limits were artificial.
- Framed normal doors use screwdriver pickup/placement.
- Frameless/gate-like openings use crowbar pickup and hammer placement.
- Physical tool choice and governing skill are separate concepts; metal ToolDefinitions in Legacy proved that behavior.
- LMION standards are defaults, not limitations: meaningful explicit modder overrides should remain possible.

## Current implementation limits

The new Core currently implements only the data contract/registration/resolution slice.

Not yet rebuilt:

- GameEntity/world-object lookup indexes
- exact Catalog geometry
- topology runtime abstraction
- canonical `IsoDoor` helpers
- Pickup mechanics
- Build mechanics
- Lock mechanics
- complete standalone-definition validation
- composition/integration tests for the new code

Do not copy old runtime implementations wholesale to fill these gaps.

## Migration strategy from here

Recommended next sequence:

1. test Registry/Resolver with built-in definitions and a fake third-party extension;
2. add the lookup contract mechanics actually need, starting with GameEntity -> definition;
3. freeze the minimum standalone definition requirements;
4. add exact geometry for one simple 1x1 opening;
5. rebuild generic 1x1 Pickup using Core only;
6. prove a second/fake external door works without editing Pickup;
7. rebuild generic 1x1 Build;
8. paired/fence gates;
9. large gates and garages;
10. Lock and additional mechanics later.

## Composition rule

A successful full-stack test is not proof of modularity.

Test Core alone and Core + each individual gameplay addon, then combinations. Shared representations must not depend on another gameplay addon having run first.

## Git / delivery workflow

- Work directly in `Coudji/LMION_Legacy` development `main` unless Coudji says otherwise.
- `Workshop/` is the clean candidate mod tree.
- Research/history stays in `Legacy/`.
- Coudji manually copies validated Workshop content into `PZMOD_LMION`.
- **Never write to `PZMOD_LMION` unless Coudji explicitly reverses that rule.**
- Re-fetch `LMION_Legacy/main` before writes because Coudji may push changes between turns.
- Prefer coherent commits over chains of tiny fixes.

The pre-reorganization state remains available on:

```text
backup/main-before-workshop-refactor-20260830
```
