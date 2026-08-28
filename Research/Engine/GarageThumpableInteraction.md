# Garage-door interaction on `IsoThumpable`

Status: **B42.20.3 bytecode/API verified; B42.20.4 runtime failure reproduced; `IsoThumpable` garage representation rejected for LMION; `OnCreate` replacement lifecycle runtime-validated.**

## Decision

LMION garage doors are a deliberate representation exception:

```text
world/map garage      -> IsoDoor
LMION-built garage    -> temporary build IsoThumpable -> SpriteConfig OnCreate -> IsoDoor
Pickup/reinstallation -> IsoDoor
```

Ordinary 1x1 doors and large DoubleDoor gates keep their representation-preservation rules. This exception applies only to the three-panel `GarageDoor` topology.

## Validated construction lifecycle — B42.20.4

The pre-refactor implementation contained two mechanisms that could appear to participate in garage conversion:

```text
1. SpriteConfig.OnCreate = LMION.Doors.onCreateGarage
2. BuildHook post-build rescan by EntityScript
```

Temporary runtime instrumentation was added specifically to determine whether both were required.

For a three-member White Garage Door, every member produced this sequence:

```text
OnCreate enter       -> IsoThumpable
OnCreate replacement -> IsoDoor
OnCreate return      -> IsoDoor
post-build found     -> same final representation: IsoDoor
post-build final     -> IsoDoor
```

Observed members covered GarageDoor indices 3, 2 and 1.

This proves:

> **`SpriteConfig.OnCreate` is the actual and sufficient representation-conversion path on B42.20.4.**

The post-build scan does not need to convert garage representation. It remains useful as the generic LMION_Build initialization phase that locates the actual completed object by EntityScript and applies Build-owned gameplay stats.

Therefore the architecture is:

```text
ISBuildIsoEntity creates temporary garage IsoThumpable
-> SpriteConfig.OnCreate converts it once to IsoDoor
-> vanilla keeps that returned IsoDoor
-> BuildHook later finds the already-final IsoDoor
-> BuildHook/Core initialize Build-owned durability/name/state only
```

Do not reintroduce a second post-build garage conversion unless a future PZ version produces new runtime evidence that the OnCreate replacement no longer survives.

## Construction lock-state caveat

The temporary construction `IsoThumpable` must not be treated as authoritative for all persistent state during conversion.

A refactor temporarily used the generic `Doors.captureDoorState()` / `restoreDoorState()` pair when converting the garage member. That also copied `locked` / `lockedByKey` from the temporary construction object and produced a freshly built garage that was unexpectedly locked.

The old validated garage conversion intentionally used a narrower state transfer:

```text
preserve name
preserve modData
preserve keyId
preserve current health
force locked = false
force lockedByKey = false
```

LMION therefore keeps that garage-specific construction behavior. Generic state capture/restore remains appropriate for transport/recreation paths where the source object is a real gameplay door, but not blindly for a temporary build object.

## Runtime evidence — rejected `IsoThumpable` garage representation

A constructed garage left as `IsoThumpable` produced both an invalid SpriteConfig warning and fatal null-sprite failures:

```text
SpriteConfig.initObjectInfo -> Invalid SpriteConfig object! scripted object = GreyGarageDoor

LightingJNI.updateChunk
-> IsoThumpable.getSprite() == nil
-> NullPointerException

IsoPlayer.performContextualAction
-> IsoThumpable.ToggleDoor()
-> IsoThumpable.ToggleDoorActual()
-> getSprite().getProperties()
-> NullPointerException
```

The contextual player action reaches `IsoThumpable.ToggleDoor()` directly in Java, so wrapping the Lua `ISOpenCloseDoor.complete` action cannot make this representation reliable.

## Constructor / sprite-state mismatch

Vanilla `ISBuildIsoEntity` treats garage open geometry specially. For garage doors it discards the ordinary `openFace` construction mapping because the open shape is not the same multi-square footprint as the closed shape.

The temporary build object is therefore created as an `IsoThumpable` from the closed sprite only.

The relevant `IsoThumpable` constructor stores that closed/current sprite, but it does not implement the garage-specific `+/-8` closed/open sprite derivation used by `IsoDoor`.

By contrast, `IsoDoor(IsoCell, IsoGridSquare, IsoSprite, boolean)` detects the `GARAGE_DOOR` sprite type and derives the matching open or closed sprite using the garage-specific offset. This gives every physical garage member a valid native closed/open pair.

## Toggle behavior mismatch

`IsoDoor.ToggleDoorActual()` contains a dedicated garage branch. It performs the garage obstruction logic and calls the collective garage helper so all three linked members change state together.

`IsoThumpable.ToggleDoorActual()` contains a DoubleDoor branch but no equivalent GarageDoor branch. It follows the ordinary single-door path instead.

Therefore a theoretically repaired `IsoThumpable` garage would still require LMION to reproduce behavior that `IsoDoor` already owns natively.

## Why not bridge it in Lua

A complete `IsoThumpable` garage implementation would need LMION to own at least:

- correct open-sprite initialization for all members;
- all player interaction paths, including direct Java contextual actions;
- collective three-member toggling;
- whole-garage obstruction checks;
- multiplayer synchronization semantics;
- mixed/open-state recovery;
- future compatibility with engine garage changes.

That would violate the project rule that vanilla owns physical opening mechanics whenever a native representation already provides them.

## Static helper caveat

The static `IsoDoor.getGarageDoor*` topology helpers can identify/traverse `IsoThumpable` garage members. That does **not** mean `IsoThumpable` is a complete garage representation.

Likewise, directly using `IsoDoor.toggleGarageDoor(thumpable, ...)` is not adopted as a generic adapter. B42.20.3 bytecode contains class-specific/network handling that is authored around the native `IsoDoor` garage path. LMION should not depend on that mixed-class path merely because some topology helpers accept `IsoObject`.

## Durability with the `IsoDoor` exception

Using `IsoDoor` does not prevent LMION from owning constructed-garage durability.

`IsoDoor` exposes current health but no useful native max-health setter. Core already handles this representation through:

```text
actual current health -> IsoDoor.setHealth(...)
effective max health  -> modData.lmionDoorMaxHealth
```

After OnCreate returns the final IsoDoor, the generic Build post-build initialization applies the Build-owned durability to that actual object.

Pickup captures/restores the same effective max and current health per segment.

Thus the stable contract is:

> **Vanilla `IsoDoor` owns garage mechanics; LMION modData/Core owns any logical durability state the native class cannot store.**

## Rejected approaches

Do not revive `garage = IsoThumpable` only for representation consistency with ordinary construction. The B42.20.3 JAR and B42.20.4 runtime failure show that garage doors are a genuine engine special case.

Do not add a redundant second garage representation conversion in BuildHook while OnCreate remains runtime-validated. The post-build scan has a separate purpose: applying Build-owned state to the already-final object.

Do not blindly reuse full generic door-state restoration when converting temporary build objects. Construction temporaries may contain lock flags that are not intended gameplay state.

Reconsider these conclusions only if a later PZ build changes the observed lifecycle or adds complete native GarageDoor handling to `IsoThumpable`.
