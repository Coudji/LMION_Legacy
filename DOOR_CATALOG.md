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

The catalog only uses engine property values from the safe reference in `DOOR_CATALOG_VALUES.md`.

`Material`, `Material2` and `Material3` describe the object's material composition and may affect vanilla generic salvage. `MaterialType` is tracked separately and is chosen for the appropriate impact sound/physical response. `DoorSound` defines the door-family open/close/break sound prefix. `ThumpSound` is recorded when LMION deliberately wants a specific zombie-impact family instead of the engine fallback.

The catalog does **not** track or choose construction `BuildBreakSound` / SpriteConfig `BreakSound`. It is not a gameplay/design parameter LMION intends to tune in this pass.

## Garage doors

Status: **validated family specification**. All garage-door models use the same gameplay rules; rolling, sectional and industrial-looking variants are not balanced separately. The only split is solid metal versus glazed metal. The internal visual notes exist only to identify the models and justify that split.

### Profiles and construction

| Variant | Class | World HP / segment | `health` | `skillBaseHealth` | Build skill | HP at required level | HP at lvl 10 | Time | XP | Craft |
|---|---|---:|---:|---:|---|---:|---:|---:|---:|---|
| Solid metal | `metal` | 1200 | 600 | 400 | MetalWelding 6 | 3000 | 4600 | 200 | 50 | Welding Mask x1 kept; Blow Torch 6 uses; Small Sheet Metal x9; Metal Bar x3; Door Hinge x6; Welding Rods 3 uses; no Screwdriver; no Screws |
| Glazed metal | `metal_glazed` | 1000 | 500 | 350 | MetalWelding 6 | 2600 | 4000 | 200 | 50 | Welding Mask x1 kept; Blow Torch 6 uses; Small Sheet Metal x6; Glass Panel (`Base.GlassPanel`) x3; Metal Bar x3; Door Hinge x6; Welding Rods 3 uses; no Screwdriver; no Screws |

### Physical properties and handling

| Property | Garage family value |
|---|---|
| `Material` | `MetalPlates` |
| `Material2` | `MetalBars` |
| `MaterialType` | `Metal_Light` — chosen for the lighter sheet-metal impact response |
| `DoorSound` | `GarageDoor` |
| Frame | none |
| Pickup skill | MetalWelding 3 (`floor(build level / 2)`) |
| Pickup tools | Blow Torch + Welding Mask |
| Pickup break chance | none |
| Pickup output | 3 packages x 20 kg = 60 kg total |
| Replacement | all 3 packages; Blow Torch + Welding Mask |
| Replacement consumable | Welding Rods if placement can support consumption cleanly; exact quantity TBD during implementation |
| Dismantling tools | Blow Torch + Welding Mask |
| Dismantling returns | delegated to implementation from the construction/material profile |
| Repair / destruction behavior | out of scope for this catalog pass |

The pickup skill must be tied to the construction skill, not inferred from the vanilla Moveables perk associated with a particular tool.

### Models

| Preview | Entity | EN name | FR name | Variant | Visual note |
|---|---|---|---|---|---|
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_IndustrialGarageDoor.png" width="120"> | `Base.IndustrialGarageDoor` | Industrial Garage Door | Porte de garage industrielle | solid | large solid industrial-style metal door; no glazing |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_GreenGarageDoor.png" width="120"> | `Base.GreenGarageDoor` | Green Garage Door | Porte de garage verte | solid | large solid green metal door |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_WhiteGarageDoor.png" width="120"> | `Base.WhiteGarageDoor` | White Garage Door | Porte de garage blanche | solid | white sectional/paneled metal door; residential/light-workshop look |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_GreyGarageDoor.png" width="120"> | `Base.GreyGarageDoor` | Grey Garage Door | Porte de garage grise | solid | large solid grey metal door |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_RollingGarageDoor.png" width="120"> | `Base.RollingGarageDoor` | Rolling Garage Door | Porte de garage à enroulement | solid | rolling/shutter appearance does not change balance |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_RedWindowGarageDoor.png" width="120"> | `Base.RedWindowGarageDoor` | Red Window Garage Door | Porte de garage rouge vitrée | glazed | sectional metal door with substantial glazed upper sections |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_RollingWindowGarageDoor.png" width="120"> | `Base.RollingWindowGarageDoor` | Rolling Window Garage Door | Porte de garage à enroulement vitrée | glazed | rolling/shutter model with glazing; same glazed profile |

## Portals and large gates

### Large wooden gates

Status: **validated design specification**. The vanilla model is the normal large wooden gate; the LMION model is deliberately a higher-level hardened version with extra timber, nails and screw fasteners. Display names may override vanilla localization without changing technical entity IDs.

#### Profiles

| Preview | Entity | EN name | FR name | World HP / segment | Build skill | `health` | `skillBaseHealth` | HP at required level | HP lvl 10 | Class | Glazed | Frame | Materials | MaterialType | DoorSound | ThumpSound |
|---|---|---|---|---:|---|---:|---:|---:|---:|---|---|---|---|---|---|---|
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_DoubleDoor.png" width="120"> | `Base.DoubleDoor` | Large Wooden Gate | Grand portail en bois | 650 | Woodwork 4 | 400 | 300 | 1600 | 3400 | `wood` | no | none | M1=Wood; M2=Nails | Wood_Solid | WoodGate | ZombieThumpWood |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_WoodenFenceDoubleGate.png" width="120"> | `Base.WoodenFenceDoubleGate` | Large Hardened Wooden Gate | Grand portail en bois durci | 750 | Woodwork 7 | 500 | 350 | 2950 | 4000 | `wood` | no | none | M1=Wood; M2=Nails; M3=Screws | Wood_Solid | WoodGate | ZombieThumpWood |

#### Craft

| Entity | Source | Time | Tools | Inputs | Design note |
|---|---|---|---|---|---|
| `Base.DoubleDoor` | vanilla | unchanged | Hammer | Plank x8; Nails x8; Door Hinge x4; Doorknob x2 | standard large wooden gate |
| `Base.WoodenFenceDoubleGate` | LMION | 200 | Hammer + Screwdriver, kept | Plank x10; Nails x10; Screws x8; Door Hinge x4; Doorknob x2 | hardened tier; +2 Planks and +2 Nails versus vanilla while intentionally keeping screws |

#### Pickup and replacement

| Entity | Pickup skill | Pickup tools | Break chance | Pickup output | Total weight | Replacement |
|---|---|---|---|---|---:|---|
| `Base.DoubleDoor` | Woodwork 2 | Hammer | none | 2 packages x 18 kg | 36 kg | both packages + Hammer |
| `Base.WoodenFenceDoubleGate` | Woodwork 3 | Hammer + Screwdriver | none | 2 packages x 22 kg | 44 kg | both packages + Hammer + Screwdriver |

### Large metal gates

Status: **validated three-tier design specification**. The farm gate is intentionally weak because it is a low livestock barrier made from light tubing and can be vaulted. `DoubleWireGate` and `DoubleFenceGate` share the same middle tier: the first is light but regular, while the second contains more metal but is visibly an improvised bric-a-brac assembly. The wrought-iron gate is the clear heavy-duty tier. Display names are player-facing only; technical vanilla IDs remain unchanged.

#### Profiles

| Preview | Entity | EN name | FR name | Tier | World HP / segment | Build skill | `health` | `skillBaseHealth` | HP at required level | HP lvl 10 | Materials | MaterialType | DoorSound | ThumpSound / effective family |
|---|---|---|---|---|---:|---|---:|---:|---:|---:|---|---|---|---|
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_FarmDoubleGate.png" width="120"> | `Base.FarmDoubleGate` | Large Farm Gate | Grand portail de ferme | 1 — light farm | 500 | MetalWelding 4 | 300 | 200 | 1100 | 2300 | M1=MetalPipe; M2=MetalBars | Metal_Light | FarmGate | ZombieThumpMetalPoleGate |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_DoubleWireGate.png" width="120"> | `Base.DoubleWireGate` | Large Chain-Link Gate | Grand portail grillagé | 2 — cheap metal | 850 | MetalWelding 5 | 400 | 275 | 1775 | 3150 | M1=MetalPipe; M2=MetalWire | Metal_Light | MetalGate | MetalGate default → ZombieThumpChainlinkFence |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_DoubleFenceGate.png" width="120"> | `Base.DoubleFenceGate` | Large Scrap Metal Gate | Grand portail en ferraille | 2 — cheap metal | 850 | MetalWelding 5 | 400 | 275 | 1775 | 3150 | M1=MetalPipe; M2=MetalScrap | Metal_Light | MetalGate | MetalGate default → ZombieThumpChainlinkFence |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_WroughtIronDoubleGate.png" width="120"> | `Base.WroughtIronDoubleGate` | Large Wrought Iron Gate | Grand portail en fer forgé | 3 — wrought iron | 1200 | MetalWelding 6 | 500 | 375 | 2750 | 4250 | M1=MetalBars; M2=MetalPipe | Metal_Solid | MetalPoleGateDouble | ZombieThumpMetalPoleGate |

#### Craft

| Entity | Source | Time | Tools | Inputs | Notes |
|---|---|---|---|---|---|
| `Base.FarmDoubleGate` | LMION | 200 | Welding Mask kept | Blow Torch 8 uses; Metal Bar x8; Metal Pipe x4; Door Hinge x4; Welding Rods 6 uses | no Screwdriver; no Screws; low/vaultable livestock barrier |
| `Base.DoubleWireGate` | vanilla | unchanged | vanilla | Blow Torch 10 uses; Metal Pipe x8; Wire 4 uses; Door Hinge x4; Scrap Metal x2; Welding Rods 10 uses | vanilla craft otherwise unchanged |
| `Base.DoubleFenceGate` | vanilla | unchanged | vanilla | Blow Torch 10 uses; Metal Pipe x10; Door Hinge x4; Scrap Metal x4; Welding Rods 10 uses | vanilla craft otherwise unchanged |
| `Base.WroughtIronDoubleGate` | LMION | 200 | Welding Mask kept | Blow Torch 8 uses; Metal Bar x8; Metal Pipe x4; Door Hinge x4; Welding Rods 6 uses | no Screwdriver; no Screws; strongest gate of this family |

#### Pickup and replacement

| Entity | Pickup skill | Pickup tools | Break chance | Pickup output | Total weight | Replacement |
|---|---|---|---|---|---:|---|
| `Base.FarmDoubleGate` | MetalWelding 2 | Blow Torch + Welding Mask | none | 2 packages x 12 kg | 24 kg | both packages + Blow Torch + Welding Mask |
| `Base.DoubleWireGate` | MetalWelding 2 | Blow Torch + Welding Mask | none | 2 packages x 15 kg | 30 kg | both packages + Blow Torch + Welding Mask |
| `Base.DoubleFenceGate` | MetalWelding 2 | Blow Torch + Welding Mask | none | 2 packages x 20 kg | 40 kg | both packages + Blow Torch + Welding Mask |
| `Base.WroughtIronDoubleGate` | MetalWelding 3 | Blow Torch + Welding Mask | none | 2 packages x 30 kg | 60 kg | both packages + Blow Torch + Welding Mask |

Dismantling rules for large metal gates have not yet been reviewed.

## Paired double doors

Left/right entities are listed together because they represent one visual door model for naming/material/balance purposes. Runtime placement/grouping may still require distinct entity handling.

| Preview | Model / entities | EN name | FR name | Class | HP / segment | Glazed | Frame | Material(s) | MaterialType | DoorSound |
|---|---|---|---|---|---:|---|---|---|---|---|
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_BlackGlassDoubleDoorLeft.png" width="70"><img src="Contents/mods/LMION_Build/42/media/textures/LMION_BlackGlassDoubleDoorRight.png" width="70"> | `Base.BlackGlassDoubleDoorLeft` / `Right` | Black Glass Double Door | Double porte vitrée noire | `glass` | 425 | yes | paired | TBD | Glass_Solid | TBD |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_GreyMetalDoubleDoorLeft.png" width="70"><img src="Contents/mods/LMION_Build/42/media/textures/LMION_GreyMetalDoubleDoorRight.png" width="70"> | `Base.GreyMetalDoubleDoorLeft` / `Right` | Grey Metal Double Door | Double porte métallique grise | `metal` | 800 | no | paired | M1=MetalPlates; M2=Door | Metal_Solid | MetalDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_YellowMetalDoubleDoorLeft.png" width="70"><img src="Contents/mods/LMION_Build/42/media/textures/LMION_YellowMetalDoubleDoorRight.png" width="70"> | `Base.YellowMetalDoubleDoorLeft` / `Right` | Yellow Metal Double Door | Double porte métallique jaune | `metal` | 800 | no | paired | M1=MetalPlates; M2=Door | Metal_Solid | MetalDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_BlueChurchDoubleDoorLeft.png" width="70"><img src="Contents/mods/LMION_Build/42/media/textures/LMION_BlueChurchDoubleDoorRight.png" width="70"> | `Base.BlueChurchDoubleDoorLeft` / `Right` | Blue Church Double Door | Double porte d'église bleue | `wood` | 600 | no | paired | M1=Wood; M2=Door | Wood_Solid | WoodDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_BrownChurchDoubleDoorLeft.png" width="70"><img src="Contents/mods/LMION_Build/42/media/textures/LMION_BrownChurchDoubleDoorRight.png" width="70"> | `Base.BrownChurchDoubleDoorLeft` / `Right` | Brown Church Double Door | Double porte d'église brune | `wood` | 600 | no | paired | M1=Wood; M2=Door | Wood_Solid | WoodDoor |

## Fence gates and wickets

These are the door-like openings used in fences and barriers. LMION uses a three-size naming hierarchy where applicable: **Large … Gate / Grand portail …** for the double-width models above, **… Gate / Portail …** for normal single-leaf models, and **Small … Gate / Portillon …** for the smallest variants. `Wicket` is avoided in player-facing English because `Small … Gate` is clearer. Naming may later be harmonized with non-door buildables when that wider construction pass happens.

### Wooden fence gates

The wooden family follows the same standard-versus-hardened logic as the large wooden gates. The tall brown model is treated as the single-leaf hardened counterpart; the small white model is deliberately lighter and simpler.

#### Profiles

| Preview | Entity | EN name | FR name | World HP | Build skill | `health` | `skillBaseHealth` | HP at required level | HP lvl 10 | Class | Frame | Materials | MaterialType | DoorSound | ThumpSound |
|---|---|---|---|---:|---|---:|---:|---:|---:|---|---|---|---|---|---|
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_SmallWhiteWoodenFenceGate.png" width="96"> | `Base.SmallWhiteWoodenFenceGate` | Small White Wooden Gate | Portillon en bois blanc | 425 | Woodwork 2 | 225 | 175 | 575 | 1975 | `wood` | none | M1=Wood; M2=Nails | Wood | WoodGateSmall | ZombieThumpWood |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_WoodFenceGate.png" width="96"> | `Base.WoodFenceGate` | Wooden Gate | Portail en bois | 500 | Woodwork 3 | 300 | 225 | 975 | 2550 | `wood` | none | M1=Wood; M2=Nails | Wood_Solid | WoodGate | ZombieThumpWood |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_TallWoodenFenceGate.png" width="96"> | `Base.TallWoodenFenceGate` | Hardened Wooden Gate | Portail en bois durci | 600 | Woodwork 5 | 400 | 275 | 1775 | 3150 | `wood` | none | M1=Wood; M2=Nails; M3=Screws | Wood_Solid | WoodGate | ZombieThumpWood |

#### Craft

| Entity | Tools | Inputs | Notes |
|---|---|---|---|
| `Base.SmallWhiteWoodenFenceGate` | Hammer kept | Plank x2; Nails x2; Door Hinge x2 | no Screwdriver; no Screws; light/simple tier |
| `Base.WoodFenceGate` | Hammer kept | Plank x4; Nails x4; Door Hinge x2; Doorknob x1 | standard wooden gate |
| `Base.TallWoodenFenceGate` | Hammer + Screwdriver kept | Plank x5; Nails x5; Screws x4; Door Hinge x2; Doorknob x1 | hardened tier; screw reinforcement intentionally retained |

#### Pickup and replacement

| Entity | Pickup skill | Pickup tools | Break chance | Pickup output / weight | Replacement |
|---|---|---|---|---|---|
| `Base.SmallWhiteWoodenFenceGate` | Woodwork 1 | Hammer | none | 1 package — 7 kg | package + Hammer |
| `Base.WoodFenceGate` | Woodwork 1 | Hammer | none | 1 package — 14 kg | package + Hammer |
| `Base.TallWoodenFenceGate` | Woodwork 2 | Hammer + Screwdriver | none | 1 package — 18 kg | package + Hammer + Screwdriver |

### Metal fence gates

Chain-link and scrap-metal models use the same durability tier at a given size, mirroring the large-gate logic. Chain-link is light but regular; the pole/scrap models use more metal but are visibly rougher assemblies. Wrought iron remains the strongest family at every size. All metal constructions are treated as welded structures, so Screwdriver and Screws are removed where present. Welding Mask is required consistently.

#### Profiles

| Preview | Entity | EN name | FR name | Family / size | World HP | Build skill | `health` | `skillBaseHealth` | HP at required level | HP lvl 10 | Materials | MaterialType | DoorSound | ThumpSound |
|---|---|---|---|---|---:|---|---:|---:|---:|---:|---|---|---|---|
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_MetalWireFenceGateSmall.png" width="96"> | `Base.MetalWireFenceGateSmall` | Small Chain-Link Gate | Portillon grillagé | chain-link / small | 450 | MetalWelding 2 | 250 | 175 | 600 | 2000 | M1=MetalPipe; M2=MetalWire | Metal_Light | MetalGate | ZombieThumpChainlinkFence |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_MetalWireFenceGate.png" width="96"> | `Base.MetalWireFenceGate` | Chain-Link Gate | Portail grillagé | chain-link / normal | 600 | MetalWelding 3 | 300 | 225 | 975 | 2550 | M1=MetalPipe; M2=MetalWire | Metal_Light | MetalGate | ZombieThumpChainlinkFence |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_MetalPoleFenceGateSmall.png" width="96"> | `Base.MetalPoleFenceGateSmall` | Small Scrap Metal Gate | Portillon en ferraille | scrap / small | 450 | MetalWelding 2 | 250 | 175 | 600 | 2000 | M1=MetalPipe; M2=MetalScrap | Metal_Light | MetalPoleGateSmall | ZombieThumpMetalPoleGate |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_MetalPoleFenceGate.png" width="96"> | `Base.MetalPoleFenceGate` | Scrap Metal Gate | Portail en ferraille | scrap / normal | 600 | MetalWelding 3 | 300 | 225 | 975 | 2550 | M1=MetalPipe; M2=MetalScrap | Metal_Light | MetalPoleGate | ZombieThumpMetalPoleGate |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_SmallMetalFenceGate.png" width="96"> | `Base.SmallMetalFenceGate` | Small Wrought Iron Gate | Portillon en fer forgé | wrought iron / small | 650 | MetalWelding 3 | 325 | 250 | 1075 | 2825 | M1=MetalBars; M2=MetalPipe | Metal_Solid | MetalPoleGateSmall | ZombieThumpMetalPoleGate |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_TallWroughtIronGate.png" width="96"> | `Base.TallWroughtIronGate` | Wrought Iron Gate | Portail en fer forgé | wrought iron / normal | 850 | MetalWelding 4 | 400 | 300 | 1600 | 3400 | M1=MetalBars; M2=MetalPipe | Metal_Solid | MetalPoleGate | ZombieThumpMetalPoleGate |

#### Craft

| Entity | Tools | Inputs | Notes |
|---|---|---|---|
| `Base.MetalWireFenceGateSmall` | Welding Mask kept | Blow Torch 2 uses; Metal Pipe x2; Wire 1 use; Door Hinge x2; Scrap Metal x1; Welding Rods 2 uses | small chain-link tier |
| `Base.MetalWireFenceGate` | Welding Mask kept | Blow Torch 4 uses; Metal Pipe x4; Wire 2 uses; Door Hinge x2; Scrap Metal x1; Welding Rods 4 uses | normal chain-link tier |
| `Base.MetalPoleFenceGateSmall` | Welding Mask kept | Blow Torch 3 uses; Metal Pipe x3; Door Hinge x2; Scrap Metal x1; Welding Rods 3 uses | small scrap tier |
| `Base.MetalPoleFenceGate` | Welding Mask kept | Blow Torch 5 uses; Metal Pipe x5; Door Hinge x2; Scrap Metal x2; Welding Rods 5 uses | normal scrap tier |
| `Base.SmallMetalFenceGate` | Welding Mask kept | Blow Torch 3 uses; Metal Bar x2; Metal Pipe x1; Door Hinge x2; Welding Rods 2 uses | no Screwdriver; no Screws; no Small Sheet Metal |
| `Base.TallWroughtIronGate` | Welding Mask kept | Blow Torch 5 uses; Metal Bar x4; Metal Pipe x2; Door Hinge x2; Welding Rods 4 uses | no Screwdriver; no Screws; no Small Sheet Metal |

#### Pickup and replacement

| Entity | Pickup skill | Pickup tools | Break chance | Pickup output / weight | Replacement |
|---|---|---|---|---|---|
| `Base.MetalWireFenceGateSmall` | MetalWelding 1 | Blow Torch + Welding Mask | none | 1 package — 6 kg | package + Blow Torch + Welding Mask |
| `Base.MetalWireFenceGate` | MetalWelding 1 | Blow Torch + Welding Mask | none | 1 package — 12 kg | package + Blow Torch + Welding Mask |
| `Base.MetalPoleFenceGateSmall` | MetalWelding 1 | Blow Torch + Welding Mask | none | 1 package — 8 kg | package + Blow Torch + Welding Mask |
| `Base.MetalPoleFenceGate` | MetalWelding 1 | Blow Torch + Welding Mask | none | 1 package — 16 kg | package + Blow Torch + Welding Mask |
| `Base.SmallMetalFenceGate` | MetalWelding 1 | Blow Torch + Welding Mask | none | 1 package — 12 kg | package + Blow Torch + Welding Mask |
| `Base.TallWroughtIronGate` | MetalWelding 2 | Blow Torch + Welding Mask | none | 1 package — 25 kg | package + Blow Torch + Welding Mask |

## Restroom stall doors

Status: **validated shared family specification**. These five models are lightweight North-American public-restroom stall doors differentiated only by color/finish. They deliberately remain fragile regardless of carpenter skill: both world and player-built durability are fixed at **150 HP**, with `skillBaseHealth = 0` so higher Woodwork never turns them into defensive doors. Their screw-based recipe also provides an early-game alternative that does not require a Hammer.

### Shared profile, craft and handling

| Class | World HP | Build skill | `health` | `skillBaseHealth` | Built HP all levels | XP | Time | Tools | Inputs | Materials | MaterialType | DoorSound | ThumpSound | Frame | Pickup | Replacement |
|---|---:|---|---:|---:|---:|---:|---:|---|---|---|---|---|---|---|---|---|
| `wood` | **150** | Woodwork 1 | **150** | **0** | **150** | 5 | 50 | Screwdriver kept | Plank x2; Screws x4; Door Hinge x2; Doorknob x1; no Nails; no Hammer | M1=Wood; M2=Screws | Wood | WoodDoor | ZombieThumpWood | standard | Woodwork 0; Screwdriver; no break chance; 1 package — 8 kg | package + Screwdriver |

### Models

| Preview | Entity | EN name | FR name |
|---|---|---|---|
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_SmallBlackPanelDoor.png" width="96"> | `Base.SmallBlackPanelDoor` | Black Restroom Stall Door | Porte de cabine sanitaire noire |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_SmallBlueDoor.png" width="96"> | `Base.SmallBlueDoor` | Blue Restroom Stall Door | Porte de cabine sanitaire bleue |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_SmallBrownPanelDoor.png" width="96"> | `Base.SmallBrownPanelDoor` | Brown Restroom Stall Door | Porte de cabine sanitaire brune |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_SmallPinkDoor.png" width="96"> | `Base.SmallPinkDoor` | Pink Restroom Stall Door | Porte de cabine sanitaire rose |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_SmallWhitePanelDoor.png" width="96"> | `Base.SmallWhitePanelDoor` | White Restroom Stall Door | Porte de cabine sanitaire blanche |

## Simple 1x1 doors

| Preview | Entity | EN name | FR name | Class | HP | Glazed | Frame | Material(s) | MaterialType | DoorSound |
|---|---|---|---|---|---:|---|---|---|---|---|
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_WoodenDoorLvl1.png" width="96"> | `Base.WoodenDoorLvl1` | Wooden Door Level 1 | Porte en bois niveau 1 | `wood` | 500 | no | standard | M1=Wood; M2=Door | Wood_Solid | WoodDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_WoodenDoorLvl2.png" width="96"> | `Base.WoodenDoorLvl2` | Wooden Door Level 2 | Porte en bois niveau 2 | `wood` | 500 | no | standard | M1=Wood; M2=Door | Wood_Solid | WoodDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_WoodenDoorLvl3.png" width="96"> | `Base.WoodenDoorLvl3` | Wooden Door Level 3 | Porte en bois niveau 3 | `wood` | 500 | no | standard | M1=Wood; M2=Door | Wood_Solid | WoodDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_WhiteWoodenDoor.png" width="96"> | `Base.WhiteWoodenDoor` | White Wooden Door | Porte en bois blanche | `wood` | 500 | no | standard | M1=Wood; M2=Door | Wood_Solid | WoodDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_MetalDoorLvl2.png" width="96"> | `Base.MetalDoorLvl2` | Metal Door Level 2 | Porte métallique niveau 2 | `metal` | 650 | no | standard | M1=MetalPlates; M2=Door | Metal_Solid | MetalDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_MetalDoorLvl1.png" width="96"> | `Base.MetalDoorLvl1` | Metal Door Level 1 | Porte métallique niveau 1 | `metal` | 650 | no | standard | M1=MetalPlates; M2=Door | Metal_Solid | MetalDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_BlueRestroomDoor.png" width="96"> | `Base.BlueRestroomDoor` | Blue Restroom Door | Porte de sanitaires bleue | `unknown` | TBD | no | standard | TBD | TBD | TBD |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_OuthouseDoor.png" width="96"> | `Base.OuthouseDoor` | Outhouse Door | Porte de latrines | `wood` | 425 | no | standard | M1=Wood; M2=Door | Wood | WoodDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_BrownSlidingGlassDoor.png" width="96"> | `Base.BrownSlidingGlassDoor` | Brown Sliding Glass Door | Porte coulissante vitrée brune | `glass` | 350 | yes | none | TBD | Glass_Solid | SlidingGlassDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_WhiteSlidingGlassDoor.png" width="96"> | `Base.WhiteSlidingGlassDoor` | White Sliding Glass Door | Porte coulissante vitrée blanche | `glass` | 350 | yes | none | TBD | Glass_Solid | SlidingGlassDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_CherryDoor.png" width="96"> | `Base.CherryDoor` | Cherry Door | Porte en cerisier | `wood` | 500 | no | standard | M1=Wood; M2=Door | Wood_Solid | WoodDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_TanDoorWithWindow.png" width="96"> | `Base.TanDoorWithWindow` | Tan Door with Window | Porte beige avec fenêtre | `wood_glazed?` | 425 | yes | standard | TBD | TBD | TBD |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_BlackDoorWithWindow.png" width="96"> | `Base.BlackDoorWithWindow` | Black Door with Window | Porte noire avec fenêtre | `wood_glazed?` | 425 | yes | standard | TBD | TBD | TBD |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_BlueMetalDoor.png" width="96"> | `Base.BlueMetalDoor` | Blue Metal Door | Porte métallique bleue | `metal` | 650 | no | standard | M1=MetalPlates; M2=Door | Metal_Solid | MetalDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_RoughWoodenDoor.png" width="96"> | `Base.RoughWoodenDoor` | Rough Wooden Door | Porte en bois brut | `wood` | 500 | no | standard | M1=Wood; M2=Door | Wood_Solid | WoodDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_SecurityDoor.png" width="96"> | `Base.SecurityDoor` | Security Door | Porte sécurisée | `security` | 3000 | no | standard | M1=MetalBars; M2=MetalPlates | Metal_Solid | MetalDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_ChestnutGlassDoor.png" width="96"> | `Base.ChestnutGlassDoor` | Chestnut Glass Door | Porte vitrée châtaigne | `glass` | 350 | yes | standard | TBD | Glass_Solid | TBD |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_BlackGlassDoor.png" width="96"> | `Base.BlackGlassDoor` | Black Glass Door | Porte vitrée noire | `glass` | 350 | yes | standard | TBD | Glass_Solid | TBD |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_WhiteDoorWithWindows.png" width="96"> | `Base.WhiteDoorWithWindows` | White Door with Windows | Porte blanche avec fenêtres | `wood_glazed?` | 425 | yes | standard | TBD | TBD | TBD |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_BlackTwoPaneDoor.png" width="96"> | `Base.BlackTwoPaneDoor` | Black Two-Pane Door | Porte noire à deux vitres | `wood_glazed?` | 425 | yes | standard | TBD | TBD | TBD |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_BrownDoor.png" width="96"> | `Base.BrownDoor` | Brown Door | Porte brune | `unknown` | TBD | no | standard | TBD | TBD | TBD |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_WhiteMetalDoor.png" width="96"> | `Base.WhiteMetalDoor` | White Metal Door | Porte métallique blanche | `metal` | 650 | no | standard | M1=MetalPlates; M2=Door | Metal_Solid | MetalDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_WhiteMetalDoorWithWindow.png" width="96"> | `Base.WhiteMetalDoorWithWindow` | White Metal Door with Window | Porte métallique blanche vitrée | `metal_glazed` | 550 | yes | standard | M1=MetalPlates; M2=Door | Metal_Solid | MetalDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_TanMetalDoor.png" width="96"> | `Base.TanMetalDoor` | Tan Metal Door | Porte métallique beige | `metal` | 650 | no | standard | M1=MetalPlates; M2=Door | Metal_Solid | MetalDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_WoodenDoor.png" width="96"> | `Base.WoodenDoor` | Wooden Door | Porte en bois | `wood` | 500 | no | standard | M1=Wood; M2=Door | Wood_Solid | WoodDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_BlueDoor.png" width="96"> | `Base.BlueDoor` | Blue Door | Porte bleue | `unknown` | TBD | no | standard | TBD | TBD | TBD |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_BlackMetalDoor.png" width="96"> | `Base.BlackMetalDoor` | Black Metal Door | Porte métallique noire | `metal` | 650 | no | standard | M1=MetalPlates; M2=Door | Metal_Solid | MetalDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_BrownDoorWithWindows.png" width="96"> | `Base.BrownDoorWithWindows` | Brown Door with Windows | Porte brune avec fenêtres | `wood_glazed?` | 425 | yes | standard | TBD | TBD | TBD |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_RedMetalDoor.png" width="96"> | `Base.RedMetalDoor` | Red Metal Door | Porte métallique rouge | `metal` | 650 | no | standard | M1=MetalPlates; M2=Door | Metal_Solid | MetalDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_JailDoor.png" width="96"> | `Base.JailDoor` | Jail Door | Porte de prison | `jail` | 2000 | no | standard | M1=MetalBars | Metal_Solid | PrisonMetalDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_PileOCrepeBlueDoorWithWindow.png" width="96"> | `Base.PileOCrepeBlueDoorWithWindow` | Pile O' Crepe Blue Door with Window | Porte bleue vitrée Pile O' Crepe | `wood_glazed?` | 425 | yes | standard | TBD | TBD | TBD |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_PileOCrepeOrangeDoor.png" width="96"> | `Base.PileOCrepeOrangeDoor` | Pile O' Crepe Orange Door | Porte orange Pile O' Crepe | `unknown` | TBD | no | standard | TBD | TBD | TBD |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_PizzaWhirledBrownGlassDoor.png" width="96"> | `Base.PizzaWhirledBrownGlassDoor` | Pizza Whirled Brown Glass Door | Porte vitrée brune Pizza Whirled | `glass` | 350 | yes | standard | TBD | Glass_Solid | TBD |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_PizzaWhirledGreenMetalDoor.png" width="96"> | `Base.PizzaWhirledGreenMetalDoor` | Pizza Whirled Green Metal Door | Porte métallique verte Pizza Whirled | `metal` | 650 | no | standard | M1=MetalPlates; M2=Door | Metal_Solid | MetalDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_SeaHorseGlassDoor.png" width="96"> | `Base.SeaHorseGlassDoor` | Sea Horse Glass Door | Porte vitrée Sea Horse | `glass` | 350 | yes | standard | TBD | Glass_Solid | TBD |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_SpiffosGlassDoor.png" width="96"> | `Base.SpiffosGlassDoor` | Spiffo's Glass Door | Porte vitrée Spiffo's | `glass` | 350 | yes | standard | TBD | Glass_Solid | TBD |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_SpiffosRedMetalDoor.png" width="96"> | `Base.SpiffosRedMetalDoor` | Spiffo's Red Metal Door | Porte métallique rouge Spiffo's | `metal` | 650 | no | standard | M1=MetalPlates; M2=Door | Metal_Solid | MetalDoor |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_FossoilDoor.png" width="96"> | `Base.FossoilDoor` | Fossoil Door | Porte Fossoil | `unknown` | TBD | no | standard | TBD | TBD | TBD |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_Gas2GoDoor.png" width="96"> | `Base.Gas2GoDoor` | Gas2Go Door | Porte Gas2Go | `unknown` | TBD | no | standard | TBD | TBD | TBD |
| <img src="Contents/mods/LMION_Build/42/media/textures/LMION_LogDoor.png" width="96"> | `Base.LogDoor` | Log Door | Porte en rondins | `heavy_wood` | 600 | no | standard | M1=Log | Wood_Solid | WoodDoor |

## Current known exceptions and validated facts

- `CherryDoor` localized names are already runtime-validated: `Cherry Door` / `Porte en cerisier`.
- Cherry's current runtime `MetalPlates` secondary material is a diagnostic canary and must be replaced by the catalog's intended wood setup when the bulk profiles are applied.
- `BlueMetalDoor` was runtime-observed with `Material = MetalPlates`, `Material2 = Door`, `MaterialType = Plastic`; the catalog intentionally proposes `Metal_Solid` as the LMION physical classification instead of inheriting that vanilla value blindly.
- `BlueMetalDoor` currently uses `worldMaxHealth = 600` only as a runtime durability canary. The catalog target is 650.
- `LogDoor` keeps `M1=Log` for semantic fidelity. Vanilla's generic salvage path does not recognize `Log` as a wood salvage tag, and `IsoDoor.destroy()` would still add knob/hinge hardware. LMION should therefore give LogDoor custom destruction loot: `1 x Base.Log`, no doorknob, no hinges, and no additional vanilla door loot.
- Jail and Security doors deliberately override normal material-class durability at 2000 and 3000 HP.
- Single fence gates/wickets are kept separate from normal 1x1 doors even if they share `IsoDoor`, so their gameplay profile can diverge later without reclassifying the catalog.

## Remaining ambiguous cases

The bulk pass intentionally leaves these rows partially unresolved because their visible construction/material cannot be determined safely from the entity name alone:

```text
BlackGlassDoubleDoor
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