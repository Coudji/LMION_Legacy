# Door durability and logical max health

Status: **B42.20.3 API/bytecode verified + runtime validated + Git-history recovered**

This note explains why LMION keeps its own persistent maximum health instead of trying to make `IsoDoor.maxHealth` authoritative.

## The original problem

LMION construction can produce doors with gameplay durability values that do not match the engine max health carried by the resulting `IsoDoor` object. The obvious implementation would be to copy both health values from the construction object into the final door:

```text
IsoThumpable health/maxHealth
        ->
IsoDoor health/maxHealth
```

That is not available symmetrically from Lua in B42.20.3.

## API evidence

For B42.20.3, `IsoDoor` publicly exposes:

```text
public int health
public int maxHealth
public void setHealth(int)
public int getHealth()
public int getMaxHealth()
```

but **does not expose `setMaxHealth(int)`**.

`IsoThumpable`, on the other hand, publicly exposes both:

```text
public void setHealth(int)
public int getHealth()
public void setMaxHealth(int)
public int getMaxHealth()
```

This is the concrete API mismatch that forced the LMION logical-max model.

Historical evidence: commit `42cfd0c` (`Core: avoid invalid IsoDoor max-health setter`) explicitly removed a call to `door:setMaxHealth(thumpable:getMaxHealth())` while retaining `door:setHealth(thumpable:getHealth())`.

## Important runtime behavior

`IsoDoor:setHealth(int)` accepts values above `IsoDoor:getMaxHealth()` in the validated runtime path. Therefore the engine max does not act as a hard setter clamp for current health.

This makes the following state both possible and intentional in LMION:

```text
IsoDoor:getHealth()     = 600
IsoDoor:getMaxHealth()  = 500
lmionDoorMaxHealth      = 700
```

For LMION gameplay, the effective condition is 600/700, not 600/500.

## LMION decision

The authoritative gameplay maximum is persisted in object modData under:

```text
lmionDoorMaxHealth
```

Core exposes the low-level helpers:

```text
Doors.setEffectiveMaxHealth(object, value)
Doors.getEffectiveMaxHealth(object)
Doors.repairHealth(object, amount)
```

`getEffectiveMaxHealth()` prefers the LMION modData value and falls back to engine `getMaxHealth()` for objects that LMION has not adopted.

Historical evidence: commit `6c66c7e` (`Core: retain construction max health for LMION doors`) introduced the modData key and effective-max helpers after the invalid engine-setter path had been removed.

## Why LMION did not use another workaround

### Direct Java/private-field mutation

Rejected as a production contract. Even if Debug/reflection could sometimes touch a Java field, that would be version-fragile and would not be a supported Lua API. Debug Mode can also surface Java/Kahlua errors in ways that make speculative reflection unreliable.

### Clamp current health to engine max

Rejected because it would destroy legitimate LMION durability. Pickup/placement experiments showed that LMION health must be restored without applying an engine-max clamp.

### Store only a percentage

Rejected because LMION wants exact durability preservation and future repair rules based on a stable gameplay maximum. Ratio-based migration would also modify already damaged world doors in surprising ways.

## World-door adoption

Existing map doors do not initially carry LMION modData. When a profile defines `durability.worldMaxHealth`, LMION adopts matching world `IsoDoor` objects as their grid squares load.

The validated migration rule is deliberately conservative:

```text
if lmionDoorMaxHealth already exists:
    do nothing
else:
    store the configured LMION max
    if currentHealth == engineMaxHealth:
        treat the door as intact and raise currentHealth to LMION max
    else:
        preserve currentHealth exactly
```

This behavior was introduced in commit `d653aa2` (`Core: adopt world door durability from profiles`).

### Why intact and damaged doors are treated differently

A pristine vanilla door at its old engine max represents "100% condition". When LMION first assigns it a larger gameplay max, preserving the old absolute value would incorrectly turn a pristine door into a damaged one.

An already damaged door contains meaningful world state. LMION therefore does **not** scale it proportionally and does **not** heal it during adoption.

Example:

```text
engine max = 500
LMION max  = 700

world door A: health 500 -> adopted as 700/700
world door B: health 320 -> adopted as 320/700
```

## Lifecycle: why adoption uses `LoadGridsquare`

World objects are not all guaranteed to exist as live Lua-visible objects at mod initialization. Adoption therefore runs when grid squares load:

```text
Events.LoadGridsquare -> Doors.adoptWorldDoorsOnSquare(square)
```

This is an object-lifecycle concern, not a script-definition concern. Running it only at Lua load or `OnGameBoot` would miss world doors that stream in later.

## Construction conversion implication

LMION construction often creates an `IsoThumpable` first and normalizes it into an `IsoDoor`. At that boundary:

- current health can be copied with `IsoDoor:setHealth()`;
- the construction max must be captured before the source object disappears;
- that max is persisted with `Doors.setEffectiveMaxHealth()` on the new door.

This is why the conversion code appears to maintain two health concepts even though vanilla exposes a `getMaxHealth()` on the final `IsoDoor`.

## Pickup / Moveables implication

A recovered LMION door must preserve both:

```text
lmionDoorHealth
lmionDoorMaxHealth
```

on its inventory representation when that state is relevant to the supported pickup path. Placement then restores the current health on the actual placed `IsoDoor` and restores the LMION logical max independently.

The engine max is **not** serialized as the authoritative gameplay maximum.

## Repair implication

Any future LMION Repair module must cap repair at:

```text
Doors.getEffectiveMaxHealth(object)
```

not at:

```text
object:getMaxHealth()
```

Otherwise a door whose current health legitimately exceeds engine max could appear "over-repaired" or become impossible to repair to its intended LMION maximum.

Core should keep the low-level arithmetic/persistence helpers; the future Repair gameplay module should own tools, materials, skills, timed actions and UI.

## Addon contract

Addon authors that interact with LMION door condition should treat these as intentional contracts:

- `lmionDoorMaxHealth` is LMION's authoritative max when present;
- `IsoDoor:getMaxHealth()` remains an engine value and may differ;
- current health may legitimately be greater than engine max;
- use `LMION.Doors.getEffectiveMaxHealth()` rather than reimplementing the fallback rule;
- do not "fix" `health > engineMaxHealth` by clamping it;
- preserve `lmionDoorMaxHealth` when replacing/recreating an LMION-owned door.

The exact modData key is currently a persistence contract because saved games and pickup items rely on it. Renaming it would require migration.

## Revalidation triggers

Recheck this research if any of the following changes:

- Project Zomboid exposes a supported Lua `IsoDoor:setMaxHealth()`;
- engine code begins clamping `setHealth()` to max health;
- LMION moves durability into a dedicated engine component that survives construction/pickup natively;
- saved-game migration changes the meaning of `lmionDoorMaxHealth`.
