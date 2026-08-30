# LMION Core GameEntity lookup

Status: first implementation, 2026-08-30.

## Purpose

Mechanics do not normally encounter an LMION `definitionId` first. They encounter a Project Zomboid object/GameEntity and must ask Core which concrete opening definition owns it.

The first lookup layer therefore provides the reverse mapping:

```text
GameEntity full name -> LMION definitionId -> effective definition
```

Public API:

```lua
LMION.getDefinitionIdByEntity("Base.WhiteMetalDoor")
LMION.getEffectiveDefinitionByEntity("Base.WhiteMetalDoor")
```

Unknown GameEntities return `nil`. Invalid empty/non-string entity IDs are programming errors.

## Indexed fields

The first pass indexes the concrete mappings that exist in the current Catalog:

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

Both Left and Right resolve to the same conceptual LMION definition.

Large gate A/B and garage member topology will extend this collector later when those exact contracts are frozen. The index must not guess those structures in advance.

## Effective data and invalidation

The index is built from **effective definitions**, not raw Catalog tables. This matters because extensions may legitimately change fields such as `entity` or topology data.

Any call to:

```text
registerDefault
registerDefinition
registerExtension
```

marks the entity index dirty.

The next lookup rebuilds it automatically. `OnGameBoot` also rebuilds it explicitly after normal mod registration has completed.

This means a third-party registration loaded after Core but before `OnGameBoot` is included without a special finalization API.

## Collision rule

Two different concrete definitions may not claim the same GameEntity.

That is an ambiguity, not an extension conflict. Core raises an error such as:

```text
LMION: GameEntity Base.SomeDoor is claimed by both ModA.SomeDoor and ModB.SomeDoor
```

Normal load-order/last-write-wins behavior still applies to **extensions targeting the same definition/default**. It does not apply to two distinct definitions claiming the same physical identity.

A mod that wants to modify an existing opening must use `registerExtension` rather than register a second definition for the same GameEntity.

## Validation against Project Zomboid

The uploaded B42.20.3 jar exposes:

```text
zombie.scripting.ScriptManager.instance
    getGameEntityScript(String)
```

`OnGameBoot` runs after script and normal Lua mod loading, so the current diagnostic uses:

```lua
ScriptManager.instance:getGameEntityScript(entityId)
```

for every indexed GameEntity.

A resolved LMION mapping and a real PZ script registration are deliberately checked separately:

```text
Catalog says Base.WhiteMetalDoor
        ↓
EntityIndex maps it to Doors.Metal.WhiteMetalDoor
        ↓
ScriptManager confirms Base.WhiteMetalDoor exists
```

Missing entities are logged with both the GameEntity and owning LMION definition so script/catalog mistakes are actionable.

This engine validation is diagnostic in the first implementation; it does not silently remove invalid third-party definitions.

## Current expected built-in result

Before this lookup pass the new Core was live-tested successfully with:

```text
23 defaults
54 definitions
0 extensions
```

With the four paired definitions contributing two GameEntity members each, the current built-in catalog is expected to produce:

```text
58 GameEntity mappings -> 54 definitions
```

The next in-game test should confirm that all 58 are present in PZ's ScriptManager.
