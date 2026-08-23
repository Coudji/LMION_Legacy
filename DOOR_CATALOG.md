# LMION — Door catalog

Status: working catalog for profile preparation. Values marked with `?` are provisional inferences that still need review before they are pushed into LMION profiles.

The inventory below is based on the openings currently present in the LMION deterministic Test Zone. The goal is to prepare names, physical classes, durability, materials and sounds in one place before profiles are generated in bulk.

The preview images are the PNG assets already stored in `LMION_Build/42/media/textures`. Raw HTML `<img>` tags are used because Markdown tables otherwise display the source PNGs at their natural size.

## Durability model

Durability is not derived from material alone. LMION uses material class plus opening size/type, then allows model-specific overrides.

| Opening type | Wood | Wood glazed | Metal | Metal glazed | Glass |
|---|---:|---:|---:|---:|---:|
| Small 1x1 | 425 | 350 | 550 | 475 | 300 |
| Normal 1x1 | 500 | 425 | 650 | 550 | 350 |
| Large / double / portal | 600 | 500 | 800 | 650 | 425 |
| Garage | — | — | 1200 | 1000 | — |

Special explicit exceptions:

```text
JailDoor     = 2000
SecurityDoor = 3000
```

For multi-tile openings, HP is per segment. Linked/group destruction behavior is left to the game's native opening logic unless a future LMION profile explicitly needs to override it.

The row's explicit HP value is authoritative once reviewed. Construction skill bonuses remain a separate Build system.

## Material and sound fields

The catalog only uses engine property values from the safe reference in `DOOR_CATALOG_VALUES.md`. `BreakSound = BreakDoor` is used as the provisional construction/`IsoThumpable` default until alternatives are deliberately auditioned. For final `IsoDoor` behavior, `DoorSound` is the important material-appropriate sound prefix.

## Garage doors

Status: **validated family specification**. All garage-door models currently listed here use the same gameplay rules. LMION does not make rolling, sectional or industrial-looking variants inherently stronger or weaker just because of their visual mechanism. The only balance split is **solid metal** versus **glazed metal**.

### Shared physical profile

- Solid garage doors: class `metal`, world max health **1200 HP per segment**.
- Glazed garage doors: class `metal_glazed`, world max health **1000 HP per segment**.
- Primary material: `MetalPlates`.
- Secondary material: `MetalBars`.
- `MaterialType = Metal_Large`.
- `DoorSound = GarageDoor`.
- `BreakSound = BreakDoor` for the construction/thumpable stage unless a better verified value is adopted later.
- Frame requirement: none.

### Player construction

All garage doors require **MetalWelding 6**, grant **50 XP**, and use `time = 200` for now. The construction time is intentionally a temporary common value to be adjusted after in-game testing.

Constructed durability is driven by MetalWelding rather than Woodwork.

| Variant | `health` | `skillBaseHealth` | HP at MetalWelding 6 | HP at MetalWelding 10 |
|---|---:|---:|---:|---:|
| Solid metal | 600 | 400 | 3000 | 4600 |
| Glazed metal | 500 | 350 | 2600 | 4000 |

#### Solid-metal craft

- Welding Mask x1 — kept.
- Blow Torch — **6 uses**.
- Small Sheet Metal x9.
- Metal Bar x3.
- Door Hinge x6.
- Welding Rods — **3 uses**.
- No Screwdriver.
- No Screws.

#### Glazed-metal craft

Same recipe as the solid version except three metal sheets are replaced by glass:

- Welding Mask x1 — kept.
- Blow Torch — **6 uses**.
- Small Sheet Metal x6.
- Glass Panel (`Base.GlassPanel`) x3.
- Metal Bar x3.
- Door Hinge x6.
- Welding Rods — **3 uses**.
- No Screwdriver.
- No Screws.

### Pickup and replacement

Garage-door pickup is intended as a controlled removal operation, not as risky salvage.

- Pickup allowed: yes.
- Required skill follows the family rule `floor(construction requirement / 2)`: MetalWelding 6 therefore gives **MetalWelding 3** for pickup.
- Required pickup tools: **Blow Torch + Welding Mask**.
- Break chance during pickup: **none**.
- Pickup output: **3 garage-door packages, 20 kg each** (60 kg total).
- Replacement requires all three packages.
- Replacement uses **Blow Torch + Welding Mask**.
- Welding Rods must also be consumed when replacing the door **if the placement flow can support that requirement cleanly**. Exact placement consumption can be finalized during implementation.

The pickup skill must be tied to the door's construction skill, not inferred from the vanilla Moveables perk associated with a particular tool.

### Dismantling scope

- Deliberate dismantling requires **Blow Torch + Welding Mask**.
- The exact materials returned by dismantling are intentionally left to the implementation pass, which should choose sensible returns from the door's construction/material profile.
- Destruction behavior and destruction loot are not defined by this catalog entry.
- Repair rules are handled elsewhere and are not part of this catalog pass.

### Models

| Preview | Model / entity | EN name | FR name | Class | World HP / segment | Glazed | Frame | Material(s) | MaterialType | DoorSound | BreakSound |
|---|---|---|---|---|---:|---|---|---|---|---|---|
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_IndustrialGarageDoor.png" width="120"> | `Base.IndustrialGarageDoor` | Industrial Garage Door | Porte de garage industrielle | `metal` | 1200 | no | none | M1=MetalPlates; M2=MetalBars | Metal_Large | GarageDoor | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_GreenGarageDoor.png" width="120"> | `Base.GreenGarageDoor` | Green Garage Door | Porte de garage verte | `metal` | 1200 | no | none | M1=MetalPlates; M2=MetalBars | Metal_Large | GarageDoor | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_WhiteGarageDoor.png" width="120"> | `Base.WhiteGarageDoor` | White Garage Door | Porte de garage blanche | `metal` | 1200 | no | none | M1=MetalPlates; M2=MetalBars | Metal_Large | GarageDoor | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_GreyGarageDoor.png" width="120"> | `Base.GreyGarageDoor` | Grey Garage Door | Porte de garage grise | `metal` | 1200 | no | none | M1=MetalPlates; M2=MetalBars | Metal_Large | GarageDoor | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_RollingGarageDoor.png" width="120"> | `Base.RollingGarageDoor` | Rolling Garage Door | Porte de garage à enroulement | `metal` | 1200 | no | none | M1=MetalPlates; M2=MetalBars | Metal_Large | GarageDoor | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_RedWindowGarageDoor.png" width="120"> | `Base.RedWindowGarageDoor` | Red Window Garage Door | Porte de garage rouge vitrée | `metal_glazed` | 1000 | yes | none | M1=MetalPlates; M2=MetalBars | Metal_Large | GarageDoor | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_RollingWindowGarageDoor.png" width="120"> | `Base.RollingWindowGarageDoor` | Rolling Window Garage Door | Porte de garage à enroulement vitrée | `metal_glazed` | 1000 | yes | none | M1=MetalPlates; M2=MetalBars | Metal_Large | GarageDoor | BreakDoor |

### Internal model descriptions

These descriptions are documentation only. They are not intended for player-facing strings; their purpose is to tell the implementation pass what visual object each catalog entry refers to and why it belongs to this profile.

- `IndustrialGarageDoor`: large solid industrial-style metal garage door with no glazing. Visually heavier/industrial, but intentionally balanced like every other solid garage model.
- `GreenGarageDoor`: large solid green metal garage door with no glazing.
- `WhiteGarageDoor`: large solid white sectional metal garage door made of multiple horizontal embossed panels, with no glazing; residential/light-workshop appearance.
- `GreyGarageDoor`: large solid grey metal garage door with no glazing.
- `RollingGarageDoor`: large solid rolling/shutter-style metal garage door with no glazing. Its rolling appearance does not change the family durability or craft.
- `RedWindowGarageDoor`: large red sectional metal garage door with substantial glazed upper sections. The metal frame remains structurally dominant, but the glazing justifies the lower `metal_glazed` durability and replacement of three metal sheets by three glass panels in the craft.
- `RollingWindowGarageDoor`: large rolling/shutter-style metal garage door with glazing. It uses the same `metal_glazed` profile as the red glazed garage door; the rolling mechanism does not receive separate balance rules.

## Portals and large gates

| Preview | Model / entity | EN name | FR name | Class | HP / segment | Glazed | Frame | Material(s) | MaterialType | DoorSound | BreakSound |
|---|---|---|---|---|---:|---|---|---|---|---|---|
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_FarmDoubleGate.png" width="120"> | `Base.FarmDoubleGate` | Farm Double Gate | Double portail de ferme | `metal` | 800 | no | none | M1=MetalPipe; M2=Wood | Metal_Light | MetalPoleGateDouble | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_WroughtIronDoubleGate.png" width="120"> | `Base.WroughtIronDoubleGate` | Wrought Iron Double Gate | Double portail en fer forgé | `metal` | 1200 | no | none | M1=MetalBars | Metal_Solid | MetalPoleGateDouble | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_WoodenFenceDoubleGate.png" width="120"> | `Base.WoodenFenceDoubleGate` | Wooden Fence Double Gate | Double portail de clôture en bois | `wood` | 600 | no | none | M1=Wood; M2=Nails | Wood_Solid | WoodDoor | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_DoubleWireGate.png" width="120"> | `Base.DoubleWireGate` | Double Wire Gate | Double portail grillagé | `metal` | 650 | no | none | M1=MetalPipe; M2=MetalWire | Metal_Light | MetalGate | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_DoubleFenceGate.png" width="120"> | `Base.DoubleFenceGate` | Double Fence Gate | Double portail de clôture | `unknown` | TBD | no | none | TBD | TBD | TBD | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_DoubleDoor.png" width="120"> | `Base.DoubleDoor` | Double Door | Double porte | `wood` | 600 | no | none | M1=Wood; M2=Door | Wood_Solid | WoodDoor | BreakDoor |

## Paired double doors

Left/right entities are listed together because they represent one visual door model for naming/material/balance purposes. Runtime placement/grouping may still require distinct entity handling.

| Preview | Model / entities | EN name | FR name | Class | HP / segment | Glazed | Frame | Material(s) | MaterialType | DoorSound | BreakSound |
|---|---|---|---|---|---:|---|---|---|---|---|---|
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_BlackGlassDoubleDoorLeft.png" width="70"><img src="Contents/mods/LMION_Build/42/media/textures/LMION_BlackGlassDoubleDoorRight.png" width="70"> | `Base.BlackGlassDoubleDoorLeft` / `Right` | Black Glass Double Door | Double porte vitrée noire | `glass` | 425 | yes | paired | TBD | Glass_Solid | TBD | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_GreyMetalDoubleDoorLeft.png" width="70"><img src="Contents/mods/LMION_Build/42/media/textures/LMION_GreyMetalDoubleDoorRight.png" width="70"> | `Base.GreyMetalDoubleDoorLeft` / `Right` | Grey Metal Double Door | Double porte métallique grise | `metal` | 800 | no | paired | M1=MetalPlates; M2=Door | Metal_Solid | MetalDoor | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_YellowMetalDoubleDoorLeft.png" width="70"><img src="Contents/mods/LMION_Build/42/media/textures/LMION_YellowMetalDoubleDoorRight.png" width="70"> | `Base.YellowMetalDoubleDoorLeft` / `Right` | Yellow Metal Double Door | Double porte métallique jaune | `metal` | 800 | no | paired | M1=MetalPlates; M2=Door | Metal_Solid | MetalDoor | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_BlueChurchDoubleDoorLeft.png" width="70"><img src="Contents/mods/LMION_Build/42/media/textures/LMION_BlueChurchDoubleDoorRight.png" width="70"> | `Base.BlueChurchDoubleDoorLeft` / `Right` | Blue Church Double Door | Double porte d'église bleue | `wood` | 600 | no | paired | M1=Wood; M2=Door | Wood_Solid | WoodDoor | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_BrownChurchDoubleDoorLeft.png" width="70"><img src="Contents/mods/LMION_Build/42/media/textures/LMION_BrownChurchDoubleDoorRight.png" width="70"> | `Base.BrownChurchDoubleDoorLeft` / `Right` | Brown Church Double Door | Double porte d'église brune | `wood` | 600 | no | paired | M1=Wood; M2=Door | Wood_Solid | WoodDoor | BreakDoor |

## Single gates, fence gates and wickets

These stay separate from normal 1x1 doors because their material, pickup, placement and later repair rules may need to differ even when the runtime object is still an `IsoDoor`.

| Preview | Entity | EN name | FR name | Class | HP | Frame | Material(s) | MaterialType | DoorSound | BreakSound |
|---|---|---|---|---|---:|---|---|---|---|---|
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_MetalWireFenceGate.png" width="96"> | `Base.MetalWireFenceGate` | Metal Wire Fence Gate | Portail de clôture grillagée | `metal` | 550 | none | M1=MetalPipe; M2=MetalWire | Metal_Light | MetalGate | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_MetalWireFenceGateSmall.png" width="96"> | `Base.MetalWireFenceGateSmall` | Small Metal Wire Fence Gate | Petit portail de clôture grillagée | `metal` | 475 | none | M1=MetalPipe; M2=MetalWire | Metal_Light | MetalGate | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_MetalPoleFenceGate.png" width="96"> | `Base.MetalPoleFenceGate` | Metal Pole Fence Gate | Portail de clôture métallique | `metal` | 650 | none | M1=MetalPipe | Metal_Light | MetalPoleGate | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_MetalPoleFenceGateSmall.png" width="96"> | `Base.MetalPoleFenceGateSmall` | Small Metal Pole Fence Gate | Petit portail de clôture métallique | `metal` | 550 | none | M1=MetalPipe | Metal_Light | MetalPoleGate | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_WoodFenceGate.png" width="96"> | `Base.WoodFenceGate` | Wood Fence Gate | Portail de clôture en bois | `wood` | 500 | none | M1=Wood; M2=Nails | Wood_Solid | WoodDoor | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_SmallMetalFenceGate.png" width="96"> | `Base.SmallMetalFenceGate` | Small Metal Fence Gate | Petit portail métallique | `metal` | 550 | none | M1=MetalBars | Metal_Light | MetalGate | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_TallWoodenFenceGate.png" width="96"> | `Base.TallWoodenFenceGate` | Tall Wooden Fence Gate | Grand portail de clôture en bois | `wood` | 600 | none | M1=Wood; M2=Nails | Wood_Solid | WoodDoor | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_TallWroughtIronGate.png" width="96"> | `Base.TallWroughtIronGate` | Tall Wrought Iron Gate | Grand portail en fer forgé | `metal` | 800 | none | M1=MetalBars | Metal_Solid | MetalPoleGate | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_SmallWhiteWoodenFenceGate.png" width="96"> | `Base.SmallWhiteWoodenFenceGate` | Small White Wooden Fence Gate | Petit portail de clôture en bois blanc | `wood` | 425 | none | M1=Wood; M2=Nails | Wood | WoodDoor | BreakDoor |

## Simple 1x1 doors

| Preview | Entity | EN name | FR name | Class | HP | Glazed | Frame | Material(s) | MaterialType | DoorSound | BreakSound |
|---|---|---|---|---|---:|---|---|---|---|---|---|
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_WoodenDoorLvl1.png" width="96"> | `Base.WoodenDoorLvl1` | Wooden Door Level 1 | Porte en bois niveau 1 | `wood` | 500 | no | standard | M1=Wood; M2=Door | Wood_Solid | WoodDoor | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_WoodenDoorLvl2.png" width="96"> | `Base.WoodenDoorLvl2` | Wooden Door Level 2 | Porte en bois niveau 2 | `wood` | 500 | no | standard | M1=Wood; M2=Door | Wood_Solid | WoodDoor | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_WoodenDoorLvl3.png" width="96"> | `Base.WoodenDoorLvl3` | Wooden Door Level 3 | Porte en bois niveau 3 | `wood` | 500 | no | standard | M1=Wood; M2=Door | Wood_Solid | WoodDoor | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_WhiteWoodenDoor.png" width="96"> | `Base.WhiteWoodenDoor` | White Wooden Door | Porte en bois blanche | `wood` | 500 | no | standard | M1=Wood; M2=Door | Wood_Solid | WoodDoor | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_MetalDoorLvl2.png" width="96"> | `Base.MetalDoorLvl2` | Metal Door Level 2 | Porte métallique niveau 2 | `metal` | 650 | no | standard | M1=MetalPlates; M2=Door | Metal_Solid | MetalDoor | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_MetalDoorLvl1.png" width="96"> | `Base.MetalDoorLvl1` | Metal Door Level 1 | Porte métallique niveau 1 | `metal` | 650 | no | standard | M1=MetalPlates; M2=Door | Metal_Solid | MetalDoor | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_SmallBlueDoor.png" width="96"> | `Base.SmallBlueDoor` | Small Blue Door | Petite porte bleue | `unknown` | TBD | no | standard | TBD | TBD | TBD | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_SmallPinkDoor.png" width="96"> | `Base.SmallPinkDoor` | Small Pink Door | Petite porte rose | `unknown` | TBD | no | standard | TBD | TBD | TBD | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_BlueRestroomDoor.png" width="96"> | `Base.BlueRestroomDoor` | Blue Restroom Door | Porte de sanitaires bleue | `unknown` | TBD | no | standard | TBD | TBD | TBD | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_OuthouseDoor.png" width="96"> | `Base.OuthouseDoor` | Outhouse Door | Porte de latrines | `wood` | 425 | no | standard | M1=Wood; M2=Door | Wood | WoodDoor | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_BrownSlidingGlassDoor.png" width="96"> | `Base.BrownSlidingGlassDoor` | Brown Sliding Glass Door | Porte coulissante vitrée brune | `glass` | 350 | yes | none | TBD | Glass_Solid | SlidingGlassDoor | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_WhiteSlidingGlassDoor.png" width="96"> | `Base.WhiteSlidingGlassDoor` | White Sliding Glass Door | Porte coulissante vitrée blanche | `glass` | 350 | yes | none | TBD | Glass_Solid | SlidingGlassDoor | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_CherryDoor.png" width="96"> | `Base.CherryDoor` | Cherry Door | Porte en cerisier | `wood` | 500 | no | standard | M1=Wood; M2=Door | Wood_Solid | WoodDoor | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_TanDoorWithWindow.png" width="96"> | `Base.TanDoorWithWindow` | Tan Door with Window | Porte beige avec fenêtre | `wood_glazed?` | 425 | yes | standard | TBD | TBD | TBD | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_BlackDoorWithWindow.png" width="96"> | `Base.BlackDoorWithWindow` | Black Door with Window | Porte noire avec fenêtre | `wood_glazed?` | 425 | yes | standard | TBD | TBD | TBD | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_BlueMetalDoor.png" width="96"> | `Base.BlueMetalDoor` | Blue Metal Door | Porte métallique bleue | `metal` | 650 | no | standard | M1=MetalPlates; M2=Door | Metal_Solid | MetalDoor | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_RoughWoodenDoor.png" width="96"> | `Base.RoughWoodenDoor` | Rough Wooden Door | Porte en bois brut | `wood` | 500 | no | standard | M1=Wood; M2=Door | Wood_Solid | WoodDoor | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_SecurityDoor.png" width="96"> | `Base.SecurityDoor` | Security Door | Porte sécurisée | `security` | 3000 | no | standard | M1=MetalBars; M2=MetalPlates | Metal_Solid | MetalDoor | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_ChestnutGlassDoor.png" width="96"> | `Base.ChestnutGlassDoor` | Chestnut Glass Door | Porte vitrée châtaigne | `glass` | 350 | yes | standard | TBD | Glass_Solid | TBD | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_BlackGlassDoor.png" width="96"> | `Base.BlackGlassDoor` | Black Glass Door | Porte vitrée noire | `glass` | 350 | yes | standard | TBD | Glass_Solid | TBD | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_WhiteDoorWithWindows.png" width="96"> | `Base.WhiteDoorWithWindows` | White Door with Windows | Porte blanche avec fenêtres | `wood_glazed?` | 425 | yes | standard | TBD | TBD | TBD | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_BlackTwoPaneDoor.png" width="96"> | `Base.BlackTwoPaneDoor` | Black Two-Pane Door | Porte noire à deux vitres | `wood_glazed?` | 425 | yes | standard | TBD | TBD | TBD | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_BrownDoor.png" width="96"> | `Base.BrownDoor` | Brown Door | Porte brune | `unknown` | TBD | no | standard | TBD | TBD | TBD | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_WhiteMetalDoor.png" width="96"> | `Base.WhiteMetalDoor` | White Metal Door | Porte métallique blanche | `metal` | 650 | no | standard | M1=MetalPlates; M2=Door | Metal_Solid | MetalDoor | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_WhiteMetalDoorWithWindow.png" width="96"> | `Base.WhiteMetalDoorWithWindow` | White Metal Door with Window | Porte métallique blanche vitrée | `metal_glazed` | 550 | yes | standard | M1=MetalPlates; M2=Door | Metal_Solid | MetalDoor | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_TanMetalDoor.png" width="96"> | `Base.TanMetalDoor` | Tan Metal Door | Porte métallique beige | `metal` | 650 | no | standard | M1=MetalPlates; M2=Door | Metal_Solid | MetalDoor | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_WoodenDoor.png" width="96"> | `Base.WoodenDoor` | Wooden Door | Porte en bois | `wood` | 500 | no | standard | M1=Wood; M2=Door | Wood_Solid | WoodDoor | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_BlueDoor.png" width="96"> | `Base.BlueDoor` | Blue Door | Porte bleue | `unknown` | TBD | no | standard | TBD | TBD | TBD | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_BlackMetalDoor.png" width="96"> | `Base.BlackMetalDoor` | Black Metal Door | Porte métallique noire | `metal` | 650 | no | standard | M1=MetalPlates; M2=Door | Metal_Solid | MetalDoor | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_SmallBrownPanelDoor.png" width="96"> | `Base.SmallBrownPanelDoor` | Small Brown Panel Door | Petite porte à panneau brune | `wood` | 425 | no | standard | M1=Wood; M2=Door | Wood | WoodDoor | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_SmallWhitePanelDoor.png" width="96"> | `Base.SmallWhitePanelDoor` | Small White Panel Door | Petite porte à panneau blanche | `wood` | 425 | no | standard | M1=Wood; M2=Door | Wood | WoodDoor | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_SmallBlackPanelDoor.png" width="96"> | `Base.SmallBlackPanelDoor` | Small Black Panel Door | Petite porte à panneau noire | `wood` | 425 | no | standard | M1=Wood; M2=Door | Wood | WoodDoor | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_BrownDoorWithWindows.png" width="96"> | `Base.BrownDoorWithWindows` | Brown Door with Windows | Porte brune avec fenêtres | `wood_glazed?` | 425 | yes | standard | TBD | TBD | TBD | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_RedMetalDoor.png" width="96"> | `Base.RedMetalDoor` | Red Metal Door | Porte métallique rouge | `metal` | 650 | no | standard | M1=MetalPlates; M2=Door | Metal_Solid | MetalDoor | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_JailDoor.png" width="96"> | `Base.JailDoor` | Jail Door | Porte de prison | `jail` | 2000 | no | standard | M1=MetalBars | Metal_Solid | PrisonMetalDoor | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_PileOCrepeBlueDoorWithWindow.png" width="96"> | `Base.PileOCrepeBlueDoorWithWindow` | Pile O' Crepe Blue Door with Window | Porte bleue vitrée Pile O' Crepe | `wood_glazed?` | 425 | yes | standard | TBD | TBD | TBD | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_PileOCrepeOrangeDoor.png" width="96"> | `Base.PileOCrepeOrangeDoor` | Pile O' Crepe Orange Door | Porte orange Pile O' Crepe | `unknown` | TBD | no | standard | TBD | TBD | TBD | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_PizzaWhirledBrownGlassDoor.png" width="96"> | `Base.PizzaWhirledBrownGlassDoor` | Pizza Whirled Brown Glass Door | Porte vitrée brune Pizza Whirled | `glass` | 350 | yes | standard | TBD | Glass_Solid | TBD | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_PizzaWhirledGreenMetalDoor.png" width="96"> | `Base.PizzaWhirledGreenMetalDoor` | Pizza Whirled Green Metal Door | Porte métallique verte Pizza Whirled | `metal` | 650 | no | standard | M1=MetalPlates; M2=Door | Metal_Solid | MetalDoor | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_SeaHorseGlassDoor.png" width="96"> | `Base.SeaHorseGlassDoor` | Sea Horse Glass Door | Porte vitrée Sea Horse | `glass` | 350 | yes | standard | TBD | Glass_Solid | TBD | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_SpiffosGlassDoor.png" width="96"> | `Base.SpiffosGlassDoor` | Spiffo's Glass Door | Porte vitrée Spiffo's | `glass` | 350 | yes | standard | TBD | Glass_Solid | TBD | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_SpiffosRedMetalDoor.png" width="96"> | `Base.SpiffosRedMetalDoor` | Spiffo's Red Metal Door | Porte métallique rouge Spiffo's | `metal` | 650 | no | standard | M1=MetalPlates; M2=Door | Metal_Solid | MetalDoor | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_FossoilDoor.png" width="96"> | `Base.FossoilDoor` | Fossoil Door | Porte Fossoil | `unknown` | TBD | no | standard | TBD | TBD | TBD | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_Gas2GoDoor.png" width="96"> | `Base.Gas2GoDoor` | Gas2Go Door | Porte Gas2Go | `unknown` | TBD | no | standard | TBD | TBD | TBD | BreakDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_LogDoor.png" width="96"> | `Base.LogDoor` | Log Door | Porte en rondins | `heavy_wood` | 600 | no | standard | M1=Log | Wood_Solid | WoodDoor | BreakDoor |

## Current known exceptions and validated facts

- `CherryDoor` localized names are already runtime-validated: `Cherry Door` / `Porte en cerisier`.
- Cherry's current runtime `MetalPlates` secondary material is a diagnostic canary and must be replaced by the catalog's intended wood setup when the bulk profiles are applied.
- `BlueMetalDoor` was runtime-observed with `Material = MetalPlates`, `Material2 = Door`, `MaterialType = Plastic`; the catalog intentionally proposes `Metal_Solid` as the LMION physical classification instead of inheriting that vanilla value blindly.
- `BlueMetalDoor` currently uses `worldMaxHealth = 600` only as a runtime durability canary. The catalog target is 650.
- `LogDoor` keeps `M1=Log` for semantic fidelity. Vanilla's generic salvage path does not recognize `Log` as a wood salvage tag, and `IsoDoor.destroy()` would still add knob/hinge hardware. LMION should therefore give LogDoor custom destruction loot: `1 x Base.Log`, no doorknob, no hinges, and no additional vanilla door loot.
- Jail and Security doors deliberately override normal material-class durability at 2000 and 3000 HP.
- Single fence gates/wickets are kept separate from normal 1x1 doors even if they share `IsoDoor`, so their gameplay profile can diverge later without reclassifying the catalog.
- `BreakDoor` is provisional across the catalog. It should not be treated as proof that every construction path has the ideal material-specific destruction sound.

## Remaining ambiguous cases

The bulk pass intentionally leaves these rows partially unresolved because their visible construction/material cannot be determined safely from the entity name alone:

```text
DoubleFenceGate
BlackGlassDoubleDoor
SmallBlueDoor
SmallPinkDoor
BlueRestroomDoor
TanDoorWithWindow
BlackDoorWithWindow
ChestnutGlassDoor
BlackGlassDoor
WhiteDoorWithWindows
BlackTwoPaneDoor
BrownDoor
BlueDoor
BrownDoorWithWindows
PileOCrepeBlueDoorWithWindow
PileOCrepeOrangeDoor
PizzaWhirledBrownGlassDoor
SeaHorseGlassDoor
SpiffosGlassDoor
FossoilDoor
Gas2GoDoor
```

For these, the next useful step is visual/runtime review rather than guessing. Everything else in this document is now a concrete provisional profile proposal ready for review before code generation.