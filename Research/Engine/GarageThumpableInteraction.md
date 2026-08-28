# Garage-door interaction on `IsoThumpable`

Status: **B42.20.3 bytecode/API verified; B42.20.4 runtime symptom reproduced; LMION bridge awaiting runtime validation.**

## Symptom

After LMION stopped forcing constructed garage doors from `IsoThumpable` into `IsoDoor`, a constructed three-panel garage could be picked up and reinstalled while preserving its `IsoThumpable` representation. Opening the restored garage then changed only the selected panel instead of all three.

The observed world state was a mixed garage: one panel open while the two neighboring panels remained closed.

This is not evidence that the three-member topology was lost. It is an engine behavior difference between the two valid door representations.

## Topology helpers support both representations

B42.20.3 bytecode for the static `IsoDoor` garage helpers explicitly supports both concrete classes:

- `IsoDoor.getGarageDoorIndex(IsoObject)`;
- `IsoDoor.getGarageDoorPrev(IsoObject)`;
- `IsoDoor.getGarageDoorNext(IsoObject)`;
- `IsoDoor.getGarageDoorFirst(IsoObject)`;
- `IsoDoor.destroyGarageDoor(IsoObject)`.

Neighbor discovery requires the adjacent garage members to use the same concrete representation, orientation and logical `GarageDoor` index. A complete `IsoThumpable` chain is therefore a valid engine topology.

This supports LMION's representation rule:

```text
world/map garage      -> IsoDoor
constructed garage    -> IsoThumpable
Pickup/reinstallation -> preserve source representation
```

## Toggle behavior is asymmetric

The important difference is in the instance toggle implementation.

### `IsoDoor.ToggleDoorActual()`

B42.20.3 contains a dedicated `GARAGE_DOOR` branch. It performs the garage obstruction check and then calls the collective static helper:

```text
IsoDoor.toggleGarageDoor(this, true)
```

That helper walks the previous/next garage chain and changes all members together.

### `IsoThumpable.ToggleDoorActual()`

The same method contains a dedicated DoubleDoor branch, but **no garage branch**.

After the DoubleDoor check it falls through to the ordinary single-door path:

```text
check this object obstruction
-> toggle this.open
-> swap this closed/open sprite
-> sync this object
```

Therefore an `IsoThumpable` carrying a valid `GarageDoor` sprite property still behaves as a single panel when the player calls its normal `ToggleDoor()`.

This exactly matches the B42.20.4 runtime symptom.

## Why LMION does not convert the garage back to `IsoDoor`

Git history shows that LMION's former `OnCreate = LMION.Doors.onCreateGarage` callback was added specifically to force garage construction into `IsoDoor`. The original SpriteConfig entities existed without that callback.

After the general door-representation refactor, the intended contract is to preserve the physical representation produced by construction rather than normalize everything to `IsoDoor` merely because one engine path is more feature-complete.

The missing garage synchronization is therefore treated as an engine-semantic gap for Core to bridge, not as a reason to revive the old global representation policy.

## Why LMION does not directly call `IsoDoor.toggleGarageDoor()` on a thumpable

The static helper's internal object-toggle code can change either `IsoDoor` or `IsoThumpable` members. That makes a direct call look attractive.

However, B42.20.3 bytecode keeps a local value cast specifically to `IsoDoor` and later dereferences it in the GameClient/GameServer synchronization branch. When the supplied source is an `IsoThumpable`, that `IsoDoor` local is null.

Consequently:

> **Do not use `IsoDoor.toggleGarageDoor(thumpable, ...)` as LMION's generic multiplayer-safe adapter.**

It can enter a null dereference in networked execution even though the topology-walking portion understands thumpables.

## Vanilla Lua interaction entry point

The matching Build 42 vanilla Lua `shared/TimedActions/ISOpenCloseDoor.lua` implements:

```lua
function ISOpenCloseDoor:complete()
    self.item:ToggleDoor(self.character)
    return true
end
```

This is a useful semantic boundary because it lets LMION preserve the selected object's normal vanilla checks and feedback before synchronizing the missing garage siblings.

## LMION bridge

Core wraps `ISOpenCloseDoor.complete` only for complete three-member `IsoThumpable` garage chains.

The sequence is:

```text
capture the three IsoThumpable garage members
-> remember selected member open state
-> run original vanilla ISOpenCloseDoor.complete
-> if selected member did not change, stop
-> if it changed, align the other two members with ToggleDoorSilent()
-> RecalcAllWithNeighbours on changed sibling squares
-> sync changed siblings with public syncIsoThumpable()
```

Important properties:

- `IsoDoor` garages are untouched and continue using the native garage branch;
- non-garage `IsoThumpable` doors are untouched;
- the player-selected panel still owns lock, barricade, obstruction and sound behavior;
- siblings are changed only after the selected panel actually changed;
- the adapter uses public Lua-facing methods rather than private/internal `sync(int)`;
- a previously mixed open/closed garage can be healed on the next successful toggle because all siblings are aligned to the selected result.

## Remaining obstruction difference

There is one known semantic difference that this first bridge intentionally does not duplicate.

`IsoDoor` has a private whole-garage obstruction helper used before collective garage toggling. `IsoThumpable.ToggleDoorActual()` only checks its own ordinary door obstruction.

Therefore a future runtime test should cover closing an open constructed garage while an obstacle affects another member's path. If that produces a concrete gameplay bug, Core should gain a narrowly scoped garage obstruction adapter based on verified engine geometry rather than speculative collision code.

Do not expand the bridge before such a failure is reproduced.

## Revalidation triggers

Recheck this note when:

- PZ adds native garage handling to `IsoThumpable.ToggleDoorActual()`;
- `IsoDoor.toggleGarageDoor()` network behavior changes;
- garage topology helpers stop accepting both door representations;
- `ISOpenCloseDoor.complete` stops being the normal player toggle boundary;
- LMION changes its representation-preservation contract.
