# Let Me In... Or Not — Development

## Current modules

The Build 42 project currently contains two internal Mod IDs:

- `LMION_Core`
- `LMION_Pickup`

`LMION_Pickup` requires `LMION_Core`.

The shared Core/Pickup bootstrap is currently versioned as `0.0.3-dev` in Lua.

## Current development workflow

The repository is the source of truth for project structure and committed code. Development is done against the live Project Zomboid Workshop source tree, with VS Code used for direct Lua edits.

For client-only Lua changes, prefer a Lua reload and reopen/recreate affected UI instances when possible. Full game restarts are still appropriate when load order, mod metadata, folder structure, or initialization state changes.

Avoid speculative Java method calls in debug code: in Debug Mode, Java/Kahlua runtime exceptions can open the Lua debugger even when Lua code uses `pcall`.

## LMION Inspector

The current milestone is a reusable in-game inspector in `LMION_Core`.

Its responsibilities include:

- inspecting all objects present on selected grid squares;
- inspecting one or several selected world objects;
- producing copyable text reports;
- reporting generic `IsoObject` data;
- reporting `IsoDoor`-specific runtime data;
- exposing selected internal fields such as closed/open door sprites through controlled reflection.

The debug code is intentionally modular under `Debug/Inspect`, `Debug/UI`, `Debug/Util`, and `Debug/World`.

Planned inspector improvements include a world square picker and persistent highlights for selected squares.

## Pickup research workflow

Before writing a Pickup strategy for an opening family:

1. place or find representative vanilla objects;
2. inspect their real runtime class and state;
3. compare closed/open and damaged/intact variants when relevant;
4. inspect multi-tile/group linkage where relevant;
5. only then encode a strategy matcher and serialization/restoration logic.

Sprite names are identifiers for appearance/restoration, not reliable family classifiers.

## Next gameplay milestone

Implement the first real Pickup strategy for a vanilla 1×1 autonomous door once classification boundaries are sufficiently understood.
