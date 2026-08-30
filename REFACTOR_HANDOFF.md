# LMION Refactor Handoff

This repository is now the development workspace for the LMION rewrite.

## Repository roles

- `Coudji/LMION_Legacy` = development workspace, research archive, old implementation reference, and refactor test area.
- `Coudji/PZMOD_LMION` = clean final repository managed manually by Coudji.

Do **not** write to `PZMOD_LMION` during development. Coudji copies validated code there manually.

## Workspace layout

```text
LMION_Legacy/
├── Legacy/      # old implementation, research, technical docs, catalogs, historical reference
└── Workshop/    # clean LMION rewrite under active development
```

`Workshop/` must contain only files intended to become part of the actual Workshop mod. Research, experiments, notes, temporary diagnostics and historical material stay outside it, normally under `Legacy/`.

The old implementation is a reference, not a codebase to migrate wholesale. Rebuild functionality deliberately and copy only ideas/behavior that have been reviewed.

## Refactor goal

The target architecture is:

> **Core owns opening content and exposes stable contracts. Submods own mechanics. No submod owns the opening catalog.**

Current/future gameplay modules:

```text
LMION_Core
LMION_Build
LMION_Pickup
LMION_Lock
```

Debug remains development tooling only.

Dependency principle:

```text
Build  ─┐
Pickup ─┼─> Core
Lock   ─┘
```

Gameplay submods must not depend on one another, either directly in source code or indirectly through world state prepared by another submod.

Each mechanic must work with Core when it is the only gameplay submod enabled.

## Core responsibility

Core should become the authoritative semantic API for openings. It should know what each opening is and expose the information mechanics need, including where applicable:

- stable opening identity
- type/family
- topology (`single`, paired, large gate A/B, garage chain, etc.)
- material / frame / other physical semantics
- exact GameEntity mapping
- exact sprite identities
- exact open and closed geometry
- exact member coordinates in each orientation
- aliases and extension/override data
- stable state/canonical placement helpers

Mechanic submods should ask Core for exact data instead of hard-coding individual door IDs or trying to infer geometry from Project Zomboid conventions.

## Explicit geometry rule

Do not rely on Project Zomboid to infer complex opening geometry for LMION.

For complex gates in particular, Core definitions should explicitly describe the complete physical shape in both orientations and states:

```text
N closed: every member -> relative coordinate + exact sprite
N open:   every member -> relative coordinate + exact sprite
W closed: every member -> relative coordinate + exact sprite
W open:   every member -> relative coordinate + exact sprite
```

Large gates also explicitly define A/B leaf membership.

This is intentional even when some information duplicates `SpriteConfig`: the PZ script describes what the engine loads; the LMION definition is the stable contract our mechanics use.

## Script vs Lua direction

Current design direction:

```text
.txt = data Project Zomboid needs during its normal script/GameEntity loading phase
.lua = explicit LMION semantic definition and geometry contract
```

A 100% runtime-Lua replacement for GameEntity scripts is not the current plan. B42 registers script entities / WorldDictionary before normal LMION Lua execution, making late creation fragile.

Do not automatically derive LMION sprite geometry from `SpriteConfig` merely because the engine exposes it. Prefer explicit LMION definitions and use engine data for validation when useful.

## File organization

For LMION itself, keep **one opening per definition file**. Avoid giant catalogs containing hundreds or thousands of lines of unrelated opening definitions.

A typical opening may eventually have:

```text
<Opening>.txt  # PZ/GameEntity side
<Opening>.lua  # LMION semantic definition
```

The physical folder layout should remain simple and be created only when it has a real purpose. Do not add speculative directories or abstractions.

Third-party mods do not have to mirror LMION's internal file organization; the API should care about registered definitions, not how many files a modder uses.

## Third-party API objective

Eventually, a third-party mod that adds doors should be able to register its openings with Core once. Generic LMION mechanics should then work automatically when enabled.

Example objective:

```text
Third-party door definition -> Core
                             -> Pickup works generically
                             -> Build works generically when construction data/defaults apply
                             -> Lock works generically
```

Adding a normal supported door must not require editing Pickup, Build or Lock catalogs.

A useful architectural test will be a fake external test door: register it only with Core, then verify `Core + Pickup` (and later other mechanics) works without changing the mechanic module.

## Migration strategy

Do not perform a giant rewrite.

Recommended order:

1. minimal Core namespace / registry / definition contract
2. one basic 1x1 door definition
3. generic 1x1 Pickup using Core only
4. second/new test door without modifying Pickup
5. generic 1x1 Build
6. paired doors / smaller gates
7. large gates with explicit open/closed N/W geometry and A/B topology
8. garages
9. other mechanics such as Lock

Use `Legacy/Contents` and `Legacy/Research` to recover known-good behavior and engine knowledge, but rewrite the new implementation cleanly inside `Workshop/`.

## Composition rule

A successful full-stack test is not proof of modularity.

Important combinations include:

```text
Core
Core + Build
Core + Pickup
Core + Lock
Core + Debug
Core + Build + Pickup
Core + Build + Lock
Core + Pickup + Lock
Core + all modules
```

When a shared representation/topology changes, explicitly ask whether each mechanic still works if no other gameplay addon ever ran before it.

## Canonical representation already learned from Legacy

The old project established that LMION-owned/finalized doors should persist as `IsoDoor`. `IsoThumpable(isDoor)` may be accepted as vanilla/legacy input, but should not become a second LMION persistent backend.

Large portals use semantic leaves **A/B**, not left/right. True paired 1x1 double doors may still use Left/Right where that is actually meaningful.

Garages use explicit START / MIDDLE / END topology and should not be treated as fixed L3 geometry.

These are known lessons from Legacy; their new APIs should still be redesigned cleanly rather than copied blindly.

## Git / delivery workflow

- Develop and test in `LMION_Legacy`.
- `Workshop/` is the candidate final mod tree.
- Keep experiments/research outside `Workshop/`.
- Coudji manually copies validated `Workshop` content into `PZMOD_LMION`.
- Do not push development branches or experimental files to `PZMOD_LMION`.
- Prefer coherent commits; avoid long chains of trivial fix/test commits when a change can be cleaned up before integration.

## Current starting point

The Legacy workspace was reorganized on 2026-08-30. The pre-reorganization state is preserved on:

```text
backup/main-before-workshop-refactor-20260830
```

The clean rewrite starts from `Workshop/`; no production functionality has yet been migrated there.
