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

### Pickup research
- Confirmed simple doors, sliding doors, large gates, and garage-door pieces can all appear as `IsoDoor` objects.
- Confirmed double-door/gate grouping through `doubleDoorIndex`.
- Confirmed garage grouping through `garageDoorIndex` plus first/prev/next linkage.
- Confirmed `closedSprite` and `openSprite` can be retrieved independently of the current open/closed state through the debug reflection helper.
