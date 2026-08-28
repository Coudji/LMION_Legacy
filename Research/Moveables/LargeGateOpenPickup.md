# Large-gate open-state Pickup

Status: **runtime validated on B42.20.3**.

This note records the final large-gate open-state transport behavior and, importantly, the approaches that were rejected during runtime testing.

## Final gameplay contract

Large gates keep the existing two-parcel-per-leaf transport model.

Open/closed state is **not stored in the parcels**. Instead, the world state at the target location decides how a leaf is reinstalled.

```text
Pickup
------
closed gate -> remove selected leaf directly -> 2 canonical closed parcels
open gate   -> remove selected leaf directly -> 2 canonical closed parcels

Placement
---------
no partner leaf present -> place selected leaf closed
partner leaf closed     -> place selected leaf closed
partner leaf open       -> place selected leaf open
partner leaf incoherent -> refuse reconnection
```

The untouched partner leaf is never toggled, moved or rebuilt merely to make Pickup/placement possible.

## Runtime-validated behavior

The reference `DoubleWireGate` path was validated with both world/map and player-built representations.

Confirmed behavior:

- a closed leaf can be picked up and reinstalled;
- an open leaf can be picked up without closing the complete portal first;
- the other leaf remains visually and logically untouched during open Pickup;
- the two parcels always use the canonical closed transport identity;
- placement with no matching partner produces a closed leaf;
- placement beside a closed matching partner produces a closed leaf;
- placement beside an open matching partner produces an open leaf in the correct open geometry;
- after correct reassembly, vanilla DoubleDoor synchronization resumes normally;
- current health/effective max survive Pickup/replacement;
- durability survives N/W rotation before placement;
- source Java representation survives Pickup/replacement (`IsoDoor` stays `IsoDoor`, `IsoThumpable` stays `IsoThumpable`);
- when an open placement target is physically blocked, the Moveables preview becomes invalid/red and clicking does not place the leaf.

That last point is important: LMION does not bypass world collision just to restore a logical gate state.

## Why the old forced-close approach was removed

The first open-Pickup implementation normalized the full gate to closed before removing one leaf:

```text
open gate
-> snapshot state
-> vanilla ToggleDoor()
-> gate closes
-> reacquire selected closed leaf
-> Pickup
```

This worked mechanically but had a bad visible side effect: when the selected leaf disappeared, the untouched leaf could appear to close by itself. It also made Pickup depend on the complete gate being able to close.

Runtime testing proved that vanilla Moveables does not require a door to be closed before removing the world object. LMION can therefore remove the selected open members directly.

Final rule:

> **Pickup must not change the visible open/closed state of the partner leaf.**

`LargeGateOpenPickup.lua` suppresses the DoubleDoor toggle-recreation observer while its direct removals are in progress so `OnObjectAboutToBeRemoved` is not mistaken for a vanilla opening/closing transition.

## Why placement adopts the partner state

A transported parcel does not carry an `open=true/false` flag. That is intentional.

A leaf placed alone is a new incomplete portal and therefore starts closed. When the complementary leaf already exists, however, forcing one state can create an impossible hybrid:

```text
A newly placed closed
B already open
```

Runtime testing showed that this hybrid causes broken DoubleDoor movement/geometry when the player next operates the portal.

Forcing B closed was considered and rejected because B may legitimately be unable to close: a vehicle, crate or other world object may occupy its closed footprint. Rebuilding B into that occupied space would bypass normal collision semantics.

The final rule is therefore:

> **A reinstalled leaf adopts the open/closed state of a valid matching partner. LMION never forces the partner to adopt the state of the new leaf.**

This keeps placement local and respects the existing world geometry.

## Partner detection

Partner detection is geometric and strict.

From the requested closed placement position, LMION derives the complete four-member DoubleDoor anchor and checks the complementary leaf against the known N/W layouts.

The partner must resolve as exactly one of:

- complete closed leaf;
- complete open leaf;
- absent.

A partially matching or contradictory partner is treated as inconsistent and reconnection is refused rather than silently repaired.

This prevents LMION from guessing through an already-corrupted topology.

## Runtime topology evidence

Validated closed layouts:

```text
N: 1 - 2 - 3 - 4

W: 4
   3
   2
   1
```

Validated open layouts:

```text
N: 2         3
   1         4

W: 4 - 3

   1 - 2
```

Equivalent coordinate tables used by the implementation:

```text
N closed: 1=(0,0) 2=(1,0) 3=(2,0) 4=(3,0)
N open:   1=(0,0) 2=(0,1) 3=(3,1) 4=(3,0)

W closed: 1=(0,0) 2=(0,-1) 3=(0,-2) 4=(0,-3)
W open:   1=(0,0) 2=(1,0) 3=(1,-3) 4=(0,-3)
```

Members 1 and 4 are stable anchors across the vanilla transition. Members 2 and 3 relocate perpendicular to the closed footprint and can be recreated by vanilla.

Open sprite aliases are derived from the canonical closed leaf specs with the validated B42.20.3 offsets:

```text
N: index 1 +5, index 2 +3, index 3 +4, index 4 +4
W: index 1 +4, index 2 +4, index 3 +5, index 4 +3
```

## Placement mechanics

LMION does not ask vanilla to perform a DoubleDoor transition while a leaf is incomplete.

For an open reinstallation:

1. detect that the complementary leaf is fully open;
2. compute the target open coordinates from the known layout;
3. validate the actual target squares through the normal Moveables placement checks;
4. create each transported member on its explicit target square using its canonical closed sprite identity;
5. give the restored door its correct open sprite and logical open state **without invoking collective `ToggleDoor()` movement**;
6. restore transported durability/representation state;
7. after all four logical members exist with coherent geometry, vanilla DoubleDoor operation works normally again.

For restored `IsoThumpable` doors Core uses the explicit closed/open sprite pair and a silent per-object state change. This changes the object's own sprite/state only; it does not ask the engine to relocate DoubleDoor neighbors.

## Physical representation preservation

A major runtime discovery was that vanilla Moveables `placeMoveableInternal()` creates an `IsoDoor` whenever the placed sprite has `doorN`/`doorW`, even if the picked-up source object was an `IsoThumpable` door.

This caused:

```text
vanilla/player-built gate
IsoThumpable
-> Pickup
-> vanilla Moveables placement
-> IsoDoor
```

Historically, LMION also normalized doors toward `IsoDoor`, which made this behavior look convenient. The current architecture explicitly rejects that normalization.

Pickup already stores:

```text
lmionDoorSourceRepresentation = IsoDoor | IsoThumpable
```

Core now uses it after vanilla placement:

```text
source IsoDoor      -> placed IsoDoor remains IsoDoor
source IsoThumpable -> temporary vanilla IsoDoor is replaced by IsoThumpable
```

The replacement reuses the engine-created object's GameEntity components, closed/open sprites and orientation, then Pickup restores the carried thumpable parameters and durability.

Runtime validation confirmed that a constructed `IsoThumpable` gate remains `IsoThumpable` after Pickup/replacement, including after changing N/W orientation.

Do not revert to a universal `IsoDoor` representation merely to simplify DoubleDoor code.

## Durability preservation across vanilla opening/closing

Vanilla opening/closing can remove/recreate DoubleDoor members 2 and 3. Object identity is therefore not stable across a transition.

`LargeGateOpenState.lua` observes real vanilla transitions and uses Core state snapshots:

```text
Doors.captureDoorState(old members)
-> vanilla recreation
-> Doors.restoreDoorState(new members)
```

Runtime validation confirmed:

- world/map `IsoDoor` gate members keep their engine durability through open/close;
- constructed `IsoThumpable` gate members keep their native vanilla durability through open/close;
- deliberately damaged members keep their damage after open/close;
- `lmionDoorMaxHealth` remains unset when no logical override is actually required.

This state-preservation observer is separate from direct Pickup removal. Do not make every object removal look like a DoubleDoor toggle.

## Important vanilla durability finding

For `DoubleWireGate`, the scripted entity defines:

```text
skillBaseHealth = 300
```

with no positive fixed base health.

Vanilla build Lua calculates total health from the player's actual relevant skill level. Runtime examples:

```text
MetalWelding 0 -> constructed IsoThumpable 0/0
MetalWelding 3 -> constructed IsoThumpable 900/900
```

The 0/0 result at skill level 0 is vanilla behavior, not LMION corruption.

World/map versions of the same gate were observed as `IsoDoor` 100/100. Core must not silently replace those values with an LMION profile max merely because the object is recognized.

## Rejected approaches

Do not repeat these without new evidence:

### 1. Normalize every transported door to `IsoDoor`

Rejected. It discards a valid engine representation and native `IsoThumpable` capabilities/state.

### 2. Close the full gate before open Pickup

Rejected. It visibly mutates the untouched leaf and unnecessarily couples Pickup to the gate's ability to close.

### 3. Reinstall closed, then force the existing open partner closed

Rejected. The partner's closed footprint may be blocked by vehicles/objects. Forcing a rebuild would bypass world collision.

### 4. Allow a closed/open hybrid and rely on the next click to fix it

Rejected. Runtime testing produced broken DoubleDoor geometry/movement.

## Revalidation triggers

Recheck this note when:

- PZ changes DoubleDoor open/closed offset logic;
- `IsoDoor.getDoubleDoorObject()` / `toggleDoubleDoor` behavior changes;
- Moveables stops automatically constructing `IsoDoor` for `doorN`/`doorW` sprites;
- `IsoThumpable` open/closed sprite APIs change;
- LMION changes parcel state serialization;
- a new large-gate family proves different open-layout or sprite-offset semantics.
