# Variable-width garage Build prototype

Status: **first implementation prepared for runtime validation; not yet gameplay-validated.**

This note records the implementation choices for LMION_Build variable-width garage construction so failed/rejected paths are not rediscovered later. It does not replace the runtime-validated Pickup notes.

## User contract implemented

Garage width is selected in the Construction recipe panel before world placement:

```text
Longueur :  [ - ]  3  [ + ]
```

The selector occupies the B42 `ISBuildRecipePanel` filler row between the recipe header/preview and `Objets requis`.

Rules:

- garage recipes only;
- default L3;
- minimum L2;
- LMION safety maximum L12 while enabled;
- no LMION numeric maximum when the Core unlimited-width option is enabled;
- requirement display updates with the selected length;
- the selected length is frozen onto the build cursor when Construction starts;
- no width-changing key is added to world placement.

## Exact cost model

All garage recipes keep one Welding Mask (`mode:keep`).

Solid garage families:

```text
SmallSheetMetal = 3 * L
MetalBar        = 1 * L
Hinge           = 2 * L
```

Glazed garage families (`RedWindowGarageDoor`, `RollingWindowGarageDoor`):

```text
SmallSheetMetal = 2 * L
GlassPanel      = 1 * L
MetalBar        = 1 * L
Hinge           = 2 * L
```

Drainable welding resources use stepped, capped costs:

```text
BlowTorch uses   = min(ceil(L / 3), 10)
WeldingRods uses = min(2 * ceil(L / 3), 20)
```

The caps represent one full BlowTorch / one full WeldingRods item in the current B42 data. They are recipe-consumption caps, not garage-width caps. Physical materials continue scaling beyond L30 if the LMION width safety limit is lifted.

This cost model is explicit LMION gameplay logic. It is **not** tied to MetalWelding level or any skill-based recipe reduction system.

## Static L2 base + exact variable delta

B42 `InputScript` amounts are shared recipe data and should not be mutated globally per player/cursor. The prototype therefore converts each garage CraftRecipe to its exact L2 baseline.

Solid L2:

```text
1 WeldingMask keep
1 BlowTorch use
6 SmallSheetMetal
2 MetalBar
4 Hinge
2 WeldingRods uses
```

Glazed L2:

```text
1 WeldingMask keep
1 BlowTorch use
4 SmallSheetMetal
2 GlassPanel
2 MetalBar
4 Hinge
2 WeldingRods uses
```

Construction then follows this authority split:

```text
BuildLogic / vanilla
-> validates + consumes the static L2 base

LMION_Build
-> separately validates the complete selected-width cost
-> after vanilla base consumption succeeds, consumes only L2 -> selected-width delta
```

The delta is consumed once before the first physical garage member is created. A fresh full-cost preflight runs on the authoritative create path before vanilla consumption begins.

Non-drainable delta materials are also added to the normal `need:Base.*` build metadata after vanilla records the L2 base. BlowTorch and WeldingRods remain excluded from that metadata, matching their existing `DontRecordInput` recipe flags.

## Resource-source matching

The LMION full-cost check scans:

- player inventory;
- the containers supplied by the active BuildLogic;
- nearby ground items from vanilla `ISBuildIsoEntity.GetAllGroundItemsForPlayer()`.

Items are deduplicated before counting. This avoids rejecting a garage merely because its extra materials are in a source vanilla Construction already exposes.

Multiplayer container-removal/synchronization still requires runtime testing; this prototype should not be described as MP-validated yet.

## Variable geometry: per-cursor FaceInfo proxy

The shared SpriteConfig remains the historical/canonical L3 role declaration. LMION does not mutate it globally.

For each garage build cursor, `ISBuildIsoEntity:getFace()` exposes a proxy with the selected length. The proxy delegates the full public `SpriteConfigManager.FaceInfo` API and remaps coordinates as:

```text
position 0       -> original START tile
interior         -> original MIDDLE tile
position L - 1   -> original END tile
```

The mapping works on the source face's active width/height axis, so the existing N/W SpriteConfig ordering remains authoritative.

Vanilla `ISBuildIsoEntity` then uses that proxy normally for:

- ghost geometry;
- `isValid()` square traversal;
- occupied tiles;
- physical member creation.

Core still owns garage `IsoDoor` canonicalization through `LMION.Doors.onCreateGarage`; Build only changes the per-construction geometry seen by vanilla.

## Multiplayer width transport discovery

B42's native `BuildAction` does not blindly serialize arbitrary Lua cursor fields. JAR inspection showed that it reconstructs a cursor from its Lua `new()` constructor and serializes matching constructor parameters.

For that reason LMION wraps the shared `ISBuildIsoEntity.new` signature with an optional:

```text
lmionGarageLength
```

The cursor table carries the same field. This places the frozen selected width in the native Build action payload and lets the server reconstruct the same geometry without global/client-only state.

The constructor/getFace/full-cost cursor hooks therefore live in shared Build Lua, not only in the server BuildHook.

## Rejected/avoided paths

Do not revive these without new evidence:

1. **Globally mutate SpriteConfig dimensions per selection.** Unsafe for simultaneous players/cursors and unnecessary.
2. **Change width during the world ghost.** It would allow material cost to change after the player last reviewed it.
3. **Use a generic variable-input ratio for the final cost model.** A single common ratio does not naturally express LMION's stepped/capped BlowTorch and WeldingRods formulas alongside linear physical materials.
4. **Treat variable recipe amount as a skill discount.** The implemented garage costs are independent from skill; skill remains vanilla progression/eligibility only.
5. **Depend on LMION_Pickup.** Build consumes Core garage semantics directly and remains addon-independent.

## First runtime validation matrix

A full game restart is required because `media/scripts` recipes and shared Lua load order changed.

Minimum first pass:

1. White Garage Door recipe shows the selector in the intended empty panel and defaults to L3.
2. Solid costs display correctly:
   - L2 -> sheets 6, bars 2, hinges 4, torch 1 use, rods 2 uses;
   - L3 -> sheets 9, bars 3, hinges 6, torch 1 use, rods 2 uses;
   - L5 -> sheets 15, bars 5, hinges 10, torch 2 uses, rods 4 uses.
3. Missing selected-width materials disable/refuse Build even when the L2 base is affordable.
4. L2, L3, L5 and L12 ghosts have the selected frozen width in both N/W orientations.
5. Construction consumes exactly the displayed total.
6. Resulting members are canonical `IsoDoor` and resume synchronized native garage opening/closing.
7. One glazed family validates its sheet/glass scaling.
8. With the L12 safety limit lifted, optionally test L13+ separately; do not infer an engine maximum from this prototype.

Only after these pass should the authoritative handoff change the status from prototype/awaiting-validation to validated Build behavior.
