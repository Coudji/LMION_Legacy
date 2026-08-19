# Let Me In... Or Not (LMION)

A modular Project Zomboid Build 42 mod project focused on movable openings, access systems, and related mechanics.

> Status: active development. Not release-ready yet.

## Modules

- `LMION_Core` — shared framework, module registry, internal event bus, persistence conventions, and developer/debug tooling.
- `LMION_Pickup` — user-facing pickup/replacement module for passable opening systems.

The project is intentionally split into several internal Mod IDs under one Workshop project. Future optional modules may add locksmithing or access-control mechanics without forcing those systems into Pickup.

## Current focus

The current milestone is the in-game LMION Inspector and runtime classification of vanilla opening families. The first gameplay MVP remains:

> Pick up and replace one vanilla simple door correctly.

The inspector exists to avoid guessing from sprite names or visual appearance. Runtime class, door indexes, paired sprites, health, group linkage, and square contents are inspected directly in game before a Pickup strategy is implemented.

## Repository layout

```text
Contents/mods/
├── LMION_Core/
└── LMION_Pickup/
```

See:

- `ARCHITECTURE.md` for code/folder organization.
- `LMION_Design_Notes.md` for design decisions and vanilla runtime findings.
- `README_DEV.md` for the current development workflow.
- `CHANGELOG.md` for changes tracked from the Git repository bootstrap onward.

## Target

- Project Zomboid Build 42
- Lua mod code
- One Workshop item, multiple internal Mod IDs
