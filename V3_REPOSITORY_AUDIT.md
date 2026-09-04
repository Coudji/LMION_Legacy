# LMION V3 repository audit

Status: initial audit scaffold, 2026-09-04

This file tracks what should enter LMION V3 and what should remain only as reference/history.
Nothing is deleted merely because it is listed as obsolete here.

## Classification vocabulary

- **MIGRATE** — strong candidate to enter V3, possibly with cleanup/renaming.
- **REFERENCE** — preserve because it defines/records working behavior, but do not copy its architecture blindly.
- **RESEARCH** — preserve as active technical knowledge/guardrail.
- **HISTORICAL** — useful context, but no longer current architecture/specification.
- **AUDIT** — inspect file-by-file before deciding.
- **REMOVE LATER** — probably removable only after V3 has replaced the relevant knowledge/functionality.

## Repository root

| Path | Classification | Notes |
| --- | --- | --- |
| `README.md` | MIGRATE | V3 entrypoint; points future sessions to canonical state. |
| `CURRENT_STATE.md` | MIGRATE | Canonical resumable project handoff. Must stay current. |
| `V3_REPOSITORY_AUDIT.md` | MIGRATE | This migration inventory. |
| `REFACTOR_HANDOFF.md` | HISTORICAL | V2 plan. Contains useful invariants but its addon architecture is superseded. Extract knowledge before eventual archival/rename. |
| `.gitignore` | AUDIT | Keep unless packaging changes require edits. |

## Legacy

### `Legacy/Contents`

**Classification: REFERENCE**

Behavioral oracle for validated pre-V2 functionality. Do not restructure or "clean" it as part of V3.
Use it to answer how established Build/Pickup/Moveables behavior actually worked.

### `Legacy/Research/Engine`

**Classification: RESEARCH**

High-value engine knowledge. In particular:

- `B42LuaLoadOrder.md` — required before changing Lua tree placement/load order or phase-specific hooks;
- `LoadLifecycle.md` — required before changing event timing / script-vs-sprite-vs-world mutation timing;
- `SpriteConfigLifecycle.md` — preserve script/SpriteConfig mutation findings;
- `DoorHealth.md`, `PropertyAliases.md`, etc. — preserve engine behavior and compatibility evidence.

These notes should become more authoritative in V3, not less.

### `Legacy/Research/Moveables`

**Classification: RESEARCH / AUDIT note-by-note**

Preserve validated vanilla Moveables findings and family-specific research.
Some documents encode V2 addon composition language; extract the engine facts and mark obsolete architectural conclusions where necessary.

`VanillaMoveablesBehavior.md` is high priority and remains directly useful.

### `Legacy/Research/Architecture`

**Classification: mixed**

- `CoreDataAPI.md` — MIGRATE conceptually: pure definitions, stable public API, private Registry/Resolver, explicit identities and extensions remain valuable.
- `CodeOrganization.md` — HISTORICAL: current content is centered on independent Core/Build/Pickup/Debug packaging.
- `AddonComposition.md` — HISTORICAL: optional-addon combination matrix is explicitly abandoned for V3.
- Other architecture notes — AUDIT individually; retain semantic/engine findings but not obsolete package ownership rules.

### `Legacy/DOOR_CATALOG.md` / `DOOR_CATALOG_VALUES.md`

**Classification: RESEARCH / DATA REFERENCE**

Do not discard researched door data. Audit against the V2 definitions before deciding which representation becomes canonical.

### `Legacy/README_DEV.md`

**Classification: HISTORICAL / AUDIT**

Likely contains valuable old implementation facts mixed with obsolete current-state claims. Do not treat as V3 source of truth.

## Workshop V2

`Workshop` is a migration source, not the target architecture.
Recent code is not presumed superior to Legacy merely because it is newer.

### Core public data/API area

Current relevant roots:

```text
Workshop/Contents/mods/LMION_Core/42/media/lua/shared/LMION/
├─ API.lua
├─ Catalog/
├─ DefinitionDefaults/
└─ Core/
```

#### `Catalog/`

**Classification: MIGRATE / AUDIT data correctness**

Large amount of already-entered door data should not be recreated manually.
Preserve explicit geometry and the recent explicit `doorType` work where correct.

#### `DefinitionDefaults/`

**Classification: MIGRATE / AUDIT**

The pure-data/default inheritance idea remains useful. Remove transitional public fields only after their V3 replacement is proven.

#### `API.lua`

**Classification: MIGRATE concept, AUDIT implementation**

Public facade is still desired. V3 should expose a small stable API to third-party mods while internal code remains free to change.

#### `Core/Registry.lua`, `Resolver.lua`, validators/indexes

**Classification: MIGRATE / AUDIT file-by-file**

The data model and defensive-copy/resolution concepts are likely reusable. Do not preserve a module merely because V2 calls it Core; place it according to V3 responsibility.

#### `Core/DoorTypes.lua`

**Classification: MIGRATE concept**

Explicit `doorType` is part of the desired public model. Audit derived fields/rules before migration.

#### `Core/DoorRuntime.lua`, `GarageRuntime.lua`, other runtime/mechanics

**Classification: AUDIT**

These are runtime behavior and may contain useful primitives, but they must prove single responsibility and parity with established behavior before entering V3.

### Pickup V2 runtime

**Classification: AUDIT / REFERENCE FOR RECENT EXPERIMENTS**

Do not bulk-migrate the current `LMION_Pickup` architecture.
The V2 tree accumulated UI, cursor, toolbar, common helpers and family-specific placement layers during the failed refactor.

Candidate pieces can be migrated only when:

1. responsibility is clear;
2. vanilla boundary is understood/documented;
3. there is no overlapping hook owner;
4. behavior is known-good or recovered from Legacy;
5. migration makes sense in the V3 responsibility-first tree.

Particularly avoid blindly reviving removed/failed router/action abstractions.

### Assets

**Classification: MIGRATE**

Preserve validated non-code assets unless a specific audit finds them obsolete:

- AnimSets / animation mappings;
- icons/textures/models;
- translations;
- item/script definitions still required by the resulting gameplay.

Scripts must be audited for obsolete addon IDs/dependencies when moving to the single-mod package.

## Debug

**Classification: preserve, separate audit**

Debug is development tooling and can remain a separate mod/tool if useful.
It does not need the same stability/public-contract constraints as player-facing LMION.

Preserve valuable Inspector/reload/Test Zone tooling, but audit stale assumptions about independent Core/Build/Pickup mods.

## V3 packaging decision

Target is one gameplay mod package, not multiple independently enabled gameplay Mod IDs.

Do not interpret "one mod" as "one Lua file".
Internal code remains modular and responsibility-oriented.

Exact package path and `mod.info` migration are **not decided yet**. Inspect all current mod metadata/scripts before creating the final V3 package layout.

## Migration order

Initial intended order:

1. repository/docs guardrails;
2. full file inventory and stale-document audit;
3. V3 package skeleton with no gameplay rewrite;
4. data definitions + public API/Registry/Resolver foundation;
5. smallest validated 1x1 runtime path;
6. other single-tile semantic types;
7. Garage;
8. LargeGate;
9. Build and future Lock integrations according to responsibility layers rather than addon packages;
10. cleanup/archive of replaced V2 material.

Do not turn this ordering into a long untested rewrite. Each runtime migration must have a small in-game checkpoint.

## Audit questions for every code file considered for migration

Before admitting a V2/Legacy code file into V3, answer:

1. What single responsibility does this file have?
2. Can its important functions each be described as doing one thing?
3. Which vanilla API/event does it touch, if any?
4. Why is that the correct intervention point?
5. When does LMION take control and when does vanilla regain control?
6. Is another file also wrapping/owning the same boundary?
7. Which research note supports the lifecycle/load-order assumption?
8. Is behavior runtime-validated, Legacy-derived, or merely experimental?
9. Does the file expose internals that should instead sit behind the public API?
10. Where does it belong in the V3 responsibility-first tree?

If those cannot be answered, migrate the knowledge first, not the file.

## Next audit work

- inventory the full `Workshop` mod metadata/scripts/assets, not only Lua;
- inventory `Legacy/Contents` Build/Pickup/Debug roots and map known-good behaviors to source files;
- audit `Legacy/Research/Architecture` for facts that need extraction before archival;
- identify stale docs that currently look authoritative but conflict with V3;
- propose the exact V3 package skeleton only after those inventories are complete.
