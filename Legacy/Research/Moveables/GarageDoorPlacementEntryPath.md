# Garage-door placement entry path

Status: **current runtime contract validated on B42.20.4. Inventory right-click `Place` uses LMION's dedicated variable-width garage cursor. The persistent Moveables sidebar `Place` intentionally remains vanilla and therefore places the historical L3 garage. This asymmetry is deliberate.**

This note records the two independent Project Zomboid placement entry paths and the LMION decision after tracing and testing both.

## Current contract

```text
Inventory parcel -> right-click -> Place
-> exact InventoryItem is known
-> LMION intercepts before vanilla fixed-SpriteGrid normalization
-> dedicated LMION garage cursor/action
-> variable Start + Middle*N + End placement

Left Moveables sidebar -> Place
-> generic vanilla Moveables Place mode
-> inventory catalogue/objectIndex selection
-> historical synthetic L3 SpriteGrid
-> vanilla L3 garage placement
```

Both behaviors are supported. Do not try to make the sidebar route variable unless a future feature explicitly justifies the additional engine coupling.

## Inventory right-click entry point

`ISMoveableContextMenu.createMenu()` exposes the normal inventory `Place` command for a Moveable item. Its callback receives the exact clicked item:

```lua
ISMoveableContextMenu.openMovableCursor(item, playerObj)
```

Vanilla normally creates `ISMoveableCursor`, enters `place` mode and calls `tryInitialItem(item)`.

The important property of this path is timing: the exact `InventoryItem` is available **before** vanilla groups multisprite Moveables by their `IsoSpriteGrid` anchor.

LMION therefore wraps only this narrow entry point:

```text
ordinary Moveable item
-> unchanged vanilla openMovableCursor()

recognized LMION garage Start/Middle/End parcel
-> GarageDoor.openPlacementCursor()
-> LMION dedicated variable-width cursor
```

The dedicated cursor owns variable garage geometry. Vanilla `ISMoveableCursor` is never created for that garage placement attempt.

## Loading-order rule

The inventory UI lives in the client Lua tree while the dedicated garage cursor lives in the gameplay/server BuildingObjects tree.

Do **not** force-load the gameplay cursor from the early client ModOptions/UI loader.

The wrapper may be installed before `GarageDoor.openPlacementCursor` exists. Installation and click-time requirements are intentionally different:

```text
early client/game start
-> ISMoveableContextMenu exists
-> LMION GarageDoor table exists
-> install wrapper

later gameplay/server load
-> GarageDoorCursor.lua attaches GarageDoor.openPlacementCursor

actual click
-> wrapper identifies garage parcel
-> if openPlacementCursor exists, hand off to LMION
-> otherwise preserve vanilla behavior
```

Durable rule:

> **A callback supplied by a later Lua tree must not gate installation of the wrapper that will call it later.**

The current implementation installs the inventory handoff at `OnGameStart` and resolves `openPlacementCursor` when the user clicks.

## Persistent Moveables sidebar entry point

The left-side `Place` icon has a different meaning. It does not mean "place this item". It means "enter the global Moveables Place mode".

Conceptually:

```text
Moveables sidebar -> Place
-> create/reuse ISMoveableCursor
-> cursor:setMoveableMode("place")
-> later getInventoryObjectList()
-> objectIndex selects one catalogue entry
```

There is no explicit `InventoryItem` argument at the button boundary.

During catalogue construction, vanilla normalizes multisprite inventory items through their SpriteGrid anchor. For LMION garage parcels, the retained synthetic historical grid is L3 because that grid is still useful for vanilla Moveables discovery/pickup/item-facing behavior.

Therefore the sidebar path naturally becomes:

```text
garage parcel(s)
-> generic Moveables catalogue
-> synthetic L3 SpriteGrid anchor
-> fixed L3 ghost/validation/action
```

This is now intentional behavior, not an outstanding defect.

## Why LMION does not hand off the sidebar

A previous experiment attempted to inspect the generic Moveables cursor after the sidebar callback and replace it with the dedicated garage cursor. That approach was reverted.

The reasons are architectural:

1. immediately after the sidebar click, the current inventory entry may not yet be resolved;
2. the real selection happens later inside the generic cursor hot path;
3. by then vanilla has already normalized multisprite identity through the SpriteGrid anchor;
4. making the handoff reliable would require hooking central `ISMoveableCursor` selection/validation/cycling behavior;
5. the sidebar is also a Moveables catalogue, so cycling between furniture and garages would require an additional state machine;
6. the benefit is only an alternate convenience entry point, while the inventory route already provides an exact, stable item-explicit boundary.

Rejected unless new evidence/requirements justify it:

- global `ISMoveableCursor:isValid()` handoff hooks;
- global rotate/TAB hooks to detect/cycle garages;
- a hybrid garage-aware replacement for the whole Moveables cursor;
- treating the sidebar's L3 result as a bug that must be made variable.

## Why the historical L3 SpriteGrid remains

The synthetic L3 SpriteGrid is no longer LMION's variable reinstallation geometry.

Its remaining purpose is compatibility with vanilla Moveables discovery/pickup/item-facing semantics.

Current separation:

```text
Core topology
-> START + zero-or-more MIDDLE + END

Pickup variable reinstallation
-> dedicated explicit placement plan
-> independent from IsoSpriteGrid geometry

Vanilla Moveables sidebar Place
-> historical synthetic L3 SpriteGrid
-> fixed L3 placement by design
```

Do not globally resize or mutate the shared SpriteGrid to represent the selected LMION width.

## Dedicated variable-placement action boundary

Vanilla `ISMoveablesAction` also normalizes a Moveable back through its SpriteGrid before final placement. For that reason the dedicated variable cursor cannot safely render variable geometry and then fall back to the normal multisprite action for completion.

LMION instead builds one explicit plan:

```text
START + MIDDLE * (L-2) + END
```

Each planned physical member is treated as a single segment for Moveables validation/placement. The action consumes only the parcels selected by that plan and leaves the historical L3 grid out of variable geometry.

## Runtime-validated variable inventory path

Validated behavior includes:

- inventory right-click `Place` opens the dedicated LMION cursor;
- width can be changed with the configured garage width keys;
- N/W rotation works;
- physical placement works for variable lengths;
- exact per-segment durability is preserved;
- the resulting garage resumes native synchronized behavior;
- the fixed L3 vanilla cursor is not the owner of this inventory placement path.

The user's runtime tests are authoritative for this contract.

## Addon / future-development contract

Safe assumptions:

- garage semantic roles belong to Core (`START`, repeatable `MIDDLE`, `END`);
- variable Pickup reinstallation belongs to `LMION_Pickup` and is item-explicit from inventory `Place`;
- the persistent sidebar remains vanilla unless a future dedicated integration is deliberately designed;
- Build and Pickup must remain independent and consume Core semantics rather than each other;
- the synthetic L3 SpriteGrid may exist even though variable placement geometry is not L3.

Do not infer that two UI controls labelled `Place` are equivalent engine entry points. They are not.
