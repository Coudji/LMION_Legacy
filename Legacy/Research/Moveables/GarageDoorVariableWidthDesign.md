# Variable-width garage design

Status: **Core topology, Pickup variable-width transport/reinstallation, and Build variable-width construction are implemented. The current validated gameplay baseline is primarily single-player.**

This note is the cross-addon design contract for garage widths. Detailed engine evidence remains in `GarageDoorTopology.md`; detailed Build implementation history is in `GarageDoorVariableBuildPrototype.md`.

## Native topology

`GarageDoor` normalized values are topological roles, not fixed member numbers:

```text
1 = START
2 = MIDDLE
3 = END
```

Valid native chains are:

```text
L2  = START + END
L3  = START + MIDDLE + END
L4+ = START + MIDDLE * (L-2) + END
```

B42 runtime research demonstrated synchronized native behavior beyond L3. No Project Zomboid engine maximum is currently established.

## Core width policy

Core owns the semantics and policy shared by independent addons:

```text
minimum = 2
default = 3
LMION default maximum = 12
UnlimitedGarageWidth -> no artificial LMION maximum
```

L12 is a gameplay/safety policy, **not an engine-limit claim**.

Core APIs/topology must remain neutral about whether a width is being used for Build or Pickup.

## Addon independence

The key architecture is:

```text
LMION_Build  -> Core garage semantics
LMION_Pickup -> Core garage semantics
```

There is no:

```text
Build -> Pickup
Pickup -> Build
```

Build and Pickup independently convert Core's `START/MIDDLE/END` semantics into their own actions and UX.

## Pickup contract

Pickup works on the actual native garage chain rather than a fixed SpriteGrid width.

Parcel identity:

```text
one physical member = one 20 kg parcel
_Part1 = START
_Part2 = repeatable MIDDLE
_Part3 = END
```

Variable reinstallation explicitly places:

```text
START + MIDDLE*(L-2) + END
```

and consumes exactly the compatible parcels needed for the chosen plan.

### Entry-point split

This behavior is intentional and must not be “fixed” by globally hijacking Moveables:

```text
inventory right-click Place
-> exact garage InventoryItem known
-> LMION dedicated variable-width cursor/action

left Moveables sidebar Place
-> generic vanilla Moveables catalogue
-> historical synthetic L3 SpriteGrid
-> fixed L3 placement
```

The synthetic L3 SpriteGrid remains only for vanilla Moveables discovery/pickup/item-facing compatibility. It is not LMION variable placement geometry.

## Build contract

Build exposes width selection in the Construction recipe panel:

```text
Longueur / Length : [ - ] L [ + ]
```

The selected width:

- follows Core min/max policy;
- is retained across B42 recipe/manual-input refreshes;
- updates displayed/full LMION requirements;
- is frozen into the world build cursor;
- survives quick-repeat cursor recreation.

Physical construction uses a per-cursor FaceInfo proxy over the canonical L3 source pattern. The mapping is semantic:

```text
first -> START
interior -> MIDDLE
last -> END
```

Build owns this cursor/recipe implementation. It does not reuse Pickup's parcel placement code.

## Build material contract

Material cost is selected-width gameplay balance, not an engine topology rule and not skill-based cost reduction.

Solid:

```text
welding protection: one kept base:weldingmask-tagged item
SmallSheetMetal = 3L
MetalBar/IronBar shared quota = L
Hinge = 2L
BlowTorch uses = min(ceil(L/3), 10)
WeldingRods uses = min(2*ceil(L/3), 20)
```

Glazed:

```text
welding protection: one kept base:weldingmask-tagged item
SmallSheetMetal = 2L
GlassPanel = L
MetalBar/IronBar shared quota = L
Hinge = 2L
BlowTorch uses = min(ceil(L/3), 10)
WeldingRods uses = min(2*ceil(L/3), 20)
```

The welding tag intentionally covers both the normal mask and old welding goggles.

Bars may be mixed between `Base.MetalBar` and `Base.IronBar`; total quantity remains L.

B42's native variable-input facility is used only to make the bar-selection UI understand the selected maximum. LMION still owns the complete material formula and additionally validates that the manual selected-bar count reaches L.

## Representation contract

Garage doors are not allowed to persist as LMION-managed `IsoThumpable` objects.

Native GarageDoor mechanics are `IsoDoor`-specific enough that garage SpriteConfigs use:

```text
OnCreate = LMION.Doors.onCreateGarage
```

This is an **early canonicalization timing requirement**, not a separate garage representation architecture. The global output contract remains canonical `IsoDoor`.

## Lifecycle contract

Garage sprite properties may not be ready during initial shared Lua even if sprite objects already exist. Cold-start tile-derived garage validation/mutation waits for `OnLoadedTileDefinitions`.

For Build, `ISBuildIsoEntity` lives in the vanilla **server** Lua tree. Therefore:

- shared reusable cursor code stays inert at top level;
- client UI does not force-load the server class;
- server `GarageBuildCursorHook.lua` installs the hook once that phase/path exists.

See `Research/Engine/B42LuaLoadOrder.md`.

## Runtime status

Pickup/reinstallation has runtime evidence for variable chains including L5 reinstallation and earlier wider native/topology tests.

Build runtime evidence currently includes:

- L12 physical construction in cheat mode;
- L3 and L5 normal-mode construction;
- resource-affordability refusal;
- width preservation through ingredient selection and quick repeat;
- mixed MetalBar/IronBar selection/consumption;
- welding-protection alternatives;
- selected-bar maximum L and minimum-selected L validation;
- smoke tests of existing 1x1, large-gate and Pickup behavior.

Do not claim exhaustive all-family/all-orientation normal-mode validation or multiplayer validation yet.

## Non-goals / rejected directions

Do not reintroduce:

- a fixed-L3 assumption into Core topology;
- Pickup dependence on Build or Build dependence on Pickup;
- a global `ISMoveableCursor` hybrid solely to make sidebar placement variable;
- persistent garage `IsoThumpable` output;
- a single generic variable ratio as the complete Build cost model;
- width state only in replaceable `CraftRecipeData.modData`;
- an artificial claim that L12 is the engine maximum.

## Current conclusion

Variable garage width is now a **Core semantic capability consumed independently by Build and Pickup**. That separation is the architecture to preserve as future garage features evolve.
