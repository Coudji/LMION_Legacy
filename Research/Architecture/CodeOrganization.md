# LMION code organization

Status: **current architecture**

This note records the intended file boundaries used to keep gameplay code readable without introducing abstractions that do not solve a concrete ownership problem.

## Refactoring rule

A file should be split when it owns several independently understandable responsibilities or lifecycle phases. A large file that is primarily declarative data does not need to be fragmented merely to reduce its line count.

Existing public/runtime behavior should be preserved during structural refactors. Refactoring is not an opportunity to silently remove extension points, alter lifecycle timing or change validated gameplay behavior.

## Lua comments

Game-loaded Lua may contain comments when they materially improve comprehension, but LMION uses only Lua block comments:

```lua
--[[ explanatory text ]]
```

Do not use single-line `-- comment` syntax in game-loaded files.

## Pickup large-gate boundaries

The large-gate implementation is intentionally split by responsibility:

- `LargeGateProfiles.lua` — Moveables gameplay requirements per left/right leaf entity;
- `LargeGateSpecs.lua` — family topology: sprites, logical DoubleDoor indices, parcel item types and preview metadata;
- `LargeGateRuntime.lua` — runtime `IsoSpriteGrid` creation and lifecycle reinstall after tile definitions;
- `LargeGateMoveables.lua` — Moveables property decoration, leaf resolution and pickup hooks;
- `LargeGatePlacement.lua` — two-segment placement planning, validation and explicit reconstruction;
- server `LargeGateCursor.lua` — placement ghost rendering only.

Family-specific presentation facts belong in `LargeGateSpecs.lua`. For example, the Large Farm Gate declares `previewAllParts = true`; the cursor renderer should not maintain a second hardcoded list of farm leaf IDs.

The established `Pickup.LargeGateLeafSpecs` alias remains available so existing LMION code does not need to know about the internal split.

## Build large-gate boundaries

`Build.lua` is a bootstrap rather than an implementation bucket.

- `Build/LargeGateProfiles.lua` — derives the runtime left/right gameplay profiles from the original family profiles. It runs at Lua load so hot reload can reconstruct derived profiles.
- `Build/VanillaLargeGateSplit.lua` — owns the three vanilla SpriteConfig ownership rewrites and their `OnGameBoot` lifecycle.
- `BuildHook.lua` — remains responsible for construction completion and `IsoThumpable -> IsoDoor` normalization.

Profile derivation and SpriteConfig rewriting stay separate because they deliberately run at different lifecycle moments.

## Files deliberately not split yet

`DoorMoveables.lua` is a reasonable next candidate because it currently contains sprite/profile discovery, Moveables decoration, durability serialization and placement restoration. Split it only if the resulting files have clear ownership and the monkey-patch order remains obvious.

`Doors.lua` is also sizeable, but much of it forms one coherent low-level door service. Possible future boundaries are engine-property application, durability/world adoption and construction normalization. Do not split it solely on line count.

`DoorProfiles.lua` is mostly declarative data; its size alone is not a refactoring problem.

The Debug module is already divided into focused `Inspect`, `TestZone`, `UI`, `Util` and `World` areas and is not a priority for further fragmentation.

## Revalidation after structural changes

Adding Lua files or changing hook/load order deserves a cold restart before declaring a refactor behavior-neutral. A minimal regression pass should cover:

- one normal 1x1 door pickup/replacement with durability preservation;
- one ordinary single-visual-member large gate, including rotation;
- the Large Farm Gate, including its two-member placement preview;
- construction of a split vanilla large gate, confirming both leaf profiles and health calculation.
