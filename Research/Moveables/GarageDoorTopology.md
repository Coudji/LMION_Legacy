# Garage-door topology

Status: **Bytecode-verified B42.20.3; runtime-observed B42.20.4; Industrial fully runtime-validated; all current LMION garage families pickup/replacement runtime-validated in N/W**

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

The corrected Industrial implementation is runtime-validated end to end:

- pickup from either N or W orientation;
- exactly three parcels `(1/3)`, `(2/3)`, `(3/3)`;
- replacement in N and W;
- rotation before placement;
- restored vanilla synchronized opening/closing;
- pickup again after replacement;
- exact per-segment current-health and `lmionDoorMaxHealth` preservation, including unequal damage.

## Current LMION SpriteConfig evidence

LMION Core owns the seven current garage-door `SpriteConfig` entities used for construction. Every current family declares three closed tiles in each orientation and the same 3-wide topology.

The engine-identity mappings encoded by Pickup are:

| Family | W member 1 / 2 / 3 | N member 1 / 2 / 3 |
|---|---|---|
| `IndustrialGarageDoor` | `industry_trucks_01_32` / `_33` / `_34` | `industry_trucks_01_35` / `_36` / `_37` |
| `GreenGarageDoor` | `walls_garage_01_16` / `_17` / `_18` | `walls_garage_01_19` / `_20` / `_21` |
| `WhiteGarageDoor` | `walls_garage_01_0` / `_1` / `_2` | `walls_garage_01_3` / `_4` / `_5` |
| `GreyGarageDoor` | `walls_garage_01_48` / `_49` / `_50` | `walls_garage_01_51` / `_52` / `_53` |
| `RollingGarageDoor` | `walls_garage_02_0` / `_1` / `_2` | `walls_garage_02_3` / `_4` / `_5` |
| `RedWindowGarageDoor` | `walls_garage_02_32` / `_33` / `_34` | `walls_garage_02_35` / `_36` / `_37` |
| `RollingWindowGarageDoor` | `walls_garage_02_48` / `_49` / `_50` | `walls_garage_02_51` / `_52` / `_53` |

The Industrial mapping is directly runtime-observed. The six generalized families use the same vanilla garage closed-tile convention reflected by their Core SpriteConfigs. To prevent another silent Part 1 / Part 3 inversion, Pickup validates every configured closed sprite against its live `GarageDoor` property before enabling Moveables or installing its runtime `IsoSpriteGrid`. A family whose raw property does not match the expected logical member is rejected rather than transported with an uncertain topology.

For every current family, Core's W `SpriteConfig` visual/local-grid order is reversed relative to engine identity. For example, `IndustrialGarageDoor` declares:

```text
W visual/local-grid order: industry_trucks_01_34
                           industry_trucks_01_33
                           industry_trucks_01_32

N visual/local-grid order: industry_trucks_01_35 industry_trucks_01_36 industry_trucks_01_37
```

The W visual/local-grid order must not be confused with engine identity. The resulting dimensions are `1x3` for W and `3x1` for N.

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

LMION resolves an arbitrary selected garage member back to logical member `1`, then enumerates the three members through vanilla garage topology rather than infer membership from family sprite names alone.

## Transport identity

The catalog models garage transport as three 20 kg packages, which matches the engine topology naturally:

```text
one garage = three physical IsoDoor segments = three parcels = one placement action
```

Pickup and replacement in both N and W orientations are now runtime-validated across all seven current LMION garage families. `IndustrialGarageDoor` remains the full reference family for the broader behavior matrix.

Each parcel preserves the exact current health and `lmionDoorMaxHealth` of its corresponding physical segment. Placement reconstructs all three closed `IsoDoor` members with the correct orientation and engine-index sprite. Vanilla previous/next discovery then restores synchronized opening/closing without LMION storing custom links.

## Industrial reference validation

The reference family passes the complete closed-state validation set:

1. target logical member 1, 2 or 3;
2. obtain exactly three `(1/3)`, `(2/3)`, `(3/3)` parcels;
3. remove exactly the selected garage;
4. require all three parcels for replacement;
5. place correctly in N and W;
6. rotate before placement;
7. open any restored panel and confirm all three synchronize through vanilla;
8. preserve exact per-segment current health and logical max, including unequal damage;
9. pick up the restored garage again successfully.

Open-state Pickup is not part of the reference path.

## Generalized family state

The Industrial reference architecture has been extended as data to:

- `GreenGarageDoor`;
- `WhiteGarageDoor`;
- `GreyGarageDoor`;
- `RollingGarageDoor`;
- `RedWindowGarageDoor`;
- `RollingWindowGarageDoor`.

Each family has three dedicated 20 kg parcel items and EN/FR localized names. The shared Pickup, rotation, placement and durability code is unchanged in principle; only family data and fail-closed sprite-index validation were added.

Runtime testing now confirms that every generalized family can be picked up and replaced successfully in both N and W orientations. Combined with the Industrial reference, the complete current garage set therefore has runtime-validated orientation coverage for pickup and replacement.

The six generalized families are not yet claimed to have passed every Industrial reference check. Remaining explicit validation includes targeting each logical member independently, rotation before placement as a cursor operation, restored synchronized opening/closing, exact unequal per-segment durability preservation and re-pickup after replacement. The startup/runtime `GarageDoor` property check remains a fail-closed guard against invalid member mappings; it complements but does not replace those interaction tests.

## Revalidation trigger

Recheck this note if Project Zomboid changes the `GarageDoor` property scheme, `IsoDoor.getGarageDoor*` methods, `IsoDoor` constructor sprite offsets, garage SpriteConfig topology, or the closed-sprite `GarageDoor` identities of any supported family.
