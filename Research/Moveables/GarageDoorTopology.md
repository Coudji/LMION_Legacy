# Garage-door topology

Status: **Bytecode-verified B42.20.3; runtime-observed B42.20.4; variable-length topology confirmed down to width 2; current LMION Pickup still assumes width 3 and must be generalized.**

This note records how Project Zomboid links and operates garage doors. Garage doors are a separate engine topology from `DoubleDoor` large gates and from ordinary paired 1x1 doors.

## Key correction: garage width is variable

Earlier LMION research incorrectly concluded:

```text
one garage = three physical door objects
```

That conclusion confused the three normalized `GarageDoor` **roles** with a fixed physical member count.

The correct model is:

```text
GarageDoor
= start(1) + zero-or-more middle(2) + end(3)
```

The middle role may repeat an arbitrary number of times, including **zero**, as long as the chain remains spatially valid and is terminated by the proper start/end members.

Runtime evidence on B42.20.4:

- a vanilla world garage five tiles wide was observed with the same start/end pieces as the familiar three-tile garage and repeated middle pieces between them;
- an earlier BrushTool experiment with a six-tile garage opened/closed correctly;
- a BrushTool experiment with a **12-tile garage** also opened and closed correctly as one native garage;
- a **two-tile garage made only from start + end** was runtime-tested and also opens/closes correctly.

Therefore the currently observed native range is at least:

```text
L2 = start + end
L3 = start + middle + end
L4+ = start + repeated middle + end
```

No engine maximum width has been established. LMION must therefore not encode an arbitrary maximum without separate evidence.

## B42.20.3 Java evidence

The following findings were verified from `zombie.iso.objects.IsoDoor` in the supplied B42.20.3 `projectzomboid.jar`.

### Logical role/index

`IsoDoor.getGarageDoorIndex(IsoObject)` reads the sprite `GarageDoor` property and accepts raw values `1..6`.

For a closed object, raw `1..3` normalize to:

```text
1 = start
2 = middle
3 = end
```

For an open object, raw `4..6` normalize to the same roles by returning `raw - 3`:

```text
4 -> 1
5 -> 2
6 -> 3
```

Therefore normalized values `1,2,3` describe **topological roles**, not “member 1 of exactly 3 / member 2 of exactly 3 / member 3 of exactly 3”.

### Why repeated middle members — or no middle at all — work

`IsoDoor.getGarageDoorPrev(IsoObject)` and `getGarageDoorNext(IsoObject)` derive neighbors spatially from orientation and normalized role.

For `north = true`:

```text
prev: x - 1, y
next: x + 1, y
```

For `north = false`:

```text
prev: x, y + 1
next: x, y - 1
```

The important bytecode rule is role comparison:

```text
prev candidate accepted when candidateIndex <= currentIndex
next candidate accepted when candidateIndex >= currentIndex
```

with hard stops:

```text
current index 1 -> no prev
current index 3 -> no next
```

That means both of these structures are valid:

```text
1 -> 3
1 -> 2 -> 2 -> 2 -> ... -> 2 -> 3
```

This exactly explains the runtime L2/L5/L6/L12 behavior.

The candidate must still use the same door-object representation class (`IsoDoor` vs `IsoThumpable`) and same orientation.

### First-member resolution

`IsoDoor.getGarageDoorFirst(IsoObject)` repeatedly follows `getGarageDoorPrev()` until it finds role `1`.

There is no fixed traversal length. The chain length is determined by world geometry.

### Vanilla opening/closing synchronization

`IsoDoor.toggleGarageDoor(IsoObject, boolean)`:

1. toggles the selected object;
2. repeatedly follows `getGarageDoorPrev()` until no previous member remains;
3. repeatedly follows `getGarageDoorNext()` until no next member remains.

Therefore vanilla naturally operates the complete variable-length chain. The L2 and L12 runtime tests are both expected consequences of the bytecode.

### Obstruction and destruction also traverse the chain

`IsoDoor.isGarageDoorObstructed(IsoObject)` derives the full span by walking previous/next members before checking vehicle obstruction.

`IsoDoor.destroyGarageDoor(IsoObject)` likewise walks the complete previous and next chains and destroys every linked member.

This reinforces the rule that garage identity is spatial and variable-length.

Pickup must continue using intentional per-member removal rather than a vanilla whole-garage destruction helper.

### Closed/open sprite relation

The `IsoDoor(IsoCell, IsoGridSquare, IsoSprite, boolean)` constructor uses the GarageDoor-specific closed/open sprite offset of `8`.

This is independent from the `GarageDoor = 1..6` role property.

When LMION reconstructs a member from the correct closed sprite, native `IsoDoor` garage behavior can derive the matching open state.

## Canonical representation

LMION's global canonical representation is now `IsoDoor`.

Garage construction remains an early-timing case:

```text
LMION-built garage
-> temporary construction IsoThumpable
-> SpriteConfig.OnCreate
-> Core canonicalization
-> IsoDoor
```

This timing is required because complete native GarageDoor mechanics are implemented on `IsoDoor`.

See `Research/Engine/GarageThumpableInteraction.md` and `Research/Architecture/DoorObjectAbstraction.md`.

## Current LMION-built garage families

The seven current LMION garage `SpriteConfig` entities are still authored as width 3:

- `IndustrialGarageDoor`;
- `GreenGarageDoor`;
- `WhiteGarageDoor`;
- `GreyGarageDoor`;
- `RollingGarageDoor`;
- `RedWindowGarageDoor`;
- `RollingWindowGarageDoor`.

Their closed role mappings are:

| Family | W start / middle / end | N start / middle / end |
|---|---|---|
| `IndustrialGarageDoor` | `industry_trucks_01_32` / `_33` / `_34` | `industry_trucks_01_35` / `_36` / `_37` |
| `GreenGarageDoor` | `walls_garage_01_16` / `_17` / `_18` | `walls_garage_01_19` / `_20` / `_21` |
| `WhiteGarageDoor` | `walls_garage_01_0` / `_1` / `_2` | `walls_garage_01_3` / `_4` / `_5` |
| `GreyGarageDoor` | `walls_garage_01_48` / `_49` / `_50` | `walls_garage_01_51` / `_52` / `_53` |
| `RollingGarageDoor` | `walls_garage_02_0` / `_1` / `_2` | `walls_garage_02_3` / `_4` / `_5` |
| `RedWindowGarageDoor` | `walls_garage_02_32` / `_33` / `_34` | `walls_garage_02_35` / `_36` / `_37` |
| `RollingWindowGarageDoor` | `walls_garage_02_48` / `_49` / `_50` | `walls_garage_02_51` / `_52` / `_53` |

These three sprites are best understood as **role sprites**, not three unique physical-part identities.

Examples for a White garage:

```text
L2 W: _0 / _2
L3 W: _0 / _1 / _2
L5 W: _0 / _1 / _1 / _1 / _2

L2 N: _3 / _5
L3 N: _3 / _4 / _5
L5 N: _3 / _4 / _4 / _4 / _5
```

subject to orientation geometry.

## Geometry

Starting from the role-1/start anchor, a closed garage of total width `L >= 2` occupies:

```text
N:
position 1       -> (x,         y) role 1
positions 2..L-1 -> (x + i - 1, y) role 2, if any
position L       -> (x + L - 1, y) role 3

W:
position 1       -> (x, y)         role 1
positions 2..L-1 -> (x, y - i + 1) role 2, if any
position L       -> (x, y - L + 1) role 3
```

The visual/local SpriteGrid order for W may remain reversed relative to engine traversal identity. Do not infer logical chain order from SpriteGrid local order.

## Pickup implications

The current LMION garage Pickup implementation was designed around exactly three physical segments and three parcels. That assumption is now known to be incomplete for vanilla world garages.

Current behavior remains valid for the seven LMION-built width-3 families, but **world-garage transport must be generalized before variable-width garages can be claimed supported**.

The correct future conceptual model is:

```text
select any garage member
-> resolve start with getGarageDoorFirst()
-> traverse getGarageDoorNext() until role 3 / end of chain
-> capture every physical member in order
-> parcel count = actual physical member count
-> placement reconstructs:
   start + zero-or-more middle + end
-> vanilla spatial linkage resumes automatically
```

Do not hardcode width `2`, `5`, `6`, `12`, or any other discovered example. The traversal itself should determine width.

### Parcel identity design direction

Variable-width garages are physical-part assemblies rather than fixed bundles.

The likely transport model is:

```text
1 start piece
0..N middle pieces
1 end piece
```

Each physical parcel keeps its own durability state. Reinstallation width can therefore depend on the number of compatible middle pieces the player chooses to consume.

This also matches previous runtime evidence that same-family garage pieces can be interchanged between different physical garages.

Cross-family mixing remains a separate gameplay-policy decision; native topology acceptance alone does not imply LMION should allow visual/family mixing.

## Build design decisions discovered from variable width

For future LMION_Build variable-width garage construction:

- width is chosen visibly in the construction window before placement;
- once placement mode begins, that width is frozen so material requirements cannot change invisibly;
- build material requirements may scale with width;
- BlowTorch usage should remain a fixed recipe cost rather than scale indefinitely with width, because tool charge capacity is finite;
- the current exact per-material scaling formula is still a gameplay/balance design task.

The engine-valid minimum is now known to be **L2**. Whether LMION_Build exposes L2 in its normal construction UI is a gameplay choice, not an engine limitation.

## Previously validated width-3 behavior

The existing width-3 architecture remains runtime validated across the seven current LMION families for N/W pickup/replacement, rotation and synchronized native opening/closing.

Industrial remains the detailed reference family for per-segment durability and engine-role mapping.

The discovery of variable width does **not** invalidate those tests. It invalidates only the broader assumption that every garage in the game contains exactly three physical members.

## Revalidation trigger

Recheck this note if Project Zomboid changes:

- the `GarageDoor` property scheme;
- `IsoDoor.getGarageDoor*` traversal rules;
- `IsoDoor` constructor sprite offsets;
- SpriteConfig `OnCreate` replacement semantics;
- garage role sprites;
- or if runtime testing establishes an actual maximum chain length or a native width below L2.
