# LMION technical research archive

This directory preserves the engine research and implementation rationale that would otherwise be lost between development sessions.

The goal is not only to record what LMION currently does. It is to preserve **why it does it that way**, what was verified in Project Zomboid, which alternatives were tried, and what addon authors must know before extending or replacing a subsystem.

This material is intended to serve three audiences:

- future LMION development, so solved engine problems are not rediscovered;
- addon authors, so they can build against LMION without depending on accidental implementation details;
- future public documentation/wiki pages, which can summarize these technical notes without having to reconstruct the research from Git history.

## Evidence and status vocabulary

Research notes should distinguish conclusions by evidence level instead of presenting every statement as equally certain.

- **Bytecode-verified B42.20.3** — confirmed from `projectzomboid.jar` for Build 42.20.3.
- **API-verified B42.20.3** — confirmed from the public methods exposed by the B42.20.3 classes used by Lua/Kahlua.
- **Vanilla-Lua verified** — confirmed from the corresponding vanilla Lua implementation.
- **Runtime-validated** — reproduced in game in the current LMION test setup.
- **Git-history recovered** — reconstructed from earlier commits/diffs after the original conversation context was no longer available.
- **Historical / superseded** — useful to understand an old decision or failed approach, but not current behavior.
- **Open** — plausible or partially observed, but not yet established strongly enough to become an LMION contract.

When Project Zomboid changes version, bytecode/API findings are version-specific until revalidated.

## Source hierarchy

For engine behavior, prefer evidence in roughly this order:

1. B42.20.3 Java bytecode/API when the behavior is implemented in Java;
2. vanilla Build 42 Lua/scripts when the behavior is implemented there;
3. controlled in-game tests and logs;
4. current LMION code;
5. Git history, especially commits that introduce/remove a workaround;
6. older documentation as historical evidence only.

Old LMION prose is useful archaeology, but it may contain assumptions that were later disproved. Current code/runtime evidence and focused research notes outrank stale documentation.

## Documentation roles

The repository intentionally keeps only a small documentation surface:

- `README.md` — short public overview;
- `README_DEV.md` — authoritative development/handoff document: architecture, current state, design guardrails, workflow and future-session instructions;
- `Research/` — this archive: engine forensics, lifecycle constraints, failed approaches and addon-facing technical contracts;
- `DOOR_CATALOG.md` / `DOOR_CATALOG_VALUES.md` — working catalog data, kept separate from architecture/research documentation.

A durable conclusion may be summarized in `README_DEV.md` and explained fully here. Detailed research should not be deleted merely because the final implementation becomes simple.

## Current research notes

### Engine

- [`Engine/DoorHealth.md`](Engine/DoorHealth.md) — why LMION has `lmionDoorMaxHealth`, the `IsoDoor`/`IsoThumpable` API mismatch, world adoption and repair implications.
- [`Engine/PropertyAliases.md`](Engine/PropertyAliases.md) — why engine-facing property writes require exact readback and restoration.
- [`Engine/LoadLifecycle.md`](Engine/LoadLifecycle.md) — why different LMION mutations run at Lua load, `OnGameBoot`, `OnLoadedTileDefinitions`, `LoadGridsquare` or `OnObjectAdded`.
- [`Engine/SpriteConfigLifecycle.md`](Engine/SpriteConfigLifecycle.md) — scripted-sprite ownership, targeted `SpriteConfigScript:PreReload()`, and the failed large-gate ownership prototypes.

### Moveables / multi-tile openings

- [`Moveables/LargeGateLeaves.md`](Moveables/LargeGateLeaves.md) — validated Chain-Link leaf pickup/rotation/replacement architecture, DoubleDoor index geometry, runtime SpriteGrid bridge and preview rendering discovery.

### Door-specific research already present

- [`Doors/Base.WoodenDoorLvl3.md`](Doors/Base.WoodenDoorLvl3.md) — detailed research snapshot for the vanilla wooden-door entity.
- [`Doors/LogGateMirrorDiscovery.md`](Doors/LogGateMirrorDiscovery.md) — mirrored large log-gate sprite discovery.

## Addon documentation rule

When an LMION subsystem becomes something addons may reasonably interact with, its research note should include an **Addon contract** section that states:

- which data/API is intentional and safe to depend on;
- which global engine objects LMION mutates;
- which lifecycle event must have happened before the data is valid;
- what an addon must preserve when wrapping/overriding the same vanilla function;
- what is an implementation detail and may change.

This is preferable to forcing addon authors to infer contracts from monkey patches or copied table layouts.

## What should be recorded during future research

For a non-trivial engine problem, preserve at least:

1. **Question / symptom** — what looked wrong or was not known.
2. **Evidence** — Java method, vanilla Lua, runtime log/test, or commit that proves the point.
3. **Conclusion** — what we now know about the engine.
4. **LMION decision** — how the mod uses that information.
5. **Rejected alternatives** — especially approaches that looked reasonable but failed.
6. **Lifecycle constraint** — if timing/load order matters.
7. **Addon contract** — when third-party code may need to interact with it.
8. **Revalidation trigger** — what PZ/LMION change would make the conclusion worth checking again.

The important rule is simple: **do not compress an expensive engine discovery into a one-line implementation comment and then throw the discovery away.**

## Archaeology backlog

Several older development areas still deserve the same treatment. They can be reconstructed progressively from Git history and the B42.20.3 sources rather than guessed from memory:

- construction `IsoThumpable -> IsoDoor` conversion and exact state copied during normalization;
- Moveables state serialization/restoration for normal 1x1 doors;
- frame-aware placement and why some doors/gates bypass a frame requirement;
- sliding-door and fence-gate classification/tool decisions;
- garage-door linkage (`garageDoorIndex`, `garage.first/prev/next`) as a system distinct from DoubleDoor;
- glass/window-state investigation and why LMION currently does not serialize a separate glass state;
- Debug reload behavior in single-player vs multiplayer and which stale closures/instances survive a Lua reload;
- Inspector evolution and removal of broad reflection/runtime dumping;
- the removed intrusive `MoveablesTrace.lua` experiment;
- localization lookup quirks and evidence for normalized recipe keys.

Items should move out of this backlog only when the surviving evidence is strong enough to explain both the conclusion and its limits.
