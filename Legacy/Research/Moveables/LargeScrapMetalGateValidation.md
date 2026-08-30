# Large Scrap Metal Gate Moveables validation

Status: **Runtime-validated on B42.20.3**

Scope: `Base.DoubleFenceGate` / `Base.DoubleFenceGateRight`, the LMION Large Scrap Metal Gate split into two two-segment leaves.

This note records the first successful reuse of the large-gate Moveables architecture originally established on `DoubleWireGate`.

## Closed-sprite mapping used by LMION

### Left leaf

```text
Part1 N = fixtures_doors_fences_01_82
Part2 N = fixtures_doors_fences_01_83

Part1 W = fixtures_doors_fences_01_81
Part2 W = fixtures_doors_fences_01_80
```

Logical DoubleDoor mapping:

```text
N: Part1 = 1, Part2 = 2
W: Part1 = 4, Part2 = 3
```

### Right leaf

```text
Part1 N = fixtures_doors_fences_01_90
Part2 N = fixtures_doors_fences_01_91

Part1 W = fixtures_doors_fences_01_89
Part2 W = fixtures_doors_fences_01_88
```

Logical DoubleDoor mapping:

```text
N: Part1 = 3, Part2 = 4
W: Part1 = 2, Part2 = 1
```

The runtime SpriteGrid geometry is the same validated leaf geometry as the Chain-Link reference implementation:

```text
N: Part2 one square east of Part1
W: Part2 one square south of Part1
```

## Runtime validation

The complete closed-leaf pickup/replacement cycle was tested in both N and W orientations.

Validated behavior:

- pickup resolves and removes exactly one two-segment leaf;
- the two parcels group and replace as one two-square Moveables object;
- rotation between N and W reconstructs the correct physical segments;
- no doubled/overlapped ghost sprite is visible in either orientation;
- current health is preserved independently and exactly for each physical segment, including pre-existing damage;
- the LMION logical maximum-health state remains preserved with the corresponding physical segment;
- after replacement, vanilla synchronized opening/closing works normally across the assembled portal.

The currently configured preview metadata is therefore runtime-valid for this family:

```text
left leaf  -> visualPartIndex = 1
right leaf -> visualPartIndex = 2
```

## Architectural consequence

`DoubleFenceGate` is the second large-gate family to validate the same LMION architecture end to end. This strengthens the case that the reusable parts are:

- facing-dependent DoubleDoor logical-index mapping;
- one two-member runtime `IsoSpriteGrid` per leaf/facing;
- two independent parcels per leaf;
- explicit per-segment placement rather than generic vanilla multisprite placement;
- per-segment durability persistence;
- family metadata for exact sprites and preview member selection.

It does **not** prove that every remaining large-gate family can copy the same sprite/index/visual tables without inspection. Each family still needs its closed sprites, DoubleDoor indices and visual member validated before being promoted to supported behavior.

## Test limit

This validation covers pickup/replacement from the normal closed-gate reference state. Open-state pickup remains outside the validated reference path unless separately tested.
