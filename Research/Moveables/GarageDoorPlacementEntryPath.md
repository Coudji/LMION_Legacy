# Garage-door placement entry path

Status: **B42 Moveables placement paths traced. Dedicated LMION garage cursor/action is implemented. Inventory `Place` was runtime-validated before the sidebar experiment; a loading-order regression was reproduced and its exact install-time cause has now been corrected. Sidebar `Place` remains pending runtime validation.**

This note complements `GarageDoorVariableWidthPlacementResearch.md` and records the exact integration points chosen after the fixed-L3 Moveables placement experiment was rejected.

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

LMION wraps `openMovableCursor()` only for recognized garage parcel item types:

```text
ordinary Moveable item
-> unchanged vanilla ISMoveableCursor

LMION garage Start/Middle/End parcel
-> LMION garage placement cursor
```

The user-facing inventory command remains the normal `Place` command.

## Loading-order rule

The inventory UI lives in the client Lua tree while `GarageDoorCursor.lua` lives in the gameplay/server BuildingObjects tree.

Do **not** force-load the dedicated garage cursor from the early client ModOptions file with:

```lua
require "LMION/Pickup/GarageDoorCursor"
```

Also do **not** require `GarageDoor.openPlacementCursor` to already exist before installing the UI wrapper.

Correct lifecycle:

```text
early client load
-> register ModOptions keys
-> install wrapper when vanilla UI entry point + LMION.Pickup.GarageDoor table exist

later gameplay/server load
-> GarageDoorCursor.lua attaches GarageDoor.openPlacementCursor

actual player click
-> wrapper checks whether openPlacementCursor now exists
-> if yes and item is a garage parcel: open dedicated cursor
-> otherwise preserve vanilla behavior
```

This distinction matters because `GarageDoor.openPlacementCursor` is defined by `server/LMION/Pickup/GarageDoorCursor.lua` and may legitimately be attached **after** the client-side wrapper installation attempt.

### Reproduced regression

Commit `0a592dcead255179ce650c95c0c7d4cfd6aa8b6e` introduced early client requires and global cursor hooks. Runtime result on B42.20.4:

```text
sidebar Place
-> fixed L3 ghost, red

inventory right-click Place
-> also enters generic Place mode
-> sidebar Place icon visibly becomes active
-> fixed L3 ghost instead of dedicated variable cursor
```

Commit `a2e2cda1fc469e44d2b01e4fc04f7d46a6ba8785` removed the early cross-tree require and global rotate/TAB hooks, but still contained one subtle install-time bug:

```lua
if type(GarageDoor.openPlacementCursor) ~= "function" then
    return
end
```

If the client installer ran before `GarageDoorCursor.lua` attached that method, the function returned without installing **any** inventory/sidebar wrapper. `Events.OnGameStart` did not guarantee the needed method was already attached in the observed runtime ordering, so inventory `Place` still fell directly into vanilla `ISMoveableCursor`.

The user's screenshot provided direct confirmation: placement was initiated from the inventory, yet the persistent left-side `Place` icon was active. That icon is vanilla Moveables mode state and therefore proves the generic `ISMoveableCursor` owned the drag cursor.

Corrected in commit `b8d21eef9136d68e5a4a0010aee81dbd9099c59a`:

- install the wrapper without requiring `openPlacementCursor` to exist yet;
- resolve/check `openPlacementCursor` only when the player actually clicks `Place`;
- keep the early client -> server `require` rejected;
- keep global `ISMoveableCursor.rotateKey` / TAB interception rejected.

Rule to retain:

> **Install-time prerequisites and click-time prerequisites are not the same thing. A callback supplied by a later Lua tree must not gate installation of the wrapper that will call it later.**

## Persistent Moveables sidebar entry point

Runtime testing after the first dedicated-cursor implementation established a second independent placement entry path:

```text
inventory right-click Place
-> correct variable LMION ghost

left sidebar Moveables -> Place
-> fixed vanilla L3 ghost
```

The relevant vanilla class is `ISEquippedItem.lua`.

`ISMoveablesIconPopup:onMouseUp()` does:

```lua
if not cursor then
    cursor = ISMoveableCursor:new(self.owner.chr)
    getCell():setDrag(cursor, cursor.player)
end
cursor:setMoveableMode(mode)
```

For the `Place` icon, `mode == "place"`.

Unlike the inventory context menu, this path has **no explicit item argument**. The generic cursor selects an inventory entry through `getInventoryObjectList()` and `objectIndex`.

Therefore LMION cannot use the same pre-cursor item-explicit interception as the inventory menu. The selected-item handoff is:

```text
Moveables sidebar -> Place
-> vanilla creates/reuses ISMoveableCursor
-> vanilla switches to Place
-> vanilla inventory selection resolves objectIndex
-> LMION inspects exactly that selected item
-> garage parcel? replace drag with LMION garage cursor
-> ordinary furniture? leave vanilla cursor untouched
```

The handoff runs immediately after the vanilla sidebar popup callback.

Cycling from ordinary furniture into a garage is **not currently part of the supported contract**. The earlier global rotate/TAB interception was deliberately removed because it risked the primary inventory path.

## Why interception must happen before variable placement logic

Once vanilla `ISMoveableCursor` actually handles a garage as a placement assembly, fixed SpriteGrid semantics are structural:

- `getInventoryObjectList()` collapses multisprite items to `spriteGrid:getAnchorSprite()`;
- `isValid()` calls multisprite `canPlaceMoveable()`;
- `renderSpriteGrid()` loops fixed grid width/height;
- rotation rebuilds MoveProps from fixed faces;
- the cursor creates `ISMoveablesAction` with the fixed MoveProps contract.

A variable garage therefore must leave generic Place mode as soon as it is identified as the selected inventory entry.

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

LMION's garage cursor overrides the actual footprint-specific methods instead of altering global sprite data.

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

No separate gameplay key listener is required for the dedicated cursor itself.

Override its `rotateKey(key)`:

```text
configured Garage Width - -> selectedLength - 1
configured Garage Width + -> selectedLength + 1
Rotate Building            -> N/W toggle
```

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

## Runtime validation status

Validated on B42.20.4 before the sidebar experiment:

- inventory right-click `Place` reached the LMION dedicated cursor;
- variable ghost length changed correctly with configured width keys;
- the fixed-L3 result was absent on that path.

Regression reproduced after the sidebar/loading experiments:

- sidebar produced fixed L3/red;
- inventory also regressed into vanilla Place mode;
- sidebar Place icon visibly activated from inventory placement.

Exact install-time cause identified and corrected in `b8d21eef9136d68e5a4a0010aee81dbd9099c59a`.

Runtime validation after this correction is pending.

## Next validation

After a full game restart with compatible same-family parcels available:

1. inventory right-click `Place`: confirm the dedicated resizable ghost returns and the sidebar Place icon does **not** become the owner of placement mode;
2. persistent Moveables sidebar `Place`: if its initially selected inventory entry is a garage parcel, confirm transfer to the same dedicated resizable ghost;
3. test `+/-` and Rotate Building on each successful dedicated-cursor entry path;
4. do **not** test cycle-to-garage as a required feature yet;
5. only once both primary entry paths show the same correct ghost, proceed to physical placement/consumption/PV/`IsoDoor` tests.
