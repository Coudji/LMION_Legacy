# LMION code organization

Status: **current architecture**

This note records the intended file boundaries used to keep gameplay code readable without introducing abstractions that do not solve a concrete ownership problem.

## Refactoring rule

A file should be split when it owns several independently understandable responsibilities or lifecycle phases. A large file that is primarily declarative data does not need to be fragmented merely to reduce its line count.

Existing public/runtime behavior should be preserved during structural refactors. Refactoring is not an opportunity to silently remove extension points, alter lifecycle timing or change validated gameplay behavior.

## Parser-safe comments

Comments are encouraged when they explain a non-obvious invariant, lifecycle constraint, engine workaround or ownership boundary. The important rule is to use the comment syntax of the parser that actually owns the file.

For game-loaded **Lua**, use Lua long comments when a comment is useful:

```lua
--[[
explanatory text
]]
```

Avoid ordinary one-line `-- comment` comments in LMION game-loaded Lua so comments remain visually distinct and multi-line-safe. B42.20.3's bundled Lua lexer explicitly recognizes `--[[ ... ]]` as a long comment.

For Project Zomboid **script files** under `media/scripts`, use the scripting parser's block-comment form:

```text
/*
explanatory text
*/
```

Do not use Lua `--` / `--[[ ... ]]` syntax in `media/scripts`. B42.20.3 `ScriptParser.stripComments()` explicitly strips `/* ... */`; using a comment syntax that the scripting parser does not own can alter how the following script text is interpreted without producing an obvious error. `/** ... */` is also matched because it begins with `/*`, but LMION uses the simpler canonical `/* ... */` form.

Comments should explain **why** something unusual exists, not narrate obvious assignments line by line. Deep engine archaeology still belongs in `Research/` rather than being duplicated into source files.

## Pickup 1x1 door boundaries

The normal 1x1 Moveables path is grouped under `LMION/Pickup/Doors/`:

- `Doors/Registry.lua` — resolves GameEntity/SpriteConfig ownership into Pickup profiles, derives N/W Moveables faces and marks known sprites moveable at the tile-definition lifecycle point;
- `Doors/Hooks.lua` — owns the actual `ISMoveableSpriteProps` hooks, including face handling, health serialization, placement validation and state restoration;
- `DoorMoveables.lua` — compatibility/bootstrap entry point that loads the focused modules above.

The compatibility entry point remains intentionally tiny so existing `require "LMION/Pickup/DoorMoveables"` callers do not need to know the internal layout.

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

`Doors.lua` is still a good candidate for a future split, but it is lower-risk to do that after the current structural pass is regression-tested. The natural boundaries are profile/sprite lookup, engine-property application, durability/world adoption, placement validation and construction normalization.

`DoorProfiles.lua` is mostly declarative data. It can be grouped by catalog-style families later if navigation becomes painful, but family files should all feed one shared profile registry rather than duplicating profile-construction logic.

The Debug module is already divided into focused `Inspect`, `TestZone`, `UI`, `Util` and `World` areas and is not a priority for further fragmentation.

## Revalidation after structural changes

Adding Lua files or changing hook/load order deserves a cold restart before declaring a refactor behavior-neutral. A minimal regression pass should cover:

- one normal 1x1 door pickup/replacement with durability preservation;
- one ordinary single-visual-member large gate, including rotation;
- the Large Farm Gate, including its two-member placement preview;
- construction of a split vanilla large gate, confirming both leaf profiles and health calculation.
