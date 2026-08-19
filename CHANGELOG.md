# Changelog

This changelog starts when the Git repository was created. Earlier local prototypes and intermediate experiments were not versioned and are intentionally not reconstructed retroactively.

## Unreleased

### Repository
- Added the Git repository as the source of truth for LMION development.
- Added a root README and `.gitignore`.
- Replaced the old Word design notebook with Markdown documentation.
- Removed temporary refactor notes that no longer describe the current debug workflow.

### Core / Debug
- Modularized the LMION Inspector under `Debug/Inspect`, `Debug/UI`, `Debug/Util`, and `Debug/World`.
- Added square/object inspection tooling for runtime investigation of vanilla world objects.
- Added copyable inspection reports.
- Made object selection drive the inspection report directly, including Ctrl+click multi-selection.
- Added persistent world highlights for selected squares, with a stronger marker for the active square.
- Added a world square picker with hover highlighting and click-to-add selection.
- Added active-square directional expansion through `+N`, `+S`, `+E`, and `+W`.
- Added project-wide LMION Lua reload tooling for loaded Core and optional-module Lua files, including a server-side reload request path for multiplayer development.
- Split inspection output into a compact default view and an optional `Full details` view.
- Added a reload-friendly property-reader registry with a Build 42 `PropertyContainer:get(name)` default reader, while keeping per-property overrides available for exceptional cases.
- Added dedicated property-container and sprite inspection, including property values, surface metadata, and sprite-grid metadata.
- Expanded IsoDoor inspection with obstruction, curtain, barricade, key, and thump-state details, using the public open-sprite getter when available.
- Structured Full details by object depth, keeping Object, Sprite, and IsoDoor data in their own sections while separating named properties from property-container metadata.

### Pickup research
- Confirmed simple doors, sliding doors, large gates, and garage-door pieces can all appear as `IsoDoor` objects.
- Confirmed double-door/gate grouping through `doubleDoorIndex`.
- Confirmed garage grouping through `garageDoorIndex` plus first/prev/next linkage.
- Confirmed `closedSprite` can be retrieved independently of the current state through controlled reflection; current Build 42 APIs also expose a public `getOpenSprite()` getter.
