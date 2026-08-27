# Large-gate open-state Pickup

Status: **implemented; runtime validation pending**.

## Contract

Large gates keep their existing two-parcel-per-leaf transport model. Open state is a world-only state and is never transported.

```text
closed gate -> Pickup selected leaf -> 2 closed canonical parcels -> placement closed
open gate   -> vanilla close -> reacquire selected leaf -> 2 closed canonical parcels -> placement closed
```

Pickup remains leaf-local: selecting either physical leaf removes only that leaf after the complete gate has been normalized to the closed layout.

## Runtime topology evidence

Full N/W closed/open reports were captured for `DoubleWireGate` and `LargeFarmGate`. Both families use the same vanilla `DoubleDoor` topology.

Closed layouts:

```text
N: 1 - 2 - 3 - 4

W: 4
   3
   2
   1
```

Open layouts:

```text
N: 2         3
   1         4

W: 4 - 3

   1 - 2
```

Members 1 and 4 stay on stable anchor squares. Members 2 and 3 are relocated perpendicular to the closed gate footprint and are recreated by vanilla.

The runtime reports also confirm vanilla's stable open-sprite offsets by facing/logical index:

```text
N: index 1 +5, index 2 +3, index 3 +4, index 4 +4
W: index 1 +4, index 2 +4, index 3 +5, index 4 +3
```

`LargeGateOpenState` derives the open aliases at runtime from the canonical closed leaf specs using this engine rule. Closed sprites remain the only inventory/placement identities.

## Open Pickup

All known closed and open large-gate sprites are marked `IsMoveAble` at runtime. Open aliases inherit tool/skill/item metadata from their corresponding closed sprite, so the Moveables cursor can recognize any open member.

`canPickUpMoveable` remains read-only. Actual mutation happens only in `pickUpMoveable`:

1. identify the selected logical leaf from the open sprite;
2. snapshot/normalize durability for all four logical members;
3. resolve a stable logical member 1/4 anchor;
4. call vanilla `ToggleDoor(character)` to close the complete gate;
5. never reuse relocated member 2/3 references;
6. reacquire the requested leaf from the now-closed gate;
7. run the existing two-parcel closed-state pickup path.

If vanilla refuses to close the gate, Pickup aborts instead of removing an open geometry.

## Durability preservation

Vanilla `toggleDoubleDoorObject` recreates `IsoDoor` members 2 and 3 without copying their health/modData. This was visible in runtime reports as inner members reverting to `health=100`, `lmionMaxHealth=<unset>` while stable members 1/4 retained LMION durability.

LMION now preserves this state at the toggle boundary:

- `OnObjectAboutToBeRemoved` for logical member 2 occurs after its sprite/open flag has switched but before it leaves its previous-layout square;
- using the known previous N/W layout, LMION resolves all four pre-toggle members and snapshots their health/effective max health;
- vanilla completes the 1 -> 2 -> 3 -> 4 toggle/recreation;
- `OnContainerUpdate` verifies the complete target layout and restores the four snapshots to the new objects.

This preserves exact member durability for future open/close cycles, including members 2/3.

### Recovery of already-tainted gates

A gate that was opened before this fix may already have lost the exact historical durability of members 2/3. That information no longer exists in the world object and cannot be reconstructed exactly.

For Pickup, LMION normalizes such a member using the surviving partner on the same leaf as the effective-max reference and scales the current engine condition onto that max. This prevents a vanilla `100/100` recreated member from becoming a permanent 100-HP parcel, but it cannot recover damage vanilla had already erased before LMION observed the gate.

## Runtime validation

Representative tests should cover `DoubleWireGate` and `LargeFarmGate` in N and W:

- open any member, enter Pickup, and confirm the leaf is recognized;
- pick from both an anchor member and a relocated inner member;
- confirm the complete gate closes through vanilla before removal;
- confirm exactly two parcels for the selected leaf;
- rotate the parcels and place them; placement must always be closed;
- confirm the untouched leaf remains closed and usable;
- assign unequal health to members while closed, open/close, and verify the same four health/max values survive;
- repeat open -> Pickup -> replace and verify parcel/replacement health preservation;
- verify the existing Farm Gate closed pickup/placement previews remain clean in N/W.

No `media/scripts` item definitions changed in this implementation; the behavioral changes are Lua/runtime-property based.
