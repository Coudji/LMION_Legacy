# LMION — Door catalog value reference

Compact reference for editing `DOOR_CATALOG.md` without inventing unsupported values.

Use `TBD` whenever a value has not been decided or verified yet. A `?` suffix means the current catalog entry is only a provisional classification, for example `metal?`.

## Class

Project-defined LMION durability classes:

```text
wood
wood_glazed
heavy_wood
metal
metal_glazed
glass
jail
security
unknown
```

Current provisional HP baseline by class:

```text
wood          = 500
wood_glazed   = 425
heavy_wood    = 600
metal         = 650
metal_glazed  = 550
glass         = 350
jail          = 1000
security      = 1200
unknown       = TBD
```

These are balance values, not engine enums. Individual doors can override them later.

## HP

Use a positive integer or `TBD`.

Current normal values to prefer while the catalog is being drafted:

```text
350
425
500
550
600
650
1000
1200
TBD
```

For multi-tile openings the HP value is per segment.

## Glazed

```text
yes
no
```

Use `yes` when glass is a meaningful structural weak point, not merely a tiny decorative detail.

## Frame

Current catalog values:

```text
standard
paired
none
```

Meaning:

```text
standard = normal 1x1 door frame required
paired   = left/right paired double-door frame logic
none     = freestanding gate, sliding door, garage, etc.
```

Do not add another frame value until an actual opening requires one.

## Material(s)

This column represents the engine `Material`, `Material2` and `Material3` properties.

Preferred notation in the catalog when order matters:

```text
M1=Wood; M2=Door
M1=MetalPlates; M2=Door
M1=Wood; M2=Nails; M3=Screws
```

Use `TBD` if not decided.

### Safe current LMION whitelist

Values already observed in vanilla data or verified in the `IsoDoor` / `IsoObject` salvage path:

```text
Door
Wood
Log
MetalBars
MetalPlates
MetalPipe
MetalWire
Nails
Screws
```

Important distinctions:

- `Door` is a vanilla tag/property value, not a physical material.
- `Log` has been observed on the vanilla LogDoor TileDef, but it is not one of the exact salvage tags already verified in `IsoObject.addItemsFromProperties()`.
- Verified salvage-producing values are `Wood`, `MetalBars`, `MetalPlates`, `MetalPipe`, `MetalWire`, `Nails`, and `Screws`.
- Do not invent values such as `Steel`, `CherryWood`, etc. without first checking the engine alias map/runtime behavior.

## MaterialType

`MaterialType` is a closed Build 42 enum. Exact values verified from the B42.20.3 JAR:

```text
Default
Flesh
Flesh_Hollow
Concrete
Plaster
Stone
Wood
Wood_Solid
Brick
Metal
Metal_Large
Metal_Light
Metal_Solid
Glass
Glass_Light
Glass_Solid
Cinderblock
Plastic
Ceramic
Rubber
Fabric
Carpet
Dirt
Grass
Gravel
Sand
Snow
```

For LMION doors, the values most likely to be useful are:

```text
Wood
Wood_Solid
Metal
Metal_Large
Metal_Light
Metal_Solid
Glass
Glass_Light
Glass_Solid
Plastic
Default
```

Do not create custom `MaterialType` names.

## DoorSound

`IsoDoor` reads the closed sprite's `DoorSound` property as a sound prefix. If absent, it falls back to `WoodDoor`.

The following prefixes are confirmed in the B42.20.3 `IsoDoor` code and are the safe current LMION whitelist:

```text
WoodDoor
MetalDoor
PrisonMetalDoor
SlidingGlassDoor
GarageDoor
MetalGate
MetalPoleGate
MetalPoleGateDouble
```

These prefixes are used by the door sound logic for events such as open, close, lock, blocked and break.

Practical intended mapping:

```text
normal wood door      -> WoodDoor
normal metal door     -> MetalDoor
jail/security metal   -> PrisonMetalDoor when appropriate
glass sliding door    -> SlidingGlassDoor
garage door           -> GarageDoor
chain/wire gate       -> MetalGate
metal pole gate       -> MetalPoleGate
large/double pole gate-> MetalPoleGateDouble
```

Do not use `FarmGate` or another guessed prefix until it is explicitly verified.

## BreakSound

`BreakSound` in `SpriteConfig` is not the same thing as `DoorSound`.

For the final LMION `IsoDoor`, material-appropriate break behavior should primarily come from `DoorSound + Break`. `BreakSound` matters especially on the temporary/constructed `IsoThumpable` path.

Confirmed relevant registered sound names in the B42.20.3 JAR include:

```text
BreakDoor
BreakFurniture
BreakFurnitureMetal
BreakGlassItem
BreakMetalItem
BreakWoodItem
BreakObject
BreakBarricadeMetal
BreakBarricadePlank
```

Current LMION entity scripts already use:

```text
BreakDoor
```

Until we deliberately audition/test alternatives, `BreakDoor` is the safest default for door entity scripts. Do not assume that a generic `BreakMetalItem` necessarily sounds better for a metal door without testing it in-game.

## Names

`EN name` and `FR name` are LMION-localized display text, not engine enums.

Rules:

```text
EN name = natural English display name
FR name = natural French display name
```

Avoid encoding engine/internal terminology in the visible name unless the player actually needs it.

## Quick template

When filling a row manually, this is a safe pattern:

```text
Class        = metal
HP           = 650
Glazed       = no
Frame        = standard
Material(s)  = M1=MetalPlates; M2=Door
MaterialType = Metal_Solid
DoorSound    = MetalDoor
BreakSound   = BreakDoor
```

If any field is uncertain, leave it as `TBD` instead of guessing.
