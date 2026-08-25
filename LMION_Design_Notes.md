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

For large double gates, one **leaf** is the transport unit, but each leaf currently maps to two physical door segments. LMION therefore represents one recovered leaf as two parcels, `(1/2)` and `(2/2)`, while replacement recreates the complete two-segment leaf in one operation.

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

`IsoDoor.getDoubleDoorIndex()` uses logical members 1..4. Open-state raw values 5..8 map back to logical 1..4.

The two leaves are:

```text
leaf A = indices 1 + 2
leaf B = indices 3 + 4
```

`IsoDoor.getDoubleDoorObject()` locates linked members using source orientation/open state, hardcoded geometry and logical index matching.

Critically, grouping does **not** require:

- matching sprite family;
- matching GameEntity/entity identity;
- matching material/profile identity.

Runtime testing confirmed that independently constructed left/right leaves with different entity identities still synchronize opening correctly when placed in the proper geometry.

### Geometry

Validated closed geometry follows four contiguous members. Opening rearranges those members according to vanilla hardcoded offsets. LMION should not reimplement that synchronization unless the engine proves insufficient.

### Construction split

The six current large-gate families are now exposed as independent left/right construction leaves:

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

LMION currently leaves this behavior unchanged. Per-leaf Pickup must therefore remove members directly and must not call whole-double-door destruction helpers.

### Pickup model

The active proof-of-concept is `Large Chain-Link Gate`.

Validated behavior:

- targeting either physical square of a closed leaf identifies the same logical leaf;
- the other leaf remains in the world;
- pickup produces two parcels for the selected leaf;
- replacement requires both parcels and places both segments in one operation;
- once reassembled, vanilla synchronized opening resumes.

Current design choice:

```text
one leaf = two parcels = one placement action
```

This is preferred over `1/4..4/4` parcels for the complete portal because construction and gameplay ownership are now leaf-based.

Open-state pickup is not yet the reference path. The intended eventual behavior is to normalize recovered parcels to the canonical closed-segment identities rather than creating separate inventory identities for open sprites.

### Placement preview

Moveables visual preview and actual placement are distinct vanilla paths. During prototyping, the cursor could preview a full multi-square SpriteGrid while actual placement created only one segment; after LMION took over paired placement, the opposite occurred: both segments were placed while the vanilla cursor previewed only one.

Therefore multi-segment preview must be treated as presentation logic, not as proof of placement semantics.

The current implementation explicitly hooks the Moveables cursor render path for the large-gate prototype. That visual path is still under runtime validation.

## SpriteConfig research

`SpriteConfigScript.getAllTileNames()` is backed by a mutable list populated from declared face/layer/row/tile entries during script checking.

`SpriteConfigManager` later uses those names for global scripted-sprite ownership and writes `EntityScriptName` / `EntityScript` flags onto owned sprites.

`SpriteConfigScript:PreReload()` clears faces and `allTileNames` and resets component state. This is the correct targeted reset before reloading a modified SpriteConfig body.

`GameEntityScript:PreReload()` is **not** an equivalent targeted reset; it clears the whole component list and would remove unrelated components such as UiConfig/CraftRecipe.

The earlier duplicate-sprite prototype failure came from stale/overlapping SpriteConfig ownership. The validated split path now verifies exact vanilla ownership before reset and exact left-leaf ownership after reload.

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

1. Finish and validate the Large Chain-Link Gate two-parcel leaf Pickup cycle, including preview.
2. Validate both parcels as placement entry points and both N/W orientations.
3. Generalize the proven leaf transport model to the other five large gates.
4. Research/implement garage-door transport separately.
5. Build the real Repair gameplay module after transport and material/craft rules are sufficiently stable.
