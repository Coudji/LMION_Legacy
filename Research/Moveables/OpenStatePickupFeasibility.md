# Open-state Pickup feasibility — garage doors and large gates

Status: **Bytecode-verified B42.20.3; current LMION architecture inspected; implementation not yet runtime-validated**

## Question

Can LMION allow Pickup while a supported garage door or large gate is **open**, while deliberately reinstalling the transported structure in the **closed** state?

Conclusion: **yes for both systems**. There is no engine-level blocker. Garage doors are a low-risk extension. Large `DoubleDoor` gates are also feasible, but their open geometry requires state-aware member resolution and one targeted durability check because vanilla relocates/recreates the two central members while toggling.

The intended contract is:

```text
open world structure -> Pickup -> existing parcels -> placement always CLOSED
```

LMION does not need to preserve the open/closed state in inventory.

## Vanilla Moveables gate

The inspected vanilla `ISMoveableSpriteProps:canPickUpMoveable()` path does not contain a generic `IsoDoor:IsOpen()` prohibition. It validates Moveables metadata, capacity, tools/skills and object constraints.

Therefore the current inability to pick up these openings while open is not a fundamental Moveables restriction:

- garage doors are explicitly rejected by LMION's current closed-reference checks;
- large-gate open sprites are not currently registered in LMION's segment tables / Moveables metadata.

## Garage doors

### Engine identity remains stable while open

`IsoDoor.getGarageDoorIndex(IsoObject)` accepts raw `GarageDoor` values `1..6`.

- closed member: raw `1..3` -> normalized `1..3`;
- open member: raw `4..6` -> normalized `1..3`.

The logical three-member identity is therefore preserved across opening/closing.

`IsoDoor.getGarageDoorPrev()` / `getGarageDoorNext()` use the normalized member index, orientation, object class and matching open state. Opening a garage does **not** change the three world squares occupied by its members.

`toggleGarageDoorObject()` changes the open state and swaps the sprite; it does not relocate/recreate the member on another square.

### Open sprite relation

The `IsoDoor` garage constructor uses an open-sprite offset of `+8` from the supplied closed sprite.

For example the Industrial W closed set:

```text
industry_trucks_01_32
industry_trucks_01_33
industry_trucks_01_34
```

has the expected open aliases:

```text
industry_trucks_01_40
industry_trucks_01_41
industry_trucks_01_42
```

The safe LMION implementation should derive this alias mechanically and validate the live sprite property rather than trust the numeric relation alone:

```text
closed raw GarageDoor = partIndex      (1..3)
open   raw GarageDoor = partIndex + 3  (4..6)
```

A family whose open alias does not validate should fail closed exactly like the existing closed-sprite validation.

### Current LMION blockers

The current garage implementation is deliberately closed-only in several places:

- `GarageDoorSpecs.lua` registers only closed sprites in `SegmentsBySprite`;
- `GarageDoorMoveables.lua` marks only closed sprites `IsMoveAble`;
- its validation explicitly rejects `selected:IsOpen()` / open chain members;
- `GarageDoorPickup.lua` also rejects an open source/member in `getGarageMembers()` / `findGarageMember()`.

These are policy/data checks, not engine limitations.

### Recommended implementation

1. For every configured closed segment, derive its `+8` open alias.
2. Validate the open alias has raw `GarageDoor = partIndex + 3`.
3. Add the validated open alias to `SegmentsBySprite`, pointing to the same family, logical part and facing as the closed segment, but retaining the **closed sprite as canonical inventory/placement identity**.
4. Mark the validated open alias `IsMoveAble`.
5. Allow `getGarageMembers()` to resolve a complete chain when all three members share the selected open/closed state.
6. During actual pickup of an open member, create/use Moveables properties from the corresponding **closed canonical sprite**, but remove the real open `IsoDoor` object and read health from that real object.
7. Keep the current placement code unchanged: it already rebuilds `family.parts[partIndex].faces[facing]`, which are closed sprites.

No open-state runtime `IsoSpriteGrid` is required for placement. The existing garage pickup cursor already resolves the real three members and shades their actual floor squares; because garage geometry does not move when opened, that mechanism naturally fits open pickup once member resolution accepts the open state.

### Garage feasibility verdict

**High feasibility / low implementation risk.**

The engine already provides normalized identities and stable geometry. The feature is mainly an alias-recognition + canonicalization change.

## Large gates (`DoubleDoor` topology)

### Logical identity also remains stable

`IsoDoor.getDoubleDoorIndex(IsoObject)` accepts raw `DoubleDoor` values `1..8`.

- closed: raw `1..4` -> normalized `1..4`;
- open: raw `5..8` -> normalized `1..4`.

`IsoDoor.getDoubleDoorObject(source, logicalIndex)` explicitly chooses its coordinate offsets according to the source object's orientation **and open state**. LMION already uses this API to resolve the two members of the selected leaf.

Therefore the current leaf model remains usable while the portal is open as soon as open sprites can be mapped back to their canonical leaf/part/facing metadata.

### Open geometry is different

Unlike garage doors, a large `DoubleDoor` changes physical geometry when opened.

B42.20.3 bytecode initializes the four logical-member offsets as follows, relative to logical member 1:

```text
North closed:
1 (0,0)  2 (+1,0)  3 (+2,0)  4 (+3,0)

North open:
1 (0,0)  2 (0,+1)  3 (+3,+1)  4 (+3,0)

West closed:
1 (0,0)  2 (0,-1)  3 (0,-2)  4 (0,-3)

West open:
1 (0,0)  2 (+1,0)  3 (+1,-3)  4 (0,-3)
```

Each two-member leaf therefore folds perpendicular to its closed footprint.

This is why LMION must **not** attach the existing closed `2x1` / `1x2` runtime SpriteGrid to open sprites and pretend the open structure still has closed geometry.

The engine's `getDoubleDoorObject()` should remain the authority for locating the real open members.

### Open sprite relation

`toggleDoubleDoorObject()` applies per-index sprite offsets.

For normalized logical indices `1..4`:

```text
North open offset: +5, +3, +4, +4
West  open offset: +4, +4, +5, +3
```

LMION's current specs already know the logical `DoubleDoor` index of every leaf part for N and W. Open aliases can therefore be derived mechanically from each closed face and validated against the live sprite property:

```text
open raw DoubleDoor = logicalIndex + 4  (5..8)
```

This avoids hand-maintaining another large sprite table.

### Current LMION blocker

`LargeGateMoveables.getLeafMembers()` already resolves each requested logical member through `IsoDoor.getDoubleDoorObject()`, which is the correct open-aware engine API.

The failure today happens earlier/later around that resolver:

- `segmentBySprite` contains closed sprites only;
- open sprites are not marked as LMION Moveables;
- therefore an open selected sprite cannot be classified as a known leaf/part/facing;
- parcel creation currently passes the world member's sprite name directly into vanilla item instancing, which would preserve the open sprite as the Moveable world sprite unless canonicalized.

### Recommended implementation

1. Derive an open alias for each configured closed leaf part from its facing + logical index sprite offset.
2. Validate raw `DoubleDoor = logicalIndex + 4` before enabling that alias.
3. Map the open alias to the same leaf, part, facing, parcel item and **closed canonical faces**.
4. Mark validated open aliases `IsMoveAble` so the Moveables cursor can select them.
5. Keep member discovery based on `IsoDoor.getDoubleDoorObject()`; do not implement custom open coordinate math in LMION.
6. For each actual open world member, create the pickup Moveables properties from its **closed canonical sprite**, then call the existing per-member pickup/removal against the real open object. This gives the parcel a closed world-sprite identity immediately while still capturing state from the object that was actually removed.
7. Keep `LargeGatePlacement.lua` unchanged. Its placement plan already selects `part.faces[facing]`, i.e. the closed sprites, and explicitly reconstructs the two closed `IsoDoor` members.
8. Add an open-pickup cursor path that highlights the actual two resolved leaf-member squares. Do not reuse the closed SpriteGrid footprint for an open gate.

This preserves the already runtime-validated closed rotation/placement architecture instead of teaching inventory placement about open geometry.

### Important durability risk to validate

Vanilla `toggleDoubleDoorObject()` treats logical members 2 and 3 specially when a large gate changes state. Those members are removed from their old square and recreated on their new open/closed square.

For `IsoThumpable`, the bytecode explicitly transfers several fields including modData. For `IsoDoor`, the observed reconstruction path creates a new `IsoDoor`, sets its open state and key ID, and adds it to the destination square; the toggle method does not explicitly copy health or modData there.

This is **not a blocker for open Pickup**, because LMION can preserve whatever health/state is present on the open object at pickup time. It does mean one targeted runtime test is required before implementation is called complete:

```text
set unequal health / lmionDoorMaxHealth
-> open the large gate
-> inspect logical members 1..4
-> pickup an open leaf
-> place it closed
-> inspect the two restored members
```

The purpose is to distinguish a possible vanilla state-loss-on-toggle issue from any Pickup issue. If opening itself already changes member 2/3 state, that is a separate engine integration problem and should not be hidden inside the open-Pickup implementation.

### Large-gate feasibility verdict

**Feasible / moderate implementation risk.**

The engine supplies exactly the open-aware logical resolver LMION needs. The main complexity is ensuring Moveables selection understands open aliases without contaminating the tested closed SpriteGrid/placement model.

## Placement contract

The user's required behavior should be made explicit and permanent:

```text
Pickup may start from CLOSED or OPEN.
Inventory parcels do not preserve open/closed state.
Placement always reconstructs CLOSED geometry and CLOSED sprites.
```

This is simpler and safer than serializing an open state because:

- all current parcel identities remain reusable;
- no new items or localization are required;
- closed placement/rotation code remains the only placement authority;
- no open-state SpriteGrid is needed in inventory;
- a transported gate cannot be reinstalled in the folded/open geometry.

## Suggested implementation order

1. Implement open pickup for `IndustrialGarageDoor` as the reference.
2. Validate open N/W selection, 3 parcels, closed replacement and health preservation.
3. Generalize the validated alias rule to all seven garages.
4. Implement Chain-Link large-gate open pickup as the `DoubleDoor` reference.
5. Run the targeted member-2/member-3 durability check around vanilla opening.
6. Once that reference is clean, generalize the same open-alias rule to all six large-gate families.

No new `media/scripts` parcel definitions should be necessary; the existing parcel items are intentionally reused.

## Revalidation trigger

Recheck this design if Project Zomboid changes:

- `GarageDoor` or `DoubleDoor` raw property schemes;
- `IsoDoor.getGarageDoorIndex()` / garage prev-next traversal;
- `IsoDoor.getDoubleDoorIndex()` / `getDoubleDoorObject()`;
- garage `+8` sprite relation;
- `DoubleDoor` per-index sprite offsets or open/closed coordinate arrays;
- `toggleDoubleDoorObject()` relocation/reconstruction behavior;
- vanilla Moveables open-door eligibility rules.
