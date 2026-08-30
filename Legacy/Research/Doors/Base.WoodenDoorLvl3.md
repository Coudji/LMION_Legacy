# Door reference: `Base.WoodenDoorLvl3`

Status: exhaustive runtime/reference capture for the current Build 42 sample, first captured 2026-08-19.

This file is the first LMION door reference dossier. It deliberately separates vanilla facts, runtime instance state, and LMION conclusions so later pickup/placement code can reuse the data without confusing one particular world object with the logical door family.

It is intentionally detailed. This is the model dossier to copy when other door families need manual classification.

## Provenance

- Source: vanilla Build 42 construction menu, then inspected in-world with LMION Inspector / Full details.
- Runtime sample square: `15606,616,0`.
- Runtime class: `zombie.iso.objects.IsoThumpable`.
- Current state at capture: north-facing, closed, unlocked, undamaged (`500 / 500`).
- Vanilla entity source reported by the game: `media/scripts/generated/entities/walls/entity_woodendoorlvl3.txt`.
- Vanilla mod ID: `pz-vanilla`.

## Logical identity

| Field | Value | Confidence / use |
|---|---|---|
| Tile property `EntityScriptName` | `WoodenDoorLvl3` | Runtime confirmed |
| Entity script name | `WoodenDoorLvl3` | Runtime confirmed |
| Entity full name | `Base.WoodenDoorLvl3` | Runtime confirmed; preferred LMION identity candidate for this entity-backed family |
| Display/debug name | `Porte en bois (artisan)` | Runtime confirmed |
| Module | `Base` | Runtime confirmed |
| Mod ID | `pz-vanilla` | Runtime confirmed |
| Vanilla | `true` | Runtime confirmed |
| Registry ID | `5300` | Runtime confirmed for this build; do not use as cross-version identity |

### Identity conclusion

For this B42 entity-backed door, `Base.WoodenDoorLvl3` is a much stronger logical identity than any sprite ID.

The sprite and sprite ID change with orientation/state. The entity full name does not describe the current visual state; it describes the door definition itself.

Working LMION rule for entity-backed openings:

```text
familyId = GameEntityScript.fullName
```

For this family:

```text
familyId = Base.WoodenDoorLvl3
```

This rule still needs to be checked against other entity-backed opening families before becoming generic production code.

## Entity components

The entity reports exactly three script components:

1. `zombie.scripting.entity.components.ui.UiConfigScript`
2. `zombie.scripting.entity.components.spriteconfig.SpriteConfigScript`
3. `zombie.scripting.entity.components.crafting.CraftRecipeComponentScript`

This gives a useful B42 definition split:

```text
GameEntityScript
├── UiConfig       -> presentation/style
├── SpriteConfig   -> visual family / geometry / build-object behavior
└── CraftRecipe    -> construction recipe / materials / skills
```

## UI definition

```text
displayNameDebug = Porte en bois (artisan)
uiEnabled = false
entityStyle = ES_Wood_DoorLvl3
xuiSkinName = default
```

`entityStyle` is useful metadata but is not currently treated as the LMION family identity.

## Visual family / SpriteConfig

### General configuration

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
cornerSprite = <nil>
debugItem = <nil>
onCreate = <nil>
onIsValid = <nil>
timedActionOnIsValid = <nil>
lightsourceFuel = <nil>
lightsourceItem = <nil>
lightsourceTagItem.count = 0
previousStages.count = 0
```

### Sprite family

The entity lists four tile names:

```text
carpentry_01_57
carpentry_01_56
carpentry_01_59
carpentry_01_58
```

Known mapping:

| Orientation/state | Sprite | Evidence |
|---|---|---|
| North, closed | `carpentry_01_57` | Runtime object + SpriteConfig face `n` |
| North, open | `carpentry_01_59` | Runtime `openSprite` |
| West, closed | `carpentry_01_56` | SpriteConfig face `w` |
| West, open | `carpentry_01_58` | Strongly implied by four-tile family; runtime confirmation still pending |

Configured closed faces:

```text
face n
  width = 1
  height = 1
  zLayers = 1
  lightOffset = 0,0,0
  tile[0,0,0] = carpentry_01_57 [blocks]

face w
  width = 1
  height = 1
  zLayers = 1
  lightOffset = 0,0,0
  tile[0,0,0] = carpentry_01_56 [blocks]
```

### Important geometry conclusion

`multiTile = true` does **not** mean this door occupies multiple world squares.

The configured faces are `1 x 1`, and the runtime door occupies one square. For LMION, actual footprint must come from the configured face/grid geometry and/or runtime grouping, not from `multiTile` alone.

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

These remain raw vanilla facts. In particular:

- `CanScrap` is not treated as equivalent to runtime `dismantable` or context-menu dismantle availability.
- `DoorSound` is behavior/audio metadata, not the logical family identity.
- `EntityScriptName` is the bridge from the placed object to the richer B42 definition.

## Construction recipe

### Recipe identity

```text
component.buildCategory = EntityRecipe
recipe.name = WoodenDoorLvl3
recipe.translationName = Porte en bois (artisan)
recipe.category = Carpentry
recipe.time = 200
recipe.tooltip = Tooltip_craft_woodenDoorDesc
recipe.modID = pz-vanilla
recipe.modName = Project Zomboid
recipe.vanilla = true
recipe.existsAsVanilla = true
recipe.buildable = true
recipe.shapeless = true
```

Other captured recipe flags:

```text
usesTools = false
needToBeLearn = false
allowBatchCraft = true
canWalk = false
canBeDoneFromFloor = false
requiresPlayer = false
smithing = false
researchAll = false
researchSkillLevel = 5
```

### Exact inputs

The vanilla recipe has five inputs.

#### Input 0: hammer-like item, kept

```text
originalLine = item 1 tags[base:hammer] mode:keep flags[Prop1;MayDegradeVeryLight]
amount = 1
itemApplyMode = Keep
```

Accepted items in this runtime build:

```text
Base.BallPeenHammerForged
Base.BallPeenHammer
Base.Hammer
Base.HammerForged
Base.HammerStone
Base.SmithingHammer
```

The recipe-level field `usesTools = false` therefore must **not** be interpreted as "no tool-like input is required". The actual inputs are more authoritative for LMION recipe analysis.

#### Input 1: planks

```text
originalLine = item 4 [Base.Plank]
amount = 4
possible item = Base.Plank
```

#### Input 2: nails

```text
originalLine = item 4 [Base.Nails]
amount = 4
possible item = Base.Nails
```

#### Input 3: hinges

```text
originalLine = item 2 [Base.Hinge]
amount = 2
possible item = Base.Hinge
```

This is direct vanilla evidence that this door family requires **two hinges** when constructed.

#### Input 4: doorknob

```text
originalLine = item 1 [Base.Doorknob]
amount = 1
possible item = Base.Doorknob
```

### Recipe material summary

```text
kept tool: 1 hammer-compatible item
consumed: 4 Base.Plank
consumed: 4 Base.Nails
consumed: 2 Base.Hinge
consumed: 1 Base.Doorknob
```

For entity-backed constructible doors, this provides a substantially stronger source for LMION hardware classification than sprite names or `DoorSound` heuristics.

### Skills and XP

```text
requiredSkillCount = 1
requiredSkill[0].perk = Woodwork
requiredSkill[0].level = 7

xpAwardCount = 1
xpAward[0].perk = Woodwork
xpAward[0].amount = 70

researchSkillLevel = 5
debugText = , requires having 5 in any of Menuiserie
```

Important: `requiredSkill.level = 7` and `researchSkillLevel = 5` are separate vanilla fields. The generated `debugText` mentions level 5, so LMION must not collapse these into one generic "skill requirement" value without understanding which game system is using each field.

### Outputs

```text
outputCount = 0
outputs.count = 0
```

The recipe is nevertheless explicitly `buildable = true` and tagged `EntityRecipe`. The current evidence therefore says that construction of this world entity does not use the ordinary recipe output list as an inventory-item output.

That interpretation is an LMION inference from the captured fields, not a separately confirmed engine contract.

## Runtime world instance

```text
class = zombie.iso.objects.IsoThumpable
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

This is instance state, not family identity.

### Runtime/definition separation

For LMION this door is best thought of as:

```text
family definition
    Base.WoodenDoorLvl3

visual definition
    SpriteConfig

construction definition
    CraftRecipe

world instance
    IsoThumpable
    health / lock / key / open state / square / etc.
```

The runtime Java class (`IsoThumpable`) is therefore also not a sufficient identity for the door family.

## Hardware conclusion for this family

For `Base.WoodenDoorLvl3`, hinge requirement is no longer heuristic:

```text
requiresHinges = true
hingeItem = Base.Hinge
hingeCount = 2
```

Likewise:

```text
usesDoorknob = true
doorknobItem = Base.Doorknob
doorknobCount = 1
```

These values come directly from the vanilla construction recipe.

This suggests the following future LMION rule for constructible entity-backed openings:

```text
1. resolve GameEntityScript
2. resolve CraftRecipe component
3. inspect exact inputs
4. derive hardware requirements from recipe data
```

For map-only/non-entity-backed doors where no such recipe exists, LMION will still need its own canonical family registry/classification.

## Other useful confirmed facts

- `breakSound = BreakDoor` comes from the entity SpriteConfig.
- `DoorSound = WoodShackDoor` comes from tile properties.
- `thumpSound = ZombieThumpGeneric` comes from the runtime object.
- These three sound-related values describe different layers and must not be conflated.
- `canBePadlocked = false` is definition-level data for this SpriteConfig.
- `dismantable = false` is runtime state for this `IsoThumpable` despite the tile having raw `CanScrap`.
- `skillBaseHealth = 300` while runtime health is `500 / 500`; the exact health formula is not established by this capture and should not be guessed.

## What remains unconfirmed

This dossier is exhaustive for the fields currently surfaced by LMION, but not literally omniscient. Remaining gaps are explicit:

1. Runtime confirmation of `carpentry_01_58` as the West/open sprite.
2. Exact interpretation of `multiTile = true` in SpriteConfig beyond the demonstrated fact that it does not equal a >1-square footprint here.
3. Exact semantic distinction between recipe `requiredSkill = Woodwork 7`, `researchSkillLevel = 5`, and the generated debug text mentioning 5.
4. Exact runtime formula producing `500 / 500` health from definition/build/skill data.
5. Raw inherited `BaseScriptObject` source/version lines did not appear in this runtime report even though the current debug inspector attempts to request them; this needs a separate inspector/reflection audit rather than speculative direct Java calls.

## Canonical LMION reference model from this sample

```text
Identity
  Base.WoodenDoorLvl3

Presentation
  Porte en bois (artisan)
  ES_Wood_DoorLvl3

Visual family
  N closed = carpentry_01_57
  N open   = carpentry_01_59
  W closed = carpentry_01_56
  W open   = carpentry_01_58   [runtime confirmation pending]

Footprint
  1 x 1 for configured N/W faces

Construction
  hammer-compatible item x1 [kept]
  Base.Plank x4
  Base.Nails x4
  Base.Hinge x2
  Base.Doorknob x1
  Woodwork 7 required
  Woodwork XP 70

Hardware classification
  hinges = yes (2)
  doorknob = yes (1)

Runtime type in tested instance
  IsoThumpable

Runtime grouping
  doubleDoorIndex = -1
  garageDoorIndex = -1
```

## Exhaustive Full report captured 2026-08-19

```text
--- Object ---
class = zombie.iso.objects.IsoThumpable
square = 15606,616,0
type = doorN
sprite = carpentry_01_57
tostring = null:carpentry_01_57:carpentry_01_57:zombie.iso.objects.IsoThumpable@47176383
objectName = Thumpable
name = <nil>
scriptName = none
objectIndex = 1
specialObjectIndex = 0
worldObjectIndex = -1
textureName = carpentry_01_57
dir = N
modData = <empty>

--- Object properties ---
flags.count = 2
flags = doorN, EntityScript
properties.count = 9
CanScrap = <empty>
DoorSound = WoodShackDoor
EntityScriptName = WoodenDoorLvl3
IsPaintable = <empty>
Material = Door
Material2 = Wood
Material3 = Nails
MaterialType = Wood
PaintingType = door

--- Object property metadata ---
surface = 0
surfaceOffset = false
table = false
tableTop = false
stackReplaceTileOffset = 0
itemHeight = 0
slopedSurface.direction = <nil>
slopedSurface.heightMin = 0
slopedSurface.heightMax = 0

--- Sprite ---
name = carpentry_01_57
id = 5177
type = doorN
tileType = doorN
parentObjectName = <nil>
grid = <none>

--- Sprite properties ---
same as = Object properties

--- Entity script ---
propertyName = WoodenDoorLvl3
resolved = true
class = zombie.scripting.entity.GameEntityScript
displayNameDebug = Porte en bois (artisan)
name = WoodenDoorLvl3
fullName = Base.WoodenDoorLvl3
module = Base
modID = pz-vanilla
file = D:\Jeux\Steam\steamapps\common\ProjectZomboid\media\scripts\generated\entities\walls\entity_woodendoorlvl3.txt
existsAsVanilla = true
registryId = 5300
hasComponents = true
components.count = 3
components[0] = zombie.scripting.entity.components.ui.UiConfigScript
components[1] = zombie.scripting.entity.components.spriteconfig.SpriteConfigScript
components[2] = zombie.scripting.entity.components.crafting.CraftRecipeComponentScript

--- Entity UiConfig ---
class = zombie.scripting.entity.components.ui.UiConfigScript
displayNameDebug = Porte en bois (artisan)
uiEnabled = false
entityStyle = ES_Wood_DoorLvl3
xuiSkinName = default

--- Entity SpriteConfig ---
class = zombie.scripting.entity.components.spriteconfig.SpriteConfigScript
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
cornerSprite = <nil>
debugItem = <nil>
onCreate = <nil>
onIsValid = <nil>
timedActionOnIsValid = <nil>
lightsourceFuel = <nil>
lightsourceItem = <nil>
lightsourceTagItem.count = 0
previousStages.count = 0
tiles.count = 4
tiles[0] = carpentry_01_57
tiles[1] = carpentry_01_56
tiles[2] = carpentry_01_59
tiles[3] = carpentry_01_58
face[0].name = n
face[0].width = 1
face[0].height = 1
face[0].zLayers = 1
face[0].lightOffsetX = 0
face[0].lightOffsetY = 0
face[0].lightOffsetZ = 0
face[0].tile[0,0,0] = carpentry_01_57 [blocks]
face[1].name = w
face[1].width = 1
face[1].height = 1
face[1].zLayers = 1
face[1].lightOffsetX = 0
face[1].lightOffsetY = 0
face[1].lightOffsetZ = 0
face[1].tile[0,0,0] = carpentry_01_56 [blocks]

--- Entity CraftRecipe component ---
class = zombie.scripting.entity.components.crafting.CraftRecipeComponentScript
buildCategory = EntityRecipe

--- Entity CraftRecipe ---
class = zombie.scripting.entity.components.crafting.CraftRecipe
name = WoodenDoorLvl3
translationName = Porte en bois (artisan)
category = Carpentry
time = 200
animation = <nil>
tooltip = Tooltip_craft_woodenDoorDesc
iconName = <nil>
modID = pz-vanilla
modName = Project Zomboid
vanilla = true
existsAsVanilla = true
buildable = true
usesTools = false
needToBeLearn = false
allowBatchCraft = true
canWalk = false
canBeDoneFromFloor = false
requiresPlayer = false
shapeless = true
smithing = false
researchAll = false
researchSkillLevel = 5
inputCount = 5
outputCount = 0
requiredSkillCount = 1
autoLearnAllSkillCount = 0
autoLearnAnySkillCount = 0
xpAwardCount = 1
tags.count = 1
tags[0] = EntityRecipe
inputs.count = 5
input[0].originalLine = item 1 tags[base:hammer] mode:keep flags[Prop1;MayDegradeVeryLight]
input[0].amount = 1
input[0].itemApplyMode = Keep
input[0].possibleItems = Base.BallPeenHammerForged, Base.BallPeenHammer, Base.Hammer, Base.HammerForged, Base.HammerStone, Base.SmithingHammer
input[1].originalLine = item 4 [Base.Plank]
input[1].amount = 4
input[1].possibleItems[0] = Base.Plank
input[2].originalLine = item 4 [Base.Nails]
input[2].amount = 4
input[2].possibleItems[0] = Base.Nails
input[3].originalLine = item 2 [Base.Hinge]
input[3].amount = 2
input[3].possibleItems[0] = Base.Hinge
input[4].originalLine = item 1 [Base.Doorknob]
input[4].amount = 1
input[4].possibleItems[0] = Base.Doorknob
outputs.count = 0
requiredSkill[0].perk = Woodwork
requiredSkill[0].level = 7
xpAward[0].perk = Woodwork
xpAward[0].amount = 70
debugText = , requires having 5 in any of Menuiserie

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
