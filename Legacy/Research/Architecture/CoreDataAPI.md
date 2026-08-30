# LMION Core data API

Status: first implementation contract, 2026-08-30.

This document records the current Core data architecture so the rewrite can continue without depending on conversation history.

## Boundary

Core owns the opening catalog and the stable data contracts. Build, Pickup and Lock consume Core; they do not own lists of concrete openings.

The first implementation deliberately covers only data registration and resolution. It does not yet implement `IsoDoor` handling, placement, pickup, construction, locks, sprite lookup or topology mechanics.

## Pure data files

Files under `DefinitionDefaults/` and `Catalog/` are data only. They return a table and do not register themselves or require the Core API.

Definition default example:

```lua
return {
    defaultId = "Doors.Metal.Base",

    defaults = {
        materialType = "Metal_Solid",
        -- ...
    },
}
```

Concrete definition example:

```lua
return {
    definitionId = "Doors.Metal.WhiteMetalDoor",
    entity = "Base.WhiteMetalDoor",
    inherits = "Doors.Metal.Base",
}
```

Identity vocabulary is intentionally explicit:

- `defaultId` identifies a `DefinitionDefault`.
- `definitionId` identifies a concrete LMION opening definition.
- `entity` identifies the Project Zomboid GameEntity where applicable.
- `extensionId` identifies a third-party or LMION extension for diagnostics and duplicate detection.

Generic top-level `id` is rejected for defaults, definitions and extensions.

## Public API and private Registry

Third-party mods and future LMION addons use:

```lua
local LMION = require "LMION/API"
```

The first public operations are:

```lua
LMION.registerDefault(definitionDefault)
LMION.registerDefinition(definition)
LMION.registerExtension(extension)
LMION.registerContent(content)

LMION.getEffectiveDefault(defaultId)
LMION.getEffectiveDefinition(definitionId)
```

`Registry.lua` is an internal storage mechanism. Its raw tables are not part of the public contract.

The Registry stores three raw collections:

```text
defaultsById
definitionsById
extensions in registration order
```

Duplicate `defaultId`, `definitionId` and `extensionId` values are errors. Re-registering an existing definition is not the extension mechanism.

Values are copied when registered. Resolving also creates fresh tables, so callers cannot mutate the Registry accidentally by keeping or modifying an input/output table.

## Built-in content bootstrap

LMION does not scan arbitrary directories for definitions.

`Core/BuiltinContent.lua` explicitly lists the built-in DefinitionDefaults and Catalog definitions. `Core/Bootstrap.lua` registers that content through the same public API exposed to third-party mods.

This is deliberate: LMION's own catalog and external catalogs use the same registration path.

A modder can organize files however they want. Only the tables they register matter.

Example external integration:

```lua
local LMION = require "LMION/API"

LMION.registerContent({
    definitions = {
        require "MyDoorMod/Definitions/FancyDoor",
        require "MyDoorMod/Definitions/AnotherDoor",
    },
})
```

An external mod may also register its own reusable default:

```lua
LMION.registerDefault({
    defaultId = "MyDoorMod.Doors.ReinforcedGlass",

    defaults = {
        -- ...
    },
})
```

## DefinitionDefault inheritance

Inheritance has one level only:

```text
DefinitionDefault -> concrete Definition
```

A DefinitionDefault cannot contain `inherits`. Defaults never inherit other defaults.

A concrete definition may declare one `inherits = <defaultId>`, or eventually be a complete standalone definition. The complete standalone validation rules are not frozen yet, so this first validator does not invent them.

Missing inherited defaults are reported when a definition is resolved rather than when it is registered. This keeps registration order flexible for third-party mods.

## Extensions

Existing defaults and definitions are modified with an extension, not by duplicate registration.

Definition example:

```lua
LMION.registerExtension({
    extensionId = "MyMod.HeavierWhiteMetalDoor",

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

Default example:

```lua
LMION.registerExtension({
    extensionId = "MyMod.StrongerMetalDoors",

    target = {
        type = "default",
        id = "Doors.Metal.Base",
    },

    patch = {
        durability = {
            health = 500,
        },
    },
})
```

`extensionId` has no priority meaning. It exists for identity, diagnostics and duplicate detection.

There is deliberately no `priority` score. If multiple extensions write the same value at the same resolution layer, they are applied in registration/load order and the last one wins, matching normal mod load-order expectations.

## Resolution order

A concrete definition is resolved in this exact order:

```text
1. raw DefinitionDefault values
2. extensions targeting that default, in registration order
3. concrete Definition overrides
4. extensions targeting that concrete definition, in registration order
5. effective Definition returned to the caller
```

A concrete definition is structurally more specific than its default. Therefore an explicit value on the concrete definition still overrides an extension made only to its default. A mod that wants to change that concrete exception should target the concrete definition.

No effective-definition cache exists in this first implementation. A newly registered extension is therefore visible on the next resolution automatically.

## Merge semantics

Overrides and extension patches use the same merge rules:

- named/map-like tables merge recursively;
- scalar values replace previous values;
- dense numeric/list tables are replaced as a whole rather than merged element by element;
- an explicit empty table `{}` replaces the previous table and therefore can clear a list/table;
- no special field-deletion token exists yet.

For example:

```lua
patch = {
    durability = {
        health = 600,
    },
}
```

changes only `durability.health` and preserves the other durability fields.

By contrast:

```lua
patch = {
    engineMaterials = { "MetalBars" },
}
```

replaces the whole `engineMaterials` list.

## Reserved extension fields

Extensions currently cannot patch:

```text
id
defaultId
definitionId
extensionId
inherits
```

Identity is immutable. `inherits` is also reserved in the first implementation because changing it after default resolution would create misleading mixed data. If rebasing a definition becomes a real use case, it should receive explicit semantics rather than being an accidental patch side effect.

Other effective properties remain open to explicit override when they have defined semantics and consumers. LMION standards are defaults, not API limitations.

## Validation in the first implementation

The validator currently guarantees the minimum structural contract:

- defaults are tables with non-empty `defaultId` and a `defaults` table;
- defaults cannot inherit;
- definitions are tables with non-empty `definitionId`;
- `inherits`, when present, is a non-empty string;
- extensions have non-empty `extensionId`, a valid target and a patch table;
- extension target type is exactly `default` or `definition`;
- `priority` is rejected;
- duplicate identities are rejected by the Registry.

It intentionally does not yet validate every construction field, sprite, GameEntity, topology or standalone-definition requirement.

## Next Core work

The useful next steps are expected to be:

1. exercise this resolver with representative built-in and fake third-party data;
2. decide/implement lookup indexes needed by mechanics, especially GameEntity -> `definitionId`;
3. freeze the minimum complete standalone-definition contract;
4. add exact geometry/topology contracts;
5. then rebuild the first generic 1x1 mechanic against `LMION/API`, without concrete door IDs in that mechanic.
