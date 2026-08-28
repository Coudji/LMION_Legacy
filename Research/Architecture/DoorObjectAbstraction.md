# Door object abstraction

Status: **canonical `IsoDoor` architecture adopted on 2026-08-28; runtime revalidation pending for the new invariant.**

## Decision

Project Zomboid can expose a semantic door through two Java representations:

- `IsoDoor` for map/world-authored doors and specialized native door mechanics;
- `IsoThumpable(isDoor)` for construction-driven engine objects.

LMION still recognizes and can read both representations, but they no longer have equal status.

> **A door created, finalized or reinstalled by LMION is represented as `IsoDoor`.**

`IsoThumpable(isDoor)` is accepted as an external/source/temporary engine representation. It is not the canonical LMION world representation.

This is intentionally consistent with the base world: doors, gates and garage doors authored in the map are already `IsoDoor`; `IsoThumpable` mainly enters the door lifecycle through player construction.

LMION does **not** scan the world and convert arbitrary `IsoThumpable` objects. Canonicalization happens only at explicit LMION ownership boundaries such as LMION_Build finalization and LMION_Pickup reinstallation.

## Why the previous representation-preservation policy was reversed

The representation refactor originally preserved both `IsoDoor` and `IsoThumpable` as persistent LMION door forms. That work was useful because it separated identity/state/topology from Java class and exposed the real engine differences.

However, preserving both forms as a long-term gameplay contract creates two physical backends for future LMION features.

Examples already visible in the engine:

```text
max health
IsoThumpable -> native setMaxHealth()
IsoDoor      -> LMION logical max in modData when needed

future access control
IsoThumpable -> native padlock/code capabilities exist
IsoDoor      -> those same capabilities are not exposed equivalently
```

A common Core API can hide call-site differences, but it cannot eliminate the cost of maintaining two different functional implementations behind that API. That cost becomes especially undesirable because LMION is intended to be the authoritative door framework and a stable target for future addons.

The project therefore chooses one canonical physical representation and lets Core provide missing LMION gameplay state where vanilla `IsoDoor` does not expose a suitable field/API.

This is **not a rollback of the architectural refactor**. The refactor's important benefits remain:

- Core owns door identity independent from engine input class;
- Core owns topology and normalized state;
- Build and Pickup remain independent modules;
- gameplay modules delegate engine-specific state handling to Core;
- addons target the LMION API rather than Project Zomboid's class split.

Only the persistent representation invariant changed.

## Core contract

Object/input helpers:

```text
isIsoDoor(object)
isThumpableDoor(object)
isDoorObject(object)
getDoorRepresentation(object)   # informational/source metadata
isCanonicalDoor(object)
ensureCanonicalDoor(object, options)
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

Placement finalization:

```text
finalizePlacedDoor(object, options)
```

`isDoorObject()` deliberately continues accepting `IsoThumpable(isDoor)` so Core/Pickup/Debug can inspect or capture external/legacy/vanilla-built inputs. `getDoorRepresentation()` remains useful diagnostics; it must not be used to choose the final representation of an LMION-managed door.

## Canonicalization boundaries

### LMION_Build

Vanilla `ISBuildIsoEntity` may first create an `IsoThumpable` door.

The normal LMION lifecycle is now:

```text
LMION_Build recipe
-> ISBuildIsoEntity temporary engine object
-> Build post-build scan identifies the completed EntityScript door
-> Core.ensureCanonicalDoor(...)
-> final IsoDoor
-> Core applies Build-owned durability/state
```

Build does not implement the conversion itself and does not need to know how Core performs it.

Fresh construction does not inherit transient `locked` / `lockedByKey` flags from the temporary `IsoThumpable`.

### Garage construction timing

Garage doors follow the same canonical `IsoDoor` policy but need earlier timing.

B42.20.3 bytecode and B42.20.4 runtime established that `IsoThumpable` does not implement complete native GarageDoor interaction mechanics. Each garage SpriteConfig therefore calls:

```text
OnCreate = LMION.Doors.onCreateGarage
```

Runtime tracing on B42.20.4 confirmed:

```text
OnCreate receives IsoThumpable
-> Core converts to IsoDoor
-> OnCreate returns IsoDoor
-> Build post-build scan later finds the same IsoDoor
```

Thus garage doors are no longer a different representation rule; they are simply an **early canonicalization case**.

### LMION_Pickup reinstallation

Pickup transports gameplay state, not the Java class of the source object.

```text
source IsoDoor
-> Pickup
-> reinstallation
-> IsoDoor

source IsoThumpable(isDoor)
-> Pickup
-> reinstallation
-> IsoDoor
```

Old development parcels may still contain `lmionDoorSourceRepresentation`. That key is intentionally ignored; source class is no longer transported gameplay state.

There is no automatic conversion of an existing old-save `IsoThumpable` merely because it is loaded. It becomes canonical when it crosses an LMION boundary such as Pickup/reinstallation. A separate save-migration feature can be designed later if ever needed.

## Max-health policy

Core still understands both source representations because it may need to capture a vanilla/legacy `IsoThumpable` before canonicalization.

`IsoThumpable` exposes native `setMaxHealth()`. `IsoDoor` exposes `getMaxHealth()` but no useful public `setMaxHealth()`.

Therefore:

```text
external/source IsoThumpable
-> read its native current/max state

canonical LMION IsoDoor
-> current health uses IsoDoor health
-> when engine max cannot represent LMION's value,
   effective max uses modData.lmionDoorMaxHealth
```

Do not create a logical max merely because Core recognizes a world door. World/map durability remains vanilla by default unless a future sandbox policy explicitly opts into LMION profile durability.

## Durability ownership

```text
world/map door
-> vanilla durability by default

vanilla/legacy IsoThumpable input
-> Core may read its actual state

LMION_Build construction
-> Build decides initial construction durability
-> Core applies it to the canonical IsoDoor

LMION_Pickup
-> never decides durability
-> captures actual source health/effective max
-> restores it onto the canonical IsoDoor
```

## State recreation and DoubleDoor transitions

Vanilla DoubleDoor transitions may remove/recreate physical members. A Java object reference is not persistent gameplay state.

The existing Core boundary remains valid:

```text
Doors.captureDoorState(oldMember)
-> vanilla transition/recreation
-> Doors.restoreDoorState(newMember, snapshot)
```

The snapshot can still record the source representation for diagnostics, but representation is not restored as a gameplay choice.

Future Locks state should extend this normalized state boundary rather than making gameplay modules own Java-class-specific persistence.

## Large gates

Logical topology remains independent from Java class:

```text
large gate
├── A = 2 DoubleDoor members
└── B = 2 DoubleDoor members
```

The previous runtime validation proved that Core/Pickup could handle both world `IsoDoor` and constructed `IsoThumpable` members and preserve health/topology. That research remains useful evidence about engine inputs.

The new expected LMION lifecycle is:

```text
world/map large gate          -> already IsoDoor
new LMION_Build large gate    -> final IsoDoor members
legacy/vanilla thumpable gate -> accepted by Pickup -> reinstalled as IsoDoor
```

Open-state placement still follows the existing invariant:

```text
partner absent   -> place closed
partner closed   -> place closed
partner open     -> place open
partner invalid  -> refuse reconnection
```

Canonicalization must not change that topology or collision policy.

## Rejected long-term policy: persistent representation preservation

Do not reintroduce the rule:

> "If the source was `IsoThumpable`, LMION must recreate an `IsoThumpable`."

That policy was implemented and successfully runtime-tested, so it is not rejected because it was technically broken. It is rejected because it makes LMION support two persistent physical backends for every future feature, including features where the classes expose materially different capabilities.

Reconsider only if Project Zomboid later unifies the two classes enough that supporting both has negligible functional cost, or if LMION's product goal changes away from being the authoritative door framework.

## Pending runtime validation after canonical migration

The migration should be verified with:

1. fresh LMION 1x1 construction -> `IsoDoor`, correct health/effective max, unlocked;
2. fresh LMION large-gate construction -> all members `IsoDoor`, native DoubleDoor synchronization intact;
3. fresh LMION garage -> all three members `IsoDoor`, unlocked, synchronized;
4. Pickup/reinstall a world `IsoDoor` -> `IsoDoor`, health/effective max preserved;
5. Pickup/reinstall a legacy/vanilla-built `IsoThumpable` door or gate -> final `IsoDoor`, health/effective max preserved;
6. open large-gate leaf Pickup/reconnection -> topology/open-state behavior unchanged.

Until this matrix is runtime-tested, the architectural decision is final but the implementation should be treated as awaiting integration validation.
