# LMION Pickup rewrite

Status: first simple 1x1 vertical slice, corrected to the proven Legacy placement-loading pattern on 2026-08-31.

## Goal

Pickup is a mechanic addon. It does not own the opening catalog and it does not contain concrete door profiles.

The normal flow is:

```text
world object
-> Core identifies the effective opening definition
-> Pickup reads pickup/replacement/geometry data
-> vanilla Moveables supplies pickup/item/tool plumbing
-> a dedicated LMION placement cursor handles replacement UX
-> Core finalizes the reinstalled door
```

Pickup knows **how to transport an opening**, while Core knows **what that opening is**.

## First supported slice

The initial implementation deliberately supports only simple 1x1 definitions with:

- one `entity`;
- no `topology` yet;
- exact `geometry.N/W.closed/open`;
- pickup package count = 1;
- replacement package count = 1;
- no replacement materials;
- pickup break chance = 0;
- frame = `standard` or `false`;
- a tool/skill combination understood by the current adapter.

This is capability detection, not a list of door IDs.

Current pilots:

```text
Doors.Wood.WhitePanelDoor
Doors.Wood.WhiteRestroomStallDoor
```

Adding exact geometry to another compatible definition should make it available without Pickup code changes.

## Generic transport parcel

Pickup uses one PZ item type:

```text
Base.LMION_OpeningParcel
```

Its world sprite is the exact closed sprite of the transported definition/facing. ModData stores the LMION definition identity and primitive door state.

Vanilla `ReadFromWorldSprite()` may overwrite item weight, so after item creation Pickup synchronizes both:

```lua
item:setActualWeight(weight)
item:setWeight(weight)
```

## World-object identity

Pickup does not identify the selected world door from its sprite. It asks Core:

```lua
LMION.getDefinitionIdForObject(object)
```

The sprite map in Pickup exists only for vanilla Moveables integration and exact geometry/preview selection.

## Placement and R rotation

The first attempt tried to patch vanilla `ISMoveableCursor.rotateMouse/rotateKey` from client startup. That was the wrong integration point: `BuildingObjects/ISMoveableCursor` belongs to the gameplay/server tree and can be unavailable during early client loading.

Legacy garages already solved this exact boundary. The rewrite now copies that proven architecture:

```text
server/LMION/Pickup/SimpleDoorCursor.lua
    -> dedicated ISBuildingObject cursor
    -> rotateMouse does nothing
    -> Rotate building key toggles N/W

client/LMION/Pickup/PlacementHandoff.lua
    -> never requires the server cursor
    -> waits for OnGameStart
    -> intercepts ISMoveableContextMenu.openMovableCursor
    -> sends LMION parcels to the dedicated cursor
    -> leaves every non-LMION item on vanilla behavior
```

There is no dedicated client/server entrypoint just for the cursor; PZ autoexecutes normal files in their own scopes.

This is intentionally the same user-facing behavior as Legacy garages:

```text
mouse drag -> no orientation change
R / Rotate building -> N <-> W
```

## Core runtime boundary

`Core/DoorRuntime.lua` owns physical rules that should not live in Pickup:

- recognize IsoDoor and door-like IsoThumpable inputs;
- capture/restore health, effective max health and basic lock state;
- verify frame/door occupancy for N/W placement;
- canonicalize reinstalled LMION doors to IsoDoor;
- install exact closed/open sprites after placement.

## First live test

Enable `LMION_Core` + `LMION_Pickup`.

Expected boot summary:

```text
[LMION:Pickup] simple 1x1 registry ready: 2 definitions, 8 sprites
```

When the game world starts, the client handoff should also report once:

```text
[LMION:Pickup] simple-door Place handoff installed
```

Recommended first target is `Base.WhiteRestroomStallDoor` because its pickup requirement is Woodwork 0 + screwdriver.

Test sequence:

1. enter vanilla Moveables Pickup mode;
2. pick the restroom stall door up;
3. verify one generic LMION parcel and the expected weight;
4. choose Place from the parcel;
5. verify the dedicated preview appears;
6. verify mouse dragging does not rotate it;
7. press `R` and confirm N/W alternation;
8. place into a valid matching frame;
9. verify the result is a functioning door and retained health.

Fix real B42 integration failures before adding more geometry, paired doors, large gates or garages.
