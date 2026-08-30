# LMION technical research archive

This directory preserves engine research and implementation rationale that would otherwise be lost between development sessions.

The goal is not only to record what LMION currently does. It is to preserve **why it does it that way**, what was verified in Project Zomboid, which alternatives were tried, and what addon authors must know before extending or replacing a subsystem.

## Evidence and status vocabulary

Use explicit evidence levels:

- **Bytecode-verified B42.20.3** — confirmed from `projectzomboid.jar` for Build 42.20.3.
- **API-verified B42.20.3** — confirmed from public methods exposed to Lua/Kahlua.
- **Vanilla-Lua verified** — confirmed from vanilla Build 42 Lua/scripts.
- **Runtime-validated** — reproduced in game in the current LMION test setup.
- **Git-history recovered** — reconstructed from commits/diffs.
- **Historical / superseded** — useful rationale, not current behavior.
- **Open** — plausible/partially observed but not established enough to become a contract.

When Project Zomboid changes version, bytecode/API findings remain version-specific until revalidated.

## Source hierarchy

For engine behavior, prefer roughly:

1. Java bytecode/API for Java behavior;
2. vanilla Build 42 Lua/scripts for Lua/script behavior;
3. controlled runtime tests/logs;
4. current LMION code;
5. Git history;
6. older prose as historical evidence.

Current code/runtime evidence and focused research notes outrank stale documentation.

## Documentation roles

- `README.md` — short public overview.
- `README_DEV.md` — authoritative current-state architecture/handoff.
- `Research/` — engine forensics, lifecycle constraints, failed approaches and addon-facing contracts.
- `DOOR_CATALOG.md` / `DOOR_CATALOG_VALUES.md` — working catalog data; do not edit unless the current task concerns the catalog.

Detailed research should not be deleted merely because the final implementation becomes simple.

## Current research notes

### Architecture

- [`Architecture/CodeOrganization.md`](Architecture/CodeOrganization.md) — current Core/Build/Pickup/Debug ownership boundaries, addon-independence audit and current garage Build file responsibilities.
- [`Architecture/DoorObjectAbstraction.md`](Architecture/DoorObjectAbstraction.md) — canonical `IsoDoor` output policy and why source `IsoThumpable(isDoor)` remains input-only.
- [`Architecture/OpeningExtensions.md`](Architecture/OpeningExtensions.md) — opening/profile extension architecture and shared semantic boundaries.

### Engine

- [`Engine/DoorHealth.md`](Engine/DoorHealth.md) — effective max health, `IsoDoor`/`IsoThumpable` API mismatch and durability implications.
- [`Engine/PropertyAliases.md`](Engine/PropertyAliases.md) — why engine-facing property writes require exact readback and restoration.
- [`Engine/LoadLifecycle.md`](Engine/LoadLifecycle.md) — lifecycle event ownership for different mutations.
- [`Engine/B42LuaLoadOrder.md`](Engine/B42LuaLoadOrder.md) — bytecode/runtime-backed Lua phase order, automatic phase execution, alphabetical path ordering, `require()` visibility and dedicated-server behavior.
- [`Engine/SpriteConfigLifecycle.md`](Engine/SpriteConfigLifecycle.md) — scripted-sprite ownership and targeted SpriteConfig reload behavior.
- [`Engine/GarageThumpableInteraction.md`](Engine/GarageThumpableInteraction.md) — why complete native GarageDoor behavior requires `IsoDoor` and why garage `OnCreate` canonicalizes early.

### Moveables / large gates

- [`Moveables/LargeGateLeaves.md`](Moveables/LargeGateLeaves.md) — A/B leaf pickup/rotation/replacement architecture, DoubleDoor geometry and runtime SpriteGrid bridge.
- [`Moveables/LargeGateOpenPickup.md`](Moveables/LargeGateOpenPickup.md) — open-state leaf Pickup/reconnection rules, untouched-partner policy and rejected hybrid states.

### Garage topology, Pickup and Build

- [`Moveables/GarageDoorTopology.md`](Moveables/GarageDoorTopology.md) — native `START / MIDDLE / END` topology and variable-length engine evidence.
- [`Moveables/GarageDoorValidation.md`](Moveables/GarageDoorValidation.md) — family/sprite validation constraints and known-good garage definitions.
- [`Moveables/GarageDoorPlacementEntryPath.md`](Moveables/GarageDoorPlacementEntryPath.md) — intentional split between variable inventory right-click placement and vanilla fixed-L3 Moveables sidebar placement.
- [`Moveables/GarageDoorVariableWidthPlacementResearch.md`](Moveables/GarageDoorVariableWidthPlacementResearch.md) — research behind explicit variable reinstallation geometry/cursor behavior.
- [`Moveables/GarageDoorVariableWidthDesign.md`](Moveables/GarageDoorVariableWidthDesign.md) — current cross-addon variable-width contract: Core semantics consumed independently by Pickup and Build.
- [`Moveables/GarageDoorVariableBuildPrototype.md`](Moveables/GarageDoorVariableBuildPrototype.md) — current variable Build implementation, material formulas, B42 variable-bar integration, rejected paths and runtime validation status. The historical filename is retained even though the feature is no longer merely a prototype.
- [`Moveables/VanillaMoveablesBehavior.md`](Moveables/VanillaMoveablesBehavior.md) — vanilla Moveables behavior relevant to LMION integration.

### Door-specific research

- [`Doors/Base.WoodenDoorLvl3.md`](Doors/Base.WoodenDoorLvl3.md) — detailed research snapshot for the vanilla wooden-door entity.
- [`Doors/LogGateMirrorDiscovery.md`](Doors/LogGateMirrorDiscovery.md) — mirrored large log-gate sprite discovery.

## Current open follow-ups

These are known research/validation gaps, not current architecture failures:

- multiplayer/server-client validation of variable garage Build;
- runtime addon-combination matrix (`Core+Build`, `Core+Pickup`, `Core+Debug`, `Core+Build+Pickup`);
- engine-profile alias rejection audit, especially the suspicious `MaterialType` projection/readback behavior;
- exhaustive all-family/all-width/all-orientation normal-mode garage Build matrix;
- later gameplay-balance review for Pickup/Place duration.

## Addon documentation rule

When a subsystem becomes something addons may reasonably interact with, its note should state:

- which data/API is intentional and safe to depend on;
- which global engine objects LMION mutates;
- which lifecycle event must have happened before data is valid;
- what an addon must preserve when wrapping the same vanilla function;
- what is an implementation detail and may change.

Addon authors should target Core semantic APIs rather than copy Build/Pickup monkey patches or private table layouts.

## What to record during future research

For a non-trivial engine problem, preserve at least:

1. question/symptom;
2. evidence;
3. conclusion;
4. LMION decision;
5. rejected alternatives;
6. lifecycle constraint;
7. addon contract when relevant;
8. revalidation trigger.

The rule is simple: **do not compress an expensive engine discovery into one implementation comment and then throw the discovery away.**

## Archaeology backlog

Older areas still worth formalizing when they become relevant:

- construction `IsoThumpable -> IsoDoor` state-copy details outside the already-documented garage path;
- Moveables state serialization/restoration for normal 1x1 doors;
- frame-aware placement and exceptions;
- sliding-door and fence-gate classification/tool rationale;
- glass/window-state investigation;
- Debug reload behavior in SP vs MP and stale closure/instance behavior;
- Inspector evolution and removal of broad reflection/runtime dumping;
- localization lookup quirks and normalized recipe-key evidence.

Move backlog items into focused notes only when surviving evidence is strong enough to explain both the conclusion and its limits.
