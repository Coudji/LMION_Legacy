# Garage-door placement entry path

Status: **B42 Moveables placement path traced; dedicated LMION garage cursor/action selected as the implementation direction.**

This note complements `GarageDoorVariableWidthPlacementResearch.md` and records the exact integration point chosen after the fixed-L3 Moveables placement experiment was rejected.

## Vanilla inventory entry point

`ISMoveableContextMenu.createMenu()` adds the normal inventory `Place` command for a Moveable item.

The callback is:

```lua
ISMoveableContextMenu.openMovableCursor(item, playerObj)
```

Vanilla implementation:

```lua
local mo = ISMoveableCursor:new(playerObj)
getCell():setDrag(mo, mo.player)
mo:setMoveableMode("place")
mo:tryInitialItem(item)
```

This is the narrowest clean handoff available **before** vanilla normalizes a multisprite parcel to its fixed `IsoSpriteGrid` anchor.

LMION should therefore wrap/intercept `openMovableCursor()` only for recognized garage parcel item types:

```text
ordinary Moveable item
-> unchanged vanilla ISMoveableCursor

LMION garage Start/Middle/End parcel
-> LMION garage placement cursor
```

The user-facing inventory command remains the normal `Place` command.

## Why interception must happen before ISMoveableCursor

Once vanilla `ISMoveableCursor` owns the item, fixed SpriteGrid semantics are already structural:

- `getInventoryObjectList()` collapses multisprite items to `spriteGrid:getAnchorSprite()`;
- `isValid()` calls multisprite `canPlaceMoveable()`;
- `renderSpriteGrid()` loops fixed grid width/height;
- rotation rebuilds MoveProps from fixed faces;
- the cursor creates `ISMoveablesAction` with the fixed MoveProps contract.

A variable garage should therefore never enter vanilla Place mode as one multisprite assembly.

## Timed-action boundary

`ISMoveablesAction:new(..., "place", ...)` independently repeats the fixed-grid normalization:

```text
item world sprite
-> if spriteGrid exists: spriteGrid:getSprite(0,0)
-> rebuild MoveProps
-> select facing
```

`complete()` then calls `moveProps:placeMoveableViaCursor()`, which is the normal fixed-multisprite placement path.

Therefore a dedicated cursor **cannot safely reuse the standard ISMoveablesAction constructor/complete path** for variable garages.

### Selected action strategy

Use a small LMION garage placement action derived from `ISMoveablesAction` (or otherwise sharing its presentation contract) but bypass its constructor's SpriteGrid normalization and override placement completion.

Useful vanilla/LMION behavior that can still be reused:

- one single-segment `ISMoveableSpriteProps` as the tool/skill/action-time definition;
- `moveProps:walkToAndEquip(character, square, "place", spriteName)` with `isMultiSprite=false`;
- LMION's existing Moveables presentation hook for hammer placement, by keeping `mode="place"` and `moveProps.lmionGarageFamily` on the action;
- `placeMoveableInternal()` per physical segment, with `isMultiSprite=false`, so existing Core canonicalization and per-parcel durability restoration remain authoritative.

Do **not** call `placeMoveableViaCursor()` for the complete variable garage.

## Dedicated cursor base class

Use `ISBuildingObject` as the cursor base instead of subclassing `ISMoveableCursor`.

Reasons:

- `ISBuildingObject` already participates in the normal world drag/click pipeline (`DoTileBuilding`);
- it already receives the game's configurable `Rotate building` key through `rotateKey()`;
- its `render()`/`isValid()` contract is intentionally overridable for arbitrary footprints;
- vanilla itself uses derived cursors that render/place arbitrary multi-tile structures without `IsoSpriteGrid` (for example `ISBuildRampCursor`);
- it has none of the fixed Moveables inventory-list/SpriteGrid assumptions that caused the failed experiment.

LMION's garage cursor should override the actual footprint-specific methods instead of altering global sprite data.

## Cursor-owned state

The cursor instance owns:

```text
familyId
selectedLength
facing N/W
player/character
```

No global selected width is required.

Available physical parcels are resolved from the player's inventory and permitted nearby floor range when the plan is built.

The selected length is clamped to:

```text
minimum = L2
maximum = min(2 + compatible Middle count, LMION L12 policy)
```

When the L12 safety option is lifted, the maximum is limited only by compatible pieces and valid world geometry.

### Anchor semantics

Use the cursor square as the **START position** regardless of whether the inventory `Place` command was invoked on a Start, Middle, or End parcel.

This matches vanilla's existing multisprite behavior conceptually: selecting any member is normalized to one assembly anchor. It also avoids inventing an identity for repeated Middle parcels.

Geometry from the START anchor:

```text
N: position i -> x + (i-1), y
W: position i -> x, y - (i-1)
```

## Width keys and rotation

Do not add another global key listener for the active placement cursor.

Override the dedicated cursor's `rotateKey(key)`:

```text
configured Garage Width - -> selectedLength - 1
configured Garage Width + -> selectedLength + 1
otherwise                  -> ISBuildingObject.rotateKey(self, key)
```

This lets Project Zomboid's existing building-cursor key routing deliver both normal rotation and LMION width controls to the active drag object.

The key definitions remain registered through ModOptions, with NumPad `-` / `+` as defaults.

## Validation and rendering

Build one explicit placement plan:

```text
START + MIDDLE * (L-2) + END
```

Each planned member contains:

```text
role
same-family parcel item
source inventory/floor
world square
closed sprite for current N/W facing
```

For validity, create per-segment MoveProps and temporarily treat them as single-sprite (`isMultiSprite=false`) before calling the existing internal placement validation. This deliberately reuses vanilla single-object collision/tool/skill rules without reintroducing fixed SpriteGrid geometry.

Render the same plan directly. The complete footprint is green only when every member is valid; otherwise render the complete selected footprint red.

The ghost length must therefore be exactly the length the action will place.

## Placement completion

On confirmation:

1. resolve/freeze the selected plan;
2. use single-segment MoveProps to walk/equip the normal garage placement tool;
3. queue the dedicated LMION garage placement action;
4. revalidate target/pieces at action time;
5. call `placeMoveableInternal()` once per member with `isMultiSprite=false`;
6. existing garage Moveables/Core hooks restore per-parcel durability and canonicalize to `IsoDoor`;
7. consume only the Start, selected number of Middles, and End used by that plan;
8. mark affected squares as construction and end the cursor.

If physical placement unexpectedly fails partway through after pre-validation, the action should fail closed and clean up any members placed by that same attempt rather than consume parcels for a partial garage.

## Scope of the remaining vanilla Moveables integration

Keep vanilla Moveables for garage **pickup** because actual-chain dismantling already works at runtime.

The synthetic historical L3 garage SpriteGrid can remain only where it is still required for Moveables discovery/pickup/item-facing metadata. It must no longer define reinstallation geometry.

As a follow-up hardening step, garage parcels should be filtered from vanilla Moveables' generic Place inventory list so users cannot accidentally enter the obsolete fixed-L3 placement path through the furniture cursor instead of the inventory `Place` command.

## First validation after implementation

Use a freshly picked-up same-family garage after the new cursor is installed.

Test in this order:

```text
L2  -> Start + End
L3  -> Start + 1 Mid + End
L5  -> Start + 3 Mid + End
L12 -> Start + 10 Mid + End
```

For each relevant length:

- ghost length matches selected length;
- `+/-` visibly resizes within available-piece/policy bounds;
- Rotate Building changes N/W without changing length;
- red/green validity covers the whole footprint;
- only selected parcels are consumed;
- extra Middle parcels remain;
- final members are `IsoDoor`;
- PV are preserved per physical parcel;
- native synchronized open/close works after placement.

Only after this single-player path is stable should Build variable-width implementation begin, using the separate FaceInfo-proxy architecture.
