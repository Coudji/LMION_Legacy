# LMION Pickup rewrite

Status: first simple 1x1 vertical slice, 2026-08-30.

## Goal

Pickup is a mechanic addon. It does not own the opening catalog and it does not contain concrete door profiles.

The normal flow is:

```text
world object
-> Core identifies the effective opening definition
-> Pickup reads pickup/replacement/geometry data
-> vanilla Moveables performs the timed action and inventory integration
-> Core finalizes the reinstalled door
```

Pickup therefore knows **how to transport an opening**, while Core knows **what that opening is**.

## First supported slice

The initial implementation deliberately supports only simple 1x1 definitions that satisfy all of these conditions:

- one `entity`;
- no `topology` yet;
- exact `geometry.N/W.closed/open`;
- pickup package count = 1;
- replacement package count = 1;
- no replacement materials;
- pickup break chance = 0;
- frame is `standard` or `false`;
- current tool/skill adapter understands the declared semantic tools.

This is capability detection, not a list of door IDs.

At the first commit two built-in definitions satisfy the contract:

```text
Doors.Wood.WhitePanelDoor
Doors.Wood.WhiteRestroomStallDoor
```

The restroom stall was given exact geometry in the same pass so a skill-0 pickup exists for easy live testing.

Adding exact geometry to another compatible definition should make it available to Pickup without changing Pickup code.

## Generic transport parcel

The rewrite uses one PZ item type:

```text
Base.LMION_OpeningParcel
```

The parcel's world sprite remains the exact closed sprite of the transported definition/facing. Its modData stores the LMION definition identity and primitive door state.

This avoids the old architecture where Pickup needed one item script per concrete door. A third-party definition can therefore use the same transport mechanic without adding a Pickup-owned item profile.

Vanilla `ReadFromWorldSprite()` may overwrite the item weight. The old Pickup already proved this behavior, so after vanilla item creation the rewrite explicitly synchronizes both:

```lua
item:setActualWeight(weight)
item:setWeight(weight)
```

## World-object identity

Pickup does not identify a door from its sprite.

For the selected object it asks Core:

```lua
LMION.getDefinitionIdForObject(object)
```

The sprite map inside Pickup has a different purpose: integrating exact known geometry with vanilla `ISMoveableSpriteProps` and the placement cursor.

A sprite candidate is only pickable when the actual world object resolves through Core to the same definition.

## Tool adapter

Core definitions keep semantic physical tools and explicit governing skills separate.

The first Pickup adapter translates the combinations already validated in Legacy:

```text
base:screwdriver + Woodwork      -> vanilla Screwdriver
base:crowbar     + Woodwork      -> vanilla Crowbar
base:hammer      + Woodwork      -> vanilla Hammer

base:screwdriver + MetalWelding  -> LMIONMetalScrewdriver
base:crowbar     + MetalWelding  -> LMIONMetalCrowbar
base:hammer      + MetalWelding  -> LMIONMetalHammer
```

The metal Moveables ToolDefinitions still use the real physical tools but change the governing perk to MetalWelding.

Unsupported combinations are not guessed.

## Placement and R rotation

The user-facing placement rule is intentionally different from vanilla Moveables.

For an LMION parcel in Place mode:

- mouse dragging does not choose orientation;
- `R` / the configured `Rotate building` key toggles N/W;
- exact Core geometry supplies the target closed sprite;
- the cursor still uses vanilla Moveables rendering, timed action and inventory flow.

Pickup exposes the two faces to vanilla as:

```lua
{ N, W, N, W }
```

The cursor hook directly toggles the visible N/W facing, so it does not inherit vanilla's normal behavior where the rotate key cycles inventory objects.

This keeps the more pleasant garage-style placement UX without introducing a separate custom cursor for ordinary 1x1 doors.

## Core runtime boundary added for Pickup

`Core/DoorRuntime.lua` now owns the physical rules that should not belong to Pickup:

- recognize IsoDoor and door-like IsoThumpable inputs;
- capture/restore health, effective max health and basic lock state;
- verify frame/door occupancy for N/W placement;
- canonicalize reinstalled LMION doors to IsoDoor;
- explicitly install exact closed/open sprites after placement.

This continues the architectural rule:

> Core owns opening identity/state contracts; Pickup owns the transport mechanic.

## First live test

Enable both Workshop mods:

```text
LMION_Core
LMION_Pickup
```

Expected boot summary after the existing Core diagnostics:

```text
[LMION:Pickup] simple 1x1 registry ready: 2 definitions, 8 sprites
```

Recommended easiest test target:

```text
Base.WhiteRestroomStallDoor
```

because its current pickup requirement is Woodwork 0 + screwdriver.

Test sequence:

1. enter vanilla Moveables Pickup mode;
2. select the restroom stall door;
3. verify screwdriver/weight information and pick it up;
4. enter Place mode;
5. verify mouse dragging does not rotate it;
6. press `R` and confirm the preview alternates N/W;
7. place it into a valid matching door frame;
8. verify the resulting object is a functioning door and retained health.

Then repeat with `WhitePanelDoor` when the character meets Woodwork 3.

The next step is to fix any real B42 integration issue exposed by this test before migrating more geometry or adding paired/large/garage topology.
