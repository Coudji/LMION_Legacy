# LMION — Design notes

## Fixed architecture

- One Workshop item.
- Several internal Mod IDs.
- `LMION_Core` owns only proven shared systems and persistence conventions.
- `LMION_Build` owns construction/crafting concerns.
- `LMION_Pickup` owns pickup/transport/reinstallation.
- `LMION_Debug` owns development-only tooling.

Core deliberately avoids speculative abstractions and parallel copies of facts already exposed by Project Zomboid runtime objects or `GameEntityScript` / `SpriteConfig`.

## Ownership principle

> Vanilla defines the physical opening mechanics; LMION defines the gameplay rules.

LMION should reuse vanilla opening/closing, collision, synchronization and sprite-state behavior wherever possible. LMION owns rules such as crafting, materials, transport identity, pickup eligibility, durability and repair.

`newtiledefinitions.tiles` remains research/reference data only and should not be edited for LMION runtime behavior.

## General Pickup rule

> If it opens and the player can pass through it, Pickup owns it.

Transport identity should follow the physical/gameplay unit that makes sense to move and reinstall. Synchronization in the world does not automatically imply a single inventory item.

For normal 1x1 doors, one physical door maps naturally to one inventory item.

For large double gates, one **leaf** is the transport unit, but each leaf maps to two physical door segments. LMION therefore represents one recovered leaf as two parcels, `(1/2)` and `(2/2)`, while replacement recreates the complete two-segment leaf in one operation.

## Runtime findings

### Generic `IsoDoor`

Many visually different opening types use `zombie.iso.objects.IsoDoor`; runtime class alone is not enough for classification.

Static closed/open sprite configuration should come from `GameEntityScript` / `SpriteConfig` or source scripts rather than private-field reflection.

### Engine max-health limitation

`IsoDoor:setHealth()` accepts values above engine max, but production Lua has no useful `IsoDoor:setMaxHealth()` path.

LMION therefore stores the authoritative gameplay max in:

```text
lmionDoorMaxHealth
```

LMION-owned repair/condition logic must use that logical max instead of `IsoDoor:getMaxHealth()`.

### Existing world-door migration

When LMION first adopts a matching world `IsoDoor` with a configured world max:

- an intact door at engine max is treated as full life and raised to the LMION max;
- an already damaged door keeps its current health exactly;
- the LMION logical max is stored in both cases;
- an already-adopted door is not repeatedly migrated.

This avoids ratio scaling and artificial healing.

### Simple / autonomous 1x1 doors

The simple-door path is considered mechanically validated enough to serve as the baseline for broader work.

Validated behavior includes:

- localized/dedicated inventory identity;
- Moveables pickup/replacement;
- frame-aware placement where required;
- preservation of current health;
- preservation of LMION logical max;
- repair above engine max;
- straightforward fence-gate and sliding-door integration.

Balance/material tuning remains separate from the mechanical architecture.

## Double doors and large gates

This area is no longer speculative: the core topology has been validated from Java research and runtime tests.

### Logical grouping

`IsoDoor.getDoubleDoorIndex()` reads the logical `DoubleDoor` member encoded by the sprite. Closed members use logical indices 1..4; open-state raw values 5..8 normalize back to logical 1..4.

`IsoDoor.getDoubleDoorObject()` locates linked members from the source member, its orientation/open state, hardcoded offsets and the requested logical index.

Critically, grouping does **not** require:

- matching sprite family;
- matching GameEntity/entity identity;
- matching material/profile identity.

Runtime testing confirmed that independently constructed left/right leaves with different entity identities still synchronize opening correctly when placed in the proper geometry.

### Orientation-dependent logical indices

Do not assume that a physical leaf always corresponds to the same pair of logical indices in every orientation.

For the validated `DoubleWireGate` closed sprites used by LMION:

```text
LEFT LEAF
N: Part1 = index 1, Part2 = index 2
W: Part1 = index 4, Part2 = index 3

RIGHT LEAF
N: Part1 = index 3, Part2 = index 4
W: Part1 = index 2, Part2 = index 1
```

For closed W-facing double doors, Java/runtime behavior shows indices progressing toward the north. The validated LMION placement geometry therefore uses:

```text
N facing: Part2 is one square east of Part1
W facing: Part2 is one square south of Part1
```

This orientation-dependent mapping is essential. Earlier code assumed fixed `{1,2}` / `{3,4}` leaf pairs and produced visually plausible but unlinked `IsoDoor` objects after rotation.

### Construction split

The six current large-gate families are exposed as independent left/right construction leaves:

- Large Farm Gate;
- Large Wrought Iron Gate;
- Large Hardened Wooden Gate;
- Large Chain-Link Gate;
- Large Scrap Metal Gate;
- Large Wooden Gate.

All six were tested in both N and W orientations and synchronized opening works.

For the three vanilla families (`DoubleDoor`, `DoubleWireGate`, `DoubleFenceGate`), LMION keeps the vanilla entity as the left leaf and adds a distinct right-leaf entity. For LMION-owned families, explicit `Left` / `Right` entities are used.

### Destruction behavior

Vanilla whole-double-door destruction intentionally follows linked members. In current gameplay, using the Destroy menu on one member destroys the complete portal.

LMION leaves this behavior unchanged. Per-leaf Pickup must therefore remove members directly and must not call whole-double-door destruction helpers.

## Large Chain-Link Gate Pickup — validated implementation

The active proof-of-concept is `Large Chain-Link Gate` / `DoubleWireGate`, and its complete closed-leaf pickup/replacement cycle is now validated.

### Transport identity

One leaf is represented by two parcels:

```text
Grand portail grillagé - vantail gauche (1/2)
Grand portail grillagé - vantail gauche (2/2)

Grand portail grillagé - vantail droit (1/2)
Grand portail grillagé - vantail droit (2/2)
```

Both parcels remain required for replacement. Pickup of either physical segment resolves the complete selected leaf and leaves the opposite leaf in the world.

The pickup code temporarily treats each physical source segment as non-multisprite while calling the vanilla internal pickup path, so two separate parcels are produced even though the same sprites are later exposed to Moveables as a logical multisprite object.

### Why LMION installs runtime `IsoSpriteGrid` objects

The closed `DoubleWireGate` sprites are not authored with the `IsoSpriteGrid` metadata that generic Moveables expects. Without a real grid, Moveables treats each recovered parcel as a separate 1x1 object: preview and placement operate on one segment at a time.

B42.20.3 exposes the required runtime API to Lua:

- `IsoSpriteGrid.new(width, height)`;
- `grid:setSprite(x, y, sprite)`;
- `grid:validate()`;
- `IsoSprite:setSpriteGrid(grid)`;
- `IsoSprite:getSpriteGrid()`.

LMION therefore creates four runtime grids for the Chain-Link prototype:

```text
left N  = 2x1, Part1 then Part2
left W  = 1x2, Part1 then Part2
right N = 2x1, Part1 then Part2
right W = 1x2, Part1 then Part2
```

The grids are attached to the global `IsoSprite` instances, not to individual `IsoDoor` objects. This means the change applies anywhere those exact sprites are used during the running session.

### Critical initialization timing

Installing the grids only when LMION Lua first loads is insufficient. During normal startup Project Zomboid subsequently runs `LoadTileDefinitions`, which rebuilds/reinitializes sprite definitions and can erase the earlier `setSpriteGrid()` state.

The validated pattern is:

1. install once at Lua load for hot-reload sessions where tile definitions are already present;
2. install again from `Events.OnLoadedTileDefinitions` after the engine has finished loading/rebuilding tile definitions.

The second installation is the one that made Moveables consistently recognize the gate leaves as multisprite objects during normal cold startup.

### What the runtime SpriteGrid is used for

The SpriteGrid is intentionally used for **Moveables semantics**, not as proof that vanilla can perform every part of the replacement correctly.

It provides useful vanilla behavior:

- pickup targeting highlights the full two-square leaf;
- the two parcels are grouped as one multisprite Moveables object in inventory;
- the cursor understands a two-square footprint;
- orientation switching can use the N/W sprite-grid faces;
- both parcel identities can participate in one logical leaf operation.

### Why actual placement is still explicit LMION placement

An early prototype tried to rely entirely on vanilla `ISMoveableSpriteProps.placeMoveable()` once the SpriteGrid existed. That approach failed after rotation because vanilla canonicalizes multisprite items around a grid anchor and assumes ordinary furniture-style grid semantics.

DoubleDoor leaf geometry and logical indices are orientation-dependent, so LMION keeps the SpriteGrid for Moveables identity/footprint but explicitly rebuilds the two physical `IsoDoor` segments.

The validated replacement path is:

```text
selected parcel
    -> resolve leaf + facing
    -> require both parcel item types
    -> calculate Part1/Part2 target squares
    -> validate each square with vanilla canPlaceMoveableInternal()
    -> place Part1 with placeMoveableInternal()
    -> place Part2 with placeMoveableInternal()
    -> consume both parcels
    -> let vanilla DoubleDoor linkage/opening behavior take over
```

Each per-segment `ISMoveableSpriteProps` is temporarily treated as non-multisprite while calling `placeMoveableInternal()`. This avoids recursively invoking generic multisprite placement while preserving the normal vanilla object-construction path for each `IsoDoor`.

Validated result: both left and right leaves can be picked up and replaced in their original orientation or rotated between N and W, and vanilla synchronized opening resumes afterward.

### Preview renderer: why generic vanilla rendering is visually wrong

A normal two-square furniture object such as a bench has two visual sprite members that complement one another. Vanilla `ISMoveableCursor.renderSpriteGrid()` can simply draw both members and the preview looks correct.

`DoubleWireGate` is authored differently. Runtime diagnostic rendering of each member separately established that one member already contains the complete visible leaf artwork while the other is a technical/partial visual member. Drawing both SpriteGrid members therefore duplicates part of the leaf.

The asymmetry is also opposite between the two leaves:

```text
left leaf  -> Part1 is the complete visual member
right leaf -> Part2 is the complete visual member
```

Therefore LMION keeps the full two-member SpriteGrid for logical Moveables behavior but overrides only the large-gate `renderSpriteGrid()` presentation path:

- both footprint squares are rendered normally;
- only the leaf's configured `visualPartIndex` sprite is rendered as the gate ghost;
- left uses Part1;
- right uses Part2;
- other Moveables objects continue to use vanilla `renderSpriteGrid()` unchanged.

This is not a placement workaround. It is strictly a visual adaptation for DoubleDoor sprite authoring that does not match ordinary furniture SpriteGrid artwork.

### Failed hypotheses worth remembering

Several experiments were useful specifically because they ruled out common assumptions:

- A SpriteGrid attached before `LoadTileDefinitions` appeared to install successfully but did not survive into actual Moveables behavior.
- Generic vanilla multisprite placement was not sufficient for rotated DoubleDoor leaves even after a valid SpriteGrid existed.
- The doubled preview was not caused by a second hidden cursor renderer: a diagnostic `renderSpriteGrid()` that drew only the floor footprint produced no gate sprite at all.
- The doubled preview was not ordinary image overlap between two complementary tiles: rendering the members far apart showed that one member already contained the complete leaf artwork.
- Changing ghost alpha did not fix the duplicate because the issue was which visual members were being rendered, not opacity.

These findings should be reused when adding SpriteGrid-based Moveables support to other engine-authored multi-tile objects.

### Non-blocking engine warning

During multi-square pickup the engine can log:

```text
GameEntityFactory.TransferComponents> Cannot transfer components for multi-square objects.
```

No concrete functional failure has been reproduced from this warning in the validated Chain-Link cycle. Both parcels are produced and the leaf can be restored. Do not add speculative workarounds unless state loss is demonstrated.

### Current design choice

```text
one leaf = two parcels = one placement action
```

This remains preferred over `1/4..4/4` parcels for the complete portal because construction and gameplay ownership are leaf-based.

Open-state pickup is not yet the reference path. The intended eventual behavior is to normalize recovered parcels to canonical closed-segment identities rather than creating separate inventory identities for open sprites.

## SpriteConfig research

`SpriteConfigScript.getAllTileNames()` is backed by a mutable list populated from declared face/layer/row/tile entries during script checking.

`SpriteConfigManager` later uses those names for global scripted-sprite ownership and writes `EntityScriptName` / `EntityScript` flags onto owned sprites.

`SpriteConfigScript:PreReload()` clears faces and `allTileNames` and resets component state. This is the correct targeted reset before reloading a modified SpriteConfig body.

`GameEntityScript:PreReload()` is **not** an equivalent targeted reset; it clears the whole component list and would remove unrelated components such as UiConfig/CraftRecipe.

The earlier duplicate-sprite prototype failure came from stale/overlapping SpriteConfig ownership. The validated split path verifies exact vanilla ownership before reset and exact left-leaf ownership after reload.

TileDefinitions can still supply physical runtime properties and open-state behavior, but current bytecode evidence does not support treating TileDefinitions as the source of `SpriteConfigScript.allTileNames`.

## Localization decision

Canonical paired naming uses:

- internal IDs: base + `Left` / `Right`;
- English display: `Left Leaf` / `Right Leaf`;
- French display: `vantail gauche` / `vantail droit`.

Construction localization uses `Recipes.json`. Current B42 lookup strips spaces from recipe display names before key lookup, so LMION translation keys must match that normalized form.

## Garage doors

Garage doors remain a separate multi-tile system and should not inherit the DoubleDoor leaf model by assumption.

Observed garage linkage uses `garageDoorIndex`, `garage.first`, `garage.prev` and `garage.next` rather than `DoubleDoor` logical indices.

A functioning garage door should likely remain one transportable opening even though it contains several physical segments, but that implementation should be researched and validated independently.

## Material system findings

Project Zomboid `PropertyContainer` values are alias-backed. Unknown strings can silently resolve to another valid alias.

LMION must verify exact readback after engine-facing property writes and restore previous values when the request did not survive exactly.

`MaterialType` is a closed engine enum and is not equivalent to salvage material tags.

`IsoDoor.destroy()` reads `Material`, `Material2` and `Material3` for salvage and separately handles door hardware.

## Debug tooling

The Inspector and Test Zone belong to `LMION_Debug` and must remain development-only.

The deterministic Test Zone now has 83 explicit entries after splitting the six large gates into twelve leaves.

Do not reintroduce intrusive generic Moveables tracing unless a new, narrowly scoped diagnostic is genuinely required.

## Future module ideas

### Repair

A future `LMION_Repair` should own tools, materials, skills, timed action, UX and repair balance. Core should retain only low-level logical-health operations.

### Locksmith / Access Control

Potential future systems include cylinders/rekeying, keys, padlocks/hasps, powered keypads, badges, fail-secure/fail-safe hardware and alarm/access logic. These remain future scope and should not influence current door transport architecture prematurely.

## Current milestone order

1. Validate per-segment health / logical-max preservation across the now-working Chain-Link leaf pickup cycle.
2. Generalize the proven leaf transport model to the other five large gates, checking each family's sprite authoring before assuming the same `visualPartIndex` rule.
3. Research/implement garage-door transport separately.
4. Build the real Repair gameplay module after transport and material/craft rules are sufficiently stable.
