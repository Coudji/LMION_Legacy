# Let Me In... Or Not — Development

## Current modules

The Build 42 project currently contains four internal Mod IDs:

- `LMION_Core`
- `LMION_Build`
- `LMION_Pickup`
- `LMION_Debug`

`LMION_Build`, `LMION_Pickup` and `LMION_Debug` require `LMION_Core`. Build and Pickup do not depend on each other, and normal gameplay modules do not depend on Debug.

A future real repair feature should be its own gameplay module depending on Core rather than being folded into Build. Core already owns the low-level logical-health repair primitive; a future Repair module should own tools, materials, skills, timed actions and player-facing repair UX.

## Current development state

The active simple-door reference is `CherryDoor`.

Validated runtime behavior now includes:

- LMION naming/localization in construction, Pickup and inventory;
- dedicated Pickup item identity;
- frame-aware pickup replacement through vanilla Moveables;
- preservation of current health through pickup and re-placement;
- preservation of LMION logical max health through pickup and re-placement;
- engine-facing material overrides with alias-safe property verification;
- world-door adoption of an LMION durability max;
- preservation of pre-existing damage when a world door is adopted;
- repairing an `IsoDoor` above its engine max-health value up to the LMION logical max.

The repository root now contains `CURRENT_STATE.md`. Treat it as the handoff document for active development: it records validated behavior, temporary canaries, important engine limitations, guardrails and the next intended milestones. Read it before changing systems that already have runtime validation.

Core now intentionally maintains a small `LMION.Doors.Profiles` registry for LMION-owned gameplay overrides. This is not a return to the old speculative parallel door model: sprite membership and static opening configuration still come from `GameEntityScript` / `SpriteConfig`, while profiles contain only rules LMION actually overrides such as naming, materials, pickup and durability.

## Development workflow

Enable `LMION_Debug` when developing. Use the in-game `Reload LMION` debug action for Lua-only iteration whenever possible. It reloads already-loaded Lua files under the shared `LMION/` namespace in load order, so active LMION submods are included automatically. In multiplayer, an authorized debug/admin client can also request the corresponding server-side reload.

A full game/server restart is still required after adding brand-new Lua files, changing load order, changing mod metadata/folder structure, changing `media/scripts` definitions, or when engine state cannot be safely reconstructed by Lua reload.

A full restart may also be required after removing or changing monkey patches: old Lua closures can survive a reload. This was observed with the retired `MoveablesTrace.lua` diagnostic.

Avoid speculative Java method calls in debug code: in Debug Mode, Java/Kahlua runtime exceptions can open the Lua debugger even when Lua code uses `pcall`.

Game-loaded LMION Lua and script files must remain free of `--` line comments. Keep rationale in repository documentation instead.

## LMION Inspector

The reusable in-game Inspector lives in `LMION_Debug` and is deliberately limited to openings relevant to LMION. It currently supports:

- selecting arbitrary world squares, multi-selection and persistent highlights;
- listing only door/gate objects from the selected squares;
- concise reports for `IsoDoor` and door-like `IsoThumpable` objects;
- runtime state needed for LMION work: orientation, open state, current health, locks, key ID, barricades and curtains where applicable;
- explicit separation between `lmionMaxHealth` and `engineMaxHealth`;
- `lmionMaxHealth = <unset>` when LMION has not actually stored a logical max;
- LMION condition percentage only when a logical max exists;
- material values from world sprite properties, profile overrides and Moveables parsing;
- double-door and garage-door grouping/link information;
- the attached `EntityScriptName` when the runtime object exposes one;
- copyable reports and an extension registry for future module-specific sections;
- rebuilding the deterministic door Test Zone;
- LMION Lua reload actions for development iteration.

Debug also currently exposes the temporary context action `LMION Repair +50 HP`. It has no tool/material/skill requirement and exists only to validate repair above the engine `IsoDoor.maxHealth`. It is not a final gameplay repair system.

The Inspector no longer dumps generic object internals, property containers, private sprite fields, `UiConfig`, `CraftRecipe` or complete `GameEntityScript` structures. Static opening configuration such as closed/open sprite pairs should be taken from the source scripts / `SpriteConfig` when a gameplay implementation needs it.

## Logical durability model

Production Lua cannot usefully change `IsoDoor.maxHealth`, so LMION stores its authoritative logical max in object modData as:

```text
lmionDoorMaxHealth
```

Current health is still the real `IsoDoor.health` and may exceed the engine max. This has been validated in runtime.

Core exposes:

- `Doors.setEffectiveMaxHealth(object, value)`;
- `Doors.getEffectiveMaxHealth(object)`;
- `Doors.repairHealth(object, amount)`.

The Debug Inspector deliberately reads the actual modData to distinguish an LMION-owned max from a fallback engine max.

### Existing world-door adoption

`BlueMetalDoor` currently has a temporary test durability of `600`. This is not final balance.

When a matching world `IsoDoor` is loaded for the first time:

- if current health equals engine max, it is treated as full life and raised to the LMION max;
- if it is already damaged, current health is kept exactly as-is;
- LMION stores the logical max either way;
- an already-adopted door is not repeatedly migrated on later square loads.

Validated examples:

```text
damaged world door
health = 316
lmionMaxHealth = 600
engineMaxHealth = 500
condition = 52.7%

intact world door
health = 600
lmionMaxHealth = 600
engineMaxHealth = 500
condition = 100.0%
```

Do not replace this migration rule with ratio scaling or unconditional healing without an explicit design change.

### Repair test

The temporary Debug repair action adds 50 HP through `Doors.repairHealth`. Runtime testing confirmed that repair crosses the engine max of 500 and stops at LMION max, for example:

```text
466 -> 516 -> 566 -> 600
```

## Material/profile safety

Engine-facing sprite properties are alias-backed. Arbitrary unknown string values can silently resolve to another valid alias. LMION therefore applies profile material properties with exact readback verification and restores the previous value if the requested value did not survive exactly.

Do not replace that logic with blind `properties:set(name, arbitraryValue)` calls.

Cherry currently uses `Material2 = MetalPlates` as a deliberate diagnostic canary. That is not its intended final material balance.

## Pickup status

Pickup has a working concrete simple-door path through `LMION/Pickup/DoorMoveables.lua`.

For LMION-enabled Moveables doors it currently:

- applies profile naming, item identity, tools, skill, weight and material information to Moveables properties;
- marks configured sprites moveable;
- enforces LMION frame requirements on placement;
- stores `lmionDoorHealth` and `lmionDoorMaxHealth` on the inventory item;
- restores those values onto the actual placed `IsoDoor` returned by the vanilla placement path when possible.

Do not reintroduce the removed intrusive `MoveablesTrace.lua` diagnostic. It was research scaffolding and caused runtime errors despite the actual pickup path succeeding.

## Test Zone

The old dynamic showroom scanner has been retired. The current Test Zone is intentionally explicit and deterministic: `LMION_Debug/42/media/lua/client/LMION/Debug/TestZone/Manifest.lua` defines which opening spawns at each position, while `Spawner.lua` handles world preparation and object creation.

The Test Zone is a development fixture, not a door-discovery system. If its composition changes, update the manifest deliberately rather than adding runtime scanning or classification heuristics.

## Build prototype notes

Build construction definitions live in `LMION_Build/42/media/scripts/`. Construction icons are standalone PNG files under `LMION_Build/42/media/textures/`.

Cherry construction currently uses vanilla-style skill-based health calculation before LMION converts the resulting temporary `IsoThumpable` to `IsoDoor`. Core captures the thumpable max before conversion and stores it as the LMION logical max.

## Documentation workflow

Do not update every document after every commit. Use documentation checkpoints instead:

- update `CURRENT_STATE.md` after a meaningful runtime validation, invalidation, shared-contract change, important engine limitation, or milestone change;
- update `ARCHITECTURE.md` when module ownership or structural guardrails change;
- update `LMION_Design_Notes.md` when a durable gameplay/design decision or engine research conclusion changes;
- update this file when the practical developer workflow or high-level status changes.

The goal is to make the next development session safe and understandable, not to duplicate Git history line by line.

## Next gameplay milestone

Finish `CherryDoor` as the complete reference simple door, then implement `LogDoor`, then validate LMION taking control of a door that already has a vanilla construction path. After those cases are stable, batch the straightforward 1x1 doors before specializing multi-tile gates/double doors/garage doors.
