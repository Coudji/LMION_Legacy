# Door reference: `Base.WoodenDoorLvl3`

Status: living research baseline, first captured 2026-08-19.

This file is a reference dossier for LMION door research. It records vanilla facts separately from LMION conclusions so the eventual Pickup/placement implementation can reuse the data without treating an early experiment as frozen architecture.

## Provenance

- Source: vanilla Build 42 construction menu, then inspected in-world with LMION Inspector / Full details.
- Runtime sample square: `15606,616,0`.
- Runtime class: `zombie.iso.objects.IsoThumpable`.
- Current state at capture: north-facing, closed, unlocked, undamaged (`500 / 500`).
- Vanilla entity source reported by the game: `media/scripts/generated/entities/walls/entity_woodendoorlvl3.txt`.

## Logical identity

| Field | Value | Confidence / use |
|---|---|---|
| Tile property `EntityScriptName` | `WoodenDoorLvl3` | Runtime confirmed |
| Entity script name | `WoodenDoorLvl3` | Runtime confirmed |
| Entity full name | `Base.WoodenDoorLvl3` | Runtime confirmed; preferred LMION identity candidate for entity-backed doors |
| Module | `Base` | Runtime confirmed |
| Mod ID | `pz-vanilla` | Runtime confirmed |
| Vanilla | `true` | Runtime confirmed |
| Registry ID | `5300` | Runtime confirmed for this game build; do not use as a cross-version LMION identity |

The working LMION rule is to prefer `Base.WoodenDoorLvl3` over a sprite ID when an entity-backed opening exposes a stable full entity name. Sprite IDs identify visual variants/states, not the logical door family.

## Entity components

The entity contains three script components:

1. `zombie.scripting.entity.components.ui.UiConfigScript`
2. `zombie.scripting.entity.components.spriteconfig.SpriteConfigScript`
3. `zombie.scripting.entity.components.crafting.CraftRecipeComponentScript`

The first capture already resolved SpriteConfig. UiConfig and CraftRecipe are part of the exhaustive follow-up capture so the dossier can include the construction-menu identity, exact recipe inputs/tools/skills, and raw script bodies.

## Visual family / SpriteConfig

Reported tile family:

```text
carpentry_01_57
carpentry_01_56
carpentry_01_59
carpentry_01_58
```

Known mapping so far:

| Orientation/state | Sprite | Evidence |
|---|---|---|
| North, closed | `carpentry_01_57` | Runtime object + SpriteConfig face `n` |
| North, open | `carpentry_01_59` | Runtime `openSprite` |
| West, closed | `carpentry_01_56` | SpriteConfig face `w` |
| West, open | `carpentry_01_58` | Strongly implied by the four-tile family; runtime confirmation still pending |

SpriteConfig facts:

```text
valid = true
multiTile = true
singleFace = false
thumpable = true
isoMasterOnly = false
pole = false
prop = false
health = -1
bonusHealth = 0
skillBaseHealth = 300
breakSound = BreakDoor
canBePadlocked = false
dontNeedFrame = false
needToBeAgainstWall = false
needWindowFrame = false
```

Configured closed faces:

```text
face n: 1 x 1 x 1 -> carpentry_01_57 [blocks]
face w: 1 x 1 x 1 -> carpentry_01_56 [blocks]
```

Important: `multiTile = true` does **not** by itself mean that this door occupies multiple world squares. The configured faces in this sample are `1 x 1`, and the runtime opening occupies one square. For LMION, footprint must be derived from face/grid geometry rather than the `multiTile` flag alone.

## Tile properties

```text
flags = doorN, EntityScript
CanScrap = <empty>
DoorSound = WoodShackDoor
EntityScriptName = WoodenDoorLvl3
IsPaintable = <empty>
Material = Door
Material2 = Wood
Material3 = Nails
MaterialType = Wood
PaintingType = door
```

These are raw vanilla properties. They should remain raw facts in the research layer; derived LMION classifications belong in a separate registry/analysis layer.

## Runtime opening state

```text
isDoor = true
north = true
open = false
locked = false
lockedByKey = false
keyId = -1
health = 500 / 500
barricaded = false
destroyed = false
closedSprite = carpentry_01_57
openSprite = carpentry_01_59
oppositeSquare = 15606,615,0
doubleDoorIndex = -1
garageDoorIndex = -1
hoppable = false
dismantable = false
canBarricade = false
canPassThrough = false
thumpSound = ZombieThumpGeneric
doorFrame = false
```

This is instance state, not family identity. Pickup serialization must keep this layer separate from the entity definition/SpriteConfig.

## Provisional LMION model

For an entity-backed one-square door like this, the useful separation is:

```text
family identity
    Base.WoodenDoorLvl3

definition
    GameEntityScript
    UiConfig
    SpriteConfig
    CraftRecipe

visual/state variants
    N/W closed/open sprites

world instance
    health, lock/key state, open state, square, etc.

LMION classification (future)
    mechanism, hinge requirement, pickup/placement strategy, inventory representation
```

This separation is deliberately provisional, but it is already preferable to using the current sprite or runtime Java class as the door identity.

## Pending exhaustive capture

The next Full report should add and then be copied back into this dossier:

- BaseScriptObject identity/version/source lines for the entity and each component.
- UiConfig display/debug/style fields.
- Full SpriteConfig source and additional face/light/stage metadata.
- CraftRecipe component metadata.
- Exact recipe name/category/time/tags/tools.
- Exact recipe inputs, quantities and flags, especially hinges/knob/nails/planks if present in vanilla data.
- Skill requirements, auto-learn rules and XP awards.
- Recipe outputs and vanilla generated debug text.
- Runtime confirmation of the west/open sprite mapping.

## Initial Full report

The original runtime report is preserved below as the baseline before exhaustive entity-component inspection was added.

```text
--- Object ---
class = zombie.iso.objects.IsoThumpable
square = 15606,616,0
type = doorN
sprite = carpentry_01_57
objectName = Thumpable
textureName = carpentry_01_57
modData = <empty>

--- Object properties ---
flags = doorN, EntityScript
CanScrap = <empty>
DoorSound = WoodShackDoor
EntityScriptName = WoodenDoorLvl3
IsPaintable = <empty>
Material = Door
Material2 = Wood
Material3 = Nails
MaterialType = Wood
PaintingType = door

--- Sprite ---
name = carpentry_01_57
id = 5177
type = doorN
tileType = doorN
grid = <none>

--- Entity script ---
propertyName = WoodenDoorLvl3
resolved = true
class = zombie.scripting.entity.GameEntityScript
name = WoodenDoorLvl3
fullName = Base.WoodenDoorLvl3
module = Base
modID = pz-vanilla
file = D:\Jeux\Steam\steamapps\common\ProjectZomboid\media\scripts\generated\entities\walls\entity_woodendoorlvl3.txt
existsAsVanilla = true
registryId = 5300
components.count = 3
component[0] = zombie.scripting.entity.components.ui.UiConfigScript
component[1] = zombie.scripting.entity.components.spriteconfig.SpriteConfigScript
component[2] = zombie.scripting.entity.components.crafting.CraftRecipeComponentScript

--- Entity SpriteConfig ---
valid = true
multiTile = true
singleFace = false
thumpable = true
isoMasterOnly = false
health = -1
skillBaseHealth = 300
breakSound = BreakDoor
tiles.count = 4
tile[0] = carpentry_01_57
tile[1] = carpentry_01_56
tile[2] = carpentry_01_59
tile[3] = carpentry_01_58
face[0].name = n
face[0].width = 1
face[0].height = 1
face[0].tile[0,0,0] = carpentry_01_57 [blocks]
face[1].name = w
face[1].width = 1
face[1].height = 1
face[1].tile[0,0,0] = carpentry_01_56 [blocks]

--- IsoThumpable ---
isDoor = true
north = true
open = false
locked = false
lockedByKey = false
keyId = -1
health = 500 / 500
barricaded = false
destroyed = false
closedSprite = carpentry_01_57
openSprite = carpentry_01_59
oppositeSquare = 15606,615,0
doubleDoorIndex = -1
garageDoorIndex = -1
hoppable = false
dismantable = false
canBarricade = false
canPassThrough = false
thumpSound = ZombieThumpGeneric
doorFrame = false
```
