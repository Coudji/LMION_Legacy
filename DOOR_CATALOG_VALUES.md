# LMION — Tile and door property reference

Reference for `DOOR_CATALOG.md` and for TileZed/PZ door properties. The goal is to record what each parameter actually means before LMION writes it back into the game.

Verification tags used in this document:

```text
[TileZed] = visible directly in the TileZed dropdown/screenshots
[JAR]     = verified in Project Zomboid B42.20.3 bytecode
[LMION]   = project balance/design choice
```

Use `TBD` whenever a gameplay value has not been decided or verified yet.

## LMION durability classes

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

`Class` is only one axis. Final HP depends on material plus size/type of opening and may then be overridden per model.

### Small 1x1 doors

```text
wood          = 425
wood_glazed   = 350
metal         = 550
metal_glazed  = 475
glass         = 300
```

### Normal 1x1 doors

```text
wood          = 500
wood_glazed   = 425
heavy_wood    = 600
metal         = 650
metal_glazed  = 550
glass         = 350
```

### Large / double / portal, per segment

```text
wood          = 600
wood_glazed   = 500
metal         = 800
metal_glazed  = 650
glass         = 425
```

### Garage, per segment

```text
metal         = 1200
metal_glazed  = 1000
```

### Special exceptions

```text
jail          = 2000
security      = 3000
```

### Current explicit overrides

```text
FarmDoubleGate          = 700
WroughtIronDoubleGate   = 1200
WoodenFenceDoubleGate   = 600
DoubleWireGate          = 650
LogDoor                 = 600
```

The row's explicit HP is authoritative once reviewed.

## Frame

Current LMION catalog values:

```text
standard
paired
none
```

```text
standard = normal 1x1 door frame required
paired   = left/right paired double-door logic
none     = freestanding gate, sliding door, garage, etc.
```

## Material / Material2 / Material3

These are TileDef sprite properties. All three slots use the same value family.

### TileZed values visible in the Material dropdown

[TileZed]

```text
Undefined
AluminumScrap
Brick
Door
Electric
Fabric
Foam
Fridge
Glass
GoldBar
Leather
Log
Mechanical
MetalBars
MetalPipe
MetalPlates
SmallMetalPlates
MetalScrap
MetalWire
Nails
Natural
Paper
Pipes
Plastic
PlasticBag
PlasticHard
Plumbing
RailroadTie
RailroadTrack
Rubber
Sandbag
Screws
Sink
Steel
Stone
Transmission
WaterContainer
Wood
```

`Undefined` is visible as a TileZed selector value, but its runtime meaning has not been investigated. LMION should not assign it deliberately for now.

### What these values drop through generic IsoObject salvage

[JAR] `IsoObject.addItemsFromProperties()` checks `Material`, `Material2` and `Material3`. Only the values below have a generic salvage effect in B42.20.3.

| Material value | Generic drop | Chance / amount |
|---|---|---|
| `Wood` | `Base.UnusableWood` | 1 guaranteed, plus 20% chance of a second |
| `MetalBars` | `Base.MetalBar` | 50% |
| `MetalPlates` | `Base.SheetMetal` | 50% |
| `MetalPipe` | `Base.MetalPipe` | 50% |
| `MetalWire` | `Base.Wire` | 33.3% |
| `Nails` | `Base.Nails` | 50% |
| `Screws` | `Base.Screws` | 50% |

Every other TileZed Material value currently has **no branch in this generic salvage method**, including:

```text
Undefined
AluminumScrap
Brick
Door
Electric
Fabric
Foam
Fridge
Glass
GoldBar
Leather
Log
Mechanical
SmallMetalPlates
MetalScrap
Natural
Paper
Pipes
Plastic
PlasticBag
PlasticHard
Plumbing
RailroadTie
RailroadTrack
Rubber
Sandbag
Sink
Steel
Stone
Transmission
WaterContainer
```

This does not mean those values are useless elsewhere. It only means they do not create an item through `IsoObject.addItemsFromProperties()`.

### Important IsoDoor destruction behavior

[JAR] For a normal non-garage `IsoDoor.destroy()`:

1. If at least one of `Material`, `Material2`, `Material3` exists, `addItemsFromProperties()` is called.
2. If all three are absent, the fallback is `1–2 x Base.Plank`.
3. After that, vanilla adds `1 x Base.Doorknob` unconditionally.
4. Vanilla then adds `0–2 x Base.Hinge`.
5. A curtain, if present, returns `1 x Base.Sheet`.

Therefore an unsupported material such as `Door` or `Log` can suppress the plank fallback while producing no generic material drop of its own.

The direct `IsoDoor.destroy()` garage branch returns before this generic loot/hardware path, so garage-door destruction is a separate case.

### LMION LogDoor consequence

[LMION] `LogDoor` should keep semantic `M1=Log`, but use custom destruction loot:

```text
1 x Base.Log
no Base.Doorknob
no Base.Hinge
no additional vanilla door salvage
```

## MaterialType

`MaterialType` is **not** the same thing as `Material`.

[JAR] It is a closed enum in B42.20.3. Custom names cannot be invented.

### Complete MaterialType enum

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

Grouped for easier reading:

| Family | Values |
|---|---|
| Generic | `Default` |
| Flesh | `Flesh`, `Flesh_Hollow` |
| Masonry | `Concrete`, `Plaster`, `Stone`, `Brick`, `Cinderblock`, `Ceramic` |
| Wood | `Wood`, `Wood_Solid` |
| Metal | `Metal`, `Metal_Large`, `Metal_Light`, `Metal_Solid` |
| Glass | `Glass`, `Glass_Light`, `Glass_Solid` |
| Soft / synthetic | `Plastic`, `Rubber`, `Fabric`, `Carpet` |
| Ground | `Dirt`, `Grass`, `Gravel`, `Sand`, `Snow` |

### Does MaterialType determine salvage loot?

No. [JAR]

`IsoObject.addItemsFromProperties()` reads `Material`, `Material2` and `Material3`; it does not read `MaterialType` for the generic salvage drops listed above.

So, for example:

```text
MaterialType = Metal_Light
```

does **not** mean a metal pipe will drop. If LMION wants pipe salvage, one of the `Material*` properties must contain `MetalPipe`.

For doors, the useful MaterialType choices will usually be:

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

## DoorSound

`DoorSound` is a TileDef property on the closed sprite. [TileZed/JAR]

`IsoDoor.getSoundPrefix()` returns the `DoorSound` value. If the property is absent, vanilla falls back to:

```text
WoodDoor
```

So TileZed `None` does **not** mean silent for an `IsoDoor`; it effectively becomes the vanilla `WoodDoor` family unless another path overrides it.

### TileZed DoorSound choices and internal prefixes

The TileZed labels below are visible in the provided dropdown. The internal prefix is confirmed by matching registered B42.20.3 GameSound families.

| TileZed label | Prefix used by IsoDoor | Registered GameSound family to search |
|---|---|---|
| `None` | property absent → `WoodDoor` fallback | `WoodDoor*` |
| `Farm Gate` | `FarmGate` | `FarmGateOpen`, `FarmGateClose`, `FarmGateBreak`, `FarmGateLocked`, `FarmGateBlocked`, `FarmGateLock`, `FarmGateUnlock` |
| `Garage Door` | `GarageDoor` | `GarageDoorOpen`, `GarageDoorClose`, `GarageDoorBreak`, `GarageDoorLocked`, `GarageDoorBlocked`, `GarageDoorLock`, `GarageDoorUnlock` |
| `Metal Door` | `MetalDoor` | `MetalDoorOpen`, `MetalDoorClose`, `MetalDoorBreak`, `MetalDoorLocked`, `MetalDoorBlocked`, `MetalDoorLock`, `MetalDoorUnlock` |
| `Metal Gate` | `MetalGate` | `MetalGateOpen`, `MetalGateClose`, `MetalGateBreak`, `MetalGateLocked`, `MetalGateBlocked`, `MetalGateLock`, `MetalGateUnlock` |
| `Metal Pole Gate` | `MetalPoleGate` | `MetalPoleGateOpen`, `MetalPoleGateClose`, `MetalPoleGateBreak`, `MetalPoleGateLocked`, `MetalPoleGateBlocked`, `MetalPoleGateLock`, `MetalPoleGateUnlock` |
| `Metal Pole Gate (Double)` | `MetalPoleGateDouble` | `MetalPoleGateDoubleOpen`, `MetalPoleGateDoubleClose`, `MetalPoleGateDoubleBreak`, `MetalPoleGateDoubleLocked`, `MetalPoleGateDoubleBlocked`, `MetalPoleGateDoubleLock`, `MetalPoleGateDoubleUnlock` |
| `Metal Pole Gate (Small)` | `MetalPoleGateSmall` | `MetalPoleGateSmallOpen`, `MetalPoleGateSmallClose`, `MetalPoleGateSmallBreak`, `MetalPoleGateSmallLocked`, `MetalPoleGateSmallBlocked`, `MetalPoleGateSmallLock`, `MetalPoleGateSmallUnlock` |
| `Prison Metal Door` | `PrisonMetalDoor` | `PrisonMetalDoorOpen`, `PrisonMetalDoorClose`, `PrisonMetalDoorBreak`, `PrisonMetalDoorLocked`, `PrisonMetalDoorBlocked`, `PrisonMetalDoorLock`, `PrisonMetalDoorUnlock` |
| `Sliding Glass Door` | `SlidingGlassDoor` | `SlidingGlassDoorOpen`, `SlidingGlassDoorClose`, `SlidingGlassDoorBreak`, `SlidingGlassDoorLocked`, `SlidingGlassDoorBlocked`, `SlidingGlassDoorLock`, `SlidingGlassDoorUnlock` |
| `Small Wood Gate` | `WoodGateSmall` | `WoodGateSmallOpen`, `WoodGateSmallClose`, `WoodGateSmallBreak`, `WoodGateSmallLocked`, `WoodGateSmallBlocked`, `WoodGateSmallLock`, `WoodGateSmallUnlock` |
| `Wood Door` | `WoodDoor` | `WoodDoorOpen`, `WoodDoorClose`, `WoodDoorBreak`, `WoodDoorLocked`, `WoodDoorBlocked`, `WoodDoorLock`, `WoodDoorUnlock` |
| `Wood Gate` | `WoodGate` | `WoodGateOpen`, `WoodGateClose`, `WoodGateBreak`, `WoodGateLocked`, `WoodGateBlocked`, `WoodGateLock`, `WoodGateUnlock` |
| `Wood Log Gate` | `WoodLogGate` | `WoodLogGateOpen`, `WoodLogGateClose`, `WoodLogGateBreak`, `WoodLogGateLocked`, `WoodLogGateBlocked`, `WoodLogGateLock`, `WoodLogGateUnlock` |
| `Wood Shack Door` | `WoodShackDoor` | `WoodShackDoorOpen`, `WoodShackDoorClose`, `WoodShackDoorBreak`, `WoodShackDoorLocked`, `WoodShackDoorBlocked`, `WoodShackDoorLock`, `WoodShackDoorUnlock` |

`WoodDoor` also has registered `WoodDoorCreak` / `WoodDoorCreaks`, and `WoodShackDoor` has `WoodShackDoorCreak`.

### Where are the actual sound files?

The JAR verifies the GameSound names above, but it does **not** expose a one-to-one `.wav` filename for each door event.

Current PZ audio uses GameSound names and FMOD; at least some audio is packaged in `.bank` files under `media/sound/banks/`. Therefore a door event may not exist as an individually playable `.wav` in the game folder.

For manual investigation, search the installed game files for the exact GameSound name, for example:

```text
FarmGateOpen
FarmGateBreak
MetalDoorOpen
WoodGateSmallClose
ZombieThumpMetalPoleGate
```

If a sound script resolves to an FMOD event/bank, the event name is the useful identifier even when no standalone WAV exists.

## ThumpSound

`ThumpSound` is a separate TileDef property. [TileZed/JAR]

If it is explicitly present, `IsoDoor.getThumpSound()` returns it directly. If absent, `IsoDoor` derives a default from `DoorSound` for only a small set of known prefixes.

### TileZed values visible in the provided dropdown

```text
None
ZombieThumpChainlinkFence
ZombieThumpGarageDoor
ZombieThumpGeneric
ZombieThumpMetalPoleFence
ZombieThumpMetalPoleGate
ZombieThumpMetal
ZombieThumpWindow
ZombieThumpWood
```

[JAR] `ZombieThumpWindowExtra` is also a registered/handled sound name even though it was not visible in the supplied dropdown crop.

### IsoDoor automatic ThumpSound mapping when ThumpSound is absent

[JAR]

| DoorSound prefix | Automatic thump sound |
|---|---|
| `MetalGate` | `ZombieThumpChainlinkFence` |
| `MetalPoleGate` | `ZombieThumpMetalPoleFence` |
| `MetalPoleGateDouble` | `ZombieThumpMetalPoleFence` |
| `GarageDoor` | `ZombieThumpGarageDoor` |
| `MetalDoor` | `ZombieThumpMetal` |
| `PrisonMetalDoor` | `ZombieThumpMetal` |
| `SlidingGlassDoor` | `ZombieThumpWindow` |
| every other prefix | `ZombieThumpGeneric` |

That means `FarmGate`, `MetalPoleGateSmall`, `WoodDoor`, `WoodGate`, `WoodGateSmall`, `WoodLogGate` and `WoodShackDoor` fall back to `ZombieThumpGeneric` unless the tile explicitly defines `ThumpSound`.

[JAR] `ZombieThumpMetalPoleGate` is explicitly handled by zombie thump logic and is treated as a metal-gate impact family.

### Registered thump GameSound names worth searching

[JAR]

```text
ZombieThumpChainlinkFence
ZombieThumpGarageDoor
ZombieThumpGeneric
ZombieThumpMetal
ZombieThumpMetalPoleFence
ZombieThumpMetalPoleGate
ZombieThumpWindow
ZombieThumpWindowExtra
ZombieThumpWood
```

Related damage-state sounds registered in B42.20.3 include:

```text
ZombieThumpChainlinkFenceDamageLow
ZombieThumpChainlinkFenceDamageHigh
ZombieThumpChainlinkFenceDamageCollapse
ZombieThumpMetalPoleFenceDamageLow
ZombieThumpMetalPoleFenceDamageHigh
ZombieThumpMetalPoleFenceDamageCollapse
ZombieThumpWoodCollapse
```

## BuildBreakSound / SpriteConfig BreakSound

This is deliberately named `BuildBreakSound` in LMION documentation to avoid confusing it with TileZed properties.

`BreakSound` is a `SpriteConfig` / GameEntity construction field, not a `DoorSound` or `ThumpSound` TileDef field. That is why it does not appear in the TileZed door-property dropdown.

Current LMION scripts commonly use:

```text
BreakDoor
```

Relevant registered generic break GameSounds in B42.20.3 include:

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

For a final `IsoDoor`, vanilla calls its door-family sound with the suffix `Break`, so for example:

```text
DoorSound = FarmGate  -> FarmGateBreak
DoorSound = MetalDoor -> MetalDoorBreak
DoorSound = WoodDoor  -> WoodDoorBreak
```

This is separate from the `SpriteConfig BreakSound` used by construction/`IsoThumpable` paths.

## Example: FarmDoubleGate reference

After visual review:

```text
Class        = metal
HP           = 700 per segment
Material(s)  = M1=MetalPipe
MaterialType = Metal_Light
DoorSound    = FarmGate
ThumpSound   = ZombieThumpMetalPoleGate
BuildBreakSound = BreakDoor
```

The wooden post is treated as support scenery rather than salvage material for each moving gate segment.

## Editing rule

Before assigning a value in LMION:

1. prefer a value visible in TileZed or verified in the B42.20.3 JAR;
2. distinguish `Material` from `MaterialType`;
3. distinguish `DoorSound` from `ThumpSound`;
4. treat `SpriteConfig BreakSound` as a separate construction-layer field;
5. if behavior is still unknown, write `TBD` rather than inventing a new alias value.
