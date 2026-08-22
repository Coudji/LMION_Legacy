# Let Me In... Or Not — Development

## Current modules

The Build 42 project currently contains three internal Mod IDs:

- `LMION_Core`
- `LMION_Build`
- `LMION_Pickup`

`LMION_Build` and `LMION_Pickup` both require `LMION_Core`; they do not depend on each other.

## Current development state

- **Core** provides the shared `LMION` framework, the canonical `LMION.Doors` registry, shared door-model data, and the LMION Inspector/debug tooling.
- **Build** is the active construction prototype. It currently covers the researched opening set, provides provisional construction recipes/definitions, and uses standalone PNG textures for custom construction-menu icons.
- **Pickup** has its shared framework/strategy registry in place, but no concrete pickup strategy is implemented yet.

The repository is the source of truth for project structure and committed code. Development is done against the live Project Zomboid Workshop source tree, with VS Code used for direct Lua edits.

## Development workflow

Use the in-game `Reload LMION` debug action for Lua-only iteration whenever possible. It reloads already-loaded Lua files under the shared `LMION/` namespace in load order, so active LMION submods are included automatically. In multiplayer, an authorized debug/admin client can also request the corresponding server-side reload.

A full game/server restart is still required after adding brand-new Lua files, changing load order, changing mod metadata/folder structure, changing `media/scripts` definitions, or when engine state cannot be safely reconstructed by Lua reload.

Avoid speculative Java method calls in debug code: in Debug Mode, Java/Kahlua runtime exceptions can open the Lua debugger even when Lua code uses `pcall`.

## LMION Inspector

The reusable in-game Inspector lives in `LMION_Core`. It currently supports, among other things:

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

The old dynamic showroom scanner has been retired. The current Test Zone is intentionally explicit and deterministic: `Debug/TestZone/Manifest.lua` defines which opening spawns at each position, while `Debug/TestZone/Spawner.lua` handles world preparation and object creation.

The Test Zone is a development fixture, not a door-discovery system. If its composition changes, update the manifest deliberately rather than adding runtime scanning or classification heuristics.

## Build prototype notes

The current Build catalog and recipes are development data, not final balance/progression. `Build/Catalog.lua` and `Build/Drafts.lua` are legacy/provisional Build-side data and are being audited separately from the Test Zone.

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
