# Large-gate open-state Pickup

Status: **topology/open-state behavior runtime validated on B42.20.3; canonical-IsoDoor representation migration pending runtime revalidation.**

This note records the final large-gate open-state transport behavior and the approaches rejected during runtime testing. Representation-specific historical findings are retained where useful, but the current LMION output invariant is canonical `IsoDoor`.

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

All LMION-reinstalled members are now expected to finish as `IsoDoor`, regardless of whether the source member was `IsoDoor` or `IsoThumpable(isDoor)`.

## Runtime-validated behavior before canonical migration

The reference `DoubleWireGate` path was validated with both world/map and player-built source representations.

Confirmed topology/gameplay behavior:

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
- when an open placement target is physically blocked, the Moveables preview becomes invalid/red and clicking does not place the leaf.

The previous implementation also validated source-class preservation (`IsoDoor` stayed `IsoDoor`, `IsoThumpable` stayed `IsoThumpable`). That result is historical evidence about the old architecture, **not the current desired behavior**. The current expected output after Pickup/reinstallation is always `IsoDoor`.

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
5. Core finalizes each placed member as canonical `IsoDoor`;
6. Core gives the final door its correct open sprite and logical open state **without invoking collective `ToggleDoor()` movement**;
7. restore transported durability;
8. after all four logical members exist with coherent geometry, vanilla DoubleDoor operation works normally again.

The explicit state application changes only the newly placed object's sprite/open flag. It does not ask the engine to relocate DoubleDoor neighbours while the leaf is incomplete.

## Canonical physical representation

A major runtime discovery was that vanilla Moveables `placeMoveableInternal()` creates an `IsoDoor` whenever the placed sprite has `doorN`/`doorW`, even if the picked-up source object was an `IsoThumpable` door.

The former architecture compensated for this by storing:

```text
lmionDoorSourceRepresentation = IsoDoor | IsoThumpable
```

and recreating an `IsoThumpable` after placement when needed. That behavior was implemented and runtime validated, including N/W rotation.

The project intentionally reversed that long-term policy on 2026-08-28. The current contract is:

```text
source IsoDoor
-> Pickup
-> placement
-> IsoDoor

source IsoThumpable(isDoor)
-> Pickup captures gameplay state
-> placement
-> IsoDoor
```

Old development parcels may still contain `lmionDoorSourceRepresentation`; the key is intentionally ignored.

This reversal was not made because representation preservation failed technically. It was made because LMION is intended to own door gameplay and future addons; maintaining both `IsoDoor` and `IsoThumpable` as persistent LMION backends would force future features such as Locks/Repair/access control to maintain parallel implementations where the engine classes expose different capabilities.

See `Research/Architecture/DoorObjectAbstraction.md`.

## Durability preservation across vanilla opening/closing

Vanilla opening/closing can remove/recreate DoubleDoor members 2 and 3. Object identity is therefore not stable across a transition.

`LargeGateOpenState.lua` observes real vanilla transitions and uses Core state snapshots:

```text
Doors.captureDoorState(old members)
-> vanilla recreation
-> Doors.restoreDoorState(new members)
```

Previous runtime validation confirmed:

- world/map `IsoDoor` gate members keep their engine durability through open/close;
- constructed `IsoThumpable` source members kept their native vanilla durability through open/close;
- deliberately damaged members keep their damage after open/close;
- `lmionDoorMaxHealth` remains unset when no logical override is actually required.

Under the canonical policy, new LMION-built/reinstalled gate members are `IsoDoor`. Source `IsoThumpable` max health is still captured through Core and transferred as effective logical max when the canonical `IsoDoor` cannot express that max natively.

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

### 1. Persist the source Java representation after LMION reinstallation

Rejected as a **long-term architecture policy**, despite successful runtime implementation. It creates two persistent physical backends for future LMION features. `IsoThumpable` remains a valid source/input representation; final LMION output is `IsoDoor`.

### 2. Close the full gate before open Pickup

Rejected. It visibly mutates the untouched leaf and unnecessarily couples Pickup to the gate's ability to close.

### 3. Reinstall closed, then force the existing open partner closed

Rejected. The partner's closed footprint may be blocked by vehicles/objects. Forcing a rebuild would bypass world collision.

### 4. Allow a closed/open hybrid and rely on the next click to fix it

Rejected. Runtime testing produced broken DoubleDoor geometry/movement.

## Revalidation triggers

Recheck this note when:

- the canonical-IsoDoor migration is runtime tested (update status/results);
- PZ changes DoubleDoor open/closed offset logic;
- `IsoDoor.getDoubleDoorObject()` / `toggleDoubleDoor` behavior changes;
- Moveables stops automatically constructing `IsoDoor` for `doorN`/`doorW` sprites;
- LMION changes parcel state serialization;
- a new large-gate family proves different open-layout or sprite-offset semantics.
