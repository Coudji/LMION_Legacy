# Let Me In... Or Not — Development

## Current modules

The Build 42 project currently contains four internal Mod IDs:

- `LMION_Core`
- `LMION_Build`
- `LMION_Pickup`
- `LMION_Debug`

`LMION_Build`, `LMION_Pickup` and `LMION_Debug` require `LMION_Core`. Build and Pickup do not depend on each other, and normal gameplay modules do not depend on Debug.

## Current development state

- **Core** provides the minimal shared `LMION` framework, module registration, shared opening engine adapters, and the entity definitions needed by the project.
- **Build** is the active construction prototype. It currently covers the researched opening set through `media/scripts` definitions and standalone PNG construction-menu icons.
- **Pickup** has its shared framework/strategy registry in place, but no concrete pickup strategy is implemented yet.
- **Debug** contains the LMION Inspector, deterministic Test Zone, reflection helpers and Lua reload tooling used during development.

Core intentionally does not maintain a parallel Lua door catalog or a generic cross-module event bus. When Project Zomboid already exposes the needed facts through runtime objects or `GameEntityScript` / `SpriteConfig`, those are preferred over duplicated model data. New shared contracts are added only when a concrete feature needs them.

The repository is the source of truth for project structure and committed code. Development is done against the live Project Zomboid Workshop source tree, with VS Code used for direct Lua edits.

## Development workflow

Enable `LMION_Debug` when developing. Use the in-game `Reload LMION` debug action for Lua-only iteration whenever possible. It reloads already-loaded Lua files under the shared `LMION/` namespace in load order, so active LMION submods are included automatically. In multiplayer, an authorized debug/admin client can also request the corresponding server-side reload.

A full game/server restart is still required after adding brand-new Lua files, changing load order, changing mod metadata/folder structure, changing `media/scripts` definitions, or when engine state cannot be safely reconstructed by Lua reload.

Avoid speculative Java method calls in debug code: in Debug Mode, Java/Kahlua runtime exceptions can open the Lua debugger even when Lua code uses `pcall`.

## LMION Inspector

The reusable in-game Inspector lives in `LMION_Debug`. It currently supports, among other things:

- inspecting objects on selected grid squares and selected world objects;
- copyable compact and full-detail reports;
- generic `IsoObject`, `IsoDoor`, door-like `IsoThumpable`, sprite and property-container inspection;
- Build 42 entity/script inspection including `GameEntityScript`, `UiConfig`, `SpriteConfig`, and `CraftRecipe` data;
- controlled access to useful runtime door fields such as closed/open sprites;
- arbitrary world-square selection, multi-selection and persistent highlights;
- rebuilding the deterministic door Test Zone used for runtime checks;
- LMION Lua reload actions for development iteration.

The debug code is intentionally modular under `Debug/Inspect`, `Debug/UI`, `Debug/Util`, `Debug/World`, and `Debug/TestZone`.

## Test Zone

The old dynamic showroom scanner has been retired. The current Test Zone is intentionally explicit and deterministic: `LMION_Debug/42/media/lua/client/LMION/Debug/TestZone/Manifest.lua` defines which opening spawns at each position, while `Spawner.lua` handles world preparation and object creation.

The Test Zone is a development fixture, not a door-discovery system. If its composition changes, update the manifest deliberately rather than adding runtime scanning or classification heuristics.

## Build prototype notes

Build no longer keeps a parallel Lua catalog or provisional recipe generator. The active construction definitions live in `LMION_Build/42/media/scripts/`; those script files are the source of truth for current Build entities, recipes and progression data.

Construction icons are standalone PNG files under `LMION_Build/42/media/textures/`. The temporary packed-icon migration workflow used during development has been retired.

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
