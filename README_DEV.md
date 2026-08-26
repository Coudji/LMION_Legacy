# Let Me In... Or Not — Development & handoff

Last updated: 2026-08-26

This is the **single authoritative development/handoff document** for LMION. It is intentionally responsible for the information that must survive between development sessions: project structure, current validated state, design guardrails, workflow rules and the next intended milestones.

Detailed engine forensics, failed approaches and addon-facing technical rationale belong in `Research/`, not here.

## Project direction

LMION progressively takes ownership of gameplay rules around doors, gates and other passable openings while leaving Project Zomboid responsible for the physical mechanics it already handles well.

> **Vanilla defines the physical opening mechanics; LMION defines the gameplay rules.**

LMION should reuse vanilla opening/closing, collision, synchronization, sprite-state behavior and object mechanics whenever practical. LMION owns things such as construction, naming/localization, material rules, pickup/transport identity, placement requirements, logical durability and future repair/access-control gameplay.

`newtiledefinitions.tiles` / TileDefinitions are research/reference data. Do not edit them as an LMION runtime solution.

## Documentation map

Keep the root documentation small:

- `README.md` — short public project overview;
- `README_DEV.md` — this document: architecture, state, guardrails and session handoff;
- `Research/` — detailed engine evidence, reverse engineering, failed hypotheses, lifecycle constraints and future addon contracts;
- `DOOR_CATALOG.md` / `DOOR_CATALOG_VALUES.md` — working door catalog data. **Do not restructure or rewrite these unless the current task explicitly concerns the catalog.**

Do not create another root-level architecture/state/design document just because one section grows. If a topic needs deep technical detail, create or extend a focused note under `Research/` and keep only the durable conclusion/link here.

## Repository / module structure

One Workshop item contains several internal Build 42 Mod IDs:

```text
Contents/mods/
├── LMION_Core/
├── LMION_Build/
├── LMION_Pickup/
└── LMION_Debug/
```

Dependencies:

```text
LMION_Build   ─┐
LMION_Pickup  ─┼─> LMION_Core
LMION_Debug   ─┘
```

Build and Pickup must remain independent of each other. Gameplay modules must not depend on Debug.

### `LMION_Core`

Core owns only functionality proven to be shared across real gameplay modules:

- the `LMION` namespace, logging and module registration;
- door/opening gameplay profiles;
- mapping profiles to `GameEntityScript` / `SpriteConfig` sprites;
- alias-safe application of engine-facing properties such as materials/sounds;
- low-level placement/persistence helpers that are genuinely shared;
- authoritative logical max-health storage in `modData.lmionDoorMaxHealth`;
- world-door durability adoption;
- low-level repair capped by LMION logical max.

Core does **not** own construction UX, Pickup UX or future Repair UX. Avoid speculative event buses, catalogs or parallel models that duplicate facts already available from runtime objects or Project Zomboid scripts.

### `LMION_Build`

Build owns construction/crafting concerns:

- construction entities and recipes;
- construction progression and requirements;
- construction-facing localization/presentation;
- large-gate construction topology and vanilla SpriteConfig ownership splitting where required.

For the three vanilla large-gate families (`Base.DoubleDoor`, `Base.DoubleWireGate`, `Base.DoubleFenceGate`), Build keeps the vanilla entity as the left leaf and assigns the right leaf to a separate entity. The vanilla SpriteConfig is reduced to left-leaf ownership at `OnGameBoot` using targeted `SpriteConfigScript:PreReload()`.

The derived left/right LMION gameplay profiles are installed both when `Build.lua` loads and again during `OnGameBoot`. This is intentional: `OnGameBoot` does not rerun during Lua hot reload, so relying on it alone can leave runtime-only profiles such as `DoubleWireGateRight` missing while the game continues running.

### `LMION_Pickup`

Pickup owns transport/reinstallation of passable openings through Moveables or specialized Moveables-compatible paths:

- pickup eligibility;
- tool/skill requirements;
- inventory transport identity;
- preservation of physical state such as health/logical max;
- placement rules;
- specialized multi-tile transport where generic 1x1 behavior is insufficient.

General design rule:

> **If it opens and the player can pass through it, Pickup owns its transport behavior.**

Transport identity should follow the gameplay unit that makes sense to remove and reinstall. World synchronization does not imply that the complete synchronized structure must become one inventory item.

### `LMION_Debug`

Debug owns development-only tooling:

- Inspector;
- world selection/highlighting;
- deterministic Test Zone;
- Lua reload helpers;
- temporary validation actions.

The Test Zone is an explicit deterministic fixture, not a runtime discovery scanner. Development diagnostics must not silently become gameplay dependencies.

## Current validated state

### Simple / 1x1 openings

The 1x1 path is mechanically stable enough to be the baseline.

Validated behavior includes:

- construction recipes across the Test Zone set;
- dedicated/localized Pickup inventory identities;
- vanilla Moveables pickup/replacement;
- frame-aware placement where required;
- current-health preservation;
- `lmionDoorMaxHealth` preservation;
- existing-world-door durability adoption;
- repair above engine max through the logical-max model;
- 1x1 fence gates and sliding doors on the shared Pickup architecture.

Current profile-specific facts worth preserving:

- `LogDoor` intentionally has no Pickup/place tools;
- sliding doors currently use Crowbar for pickup and Hammer for placement through custom Moveables tool definitions.

### Large-gate construction

The six current large-gate families are split into independent left/right construction leaves:

- Large Farm Gate;
- Large Wrought Iron Gate;
- Large Hardened Wooden Gate;
- Large Chain-Link Gate;
- Large Scrap Metal Gate;
- Large Wooden Gate.

All six were runtime-tested in both N and W orientations. Correctly assembled left/right leaves synchronize opening through vanilla `DoubleDoor` behavior even when the leaves use different GameEntity identities.

For the Chain-Link reference gate, both left and right construction profiles now survive Lua reload correctly. Runtime validation at MetalWelding level 2 produced the same skill-derived logical/current health on all four segments (`950/950`) and the expected `MetalPipe` / `MetalWire` profile materials on both leaves.

The deterministic Test Zone currently contains 83 explicit entries.

The vanilla Destroy action still destroys the complete linked portal. LMION intentionally does not override that behavior at this stage.

### Large-gate Pickup

The two-segment leaf transport architecture is now runtime-validated for **all six current large-gate families**:

- Large Farm Gate;
- Large Wrought Iron Gate;
- Large Hardened Wooden Gate;
- Large Chain-Link Gate;
- Large Scrap Metal Gate;
- Large Wooden Gate.

Validated closed-leaf behavior across the set:

- either physical segment of a leaf can be targeted;
- only the selected two-segment leaf is removed;
- Pickup creates two localized parcels `(1/2)` and `(2/2)`;
- both parcels are required for replacement;
- both physical `IsoDoor` members are rebuilt in one placement action;
- left and right leaves place correctly in both N and W orientations, including rotation before replacement;
- restored leaves resume vanilla synchronized opening/closing;
- each physical segment preserves its exact current health and `lmionDoorMaxHealth` independently through pickup and replacement, including pre-existing unequal damage;
- placement previews are clean for every current family.

Design identity:

```text
one leaf = two physical IsoDoor segments = two parcels = one placement action
```

The logical runtime SpriteGrid keeps both segments for Moveables semantics. Final placement is explicit LMION per-segment reconstruction because generic vanilla multisprite placement does not preserve rotated DoubleDoor geometry correctly.

Preview rendering is family-aware. Chain-Link, Scrap Metal, Wooden, Hardened Wooden and Wrought Iron use the configured single complete visual member (`visualPartIndex`) to avoid duplicated artwork. **Large Farm Gate is the validated exception:** its two member sprites are complementary, so its placement preview intentionally renders both SpriteGrid members.

Full architecture/evidence: `Research/Moveables/LargeGateLeaves.md`. Scrap Metal's first generalization validation is also recorded in `Research/Moveables/LargeScrapMetalGateValidation.md`.

Open-state Pickup is not yet the reference path.

A non-blocking engine warning can appear during multi-square pickup:

```text
GameEntityFactory.TransferComponents> Cannot transfer components for multi-square objects
```

No concrete state-loss bug has been reproduced from it. Do not add a workaround until one is demonstrated.

### Garage doors

Garage doors remain a separate multi-tile problem. Their linkage uses `garageDoorIndex`, `garage.first`, `garage.prev`, `garage.next`, etc., rather than DoubleDoor logical indices.

Do not generalize the two-segment leaf model to garage doors without separate research/validation.

## Core technical guardrails

This section is intentionally concise. Detailed evidence belongs in `Research/`.

### Logical max health

B42.20.3 exposes `IsoDoor:setHealth()` but no usable public `IsoDoor:setMaxHealth()` path for production Lua. LMION therefore stores the authoritative gameplay maximum in:

```text
lmionDoorMaxHealth
```

Current `IsoDoor.health` may legitimately exceed `IsoDoor:getMaxHealth()`. LMION-owned repair/condition logic must use `Doors.getEffectiveMaxHealth()` rather than engine max.

Existing-world adoption is conservative: intact doors at engine max are raised to the configured LMION world max; already-damaged doors retain their exact current health; already-adopted doors are not repeatedly migrated.

See `Research/Engine/DoorHealth.md`.

### Engine-facing property aliases

Project Zomboid `PropertyContainer` values are alias-backed. Unknown strings can silently resolve to another valid alias instead of preserving the requested value.

LMION engine-facing property writes must use the pattern:

```text
preserve old value -> write requested value -> exact readback -> keep or restore
```

See `Research/Engine/PropertyAliases.md`.

### SpriteConfig ownership

`SpriteConfigScript.allTileNames` is derived from declared SpriteConfig face tiles and participates in global scripted-sprite ownership.

When LMION reduces vanilla large-gate ownership:

1. validate the exact original tile set;
2. call `SpriteConfigScript:PreReload()` on that component only;
3. reload only the intended SpriteConfig body;
4. verify the resulting ownership set exactly.

Do not call `GameEntityScript:PreReload()` merely to reset SpriteConfig; it clears all component scripts.

See `Research/Engine/SpriteConfigLifecycle.md`.

### Load timing matters

Different mutations intentionally happen at different lifecycle points:

- Lua load — useful for already-running/hot-reload sessions, including reconstruction of runtime-derived split profiles;
- `OnGameBoot` — scripted entities are available and vanilla SpriteConfig ownership can be adjusted before later consumers rely on it;
- `OnLoadedTileDefinitions` — tile/sprite definitions have finished rebuilding; runtime sprite mutations such as large-gate `IsoSpriteGrid` attachment must be re-applied here;
- `LoadGridsquare` — adopt matching existing world doors as squares stream in;
- `OnObjectAdded` — adopt newly created doors too.

Do not move code between these phases merely for tidiness without checking what engine state exists at that point.

See `Research/Engine/LoadLifecycle.md`.

## Localization conventions

Build construction localization uses `Recipes.json`. Current B42 lookup removes spaces from recipe `DisplayName` before translation-key lookup, so LMION keys follow that normalized form.

Paired large-gate naming convention:

```text
internal ID:  <Base>Left / <Base>Right
English:      <base> - Left Leaf / Right Leaf
French:       <base> - vantail gauche / vantail droit
```

## Development workflow / hard rules

- Development currently happens directly on `main`. Do not create PRs or feature branches unless explicitly requested or a temporary rollback branch materially reduces risk.
- Before changing an unfamiliar subsystem, inspect the current code and the relevant `Research/` note rather than relying on remembered conversation context.
- Prefer Java/API/vanilla-source/runtime verification over guessed engine behavior.
- Avoid speculative Java/reflection calls in production or Debug. Kahlua/Debug Mode may surface Java exceptions even inside `pcall`.
- Runtime classification should prefer strong engine structure (`GameEntityScript`, SpriteConfig, DoubleDoor index, object type/properties) over sprite-name guessing when available.
- Game-loaded LMION Lua/script files intentionally contain no `--` line comments. Rationale belongs in documentation.
- `media/scripts` changes require a full game/server restart.
- New Lua files, load-order changes, mod metadata changes and stale monkey-patch closures may also require a full restart.
- Lua-only edits to already-loaded files can often use the LMION Debug reload path, but active cursors/actions may hold stale state. Re-enter the mode first; if behavior still looks stale, cold restart before concluding the code path is wrong.
- Do not add speculative abstractions or compatibility workarounds without a reproduced requirement/bug.
- Do not modify the door catalog unless the current task explicitly calls for catalog work.

## Instructions for future development / AI sessions

These rules exist specifically so the project does not depend on the user repeating the same context in every new conversation.

1. **Start by reading this file and `Research/README.md`, then inspect current `main`.** Do not assume a remembered checkpoint is newer than the repository.
2. **Use the repository as the handoff.** When conversation context is missing, reconstruct from current code, Git history and Research before asking the user to re-explain work that is recoverable.
3. **Update documentation proactively when it is relevant.** A meaningful architecture change, validated/invalidated behavior, engine limitation or expensive research result should update `README_DEV.md` and/or the appropriate `Research/` note in the same development pass. Do not wait for the user to remind you.
4. **Do not document every commit.** Update the durable state/decision, not a changelog. Git already records mechanical history.
5. **Preserve why, not only what.** If a workaround exists because an engine API is missing, a lifecycle event is required, or an apparently obvious alternative was tested and failed, put that reasoning in `Research/`.
6. **Do not resurrect a rejected approach casually.** Check relevant Research notes and Git history first; if revisiting it because PZ changed, explicitly state what changed and revalidate the old conclusion.
7. **Keep this file concise enough to read at the start of every session.** Deep reverse engineering belongs under `Research/` with a short summary/link here.
8. **Current code + runtime validation outrank stale prose.** If documentation and implementation disagree, investigate the discrepancy, fix the documentation, and do not silently assume either side is correct.

## Known compatibility note

Existing saves containing old full `Base.DoubleWireGate` instances from before the construction split may emit:

```text
Invalid SpriteConfig object! scripted object = DoubleWireGate
```

A new save did not reproduce the warning, including after interacting with naturally placed Chain-Link gates. Current evidence points to stale serialized old-gate instances. Treat old-save migration as a separate compatibility task rather than distorting the new split topology.

## Next intended milestones

1. Research/implement garage-door transport as its own multi-tile system.
2. Build a real `LMION_Repair` gameplay module after transport/material/craft rules are stable enough. Core should keep only the low-level logical-health primitives.

Potential locksmith/access-control systems remain future scope and must not distort the current transport architecture prematurely.
