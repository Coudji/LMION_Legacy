# LMION — Current development state

Last updated: 2026-08-23

This file is the handoff document for active development. It should be updated after meaningful milestones, validated behavior changes, or architecture decisions. It does not need to change for every experimental commit.

## Project direction

LMION is progressively taking ownership of door gameplay rules while leaving Project Zomboid responsible for the physical object mechanics it already handles well.

Working principle:

> Vanilla defines the physical door mechanics; LMION defines the gameplay rules.

For known openings LMION is expected to own, as needed:

- localized display name;
- materials and salvage-facing properties;
- weight;
- pickup eligibility, tools, skill and break chance;
- frame requirements for placement;
- construction recipes and progression;
- logical durability/max health;
- later, specialized handling for double doors, gates and garage doors.

Do not edit `newtiledefinitions.tiles`; TileDef data is research/reference only.

## Current modules

- `LMION_Core` — shared LMION namespace, door profiles, engine-facing profile application, placement helpers, logical durability state and low-level repair primitive.
- `LMION_Build` — construction/crafting definitions and the hook that converts constructed temporary thumpables into LMION `IsoDoor` objects.
- `LMION_Pickup` — Moveables integration for LMION doors, including pickup/placement rules and transport of door state.
- `LMION_Debug` — Inspector, deterministic Test Zone, reload helpers and temporary validation actions.

Build, Pickup and Debug depend on Core. Build and Pickup remain independent of each other.

A future real repair feature should be a separate gameplay module (for example `LMION_Repair`) depending on Core. Core should keep only the low-level durability/repair primitive; tools, materials, skill, timed actions and repair UX belong outside Core.

## CherryDoor reference status

CherryDoor is the current reference implementation for a simple 1x1 LMION door.

Validated in runtime:

- localized name is used in construction, Pickup and inventory;
- dedicated pickup item is `Base.LMION_CherryDoor`;
- pickup works through vanilla Moveables integration;
- placement requires a matching frame;
- invalid placement uses the vanilla red placement ghost;
- replacement creates a real `IsoDoor`;
- pickup weight is 20;
- hammer/tool and skill requirements are exposed through Moveables;
- current health survives pickup and re-placement;
- logical LMION max health survives pickup and re-placement;
- a constructed CherryDoor can have current health and logical max health above the engine `IsoDoor.maxHealth` of 500.

The tested constructed-door example reached:

```text
health = 3000
lmionMaxHealth = 3000
engineMaxHealth = 500
condition = 100.0%
```

After damage, pickup and replacement, values such as the following were preserved:

```text
health = 2540
lmionMaxHealth = 3000
engineMaxHealth = 500
condition = 84.7%
```

CherryDoor is not yet considered balance-complete.

### Temporary Cherry material canary

Cherry currently deliberately uses:

```text
Material = Door
Material2 = MetalPlates
MaterialType = Wood_Solid
```

`MetalPlates` is a diagnostic canary, not the intended final Cherry material. It proved that LMION can apply engine-facing sprite properties and that physical destruction/dismantling reacts to them. Do not treat this as final balance/material design.

Once material/craft balance is settled, Cherry should be changed to its intended material setup.

## Door profiles

`LMION.Doors.Profiles` is now an intentional gameplay-override registry. It is not meant to duplicate every fact already available from `GameEntityScript` / `SpriteConfig`.

A profile contains only LMION-owned rules that need overriding or additional state, for example:

- naming/localization;
- materials;
- pickup rules;
- frame requirement;
- durability policy.

Sprite membership is derived from the matching `GameEntityScript` / `SpriteConfig` tile names rather than from hardcoded sprite ranges.

## Material property safety

Build 42's `PropertyContainer:set(name, value)` resolves values through `TilePropertyAliasMap`. Unknown values can collapse to alias index 0 and silently become a different valid value.

Observed examples during research included arbitrary `CustomName` / `MoveType` strings resolving to unrelated aliases.

Therefore engine-facing profile application must remain alias-safe:

1. save the previous property value;
2. set the requested known value;
3. read the value back;
4. keep it only if the exact requested value survived;
5. otherwise restore the previous state.

Do not blindly write arbitrary strings into sprite property containers.

### Verified IsoDoor destruction material path

`IsoDoor.destroy()` reads `Material`, `Material2` and `Material3` and then uses the engine salvage path. Relevant recognized values observed in that path include:

- `Wood`;
- `MetalBars`;
- `MetalPlates`;
- `MetalPipe`;
- `MetalWire`;
- `Nails`;
- `Screws`.

Door knobs and hinges are handled separately by `IsoDoor.destroy()`.

`Door` is a vanilla property/tag value, not a physical material. Do not describe it as one.

## Logical max-health model

Production Lua has `IsoDoor:getMaxHealth()` and `IsoDoor:setHealth()`, but no usable production `setMaxHealth()` for `IsoDoor`.

The engine max therefore remains whatever the `IsoDoor` instance owns internally, commonly 500. LMION keeps its authoritative logical max in object modData:

```text
lmionDoorMaxHealth
```

Core APIs:

- `Doors.setEffectiveMaxHealth(object, value)` stores the LMION logical max;
- `Doors.getEffectiveMaxHealth(object)` returns the stored LMION max, falling back to engine max when none exists;
- `Doors.repairHealth(object, amount)` repairs current health up to the LMION logical max, even when that is above engine max.

The Debug Inspector deliberately does not hide the distinction. It reads the actual modData for `lmionMaxHealth` and shows `<unset>` when LMION has not stored one.

Example untouched vanilla world door before adoption:

```text
health = 500
lmionMaxHealth = <unset>
engineMaxHealth = 500
condition = <unset>
```

## Existing world-door adoption

`BlueMetalDoor` currently has a temporary durability profile only:

```text
worldMaxHealth = 600
```

The value 600 is a conservative test value, not final balance.

World doors are adopted when their grid square loads. Adoption only happens when:

- the object is an `IsoDoor`;
- its sprite resolves to an LMION profile with `durability.worldMaxHealth`;
- `lmionDoorMaxHealth` is not already stored.

The migration rule is intentionally conservative:

- if current health equals engine max at first adoption, the door is considered full life and current health is raised to the new LMION max;
- if the door is already damaged, current health is left exactly unchanged;
- in both cases LMION stores the new logical max.

Runtime validation succeeded with two existing developer-placed BlueMetalDoor objects:

```text
damaged door:
health = 316
lmionMaxHealth = 600
engineMaxHealth = 500
condition = 52.7%

intact door:
health = 600
lmionMaxHealth = 600
engineMaxHealth = 500
condition = 100.0%
```

This avoids artificially healing a door that was already damaged before LMION adopted it.

Multiplayer synchronization of world adoption has not yet been specifically validated.

## Repair validation

Core now contains the generic low-level repair primitive `Doors.repairHealth(object, amount)`.

Debug currently exposes a temporary context-menu action:

```text
LMION Repair +50 HP
```

It requires no tool, material or skill and exists only to validate the durability model.

Runtime testing confirmed that a door can be repaired past the engine max of 500 and continues until its LMION logical max, for example:

```text
466 -> 516 -> 566 -> 600
```

This proves that future repair gameplay can use LMION's logical max rather than being capped by `IsoDoor.maxHealth`.

The temporary Debug action is not the final repair system. Multiplayer synchronization for the repair primitive has not yet been specifically validated.

## Pickup state transport

For LMION Moveables doors, Pickup stores on the inventory item:

```text
lmionDoorHealth
lmionDoorMaxHealth
```

On placement the actual resulting `IsoDoor` is resolved from the vanilla placement result when possible, with a sprite-based fallback, then current health and LMION max are restored.

Do not reintroduce the old intrusive `MoveablesTrace.lua` wrapper. It was temporary research tooling, caused runtime errors due to assumptions about vanilla return values, and was removed after the real pickup path was validated.

A full game restart was required to clear its stale wrapper closures from an already running Lua VM.

## Engine facts that matter to current design

- `IsoDoor:setHealth(int)` accepts values above `IsoDoor:getMaxHealth()`; runtime tests validated this.
- `IsoDoor:getThumpCondition()` still uses the engine max, so vanilla condition consumers may see full condition while LMION health is above 500. This is a known compromise of the logical-max model.
- `IsoDoor` save/load persists health and engine max internally, while LMION logical max lives in modData.
- classic vanilla player-built wooden doors are often created as `IsoThumpable`, which does expose max-health mutation; LMION Build converts its constructed result to `IsoDoor` to keep one door runtime type.
- LMION captures the constructed thumpable max before conversion and stores it as the logical LMION max on the resulting `IsoDoor`.

## Source and workflow guardrails

- Game-loaded LMION Lua and script files must remain free of `--` line comments.
- Important rationale belongs in repository documentation instead of source comments.
- `media/scripts` changes require a real game restart.
- New Lua files, load-order changes, mod metadata changes, or stale monkey-patch closures can also require a full restart.
- Do not use speculative Java reflection as a production solution; Debug reflection privileges are not a deployable gameplay path.
- Prefer runtime/source verification over guessed engine APIs.
- Current development work is committed directly to `main`; branches are reserved for definitive/release snapshots unless that workflow decision changes.

## Documentation checkpoint rule

Do not update documentation mechanically for every commit. That creates noise and makes the handoff harder to read.

Update `CURRENT_STATE.md` when at least one of these changes:

- a runtime behavior is newly validated or invalidated;
- a public/shared LMION contract changes;
- a temporary diagnostic becomes important enough that the next session must know about it;
- a major engine limitation or compatibility rule is discovered;
- the next milestone changes.

Update `ARCHITECTURE.md` only for structural/responsibility changes, and `LMION_Design_Notes.md` for durable design decisions and research conclusions.

## Next intended milestones

1. Finish CherryDoor as the complete reference simple door, including intended materials/craft/balance rather than current canaries.
2. Implement and validate LogDoor using the same architecture.
3. Test a door that already has vanilla construction support so LMION can prove it can take control of an existing vanilla construction path.
4. Once those three cases are stable, batch simple 1x1 doors.
5. Handle specialized multi-tile openings separately: double doors/gates and garage doors.
6. Build the real repair gameplay module only after material/craft rules are sufficiently defined; keep the Core repair primitive as the shared low-level operation.

## Useful milestone commits

- `66d9b53819cd14946901fe4892963c31f2cb468f` — apply door materials to engine sprites with alias verification.
- `5a00f6ff5addb134b3408e9a0000ddad1711bb83` — restore current health on the actual vanilla placement result.
- `6c66c7eca5b339e738fde82fdfad6463ee0dfb02` — retain construction max health as LMION logical max.
- `7965c41eb0ef46d64897d4cbbf4b253455ed82d3` — preserve LMION max health through Moveables pickup/replacement.
- `b439169bc3ea4393a794202eee4f9534db46fd4d` — remove intrusive Moveables runtime trace.
- `0ee171c0f26d15692ecb57b1393fb87b7f6554c2` — make Inspector distinguish an unset LMION max from engine fallback.
- `d653aa2b4fe5c623745cc1128179c8f78f5b5687` — adopt world-door durability from profiles.
- `1f34193dd6e4a1a969a5f34c8c6722f53b3b20c3` — add Core logical-health repair helper.
- `c8305376868b56a92071094de2c1dabfe485161c` — add temporary Debug +50 HP repair action.
