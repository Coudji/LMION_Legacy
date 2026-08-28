# Garage-door interaction on `IsoThumpable`

Status: **B42.20.3 bytecode/API verified; B42.20.4 runtime failure reproduced; `IsoThumpable` garage representation rejected; `OnCreate` lifecycle runtime-validated.**

## Decision

Garage doors use the same canonical representation now adopted by LMION globally:

```text
world/map garage      -> IsoDoor
LMION-built garage    -> temporary build IsoThumpable -> SpriteConfig OnCreate -> IsoDoor
Pickup/reinstallation -> IsoDoor
```

The garage is therefore **not a representation exception anymore**. It is a timing exception: its temporary construction `IsoThumpable` must be canonicalized earlier than ordinary built doors because complete native GarageDoor mechanics exist on `IsoDoor`.

See `Research/Architecture/DoorObjectAbstraction.md` for the global canonical policy.

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

> **`SpriteConfig.OnCreate` is the actual and sufficient early representation-conversion path on B42.20.4.**

The post-build scan does not need to convert garage representation. It remains the generic LMION_Build finalization phase that locates the actual completed object by EntityScript and asks Core to apply the common canonical/build-state contract. For a garage it simply finds the `IsoDoor` already returned by OnCreate.

Do not reintroduce a second garage-specific conversion unless a future PZ version produces new runtime evidence that the OnCreate replacement no longer survives.

## Construction lock-state caveat

A temporary construction `IsoThumpable` must not be treated as authoritative for all persistent state during canonicalization.

A refactor temporarily used the generic captured snapshot unchanged when converting a garage member. That copied `locked` / `lockedByKey` from the temporary construction object and produced a freshly built garage that was unexpectedly locked.

The validated intended construction result is:

```text
preserve useful construction state (name/modData/keyId/health as applicable)
force locked = false
force lockedByKey = false
```

This lesson now applies to the **generic LMION construction canonicalization boundary**, not only garages. `Doors.ensureCanonicalDoor(..., { preserveLockState = false })` is used for fresh LMION construction. By contrast, state capture from a real gameplay source object remains appropriate for transport/recreation paths.

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

Likewise, directly using `IsoDoor.toggleGarageDoor(thumpable, ...)` is not adopted as a generic adapter. B42.20.3 bytecode contains class-specific/network handling authored around the native `IsoDoor` garage path. LMION should not depend on that mixed-class path merely because some topology helpers accept `IsoObject`.

## Durability on canonical `IsoDoor`

Using `IsoDoor` does not prevent LMION from owning constructed-garage durability.

`IsoDoor` exposes current health but no useful native max-health setter. Core handles this through:

```text
actual current health -> IsoDoor.setHealth(...)
effective max health  -> modData.lmionDoorMaxHealth when native max cannot represent it
```

After OnCreate returns the final IsoDoor, generic Build finalization applies Build-owned durability to that actual object. Pickup captures/restores the same effective max and current health per segment.

Thus the stable contract is:

> **Vanilla `IsoDoor` owns garage physical mechanics; LMION Core/modData owns gameplay state the native class cannot represent.**

## Rejected approaches

Do not revive `garage = IsoThumpable`. The B42.20.3 JAR and B42.20.4 runtime failure show that garage doors are a genuine engine special case.

Do not add a redundant second garage-specific conversion in BuildHook while OnCreate remains runtime-validated. The generic post-build phase has a separate role.

Do not blindly preserve lock flags from temporary construction objects.

The former project-wide representation-preservation policy is also intentionally retired. Garage research helped expose why two persistent physical backends are a poor long-term fit for LMION, but the global decision is documented separately in `Research/Architecture/DoorObjectAbstraction.md`.

Reconsider the garage-specific engine conclusions only if a later PZ build changes the observed lifecycle or adds complete native GarageDoor handling to `IsoThumpable`.
