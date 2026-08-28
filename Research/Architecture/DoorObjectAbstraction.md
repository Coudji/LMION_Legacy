# Door object abstraction

Status: implementation in progress; runtime validation required.

## Problem

Project Zomboid uses more than one valid Java representation for a door:

- map-authored doors are normally `IsoDoor`;
- GameEntity/construction paths can produce `IsoThumpable` objects configured as doors.

LMION previously normalized constructed doors to `IsoDoor`. That simplified some callers but discarded capabilities exposed by `IsoThumpable`, most notably native `setMaxHealth()`, and made the physical Java class part of LMION's gameplay identity.

The new rule is:

> LMION identifies a door independently from its physical Java representation.

## Core contract

`LMION.Doors` owns the engine-class differences.

Object helpers:

```text
isIsoDoor(object)
isThumpableDoor(object)
isDoorObject(object)
getDoorRepresentation(object)
```

Durability helpers:

```text
getHealth(object)
setHealth(object, value)
getEffectiveMaxHealth(object)
setEffectiveMaxHealth(object, value)
restoreEffectiveMaxHealth(object, value, hadLogicalOverride)
```

State helpers:

```text
captureDoorState(object)
restoreDoorState(object, state)
```

Gameplay modules should use these helpers when the behavior differs between `IsoDoor` and `IsoThumpable`. They do not need wrappers for ordinary shared `IsoObject` operations such as `getSquare()` or `getSprite()`.

## Max-health policy

`IsoThumpable` exposes native `setMaxHealth()`. Core therefore stores its max in the engine.

`IsoDoor` exposes `getMaxHealth()` but not `setMaxHealth()`. `modData.lmionDoorMaxHealth` remains the fallback when LMION needs a max that the engine cannot represent.

The fallback is not created merely because Core recognizes a door.

Examples:

```text
world IsoDoor, vanilla 500/500
-> effective max = engine 500
-> lmionDoorMaxHealth remains unset

IsoDoor that must preserve a logical 850 max
-> engine max may remain 500
-> lmionDoorMaxHealth = 850

constructed IsoThumpable with Build max 850
-> engine max = 850 through setMaxHealth()
-> lmionDoorMaxHealth remains unset
```

## Durability ownership

Recognizing a world door must not silently alter its durability.

Intended policy:

```text
world-authored door
-> vanilla durability by default
-> future sandbox option may explicitly apply LMION profile durability

vanilla construction without LMION_Build
-> vanilla decides durability

LMION_Build construction
-> Build decides construction durability
-> Core applies that value through the appropriate engine adapter

Pickup
-> never decides durability
-> captures and restores the state exposed by Core
```

## Construction representation

LMION_Build no longer converts a newly built `IsoThumpable` door into `IsoDoor` merely for consistency.

The engine-created representation is preserved. Build asks Core to initialize the gameplay values Build owns.

## State recreation

Some vanilla DoubleDoor transitions remove and recreate physical members when a large gate opens or closes. A Java object reference therefore cannot be treated as persistent state.

The current large-gate transition path captures each member through:

```text
Doors.captureDoorState(oldMember)
```

and restores the state after vanilla recreation through:

```text
Doors.restoreDoorState(newMember, snapshot)
```

The snapshot currently carries:

- physical representation for diagnostics/future placement policy;
- current health;
- effective max health and whether it was a logical override;
- key id;
- locked / locked-by-key state;
- copied modData.

This is intentionally owned by Core so future Locks state can extend the same persistence boundary instead of each gameplay module inventing its own recreation workaround.

## Pickup placement representation

The first refactor does not force a class conversion during placement. Vanilla Moveables may recreate whatever representation its normal path produces, and Core restores the transported state onto that object.

A later policy may intentionally normalize a transported world `IsoDoor` into an `IsoThumpable` at placement time. This is technically plausible and could make future native max-health / padlock features easier, but it must be runtime-tested for door behavior, networking, curtains, barricades and interoperability before becoming the default.

## Large gates

Large-gate topology remains independent from Java class:

```text
large gate
├── A = 2 DoubleDoor members
└── B = 2 DoubleDoor members
```

A member may be an `IsoDoor` or an `IsoThumpable` door. Core's A/B topology and the engine's DoubleDoor helpers work on the opening structure, not on LMION's choice of one universal concrete class.
