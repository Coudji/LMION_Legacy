# Garage-door interaction on `IsoThumpable`

Status: **B42.20.3 bytecode/API verified; B42.20.4 runtime failure reproduced; `IsoThumpable` garage representation rejected for LMION.**

## Decision

LMION garage doors are a deliberate representation exception:

```text
world/map garage      -> IsoDoor
LMION-built garage    -> temporary build IsoThumpable -> finalization -> IsoDoor
Pickup/reinstallation -> IsoDoor
```

Ordinary 1x1 doors and large DoubleDoor gates keep their representation-preservation rules. This exception applies only to the three-panel `GarageDoor` topology.

## Historical working construction contract

The pre-representation-refactor implementation did **not** rely on `SpriteConfig.OnCreate` alone.

It had two safeguards:

```text
1. SpriteConfig.OnCreate = LMION.Doors.onCreateGarage
   -> first-chance temporary IsoThumpable -> IsoDoor replacement

2. BuildHook after ISBuildIsoEntity.setInfo()
   -> rescan the completed square by EntityScript
   -> if the completed LMION door is still an IsoThumpable
   -> call Core conversion/finalization again
```

The second pass was easy to miss during the refactor because the old `BuildHook` normalized every built LMION door to `IsoDoor`. When the general normalization was correctly removed for 1x1 doors and large gates, the garage-specific safety-net behavior disappeared with it.

B42.20.4 runtime testing after that refactor proved that `OnCreate` by itself is not sufficient to guarantee the final garage representation: a freshly built White Garage Door was inspected as:

```text
class = IsoThumpable
entity = WhiteGarageDoor
group = garage
garageDoorIndex = 2
health = 1800
engineMaxHealth = 1800
```

Therefore the adapted architecture keeps the old two-stage construction contract but narrows its scope:

> **Core owns garage finalization; Build performs the post-build rescan and asks Core to finalize the actual completed object.**

For ordinary doors and large gates the same Core entry point preserves the engine-created representation. Only a completed `IsoThumpable` with valid `GarageDoor` topology is replaced with `IsoDoor`.

Do not remove the post-build garage finalization merely because all seven SpriteConfigs still declare `OnCreate = LMION.Doors.onCreateGarage`.

## Runtime evidence — B42.20.4

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

The post-build finalization must apply Build-owned durability to the **final returned IsoDoor**, never to the stale temporary `IsoThumpable` reference.

Pickup captures/restores the same effective max and current health per segment.

Thus the stable contract is:

> **Vanilla `IsoDoor` owns garage mechanics; LMION modData/Core owns any logical durability state the native class cannot store.**

## Rejected approach

Do not revive `garage = IsoThumpable` only for representation consistency with ordinary construction. The B42.20.3 JAR and B42.20.4 runtime failure show that garage doors are a genuine engine special case.

Do not simplify garage construction to `OnCreate` only. The historical working implementation included a second post-build rescan/finalization pass, and B42.20.4 runtime testing proved that this fallback is materially required.

Reconsider only if a later PZ build adds complete native GarageDoor handling to `IsoThumpable`, including construction sprite initialization, collective toggle/obstruction behavior and network synchronization.
