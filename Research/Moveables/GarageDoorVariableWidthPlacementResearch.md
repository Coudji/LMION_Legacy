# Variable-width garage placement research

Status: **2026-08-29 research checkpoint. Variable-width Pickup dismantling is valid; the attempted variable reinstallation built on top of vanilla's fixed L3 Moveables SpriteGrid is rejected. No further gameplay implementation should proceed from that approach.**

This note supersedes the optimistic placement-status wording in `GarageDoorVariableWidthDesign.md` until that document is consolidated.

## Runtime evidence that stopped the current approach

B42.20.4 runtime after the variable-width Pickup work:

- a variable-width garage can be picked up successfully and produces one parcel per real physical member;
- parcels now correctly represent roles: Start / repeatable Middle / End;
- the placement cursor still displays the old three-square ghost;
- that ghost is invalid/red even when the player reports all same-family pieces gathered nearby;
- configurable width keys are received by LMION, but the placement plan cannot be produced.

The decisive trace was:

```text
[LMION:Pickup] garage width key family=RollingGarageDoor delta=-1 old=nil new=nil
[LMION:Pickup] garage width key family=RollingGarageDoor delta=1 old=nil new=nil
```

Therefore:

```text
key binding works
family identification works
placement length/plan resolution fails
vanilla fixed L3 cursor remains visible as fallback
```

Do not diagnose this as a simple keybind or render-timing bug again.

## Why the fixed-L3 Moveables strategy is the wrong abstraction

Vanilla B42 Moveables represents multisprite furniture through `IsoSpriteGrid`.

`ISMoveableCursor` uses that grid as a structural contract, not merely a visual helper:

1. inventory placement entries are grouped by `sprite:getSpriteGrid():getAnchorSprite()`;
2. non-anchor pieces are normalized back to the anchor MoveProps;
3. placement validity calls the multisprite MoveProps path;
4. the ghost loops the current SpriteGrid width/height;
5. the Moveables placement implementation loops the SpriteGrid members and consumes the corresponding fixed multisprite pieces.

LMION's historical garage support installed a synthetic 3-member SpriteGrid because every supported garage was then assumed to be L3. That was correct for the old requirement.

After discovering native variable topology, trying to retain this permanent L3 SpriteGrid while layering a separate L2/L5/L12 plan above it creates two competing geometry models:

```text
vanilla Moveables geometry -> fixed L3 IsoSpriteGrid
LMION intended geometry    -> Start + Middle*N + End
```

The runtime failures are consistent with this architectural mismatch.

### Rejected direction

Do **not** continue by adding more wrappers around:

- `ISMoveableCursor.renderSpriteGrid`;
- `ISMoveableSpriteProps.canPlaceMoveable`;
- `ISMoveableSpriteProps.placeMoveable`;
- MoveProps identity restoration;
- or further fallback/caching tricks

while the underlying selected garage is still represented to vanilla Moveables as one fixed L3 multisprite assembly.

The problem is not one missing hook. The fixed-grid assumption exists in multiple stages of vanilla placement.

## Reference mod studied: Buildable Garage Doors

Reference supplied by the user: Workshop item `3727753275`, source repository `MatthieuLepers/Buildable-Garage-Doors`.

The useful idea is **not** its complete implementation and must not be copied wholesale.

### Its key technique

The mod leaves the scripted garage SpriteConfig authored with the normal three semantic role tiles, then overrides `ISBuildIsoEntity:getFace()` for garage cursors and returns a proxy around `SpriteConfigManager.FaceInfo`.

The proxy:

```text
getWidth()/getHeight()
-> returns selected garage length on the variable axis

getTileInfo()
-> first position = original first/START tile
-> last position  = original last/END tile
-> every interior position = original MIDDLE tile
```

Conceptually:

```text
source SpriteConfig: START MID END

L2 -> START END
L3 -> START MID END
L5 -> START MID MID MID END
...
```

This is exactly compatible with the native GarageDoor topology discovered by LMION.

### API verification against LMION's supplied B42.20.3 JAR

`zombie.entity.components.spriteconfig.SpriteConfigManager$FaceInfo` still exposes the API mirrored by the reference proxy:

- `getFaceName()`
- `getWidth()`
- `getHeight()`
- `getzLayers()`
- `getMasterX/Y/Z()`
- `isMasterSet()`
- `isMultiSquare()`
- `getMasterTileInfo()`
- `verifyObject(...)`
- `getTileInfo(...)`
- `getTileInfoForSprite(...)`

Therefore this is not merely an obsolete old-B42 trick. The underlying FaceInfo-proxy technique remains compatible with the target JAR API.

### What LMION should NOT copy

The reference mod also does things that conflict with LMION's design:

- it lets the user change garage length with keys while the Build ghost is active;
- LMION explicitly forbids this because the player must never change material requirements after leaving the construction window;
- its recipe does not implement LMION's variable material-cost policy;
- it overrides `ISBuildIsoEntity:setInfo()` to create `IsoDoor` itself;
- LMION Core already owns canonical `IsoDoor` finalization and Build must not take that responsibility;
- its maximum-width policy is unrelated to LMION's L12 default + explicit limit-lift option;
- its MP size synchronization should not be copied before LMION decides server/admin authority.

Its commit history contains several dedicated-server / wrong-size fixes. This reinforces the decision to solve single-player architecture first and defer multiplayer authority/synchronization deliberately.

## Recommended Build architecture

For `LMION_Build`, adapt only the **FaceInfo proxy concept**.

Desired lifecycle:

```text
construction window
-> player chooses L2..L12 (or larger when limit is lifted)
-> displayed resource requirements update visibly
-> player confirms construction
-> chosen width is copied into that specific ISBuildIsoEntity instance
-> width is frozen
-> LMION garage FaceInfo proxy exposes variable geometry
-> vanilla ISBuildIsoEntity handles ghost, occupied squares, validity and creation loops
-> Core performs canonical IsoDoor finalization
-> Build applies Build-owned durability/stats
```

Important properties:

- no global SpriteConfig mutation;
- no global mutable garage width;
- no Build +/- keys during world placement;
- Start/Middle/End role sprites remain the sole source geometry;
- proxy width belongs to the individual construction cursor/action.

This should let LMION use the engine's own Build pipeline instead of manually reproducing its geometry rules.

## Recommended Pickup architecture

Pickup and Build have different engine pipelines. The FaceInfo technique does not directly solve Moveables placement.

For variable garage **reinstallation**, the recommended direction is to stop treating the assembly as a normal vanilla fixed multisprite Moveable during placement.

### Preferred direction: dedicated LMION garage placement cursor

Pickup can continue using vanilla Moveables integration for:

- world-object discovery;
- pickup interaction;
- tool/skill rules;
- creation of Start/Middle/End parcel items.

When the player chooses to place a garage parcel, LMION should transition to a dedicated garage-placement cursor/plan that owns variable geometry instead of asking `IsoSpriteGrid` to represent it.

That cursor should own only garage-specific placement state:

```text
family
selected width
facing N/W
selected/anchor role
available Start/Middle/End parcels
world target plan
```

It should then provide:

- actual L2/L3/L5/L12/+ ghost rendering;
- per-square validity for the complete selected span;
- configurable NumPad +/- width changes;
- normal Rotate Building key for N/W;
- L12 policy via Core;
- same-family parcel filtering;
- one placement confirmation that consumes only the chosen physical pieces;
- per-parcel durability restoration;
- canonical IsoDoor output via Core.

The exact base class/interception point is **not yet decided**. Before coding, inspect how a garage parcel enters vanilla Place mode and choose the smallest stable handoff to an LMION-specific cursor/action.

Possible implementation forms to compare before coding:

1. a thin dedicated cursor derived from `ISBuildingObject`;
2. a specialized branch/subclass around `ISMoveableCursor` that bypasses SpriteGrid geometry entirely for garage placement;
3. another existing vanilla cursor type if it already supplies the right arbitrary-footprint contract.

Do not choose among these by trial-and-error. Inspect the entry path and timed-action contract first.

## Rejected alternative: dynamically mutate IsoSpriteGrid width

Do not solve variable Pickup placement by globally replacing garage sprites' SpriteGrid with L2/L5/L12 grids as the user presses +/-.

Reasons:

- `IsoSprite`/SpriteGrid objects are shared engine data;
- simultaneous players/cursors could require different widths;
- global mutation creates ordering/race/cache problems;
- multiplayer would become especially fragile;
- Build already has a per-instance FaceInfo mechanism, so reproducing global mutable geometry in Pickup would violate the architecture goal.

## Parcel freshness / current test items

There is currently **no evidence that the repeatedly tested parcels are corrupted**.

The current variable availability logic primarily identifies compatible pieces through their script/full item types (Start/Middle/End prototypes). Old `modData` from previous attempts is not a proven explanation for `old=nil new=nil`.

Nevertheless, once the placement architecture is replaced, the first validation should use parcels produced by a **fresh Pickup performed with the new code**. This removes stale worldSprite/modData/cursor-cache variables from the first diagnosis.

After fresh L2/L3/L5/L12 tests pass, existing dev parcels should be tested separately as a backward-compatibility case.

## Current safe implementation status

Keep:

- Core GarageRole definitions;
- native chain traversal;
- L12 policy and limit-lift semantics;
- variable-width Pickup dismantling;
- Start/Middle/End parcel model and translations;
- per-member durability capture;
- configurable width key definitions as a UX decision.

Reconsider/remove before final implementation:

- fixed-L3 SpriteGrid-based variable placement planning;
- cursor hooks whose purpose is to make fixed Moveables geometry pretend to be variable;
- any assumption that a vanilla multisprite Moveable can naturally represent arbitrary garage length.

## Next research step before any gameplay code

Trace the exact garage-parcel placement entry path:

```text
inventory garage parcel
-> Moveables Place selection
-> cursor creation / initial item selection
-> timed action creation
-> final placement call
```

Then identify the narrowest point where LMION can hand garage placement to a dedicated variable-footprint cursor/action while all non-garage Moveables continue untouched.

Only after that design is understood should variable Pickup placement code be rewritten.
