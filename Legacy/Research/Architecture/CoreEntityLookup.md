# LMION Core GameEntity and world-object lookup

Status: first live implementation, 2026-08-30.

## Purpose

Mechanics usually encounter a Project Zomboid world object, not an LMION `definitionId`.

Core therefore owns this lookup chain:

```text
IsoObject / IsoDoor
-> GameEntityScript full name
-> LMION definitionId
-> effective definition
```

The public API currently exposes both the GameEntity-level and object-level forms:

```lua
LMION.getDefinitionIdByEntity("Base.WhitePanelDoor")
LMION.getEffectiveDefinitionByEntity("Base.WhitePanelDoor")

LMION.getEntityIdForObject(object)
LMION.getDefinitionIdForObject(object)
LMION.getEffectiveDefinitionForObject(object)
```

Unknown but otherwise valid objects/entities return `nil` when LMION has no matching definition.

## Why world-object lookup does not use sprites

The uploaded B42.20.3 jar confirms:

```text
IsoObject extends GameEntity
GameEntity.getEntityScript()
GameEntityScript.getFullName()
```

For an entity-backed door the canonical path is therefore:

```lua
local entityScript = object:getEntityScript()
local entityId = entityScript:getFullName()
```

This is preferable to guessing identity from the current sprite. A door can change sprite when opened while its GameEntity identity remains stable.

Sprite/geometry data still matters for exact placement, orientation and topology mechanics; it is not the primary identity lookup.

## Indexed fields

The first entity index handles the concrete shapes already present in the Catalog:

```lua
entity = "Base.WhiteMetalDoor"
```

and true paired 1x1 doors:

```lua
topology = {
    type = "paired",
    left = "Base.GreyMetalDoubleDoorLeft",
    right = "Base.GreyMetalDoubleDoorRight",
}
```

Both Left and Right map to the same conceptual definition.

Large gate A/B and garage member topology will extend the collector only after those exact contracts are frozen.

## Effective data and invalidation

The index is built from effective definitions, not raw Catalog tables.

Every `registerDefault`, `registerDefinition` and `registerExtension` invalidates it. The next lookup rebuilds automatically, and `OnGameBoot` explicitly rebuilds after normal mod registration.

This keeps third-party registration compatible with PZ load order without requiring a separate finalize call.

## Collision rule

Two different definitions may not claim the same GameEntity. That is an identity ambiguity, not a normal extension conflict.

A mod that wants to change an existing opening uses `registerExtension`.

Extensions themselves still follow load order: later same-layer writes win.

## Live GameEntity validation

The first in-game validation produced:

```text
23 defaults
54 definitions
58 indexed GameEntity mappings
56/58 GameEntities found in ScriptManager
```

The only missing mappings were:

```text
Base.LargeWroughtIronGate
Base.LargeHardenedWoodenGate
```

Those two are currently expected because the new large-gate A/B script representation has deliberately not been created yet. The diagnostic remains an `ERROR` for visibility; this is a known development gap, not evidence that the current lookup mechanism failed.

The other 56 mappings were confirmed by PZ's `ScriptManager.getGameEntityScript(String)`.

## First exact geometry contract

`Doors.Wood.WhitePanelDoor` is the first concrete definition with explicit exact 1x1 geometry:

```lua
geometry = {
    N = {
        closed = "fixtures_doors_01_1",
        open = "fixtures_doors_01_3",
    },
    W = {
        closed = "fixtures_doors_01_0",
        open = "fixtures_doors_01_2",
    },
}
```

These values come directly from its verified PZ `SpriteConfig`; no sprite-number arithmetic is used.

This establishes the intended simple-door shape before geometry is migrated across the rest of the Catalog.

## Runtime diagnostics

The one-line-per-definition catalog dump was useful for the first bootstrap test but is now removed from normal startup because it is too noisy.

Normal development boot output is intentionally compact:

```text
[LMION:Core] OnGameBoot registry snapshot: ...
[LMION:Core] GameEntity index ready: ...
[LMION:Core] PZ GameEntity validation: ...
```

Only actual missing GameEntity mappings are then listed individually.
