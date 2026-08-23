# LMION — Door catalog value reference

Compact reference for editing `DOOR_CATALOG.md` without inventing unsupported values.

Use `TBD` whenever a value has not been decided or verified yet. A `?` suffix means the current catalog entry is only a provisional classification, for example `metal?`.

## Class

Project-defined LMION material/durability classes:

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

`Class` is only one axis of durability. The final HP also depends on the kind/size of opening. A small door should not automatically have the same HP as a normal door made from the same material, and a garage door should not use the normal 1x1 baseline.

## Durability by opening type

### Small 1x1 doors

Use for clearly undersized doors/panels compared with a normal exterior/interior door.

```text
wood          = 425
wood_glazed   = 350
metal         = 550
metal_glazed  = 475
glass         = 300
```

This is intentionally a little below normal 1x1 durability at equivalent material.

### Normal 1x1 doors

```text
wood          = 500
wood_glazed   = 425
heavy_wood    = 600
metal         = 650
metal_glazed  = 550
glass         = 350
```

### Large / double doors and portals

These are per segment/battant, not the HP of the whole opening.

```text
wood          = 600
wood_glazed   = 500
metal         = 800
metal_glazed  = 650
glass         = 425
```

These are starting points only. Structure matters a lot for gates: a light tube gate can stay around 650–800, while a heavy wrought-iron gate can override upward to 1200 or more.

### Garage doors

Garage doors use their own baseline because each segment belongs to a large reinforced opening:

```text
metal         = 1200
metal_glazed  = 1000
```

The value is still per segment. Group destruction is handled separately: if one garage segment reaches zero, the whole garage door is destroyed.

### Special exceptions

```text
jail          = 2000
security      = 3000
```

These are explicit design exceptions rather than ordinary material baselines.

### Overrides

Individual models may override the table when their construction clearly justifies it. Examples already accepted in the catalog:

```text
FarmDoubleGate          = 800
WroughtIronDoubleGate   = 1200
WoodenFenceDoubleGate   = 600
DoubleWireGate          = 650
LogDoor                 = 600
```

The row's explicit HP value is authoritative once reviewed.

## HP

Use a positive integer or `TBD`.

Do not force every member of a class to the same HP. Use the opening-type baseline above, then adjust for visible construction, thickness, reinforcement and special gameplay role.

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
normal wood door       -> WoodDoor
normal metal door      -> MetalDoor
jail/security metal    -> PrisonMetalDoor when appropriate
glass sliding door     -> SlidingGlassDoor
garage door            -> GarageDoor
chain/wire gate        -> MetalGate
metal pole gate        -> MetalPoleGate
large/double pole gate -> MetalPoleGateDouble
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

## Quick examples

Normal metal 1x1:

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

Small metal 1x1:

```text
Class        = metal
HP           = 550
```

Large metal portal segment:

```text
Class        = metal
HP           = 800
```

Metal garage segment:

```text
Class        = metal
HP           = 1200
```

If any field is uncertain, leave it as `TBD` instead of guessing.
