# Garage-door topology

Status: **Bytecode-verified B42.20.3; runtime-observed B42.20.4; Pickup implementation open**

This note records how Project Zomboid links and operates three-panel garage doors. Garage doors are a separate engine topology from `DoubleDoor` large gates and from ordinary paired 1x1 doors.

## Question

LMION needs to transport garage doors through Pickup without inventing a linkage model that conflicts with vanilla opening/closing behavior.

The relevant questions are:

- how many physical objects make one garage door;
- how a segment identifies its position;
- whether linkage is stored or reconstructed;
- how neighboring members are found;
- how open and closed sprite states are represented;
- what must be restored after Pickup for vanilla synchronization to resume.

## B42.20.3 Java evidence

The following findings were verified from `zombie.iso.objects.IsoDoor` in the B42.20.3 `projectzomboid.jar`.

### Logical segment index

`IsoDoor.getGarageDoorIndex(IsoObject)` reads the sprite `GarageDoor` property and accepts raw values `1..6`.

For a closed `IsoDoor` / `IsoThumpable`, the raw value is returned directly. For an open object, only raw values `4..6` are accepted and the method returns `raw - 3`.

Therefore the normalized garage index is always:

```text
1, 2, 3
```

The raw values `4, 5, 6` are the open-state counterparts of logical members `1, 2, 3`; they are not three additional physical members.

Conclusion:

```text
one garage = three physical door objects
```

### Linkage is spatial, not stored as garage.first/prev/next fields

`IsoDoor.getGarageDoorPrev(IsoObject)` and `IsoDoor.getGarageDoorNext(IsoObject)` derive neighboring members from the current square, orientation, object class and normalized garage index.

They do not read persistent `garage.first`, `garage.prev` or `garage.next` object references.

For a north-oriented door (`north = true`):

```text
prev: x - 1, y
next: x + 1, y
```

For a west-oriented door (`north = false`):

```text
prev: x, y + 1
next: x, y - 1
```

The candidate on the adjacent square must be the same door-object class (`IsoDoor` or `IsoThumpable`), have the same north orientation and have an appropriate normalized garage index.

`IsoDoor.getGarageDoorFirst(IsoObject)` repeatedly follows `getGarageDoorPrev()` until logical member `1` is found. If a valid previous chain cannot be completed, it falls back to the supplied object.

### Vanilla opening/closing synchronization

`IsoDoor.toggleGarageDoor(IsoObject, boolean)` toggles the selected member, then walks both the previous and next chains and toggles every linked garage member.

This is why the three physical panels open and close as one garage door even though the linkage is reconstructed from world geometry rather than persisted as explicit object references.

This is fundamentally different from LMION's paired 1x1 double-door profiles: those leaves are independent and opening one does not open the other.

### Closed/open sprite relation

The `IsoDoor(IsoCell, IsoGridSquare, IsoSprite, boolean)` constructor normally uses a sprite offset of `2` for a standard door and `4` for a `DoubleDoor`.

When the supplied sprite has the `GarageDoor` property, the constructor uses an offset of `8` between closed and open sprites.

Therefore, when LMION reconstructs a garage member from the correct closed sprite, vanilla can derive the corresponding open sprite using its normal garage-door constructor path.

The `+8` sprite offset is separate from the `GarageDoor = 1..6` property values described above.

### Destruction traverses the full garage

`IsoDoor.destroyGarageDoor(IsoObject)` walks both previous and next garage members and destroys the complete linked structure.

`IsoDoor.forEachDoorObject(IsoObject, Consumer)` also has a dedicated garage branch that traverses previous/next members, distinct from its `DoubleDoor` branch.

Pickup must therefore use intentional per-segment removal rather than calling a vanilla whole-garage destruction path.

### Rendering also resolves a first member

`IsoDoor.getRenderEffectMaster()` resolves `getGarageDoorFirst()` for garage doors, and the render-object count/index logic traverses the linked members.

This is additional confirmation that garage identity is reconstructed from the three-member spatial chain.

## Runtime evidence — B42.20.4

Instrumented Pickup traces on an untouched west-facing `IndustrialGarageDoor` establish the actual closed-sprite/index mapping seen by the engine:

```text
industry_trucks_01_32 -> GarageDoor raw 1 / normalized 1
industry_trucks_01_33 -> GarageDoor raw 2 / normalized 2
industry_trucks_01_34 -> GarageDoor raw 3 / normalized 3
```

Observed world coordinates for one reference door were:

```text
_32 / index 1 -> y = 606
_33 / index 2 -> y = 605
_34 / index 3 -> y = 604
```

This exactly matches the bytecode linkage rule for W: `next` advances toward `y - 1`.

This runtime evidence corrects an earlier LMION implementation mistake where W sprite identities were assigned as `_34=1`, `_33=2`, `_32=3`. That mistake caused Pickup parcels to swap Part 1 and Part 3 and caused replacement to create valid sprites with the wrong `GarageDoor` indices.

## Current LMION SpriteConfig evidence

LMION Core already owns garage-door `SpriteConfig` entities for construction. The current `Base.IndustrialGarageDoor` configuration declares three closed tiles in each orientation:

```text
W visual/local-grid order: industry_trucks_01_34
                           industry_trucks_01_33
                           industry_trucks_01_32

N visual/local-grid order: industry_trucks_01_35 industry_trucks_01_36 industry_trucks_01_37
```

The W visual/local-grid order must not be confused with engine identity. The engine identities are `_32=1`, `_33=2`, `_34=3`.

The resulting dimensions are `1x3` for W and `3x1` for N.

## Geometry contract for LMION Pickup

If logical member `1` is the placement anchor, the three-member closed structure is:

```text
N:
index 1 -> (x,     y)
index 2 -> (x + 1, y)
index 3 -> (x + 2, y)

W:
index 1 -> (x, y)
index 2 -> (x, y - 1)
index 3 -> (x, y - 2)
```

For `IndustrialGarageDoor`, that means:

```text
N engine identity:
1 = _35
2 = _36
3 = _37

W engine identity:
1 = _32
2 = _33
3 = _34

W SpriteGrid local +Y order:
3 = _34
2 = _33
1 = _32
```

This is the same direction used by vanilla `getGarageDoorNext()`.

LMION should resolve an arbitrary selected garage member back to logical member `1`, then enumerate the three members through vanilla garage topology rather than infer membership from family sprite names alone.

## Proposed transport identity

The catalog already models garage transport as three 20 kg packages. The engine topology gives a natural interpretation:

```text
one garage = three physical IsoDoor segments = three parcels = one placement action
```

This is an implementation proposal until runtime-validated.

Each parcel should preserve the exact current health and `lmionDoorMaxHealth` of its corresponding physical segment. Placement should reconstruct all three closed `IsoDoor` members with the correct orientation and closed sprites. If geometry and `GarageDoor` properties are correct, vanilla previous/next discovery should immediately restore synchronized opening/closing without LMION storing custom links.

## Initial implementation scope

Use `IndustrialGarageDoor` as the reference family first.

The first runtime validation should cover:

1. target logical member 1, 2 and 3 independently;
2. obtain exactly three `(1/3)`, `(2/3)`, `(3/3)` parcels;
3. remove exactly the selected garage and no adjacent unrelated opening;
4. require all three parcels for replacement;
5. place correctly in N and W;
6. rotate before placement;
7. open any restored panel and confirm all three synchronize through vanilla;
8. preserve exact per-segment current health and logical max, including unequal damage.

Open-state Pickup is not part of the initial reference path unless runtime testing shows it comes for free without ambiguity.

Only after the Industrial family passes should the remaining garage families be generalized as data.

## Revalidation trigger

Recheck this note if Project Zomboid changes the `GarageDoor` property scheme, `IsoDoor.getGarageDoor*` methods, `IsoDoor` constructor sprite offsets, or garage SpriteConfig topology.
