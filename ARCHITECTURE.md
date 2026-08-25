# LMION folder architecture

This is the working layout for the current Build 42 project. Do not create empty folders merely because they may be useful someday.

```text
LMION_Workshop/
├── README.md
├── README_DEV.md
├── ARCHITECTURE.md
├── CURRENT_STATE.md
├── LMION_Design_Notes.md
├── Research/
├── workshop.txt
└── Contents/
    └── mods/
        ├── LMION_Core/
        │   └── 42/
        │       ├── mod.info
        │       ├── media/scripts/
        │       └── media/lua/shared/LMION/
        │           ├── Core.lua
        │           ├── Doors.lua
        │           └── DoorProfiles.lua
        ├── LMION_Build/
        │   └── 42/
        │       ├── mod.info
        │       └── media/
        │           ├── lua/shared/LMION/Build.lua
        │           ├── lua/shared/Translate/
        │           ├── scripts/
        │           └── textures/
        ├── LMION_Pickup/
        │   └── 42/
        │       ├── mod.info
        │       └── media/
        │           ├── lua/shared/LMION/Pickup.lua
        │           ├── lua/shared/LMION/Pickup/
        │           │   ├── DoorMoveables.lua
        │           │   ├── DoorProfiles.lua
        │           │   ├── LargeGateMoveables.lua
        │           │   ├── LargeGateProfiles.lua
        │           │   └── ToolDefinitions.lua
        │           ├── lua/shared/Translate/
        │           └── scripts/
        └── LMION_Debug/
            └── 42/
                ├── mod.info
                └── media/lua/
                    ├── client/LMION/Debug/
                    │   ├── Inspect/
                    │   ├── UI/
                    │   ├── Util/
                    │   ├── World/
                    │   ├── Inspector.lua
                    │   └── TestZone/
                    └── server/LMION/Debug/ReloadServer.lua
```

## Module responsibilities

### `LMION_Core`

Core owns shared functionality proven necessary across gameplay modules:

- the `LMION` namespace, logging and module registration;
- LMION door gameplay profiles;
- sprite/profile mapping from `GameEntityScript` / `SpriteConfig`;
- alias-safe application of engine-facing material and sound properties;
- low-level placement and durability helpers;
- authoritative logical max-health storage in `modData.lmionDoorMaxHealth`;
- world-door adoption and low-level repair capped by the LMION logical max.

Core does not own construction UX, pickup UX or future repair gameplay. It should not accumulate speculative abstractions or duplicate facts already available from Project Zomboid runtime objects and scripts.

### `LMION_Build`

Build owns construction recipes, progression and construction-facing localization/UI.

Build also owns the current large-gate split preparation because that split changes construction entity topology. On `OnGameBoot`, Build validates the exact vanilla closed-sprite sets for `Base.DoubleDoor`, `Base.DoubleWireGate` and `Base.DoubleFenceGate`, resets only their `SpriteConfig`, and reloads each vanilla entity as its left leaf. Right leaves use separate entities.

For LMION-owned large gates, the old full-gate identities have been replaced by explicit `Left` / `Right` entities. The six current large-gate families are therefore represented as twelve craftable leaves.

Build depends on Core, not Pickup.

### `LMION_Pickup`

Pickup owns transport/reinstallation through vanilla Moveables.

For validated 1x1 doors it handles:

- pickup eligibility;
- tools and skill requirements;
- dedicated inventory items;
- frame-aware replacement;
- preservation of current health and LMION logical max.

Large-gate Pickup is now a specialized path rather than forcing a 1x1 abstraction onto multi-square leaves. The active prototype is `Large Chain-Link Gate`:

- either square of one leaf can be targeted;
- logical `DoubleDoor` indices identify the two members of that leaf;
- only that leaf is removed;
- Pickup produces two parcels, `(1/2)` and `(2/2)`;
- replacement requires both parcels and recreates both segments in one action;
- vanilla `DoubleDoor` grouping resumes automatically when compatible leaves are adjacent.

The current large-gate placement preview is still under active validation. Keep preview/render code separate conceptually from the already working pickup and two-segment placement logic.

Pickup depends on Core, not Build.

### `LMION_Debug`

Debug owns development-only tooling:

- the Inspector;
- world-square selection/highlighting;
- deterministic Test Zone;
- LMION Lua reload helpers;
- temporary validation actions.

The Test Zone is an explicit fixture, not a runtime discovery scanner. It currently contains 83 entries after splitting the six large gates into twelve leaves.

Debug depends on Core. Gameplay modules do not depend on Debug.

## Large-gate topology rule

Project Zomboid runtime grouping for `IsoDoor` double doors/gates is driven by `DoubleDoor` indices and geometry, not by matching entity identity or sprite family.

Validated logical leaves are:

```text
leaf A = indices 1 + 2
leaf B = indices 3 + 4
```

LMION may therefore expose each leaf as an independent construction/pickup unit while still letting vanilla synchronize opening and closing across a correctly assembled four-member portal.

Do not call vanilla whole-double-door destruction logic when implementing per-leaf pickup, because that path intentionally destroys linked members. The vanilla `Destroy` menu is currently expected to destroy the complete portal and is left unchanged.

## SpriteConfig ownership rule

`SpriteConfigScript.allTileNames` is derived from actual declared `SpriteConfig` face tiles. `SpriteConfigManager` uses those names for global scripted-sprite ownership.

When changing vanilla large-gate ownership at runtime:

- validate the expected vanilla tile set first;
- call `SpriteConfigScript:PreReload()` on that component only;
- reload only the intended `SpriteConfig` body;
- verify the resulting tile set exactly;
- never call `GameEntityScript:PreReload()` merely to reset SpriteConfig, because that would clear all components.

`media/scripts` and TileDefinitions remain separate concerns: TileDefinitions can provide runtime physical properties and open-state behavior without being the source of `SpriteConfigScript.allTileNames`.

## Durability rule

`IsoDoor` exposes current health and engine max health, but production Lua has no usable `IsoDoor:setMaxHealth()` path. LMION therefore keeps the authoritative gameplay max in:

```text
lmionDoorMaxHealth
```

Current health may legitimately exceed `IsoDoor:getMaxHealth()`. LMION-owned repair and condition logic must use the logical max.

## Material-property safety rule

Project Zomboid property values are alias-backed. Unknown string values can resolve to a different valid alias. Engine-facing writes must verify exact readback and restore the previous property if the requested value did not survive exactly.

## Localization rule

Build construction names use `Recipes.json`. In current B42 behavior, recipe translation lookup removes spaces from `DisplayName`, so translation keys must match that normalized form. Pickup inventory items use their own item/localization path.

Canonical LMION paired naming uses the English base name plus `Left` / `Right` in internal identifiers and `Left Leaf` / `Right Leaf` in English display text. French display text uses `vantail gauche` / `vantail droit`.

## Folder and source rules

- `shared/LMION/` contains code usable by both client/server contexts.
- `client/LMION/` is for client UI/context behavior.
- `server/LMION/` is for authoritative server behavior when genuinely needed.
- Game-loaded LMION Lua and script files intentionally contain no `--` line comments; rationale belongs in documentation.
- `media/scripts` changes require a full game restart.
- New Lua files, load-order changes, metadata changes and stale monkey-patch closures may also require a full restart.
- Lua-only edits to already loaded LMION files may be tested with the Debug reload path, but active cursor instances/closures can still require re-entering the mode or restarting.
- Runtime classification should prefer engine structure over sprite-name guesses whenever stronger data exists.
- Development-only diagnostics must not become permanent gameplay dependencies.

## Documentation roles

- `CURRENT_STATE.md` is the active handoff/checkpoint.
- `ARCHITECTURE.md` documents module boundaries and hard guardrails.
- `LMION_Design_Notes.md` records durable gameplay decisions and engine research conclusions.
- `README_DEV.md` records practical workflow and current high-level implementation status.
