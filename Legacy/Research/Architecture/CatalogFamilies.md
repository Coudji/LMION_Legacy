# LMION Catalog Families — working draft

Status: **draft for the clean rewrite**. This file is intentionally outside `Workshop/`: it is a design/reference document to refine before implementation.

Source of truth for the current balance values and reviewed entities remains `Legacy/DOOR_CATALOG.md`.

## Goal

The new Core should separate three concepts:

```text
CATALOG PATH
= where an opening lives structurally / where humans find its definition

FAMILY
= a reusable set of default gameplay/construction properties

DEFINITION
= one exact opening model, its identity, exact geometry, and any overrides
```

A family exists to avoid repeating the same recipe, durability, material, sound, pickup and replacement data in every opening definition.

A definition inherits its family defaults. A special model may override only the values that differ. This is desirable and should be used deliberately in LMION itself so the inheritance/override mechanism is exercised by real content and gives third-party modders concrete examples.

## Initial catalog layout

This is the current agreed navigation structure. Fine distinctions should remain in Lua unless they are structurally important enough to justify another folder.

```text
Catalog/
├── Doors/
│   ├── Single/
│   │   ├── Wooden/
│   │   ├── Metal/
│   │   └── Glass/
│   └── Paired/
│       ├── Wooden/
│       └── Metal/
│
├── FenceGates/
│   ├── Wooden/
│   └── Metal/
│
├── LargeGates/
│   ├── Wooden/
│   └── Metal/
│
├── GarageDoors/
└── Windows/
```

`FenceGates` contains both small portillons and standard single-leaf fence gates. Their size/style differences belong in their definitions/families rather than separate top-level folders.

`LargeGates` is reserved for the large multi-tile portals using LMION A/B semantics.

`Windows` is reserved now because LMION is expected to support windows later, but no window family taxonomy is defined yet.

## Family IDs — first complete draft

The IDs below are deliberately provisional. They are the first full mapping extracted from the current catalog so they can now be simplified/refined before code is written.

The wooden 1x1 section is expected to be consolidated further: several current groups can probably share a broader family and use definition-level overrides instead. That consolidation is desirable because it will make the inheritance model simpler and provide useful real override examples.

---

## Doors / Wooden

### `Doors.Wooden.BasicWooden`

Current members:

- `Base.WoodenDoorLvl1`
- `Base.RoughWoodenDoor`

Current reason for grouping:

- same basic durability/build tier
- same main construction recipe
- same material/sound/frame profile
- only small per-model values such as package weight differ

### `Doors.Wooden.StandardWooden`

Current members:

- `Base.WoodenDoorLvl2`
- `Base.RusticWoodenDoor`

Current reason for grouping:

- same standard durability/build tier
- same construction recipe
- same material/sound/frame profile

### `Doors.Wooden.ArtisanWooden`

Current members:

- `Base.WoodenDoorLvl3`

Current note:

- single-member family in this first draft
- likely candidate for consolidation into a broader solid-wood family with overrides

### `Doors.Wooden.Outhouse`

Current members:

- `Base.OuthouseDoor`

Current note:

- fixed-durability utility model
- likely candidate for a broad wooden family plus explicit overrides rather than a permanent one-member family

### `Doors.Wooden.Paneled`

Current members:

- `Base.WhitePanelDoor`
- `Base.BrownPanelDoor`
- `Base.MahoganyPanelDoor`
- `Base.BluePanelDoor`
- `Base.BlueChurchDoubleDoorLeft`
- `Base.BlueChurchDoubleDoorRight`
- `Base.BrownChurchDoubleDoorLeft`
- `Base.BrownChurchDoubleDoorRight`

Current reason for grouping:

- the single doors share one reviewed profile and recipe
- the paired church doors deliberately reuse that same profile per leaf
- paired topology belongs to the definition, not to the family

### `Doors.Wooden.OneWindowResidential`

Current members:

- `Base.WhiteDoorWithWindows`
- `Base.BrownDoorWithWindows`

Current reason for grouping:

- same residential one-window profile
- same recipe and handling values

### `Doors.Wooden.OneWindowCommercial`

Current members:

- `Base.BlueDoorWithWindow`

Current note:

- currently differs from the residential one-window models in durability/build values and timing
- strong candidate for using `OneWindowResidential` or a broader glazed-wood family plus overrides instead of keeping a permanent separate family

### `Doors.Wooden.TwoPane`

Current members:

- `Base.RedTwoPaneDoor`
- `Base.BlueTwoPaneDoor`
- `Base.GreenStripedTwoPaneDoor`
- `Base.BrownTwoPaneDoor`
- `Base.DarkBrownTwoPaneDoor`

Current reason for grouping:

- one reviewed two-pane gameplay profile
- same recipe and handling profile
- color/branding is cosmetic

### `Doors.Wooden.FullGlass`

Current members:

- `Base.BlackFullGlassDoor`
- `Base.BrownFullGlassDoor`

Current reason for grouping:

- same wooden-framed full-glass profile
- same recipe and handling profile

### `Doors.Wooden.RestroomStall`

Current members:

- `Base.BlackRestroomStallDoor`
- `Base.BlueRestroomStallDoor`
- `Base.BrownRestroomStallDoor`
- `Base.PinkRestroomStallDoor`
- `Base.WhiteRestroomStallDoor`

Current reason for grouping:

- cosmetic variants of one fixed-durability stall-door profile
- same recipe and handling profile

### `Doors.Wooden.RestroomFullHeight`

Current members:

- `Base.BlueRestroomDoor`

Current note:

- one-member first-draft family
- likely candidate for a broader family plus overrides

### `Doors.Wooden.Log`

Current members:

- `Base.LogDoor`

Current note:

- deliberately special construction/material profile
- placement in the normal family hierarchy is not final

---

## Doors / Metal

### `Doors.Metal.PatchworkMetal`

Current members:

- `Base.MetalDoorLvl1`

Current note:

- rough vanilla metal tier
- one-member first-draft family; may later be generalized with overrides

### `Doors.Metal.SimpleMetal`

Current members:

- `Base.MetalDoorLvl2`

Current note:

- cleaner second vanilla tier
- one-member first-draft family; may later be generalized with overrides

### `Doors.Metal.FinishedMetal`

Current members:

- `Base.WhiteMetalDoor`
- `Base.TanMetalDoor`
- `Base.GreyMetalDoubleDoorLeft`
- `Base.GreyMetalDoubleDoorRight`

Current reason for grouping:

- same reviewed finished-solid profile
- paired grey door reuses the same per-leaf recipe/profile

### `Doors.Metal.FinishedMetalOneWindow`

Current members:

- `Base.BlackMetalDoorWithWindow`
- `Base.TanMetalDoorWithWindow`

Current reason for grouping:

- same finished one-window profile and recipe

### `Doors.Metal.TwoPane`

Current members:

- `Base.BlackTwoPaneMetalDoor`
- `Base.BlackTwoPaneDoubleDoorLeft`
- `Base.BlackTwoPaneDoubleDoorRight`

Current reason for grouping:

- same reviewed two-pane metal profile
- paired version reuses the same per-leaf recipe/profile

### `Doors.Metal.ServiceSolid`

Current members:

- `Base.BlueServiceDoor`
- `Base.OrangeServiceDoor`
- `Base.LightRedServiceDoor`
- `Base.BlackServiceDoor`
- `Base.GreenServiceDoor`
- `Base.RedServiceDoor`

Current reason for grouping:

- same light service-door construction
- same recipe and handling profile
- colors are cosmetic

### `Doors.Metal.ServiceGlazed`

Current members:

- `Base.WhiteServiceDoorWithPorthole`
- `Base.YellowServiceDoubleDoorLeft`
- `Base.YellowServiceDoubleDoorRight`

Current reason for grouping:

- same glazed service-door profile per leaf
- paired topology is definition data, not a separate gameplay family

### `Doors.Metal.Jail`

Current members:

- `Base.JailDoor`

Current note:

- deliberately special high-end model
- placement as a one-member family is provisional

### `Doors.Metal.Security`

Current members:

- `Base.SecurityDoor`

Current note:

- deliberately special high-end model
- placement as a one-member family is provisional

---

## Doors / Glass

### `Doors.Glass.SlidingGlass`

Current members:

- `Base.BrownSlidingGlassDoor`
- `Base.WhiteSlidingGlassDoor`

Current reason for grouping:

- same sliding-glass gameplay profile
- same fixed durability
- same recipe and handling values
- frame finish is cosmetic

---

## FenceGates / Wooden

### `FenceGates.Wooden.SmallWooden`

Current members:

- `Base.SmallWhiteWoodenGate`

Current note:

- small portillon profile
- provisional one-member family

### `FenceGates.Wooden.StandardWooden`

Current members:

- `Base.WoodFenceGate`

Current note:

- standard wooden fence-gate profile
- provisional one-member family

### `FenceGates.Wooden.HardenedWooden`

Current members:

- `Base.HardenedWoodenGate`

Current note:

- hardened wooden profile
- provisional one-member family

---

## FenceGates / Metal

For fence gates, size materially changes recipe, durability and handling. The first draft therefore keeps small and standard variants as separate families rather than adding a second default-inheritance axis for `size`.

### `FenceGates.Metal.SmallChainLink`

Current members:

- `Base.MetalWireFenceGateSmall`

### `FenceGates.Metal.ChainLink`

Current members:

- `Base.MetalWireFenceGate`

### `FenceGates.Metal.SmallScrapMetal`

Current members:

- `Base.MetalPoleFenceGateSmall`

### `FenceGates.Metal.ScrapMetal`

Current members:

- `Base.MetalPoleFenceGate`

### `FenceGates.Metal.SmallWroughtIron`

Current members:

- `Base.SmallWroughtIronGate`

### `FenceGates.Metal.WroughtIron`

Current members:

- `Base.WroughtIronGate`

---

## LargeGates / Wooden

### `LargeGates.Wooden.StandardWooden`

Current members:

- `Base.DoubleDoor`

### `LargeGates.Wooden.HardenedWooden`

Current members:

- `Base.LargeHardenedWoodenGate`

These remain separate in the first draft because their construction and durability profiles are intentionally different.

---

## LargeGates / Metal

### `LargeGates.Metal.Farm`

Current members:

- `Base.LargeFarmGate`

### `LargeGates.Metal.ChainLink`

Current members:

- `Base.DoubleWireGate`

### `LargeGates.Metal.ScrapMetal`

Current members:

- `Base.DoubleFenceGate`

### `LargeGates.Metal.WroughtIron`

Current members:

- `Base.LargeWroughtIronGate`

`DoubleWireGate` and `DoubleFenceGate` share a reviewed durability tier but should not automatically share one family because their materials and construction recipes differ substantially. A family should be useful as a real default provider, not merely a balance label.

---

## GarageDoors

### `GarageDoors.Solid`

Current members:

- `Base.IndustrialGarageDoor`
- `Base.GreenGarageDoor`
- `Base.WhiteGarageDoor`
- `Base.GreyGarageDoor`
- `Base.RollingGarageDoor`

### `GarageDoors.Glazed`

Current members:

- `Base.RedWindowGarageDoor`
- `Base.RollingWindowGarageDoor`

This is already a strong family split in the reviewed catalog: rolling/sectional/industrial appearance does not create a different gameplay profile; solid versus glazed does.

---

## Paired doors are not a separate family namespace

Paired doors live under `Catalog/Doors/Paired/...` because that is their structural form, but their family should normally be the same family used by the matching single-door construction.

Examples:

```text
Catalog/Doors/Single/Wooden/WhitePanelDoor.lua
family = Doors.Wooden.Paneled

Catalog/Doors/Paired/Wooden/BlueChurchDoubleDoor.lua
family = Doors.Wooden.Paneled
```

```text
Catalog/Doors/Single/Metal/WhiteMetalDoor.lua
family = Doors.Metal.FinishedMetal

Catalog/Doors/Paired/Metal/GreyMetalDoubleDoor.lua
family = Doors.Metal.FinishedMetal
```

The paired definition adds Left/Right identity and paired geometry. It does not create a duplicate recipe family.

---

## Inheritance / override direction

The intended resolution model is deliberately simple:

```text
Family defaults
      +
Definition overrides
      =
Effective definition
```

Working semantics:

- absent property = inherit family value
- explicit property = override inherited value
- explicit `false` = disable an inherited optional capability
- complete lists such as construction material lists should normally replace the inherited list rather than use implicit item-by-item merge magic

Core owns this resolution. Build, Pickup, Lock and future mechanics should consume the effective definition and should not need to know where an individual value originated.

## Refinement target

Before implementation, review this list with two goals:

1. remove families that exist only because the old catalog had a separate balance row but do not need a permanent reusable default set;
2. deliberately keep a few definitions that inherit a broad family and override recipe/durability/material details, so LMION itself demonstrates the extension model to future modders.

The wooden 1x1 families are the first place to perform this simplification.
