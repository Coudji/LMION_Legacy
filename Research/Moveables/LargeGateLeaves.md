# Large-gate leaf Moveables architecture

Status: **B42.20.3 bytecode/API verified + vanilla-Lua inspected + runtime validated**

Scope: current validated proof-of-concept for `Base.DoubleWireGate` / Large Chain-Link Gate.

This note records the full chain of discoveries behind LMION's two-segment leaf pickup/replacement system. The final code is relatively compact; the engine constraints that produced it are not.

## Goal

Treat one physical large-gate **leaf** as the gameplay transport/construction unit while preserving vanilla DoubleDoor behavior.

For `DoubleWireGate`, one complete portal contains four physical `IsoDoor` members. LMION exposes it as two independently handled leaves, each containing two physical members.

Transport representation:

```text
one leaf
  -> parcel (1/2)
  -> parcel (2/2)
```

Replacement consumes both parcels in one action and recreates both physical `IsoDoor` members.

## Why not one item for the whole four-member portal

Construction and gameplay ownership are leaf-based. The two leaves can be built/recovered independently while vanilla still synchronizes them when correctly assembled.

Representing the entire portal as one `1/4..4/4` unit would couple two independently meaningful leaves and make partial removal/reinstallation unnecessarily awkward.

## DoubleDoor identity comes from sprite properties

B42.20.3 `IsoDoor.getDoubleDoorIndex(IsoObject)` does not derive the member number from object position alone. It reads the sprite/property value `DoubleDoor` (engine property type `DOUBLE_DOOR`).

Validated bytecode behavior:

```text
closed property 1..4 -> logical index 1..4
open property   5..8 -> logical index (value - 4)
```

So open and closed artwork map back to the same logical four members.

## Linked-member lookup is geometry/index based

`IsoDoor.getDoubleDoorObject(source, requestedIndex)`:

- resolves the source logical index;
- checks source orientation (`north`) and open state;
- chooses one of the engine's hardcoded DoubleDoor offset tables;
- computes the requested member square;
- searches that square for the corresponding door/thumpable member.

Matching GameEntity identity, LMION profile or material family is not part of that core lookup.

This is why separately scripted LMION left/right leaves can still resume vanilla synchronized opening when their members carry the correct DoubleDoor sprite indices and geometry.

## Validated Chain-Link sprite/member mapping

### Left leaf

```text
Part1 N = fixtures_doors_fences_01_66
Part2 N = fixtures_doors_fences_01_67

Part1 W = fixtures_doors_fences_01_65
Part2 W = fixtures_doors_fences_01_64
```

Logical DoubleDoor indices:

```text
N: Part1 = 1, Part2 = 2
W: Part1 = 4, Part2 = 3
```

### Right leaf

```text
Part1 N = fixtures_doors_fences_01_74
Part2 N = fixtures_doors_fences_01_75

Part1 W = fixtures_doors_fences_01_73
Part2 W = fixtures_doors_fences_01_72
```

Logical DoubleDoor indices:

```text
N: Part1 = 3, Part2 = 4
W: Part1 = 2, Part2 = 1
```

### Placement geometry

Validated closed-leaf geometry is:

```text
N facing: Part2 is one square east of Part1
W facing: Part2 is one square south of Part1
```

The W mapping is easy to get wrong because the logical DoubleDoor indices progress in the opposite-looking order from the original fixed-pair assumption.

## Failed assumption: fixed leaf index pairs

An early implementation treated the leaves as permanently:

```text
left  = {1,2}
right = {3,4}
```

for every facing.

That produced two adjacent doors that could look plausible after rotation but were not the correct logical DoubleDoor pair. Runtime diagnostics showed missing partners and unexpected indices.

The fix was to make the index list facing-dependent, as documented above.

Do not simplify the table back to fixed pairs.

## Why a runtime `IsoSpriteGrid` was added

Generic vanilla Moveables expects real multisprite furniture to expose an `IsoSpriteGrid`. The original DoubleWireGate closed sprites do not provide the grid metadata needed for the desired two-tile leaf behavior.

Without a grid, Moveables sees the recovered parts as independent one-square objects. The preview/placement UX then operates one parcel at a time.

B42.20.3 exposes the required runtime API:

```text
IsoSpriteGrid.new(width, height)
grid:setSprite(x, y, sprite)
grid:validate()
IsoSprite:setSpriteGrid(grid)
IsoSprite:getSpriteGrid()
```

LMION creates four grids:

```text
left N  = 2x1
left W  = 1x2
right N = 2x1
right W = 1x2
```

with logical Part1 then Part2 in spatial order.

These grids are attached to the **global `IsoSprite` objects**, not individual world `IsoDoor` instances.

## Critical discovery: initial Lua-load installation is not enough

The first runtime SpriteGrid prototype installed successfully during Lua load, but a cold-start runtime test still behaved as single-tile Moveables.

Logs showed the grid installation happened before normal tile-definition loading. Reinstalling the same grids from:

```text
Events.OnLoadedTileDefinitions
```

changed behavior immediately:

- targeting highlighted the whole leaf;
- the two parcels grouped like a normal vanilla multisprite object;
- the preview understood the complete two-square footprint.

Validated pattern:

```text
install at Lua load                -> hot reload / already-loaded session
install again OnLoadedTileDefinitions -> reliable cold start
```

The apparent duplicate initialization is intentional.

## Why pickup still creates two parcels

Once the global sprites have SpriteGrids, vanilla Moveables naturally treats them as a multisprite logical object. LMION still wants one inventory parcel per physical leaf segment.

During actual pickup, LMION:

1. resolves the selected physical `IsoDoor`;
2. uses facing-specific DoubleDoor indices to resolve both members of that leaf;
3. validates both members;
4. creates per-member `ISMoveableSpriteProps`;
5. temporarily sets each member's `isMultiSprite = false`;
6. calls vanilla `pickUpMoveableInternal()` separately for each member.

This intentionally separates **world removal/parcel creation** from the **multisprite inventory/preview identity** provided by the global SpriteGrid.

The result is two parcels that vanilla can still group as one logical 2-tile Moveables object later.

## Failed approach: rely completely on vanilla multisprite placement

After adding the runtime SpriteGrid, the first attempt let generic vanilla placement reconstruct the leaf.

Original-facing placement improved, but rotation was wrong. Vanilla Moveables canonicalizes multisprite placement around its grid-anchor assumptions, which fit ordinary furniture SpriteGrids but did not preserve the DoubleDoor member semantics LMION needed across N/W rotation.

A later attempt tried merely to preserve logical Part1/Part2 across facing changes; runtime behavior did not change enough to solve the issue.

Conclusion: **having a valid SpriteGrid does not imply generic vanilla multisprite placement is correct for an engine-authored DoubleDoor leaf**.

## Validated replacement path: explicit physical placement

LMION keeps the SpriteGrid for Moveables semantics but takes over final reconstruction.

The placement hook:

```text
selected parcel/current facing
    -> resolve leaf specification
    -> require both parcel item types
    -> compute exact Part1/Part2 target squares
    -> validate each target through vanilla canPlaceMoveableInternal()
    -> create exact per-part move props
    -> temporarily disable isMultiSprite for each part
    -> place each physical segment through vanilla placeMoveableInternal()
    -> consume both parcels
```

LMION does **not** manually emulate all `IsoDoor` construction. It still delegates each physical member to vanilla's internal Moveables placement; it only controls which exact sprite goes on which exact square and prevents recursive generic multisprite placement.

Runtime validation confirmed:

```text
left  original facing: works
left  rotated N/W:     works
right original facing: works
right rotated N/W:     works
```

After replacement, compatible neighboring members resume vanilla DoubleDoor synchronization.

## Preview problem: vanilla multisprite renderer duplicated artwork

Once the SpriteGrid worked, vanilla `ISMoveableCursor.render()` correctly entered its multisprite branch and called `renderSpriteGrid()`.

A normal vanilla two-tile bench rendered correctly, proving that the generic renderer itself is not globally broken.

The gate preview, however, showed one section darker/doubled.

### Hypothesis 1: custom renderer + vanilla renderer were both active

Rejected.

A diagnostic override made the large-gate `renderSpriteGrid()` draw **only the floor footprint and no gate sprites at all**. During placement, no gate sprite remained visible.

Therefore there was no second hidden renderer continuing to draw an individual segment elsewhere.

### Hypothesis 2: ordinary overlap/alpha between two complementary half-sprites

Changing ghost alpha did not fix the duplication.

A stronger diagnostic then rendered the two SpriteGrid members several squares apart, one red and one blue.

That revealed the actual sprite authoring:

- one member is only a partial/technical visible section;
- the other member already contains the **complete visible leaf artwork**.

So vanilla's normal furniture algorithm:

```text
draw member A + draw member B
```

necessarily redraws part of this DoubleDoor artwork.

## Visual member asymmetry

The complete visible member is not the same logical part for both leaves:

```text
left leaf  -> Part1 contains the complete visual leaf
right leaf -> Part2 contains the complete visual leaf
```

This was runtime-validated in both N and W orientations.

Current leaf specs therefore store:

```text
visualPartIndex = 1   -- left
visualPartIndex = 2   -- right
```

## Validated preview adaptation

LMION overrides only the large-gate `ISMoveableCursor.renderSpriteGrid()` case.

For LMION large-gate move props it:

1. keeps the normal two-square floor footprint rendering;
2. resolves the configured `visualPartIndex` for the leaf/facing;
3. renders only that full-artwork sprite as the ghost;
4. delegates every non-LMION/non-large-gate multisprite object back to vanilla.

This is strictly a visual adaptation. The logical SpriteGrid still contains both physical members because Moveables grouping, targeting and inventory semantics need them.

## Pickup preview vs placement preview

During pickup, the real gate still exists in the world beneath the cursor; during placement it does not. This initially made visual diagnosis confusing.

The floor-only placement diagnostic was important because it isolated the cursor renderer from world-object rendering. Future preview investigations should similarly prefer empty-target placement tests when trying to prove whether an extra render path exists.

## Non-blocking engine warning

Multi-square pickup can log:

```text
GameEntityFactory.TransferComponents> Cannot transfer components for multi-square objects.
```

No concrete state-loss bug has been reproduced from this warning in the validated Chain-Link closed-leaf cycle. The two parcels are created and can be restored successfully.

Do not add speculative compensation until a specific missing component/state is demonstrated.

## Why this is not yet a generic "large gate algorithm"

The Chain-Link implementation proves an architecture, not that every gate family uses identical sprite art/index conventions.

Before generalizing another family, inspect at least:

- closed N/W sprite names;
- actual `DoubleDoor` logical property values;
- Part1/Part2 spatial geometry;
- whether open-state normalization behaves identically;
- which SpriteGrid member(s) contain the complete visible artwork;
- whether the family has two-member leaves at all.

In particular, **do not copy `visualPartIndex` blindly**. The left/right asymmetry on DoubleWireGate was discovered only by controlled rendering.

## Garage doors are a separate system

Garage doors use linkage fields/properties such as:

```text
garageDoorIndex
garage.first
garage.prev
garage.next
```

rather than DoubleDoor logical indices.

Do not force the two-member-leaf design onto garage doors merely because both are multi-tile openings.

## Addon contract

For the current Chain-Link implementation, addon authors should treat these as intentional behavior:

- one LMION gate leaf is the transport unit;
- one leaf currently requires two parcel items;
- global Chain-Link closed sprites receive runtime `IsoSpriteGrid` attachments;
- those grids are reinstalled after `OnLoadedTileDefinitions`;
- final physical placement is LMION-controlled even though individual segment creation delegates to vanilla internals;
- `LMION.Pickup.LargeGateLeafSpecs` describes the currently supported leaf mapping, including `visualPartIndex`;
- `visualPartIndex` is presentation metadata, not the logical DoubleDoor index;
- another addon wrapping `ISMoveableCursor.renderSpriteGrid` must preserve/delegate LMION's large-gate case rather than overwriting it blindly.

The monkey-patched vanilla functions are implementation hooks, not ideal long-term addon APIs. A future public LMION addon API should expose registration points instead of asking addons to patch the same functions.

## Revalidation triggers

Recheck this research when:

- Project Zomboid changes `IsoDoor` DoubleDoor offsets/property semantics;
- vanilla Moveables changes its multisprite anchor or rendering logic;
- LMION generalizes beyond DoubleWireGate;
- open-state pickup becomes a supported reference path;
- a formal LMION large-opening registration API replaces hardcoded leaf specs.
