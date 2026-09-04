# LMION V3 repository audit

Status: active migration audit, 2026-09-04

This file tracks what should enter LMION V3 and what should remain only as reference/history.
Nothing is deleted merely because it is listed as obsolete here.

## Classification vocabulary

- **MIGRATE** — strong candidate to enter V3, possibly with cleanup/renaming.
- **REFERENCE** — preserve because it defines/records working behavior, but do not copy its architecture blindly.
- **RESEARCH** — preserve as active technical knowledge/guardrail.
- **HISTORICAL** — useful context, but no longer current architecture/specification.
- **AUDIT** — inspect file-by-file before deciding.
- **REMOVE LATER** — probably removable only after V3 has replaced the relevant knowledge/functionality.

## Repository strategy

V3 should live in a **new clean repository** rather than moving V1/V2 into an `archive/` folder here.

Recommended target:

```text
Coudji/LMION
```

`Coudji/LMION_Legacy` remains intact as the archaeology/reference repository. This preserves:

- original V1/V2 paths;
- Git history and useful commits/branches;
- research links and references;
- direct comparison between Legacy behavior and V2 experiments;
- a clean V3 root where everything visible is current.

Do not perform a mass rename/move of `Legacy/` and `Workshop/` merely to make room for V3 here.
Do not touch `Coudji/PZMOD_LMION` unless Coudji explicitly requests it.

Until the new repository exists, `CURRENT_STATE.md` in this repository remains the canonical resumable handoff.

## Repository root

| Path | Classification | Notes |
| --- | --- | --- |
| `README.md` | MIGRATE concept | Current entrypoint for archaeology/V3 preparation. A V3-specific README will be created in the new repo. |
| `CURRENT_STATE.md` | MIGRATE | Canonical resumable project handoff. Must stay current and later move to V3. |
| `V3_REPOSITORY_AUDIT.md` | MIGRATE during migration | Migration inventory; later it may remain here as archaeology once migration finishes. |
| `REFACTOR_HANDOFF.md` | HISTORICAL | V2 plan. Contains useful invariants but its addon architecture is superseded. |
| `.gitignore` | AUDIT | Recreate deliberately in V3 rather than copy blindly. |

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

This directory mixes reusable semantic/engine findings with V2 architecture decisions. Current classification:

| Document | Classification | V3 treatment |
| --- | --- | --- |
| `CoreDataAPI.md` | MIGRATE conceptually | Pure definitions, stable public facade, private Registry/Resolver, explicit identities/extensions remain valuable. Rename/reframe away from the old independent-Core packaging. |
| `CoreEntityLookup.md` | MIGRATE / RESEARCH | GameEntity identity lookup is strong: world object -> `getEntityScript():getFullName()` -> definition. Preserve the no-sprite-primary-identity rule and collision behavior. Audit implementation/index invalidation details. |
| `CoreLoadOrder.md` | RESEARCH + HISTORICAL mix | Preserve verified PZ mod/scope ordering and the proven client/server cursor boundary. Drop wording requiring separate Core/Build/Pickup addons. |
| `DoorObjectAbstraction.md` | RESEARCH / MIGRATE semantic decision | Preserve canonical `IsoDoor` direction, `IsoThumpable(isDoor)` as accepted source/temp input, and especially the Lua boolean `a and value or fallback` pitfall. Runtime revalidation remains required where the note says so. |
| `CatalogFamilies.md` | DATA DESIGN / AUDIT | Useful catalog taxonomy and inheritance rationale, but it is explicitly a working draft. V2 later moved toward `DefinitionDefaults`; reconcile rather than copy its provisional family taxonomy verbatim. |
| `OpeningExtensions.md` | HISTORICAL + RESEARCH facts | Independent-feature-module dependency model is obsolete. Preserve A/B LargeGate semantics, N/W member mapping, paired Left/Right distinction and persistent-ID warning. Do not preserve the old priority-based extension contract if it conflicts with later `CoreDataAPI.md`. |
| `PickupRewrite.md` | HISTORICAL implementation + RESEARCH boundary | Old “Pickup addon” framing is obsolete. Preserve the proven client/server placement-handoff boundary, generic parcel idea, exact geometry rule and no-sprite-primary-identity rule. Do not copy its V2 vertical-slice architecture wholesale. |
| `CodeOrganization.md` | HISTORICAL | Centered on independent Core/Build/Pickup/Debug packaging. |
| `AddonComposition.md` | HISTORICAL | Optional-addon combination matrix is explicitly abandoned for V3. |

Important conflict discovered during audit:

- `OpeningExtensions.md` describes extension ordering by numeric `priority` then extension id;
- the later `CoreDataAPI.md` explicitly rejects `priority` and applies same-layer extensions in registration/load order.

For V3, do **not** silently reconcile these. Treat the later V2 API direction as the stronger migration candidate, then deliberately confirm the V3 extension contract before implementation.

### `Legacy/DOOR_CATALOG.md` / `DOOR_CATALOG_VALUES.md`

**Classification: RESEARCH / DATA REFERENCE**

Do not discard researched door data. Audit against the V2 definitions before deciding which representation becomes canonical.

### `Legacy/README_DEV.md`

**Classification: HISTORICAL / AUDIT**

Likely contains valuable old implementation facts mixed with obsolete current-state claims. Do not treat as V3 source of truth.

## Workshop V2 packaging inventory

Workshop currently contains two gameplay Mod IDs:

```text
LMION_Core
LMION_Pickup
```

`LMION_Pickup` has `require=LMION_Core` in `mod.info`. This packaging is V2-only and must not be copied to V3.

V3 target is one gameplay Mod ID/package. Exact final `id=` should be chosen when the new repo/package skeleton is created; do not inherit `LMION_Core` merely because it exists today.

### Workshop Core

Current top-level media responsibilities:

```text
media/lua/          -> API, catalog/defaults, registry/runtime and translations
media/scripts/      -> LMION GameEntity/script definitions
media/sandbox-options.txt
```

#### `Catalog/`

**Classification: MIGRATE / AUDIT data correctness**

Large amount of already-entered door data should not be recreated manually.
Current catalog includes at least:

```text
Doors/Single
Doors/Paired
FenceGates
SlidingDoors
GarageDoors
LargeGates
Windows (reserved/empty)
```

Preserve explicit geometry and recent explicit `doorType` work where correct.
Do not infer complex geometry from sprite-number arithmetic.

#### `DefinitionDefaults/`

**Classification: MIGRATE / AUDIT**

Pure-data/default inheritance remains useful. Current defaults cover doors, fence gates, sliding doors, garage doors and large gates.

V3 should deliberately decide whether the public term stays `DefinitionDefault`; do not revive the older provisional `family` model merely because some research uses that word.

Remove transitional public fields only after their V3 replacement is proven.

#### `media/scripts/LMION/...`

**Classification: MIGRATE DATA / AUDIT EACH FAMILY**

There is substantial already-authored PZ script/GameEntity data corresponding to the catalog. This is expensive data and should not be recreated casually.

Migration rules:

- compare each family with the effective Lua definition before moving it;
- preserve persistent IDs unless a deliberate pre-release rename is chosen;
- remember script changes require cold restart;
- remove assumptions that existed solely to support separate `LMION_Core` / `LMION_Pickup` packaging;
- do not mix script-data migration with runtime-hook redesign in the same step.

#### `API.lua`

**Classification: MIGRATE concept, AUDIT implementation**

Public facade is still desired. V3 should expose a small stable API to third-party mods while internal code remains free to change.

#### `Core/Registry.lua`, `Resolver.lua`, `TableUtils.lua`

**Classification: strong MIGRATE candidates / audit code quality**

The private storage, copy-on-register/resolve and explicit resolution model are likely reusable.
They should move into responsibility-named V3 folders rather than preserve `Core/` merely for historical reasons.

#### `Core/Validation.lua`, `GameEntityValidation.lua`, `EntityIndex.lua`

**Classification: MIGRATE concepts / AUDIT implementation**

Keep validation separate from storage/resolution. Preserve GameEntity reverse lookup as its own responsibility.
Do not let validation become a large all-knowing module; V3 can split structural definition validation from PZ-runtime validation if that keeps functions single-purpose.

#### `Core/DoorTypes.lua`

**Classification: MIGRATE concept**

Explicit `doorType` is part of the desired public model. Audit derived fields/rules before migration.

#### `Core/GarageTopology.lua`, `LargeGateTopology.lua`

**Classification: strong MIGRATE semantic candidates**

These are small semantic/topology concepts and fit naturally under V3 `Domain/` if their contracts match the final definitions.
Audit them against Legacy/research rather than rewrite from memory.

#### `Core/DoorRuntime.lua`, `GarageRuntime.lua`, `LargeGateRuntime.lua`

**Classification: AUDIT / likely split rather than copy**

Runtime/mechanics may contain valuable primitives but must prove single responsibility and parity. `DoorRuntime.lua` is already ~10 KB; V3 should not automatically preserve that aggregation.

Potential destination responsibilities include object identity, state capture/restore, PZ placement/finalization and topology runtime, but only split after reading the actual functions.

#### `Core/BuiltinContent.lua`

**Classification: MIGRATE responsibility, reconsider implementation size**

Explicit built-in registration is preferable to magic directory scanning, especially for deterministic addon behavior. Current file is ~6.5 KB because it lists content. V3 can retain explicit registration while organizing manifests/data lists so a human can navigate them easily.

#### `sandbox-options.txt`

**Classification: MIGRATE GAMEPLAY SETTINGS / AUDIT naming**

Current options are Garage max length and unlimited Garage width. These are gameplay configuration, **not feature-enable/disable toggles**, so the prior rejection of feature toggles does not automatically remove them.

However, names/page identifiers currently use `LMION_Core`; V3 must rename them for the single mod and decide compatibility implications before public release.

### Workshop Pickup assets/data

#### AnimSets

**Classification: MIGRATE**

Current custom actions:

```text
LMION_CrowbarPickupLow.xml
LMION_ScrewdriverHinge.xml
```

Research records these as runtime-validated presentation improvements. Preserve unless later gameplay design removes them.

#### `Base.LMION_OpeningParcel`

**Classification: MIGRATE concept / AUDIT script**

The generic transport parcel is a useful single item identity carrying definition/part/state in modData. Preserve the concept; audit the current script fields before moving it.

#### translations

**Classification: MIGRATE / CLEANUP**

Preserve EN/FR strings that remain relevant, but merge Core/Pickup-era translation namespaces/pages into the single-mod vocabulary instead of carrying historical package names forward.

### Workshop Pickup runtime

**Classification: AUDIT / REFERENCE FOR RECENT EXPERIMENTS**

Do not bulk-migrate the current `LMION_Pickup` architecture.
The V2 tree accumulated UI, cursor, toolbar, common helpers and family-specific placement layers during the failed refactor.

Large files are a visible warning sign for V3 responsibility rules:

```text
Simple/MoveableAdapter.lua          ~21 KB
LargeGate/LargeGatePlacement.lua    ~17 KB
LargeGate/LargeGatePickup.lua       ~16 KB
Garage/GaragePickup.lua             ~14 KB
Garage/GarageToolbarAdapter.lua     ~14 KB
Garage/GaragePlacement.lua          ~11 KB
Garage/GarageCursor.lua             ~10 KB
LargeGate/LargeGateCursor.lua       ~10 KB
```

Size alone does not prove bad code, but none of these should enter V3 wholesale without a responsibility audit.

Candidate code can migrate only when:

1. its single responsibility is clear;
2. important functions each do one thing;
3. vanilla boundary is understood/documented;
4. there is one hook owner;
5. behavior is known-good or recovered from Legacy;
6. it belongs naturally in the V3 responsibility-first tree.

Particularly avoid blindly reviving removed/failed router/action/parity abstractions.

## Debug

**Classification: preserve, separate audit**

Debug is development tooling and can remain a separate mod/tool if useful.
It does not need the same stability/public-contract constraints as player-facing LMION.

Preserve valuable Inspector/reload/Test Zone tooling, but audit stale assumptions about independent Core/Build/Pickup mods.

## Minimum V3 seed set

Before porting any gameplay runtime, the new repository should contain only a small, understandable foundation:

```text
README.md
CURRENT_STATE.md
Docs/
  Architecture/
  Research/
  Decisions/
Contents/
  mods/
    LMION/
      42/
        mod.info
        media/
          lua/
            shared/LMION/
          scripts/
```

This is a packaging sketch, not the final Lua architecture.

Recommended first active docs to seed/copy in rewritten form:

```text
Research/Engine/B42LuaLoadOrder.md
Research/Engine/LoadLifecycle.md
Research/Moveables/VanillaMoveablesBehavior.md
Decisions/ArchitectureRules.md
Decisions/VanillaBoundaries.md
Decisions/HookOwnership.md
```

The new repo should not copy the entire Legacy research tree on day one. Copy the active, verified knowledge needed to prevent repeated mistakes; leave archaeology here and link back when necessary.

## Migration order

1. finish archaeology/audit enough to identify the seed set;
2. create new V3 repository;
3. seed handoff + active research + architecture rules;
4. create one-mod package skeleton with no gameplay behavior;
5. migrate definitions/defaults + Registry/Resolver/API foundation;
6. validate data bootstrap independently from Pickup/Build;
7. port smallest known-good 1x1 gameplay path;
8. port other single-tile semantics;
9. Garage;
10. LargeGate;
11. construction/Build behavior into responsibility-based layers;
12. future Lock only after current V3 base is stable.

Do not turn this into a long untested rewrite. Every runtime migration gets a small in-game checkpoint.

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

- inspect the actual V2 Registry/Resolver/API implementation and decide what can be ported nearly unchanged versus rewritten cleanly;
- inspect the current definition/default schema and identify transitional V2 fields before seeding V3;
- map Legacy known-good simple-door behavior to exact source files for the first runtime slice;
- inventory Debug only when the V3 gameplay skeleton is established;
- create the clean V3 repository once Coudji provides/creates it, because the current GitHub tooling does not expose repository creation.
