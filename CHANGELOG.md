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
- Added door-like IsoThumpable inspection for Build 42 entity-scripted gates and grouped openings.
- Added Full-details inspection of Build 42 `GameEntityScript` and `SpriteConfig` data for objects carrying `EntityScriptName`, including script identity, component list, tile list, face dimensions, and configured tiles.
- Structured Full details by object depth, keeping Object, Sprite, and runtime-class data in their own sections while separating named properties from property-container metadata.
- Added a debug door-showroom scanner/spawner that enumerates loaded sprites by door properties rather than sprite names, groups garage and DoubleDoor families, deduplicates obvious N/W single-door pairs, and lays the resulting families out from a chosen world square.
- Added canonical closed-orientation showroom generation using vanilla DoubleDoor and garage sprite/group rules, plus a separate rejected-candidate area for incomplete or unoriented records.
- Added automatic door-showroom scan reports with DoorSound and EntityScriptName distributions and a context-menu action that copies the full report without selecting showroom objects.
- Added object-list filters to the Inspector for all objects, doors/gates, floor tiles, and world inventory items; `Select shown` follows the active filter.
- Restored the world context menu to a single `LMION Inspector` entry and moved showroom rebuild/report actions into the Inspector window.

### Pickup research
- Confirmed simple doors, sliding doors, and garage-door pieces can appear as `IsoDoor` objects, while Build 42 entity-scripted gates can also appear as door-like `IsoThumpable` objects.
- Confirmed double-door/gate grouping through the `DoubleDoor` tile property and runtime double-door helpers.
- Confirmed garage grouping through `garageDoorIndex` plus first/prev/next linkage; open sprites use `GarageDoor=4..6` while the runtime index remains normalized to `1..3`.
- Confirmed `closedSprite` can be retrieved independently of the current state through controlled reflection; current Build 42 APIs also expose a public `getOpenSprite()` getter.
