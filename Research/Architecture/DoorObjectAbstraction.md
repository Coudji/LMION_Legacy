# Door object abstraction

Status: **implemented and runtime validated on B42.20.3**.

## Problem

Project Zomboid uses more than one valid Java representation for a door:

- map-authored doors are normally `IsoDoor`;
- GameEntity/construction paths can produce `IsoThumpable` objects configured as doors.

LMION previously normalized constructed doors to `IsoDoor`. That simplified some callers but discarded capabilities exposed by `IsoThumpable`, most notably native `setMaxHealth()`, and made the physical Java class part of LMION's gameplay identity.

The current rule is:

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

`IsoDoor` exposes `getMaxHealth()` but not a useful public `setMaxHealth()`. `modData.lmionDoorMaxHealth` remains the fallback when LMION intentionally needs a max that the engine cannot represent.

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

Current policy:

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
-> captures and restores the actual source state exposed by Core
```

## Construction representation

LMION_Build no longer converts a newly built `IsoThumpable` door into `IsoDoor` merely for consistency.

The engine-created representation is preserved. Build asks Core to initialize only the gameplay values Build owns.

### Runtime validation with Build enabled

Integration was re-tested with `LMION_Core + LMION_Build + LMION_Pickup + LMION_Debug` enabled after the representation refactor.

Validated 1x1 behavior:

```text
LMION_Build construction
-> engine representation preserved
-> Build durability present
-> Pickup/replacement same facing
-> representation + health/max preserved
-> Pickup/replacement rotated N/W
-> representation + health/max preserved
-> source may be picked up open or closed
-> replacement remains correct in both cases
```

A smoke test on LMION_Build large gates also showed no behavioral regression: construction, opening/closing, Pickup/replacement and vanilla synchronization continued to behave as expected. This large-gate Build-enabled pass was not exhaustive across all six families, so it should be treated as successful integration coverage rather than a six-family matrix revalidation.

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

- physical representation;
- current health;
- effective max health and whether it was a logical override;
- key id;
- locked / locked-by-key state;
- copied modData.

This is intentionally owned by Core so future Locks state can extend the same persistence boundary instead of each gameplay module inventing its own recreation workaround.

## Pickup placement representation

Vanilla Moveables creates an `IsoDoor` for placed sprites carrying `doorN`/`doorW`, even when the picked-up source object was an `IsoThumpable` door.

LMION therefore transports the source representation and corrects the vanilla placement result when necessary:

```text
source IsoDoor
-> Pickup
-> vanilla placement IsoDoor
-> remains IsoDoor

source IsoThumpable
-> Pickup
-> vanilla temporary IsoDoor
-> Core recreates final IsoThumpable
-> Pickup restores thumpable parameters + durability
```

This behavior is runtime validated for 1x1 doors and large-gate leaves, including N/W rotation.

The previous idea of normalizing transported world `IsoDoor` objects into `IsoThumpable` is rejected as a default policy. Representation is part of transported physical state and should be preserved unless a future explicit migration policy has a stronger reason to change it.

## Open-state large-gate placement

Open/closed state is not serialized into the parcels.

When a large-gate leaf is reinstalled, Pickup detects the complementary leaf:

```text
partner absent   -> place closed
partner closed   -> place closed
partner open     -> place open
partner invalid  -> refuse reconnection
```

LMION does not force the existing partner to move or change state. This avoids bypassing collision when the partner's alternate footprint is blocked by a vehicle, crate or other object.

Runtime validation confirmed that blocked target geometry makes the Moveables preview invalid/red and placement is refused.

## Large gates

Large-gate topology remains independent from Java class:

```text
large gate
├── A = 2 DoubleDoor members
└── B = 2 DoubleDoor members
```

A member may be an `IsoDoor` or an `IsoThumpable` door. Core's A/B topology and the engine's DoubleDoor helpers work on the opening structure, not on LMION's choice of one universal concrete class.

Correctly reassembled leaves resume vanilla DoubleDoor synchronization regardless of whether the source gate was map-authored `IsoDoor` or constructed `IsoThumpable`.

## Remaining work for this refactor

The main unresolved functional item is the world-door durability sandbox policy:

```text
World Door Durability
- Vanilla          (default)
- LMION Profiles
```

`Vanilla` must remain non-mutating. `LMION Profiles` should be an explicit opt-in policy for world/map doors and must not overwrite vanilla-construction or LMION_Build ownership rules.

Additional testing across every large-gate family with Build enabled is useful QA, but no current runtime evidence points to a remaining architecture defect there.
