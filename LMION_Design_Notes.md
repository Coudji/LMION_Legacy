# LMION — Design notes

## Fixed architecture

- One Workshop item.
- Several internal Mod IDs.
- `LMION_Core` orchestrates only shared systems and persistence conventions that are proven necessary by gameplay modules.
- `LMION_Build` owns construction/crafting concerns.
- `LMION_Pickup` is the single user-facing pickup module for passable opening systems.
- `LMION_Debug` owns development-only tooling such as the Inspector, Test Zone, Lua reload helpers and temporary validation actions.
- Internal complexity is handled through focused strategies or feature modules only when a real opening type requires them.

`LMION_Debug` depends on Core, but Core, Build and Pickup do not depend on Debug.

Core deliberately avoids speculative abstractions. The old generic event bus and parallel all-purpose door model were removed because there was no concrete consumer and they duplicated information already available from Project Zomboid runtime objects and `GameEntityScript` / `SpriteConfig` data.

The current `LMION.Doors.Profiles` registry is intentionally narrower: it stores only gameplay facts LMION owns or overrides, such as localized naming, materials, pickup rules, frame requirements and durability policy. Sprite membership and static opening configuration are still derived from `GameEntityScript` / `SpriteConfig`.

## Ownership principle

> Vanilla defines the physical opening mechanics; LMION defines the gameplay rules.

LMION should reuse vanilla door behavior wherever possible for opening/closing, collision, sprite state and other physical mechanics. LMION should own gameplay decisions such as materials, pickup, crafting, durability, repair rules and later specialized transport logic.

`newtiledefinitions.tiles` is research/reference data only and should not be edited for LMION runtime behavior.

## Pickup rule

> If it opens and the player can pass through it, Pickup owns it.

Synchronization between world objects does not automatically make them one inventory item. Pickup identity follows the physical/gameplay unit that makes sense to transport and reinstall.

## General pickup behavior

Pickup is a non-destructive alternative to vanilla dismantling.

For normal hinged doors, current intended eligibility includes appropriate lock/barricade/curtain/tool/skill handling as the profile defines it. The door does not need to be open before removal.

The primary physical condition is current health relative to LMION's logical max where one exists. `modData.itemCondition` is not reliable as the authoritative damage state.

For validated simple LMION doors, Pickup now transports both:

```text
lmionDoorHealth
lmionDoorMaxHealth
```

The actual placed `IsoDoor` is resolved from the vanilla placement result when possible before state is restored.

## Runtime findings

### Generic `IsoDoor`

Multiple visually and behaviorally different opening types use `zombie.iso.objects.IsoDoor`. Runtime class alone is therefore not enough to classify an opening.

Closed/open sprite pairs are static opening configuration. Use `GameEntityScript` / `SpriteConfig` or source script data rather than private-field reflection.

For `IsoDoor` orientation, prefer door-specific orientation data such as `north` / `doorN` / `doorW` over generic direction fields.

### Engine max health limitation

`IsoDoor` exposes current health and max health, but production Lua does not provide a usable `setMaxHealth()` path for `IsoDoor`.

`IsoDoor:setHealth()` does accept values above engine max. This was validated in runtime.

LMION therefore uses object modData key:

```text
lmionDoorMaxHealth
```

as the authoritative gameplay max.

The engine max may remain 500 while LMION current health and logical max are higher. Example validated runtime state:

```text
health = 2540
lmionMaxHealth = 3000
engineMaxHealth = 500
```

Known compromise: vanilla systems that explicitly use `IsoDoor:getMaxHealth()` or `getThumpCondition()` still see the engine max. LMION-owned repair/condition logic must use the logical max instead.

### Existing world-door migration

When LMION first adopts a matching world `IsoDoor` with a configured `worldMaxHealth`:

- if current health equals engine max, the object is treated as full life and current health is raised to the LMION max;
- if current health is already below engine max, current health is kept exactly unchanged;
- LMION stores the logical max in either case;
- a door that already has an LMION max is not re-adopted on every grid-square load.

This rule intentionally avoids both ratio rescaling and artificial healing of previously damaged doors.

Validated test with temporary `BlueMetalDoor` max of 600:

```text
damaged: 316 / 600 logical, engine max 500
intact: 600 / 600 logical, engine max 500
```

The value 600 is test balance only.

### Repair model

Core owns only the low-level operation needed to change current health safely:

```text
Doors.repairHealth(object, amount)
```

It caps against LMION logical max rather than engine max.

Runtime testing with the temporary Debug `+50 HP` action proved that repair can cross 500 and reach 600.

The final repair gameplay system should not live in Build. It should be a separate optional gameplay module depending on Core, with its own tools, materials, skill checks, timed actions and UX.

### Simple / autonomous 1x1 doors

CherryDoor is the active reference implementation.

Validated behavior includes localized naming, dedicated pickup item identity, frame-aware replacement, preservation of current health, preservation of logical max health and repair above engine max.

Cherry is not balance-complete yet.

### Visually glazed doors

Tested doors that look glazed do not appear to contain an independently breakable window component. Do not serialize a door `glassState` unless a real vanilla runtime state is later found.

### Sliding doors

Tested sliding doors are also `IsoDoor` and can share the broad runtime shape of normal 1x1 doors. Do not assume a dedicated sliding-door class exists for classification.

### Double doors and large gates

Large gate pieces tested as `IsoDoor` expose a `DoubleDoor` property and non-negative `doubleDoorIndex` values.

Observed large-gate structure suggests fixed logical member indexes across a grouped opening, but the exact universal leaf/member model is not yet proven across all vanilla types.

Do not encode a universal two-members-per-leaf assumption until more complete families are validated.

### Garage doors

Garage doors are also composed of `IsoDoor` objects, but use a distinct linkage system:

- `doubleDoorIndex = -1`;
- `garageDoorIndex >= 0`;
- `garage.first` identifies the start of the contiguous chain;
- `garage.prev` / `garage.next` link neighboring compatible pieces.

Although vanilla stores separate components, LMION should treat a functioning garage door as one transportable opening rather than exposing individual segments as separate inventory items.

## Material system findings

### Alias safety

Project Zomboid `PropertyContainer` values are backed by `TilePropertyAliasMap`. Setting an unknown string value can silently resolve to the first valid alias rather than preserving the requested value.

LMION engine-facing property writes must therefore verify exact readback and restore the old value if the requested value was not preserved exactly.

This is a hard guardrail. Do not replace it with blind arbitrary-string property writes.

### `MaterialType`

`MaterialType` is a closed engine enum and cannot be freely invented in Lua.

It is useful for engine physical/audio behavior but is not the same thing as destruction salvage material tags.

### `IsoDoor.destroy()` materials

`IsoDoor.destroy()` reads `Material`, `Material2` and `Material3` for salvage and separately handles door hardware such as knobs and hinges.

Observed recognized salvage-facing values include:

- `Wood`;
- `MetalBars`;
- `MetalPlates`;
- `MetalPipe`;
- `MetalWire`;
- `Nails`;
- `Screws`.

`Door` is a vanilla property/tag value, not a physical material.

### Cherry material canary

Cherry currently deliberately uses `Material2 = MetalPlates` to prove that LMION material overrides affect physical destruction/dismantling behavior. This is not intended final balance and must not be mistaken for Cherry's final material design.

## Debug tooling

The LMION Inspector belongs to the dedicated `LMION_Debug` module because it is a developer tool, not gameplay runtime.

The Inspector now deliberately distinguishes:

```text
lmionMaxHealth = <unset>
```

from an actual stored logical max. It also reports engine max separately and only computes LMION condition when a stored logical max exists.

The old intrusive `MoveablesTrace.lua` diagnostic was removed. It wrapped vanilla Moveables functions, caused runtime errors due to assumptions about return values, and was not required for the real Pickup path. Do not reintroduce it casually.

## Build prototype

Build construction definitions live in `media/scripts` and remain the source of truth for current construction entities/recipes.

For Cherry, vanilla-style construction first creates a temporary `IsoThumpable` with skill-based health. LMION captures that object's max health before converting it to `IsoDoor`, then stores the captured value as the logical LMION max.

The final relationship between materials, craft cost and durability is not yet balanced. Avoid assigning exaggerated final PV values before that design is settled.

## Future module ideas

### Repair

Likely scope:

- context/menu action;
- material-dependent repair recipes;
- required tools;
- relevant skill checks;
- timed action;
- health restored per operation;
- eventual failure/waste behavior if desired.

Core should remain responsible only for the low-level logical-health primitive.

### Locksmith

Possible scope includes:

- removable/installable cylinders or barrels;
- Key ID belonging conceptually to the cylinder;
- rekeying;
- duplicating keys from blanks with appropriate tools/machines;
- padlocks and hasps;
- hinge wear/breakage and replacement;
- forced entry based on material, strength, lock type, damage, and injury risk.

### Access Control

Possible scope includes:

- powered keypad/code access;
- mechanical key fallback;
- fail-secure/fail-safe behavior depending on hardware;
- battery-backed keypads;
- RFID/badges;
- exit buttons;
- alarms after repeated failed codes;
- codes/credentials found in notes, maps, zombies, or containers.

## Current milestone order

1. Finish CherryDoor as the complete simple-door reference.
2. Implement and validate LogDoor.
3. Validate LMION takeover of a door that already has a vanilla construction path.
4. Batch straightforward 1x1 doors.
5. Handle multi-tile/double/gate/garage openings separately.
6. Build the real Repair gameplay module after material/craft balance is sufficiently defined.
