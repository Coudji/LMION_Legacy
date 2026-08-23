# LMION folder architecture

This is the working layout for the current Build 42 project. Do not create empty folders merely because they may be useful someday.

```text
LMION_Workshop/
├── README.md
├── README_DEV.md
├── ARCHITECTURE.md
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
        │           └── Doors.lua
        │
        ├── LMION_Build/
        │   └── 42/
        │       ├── mod.info
        │       └── media/
        │           ├── lua/shared/LMION/
        │           │   └── Build.lua
        │           ├── scripts/
        │           └── textures/
        │
        ├── LMION_Pickup/
        │   └── 42/
        │       ├── mod.info
        │       └── media/lua/shared/LMION/
        │           └── Pickup.lua
        │
        └── LMION_Debug/
            └── 42/
                ├── mod.info
                └── media/lua/
                    ├── client/LMION/Debug/
                    │   ├── Inspect/
                    │   │   ├── Door.lua
                    │   │   └── ObjectInspector.lua
                    │   ├── UI/
                    │   ├── Util/
                    │   │   └── Safe.lua
                    │   ├── World/
                    │   ├── TestZone.lua
                    │   └── TestZone/
                    │       ├── Manifest.lua
                    │       └── Spawner.lua
                    └── server/LMION/Debug/
                        └── ReloadServer.lua
```

## Module responsibilities

### `LMION_Core`

Core owns only shared functionality that is proven necessary across gameplay modules:

- the `LMION` namespace, logging helpers and module registration;
- shared opening-specific engine adapters such as garage-door creation;
- shared low-level placement or persistence primitives only when real Build/Pickup use cases require them;
- `media/scripts` entity definitions needed by the project.

Core intentionally has no generic event bus, no speculative cross-module hook system, and no parallel Lua door-model registry. Runtime objects and their `GameEntityScript` / `SpriteConfig` data are preferred as the authoritative source when the engine already exposes the needed facts.

Future cross-module contracts should be added only for concrete requirements. Core should not accumulate generic abstractions merely because a later module might need them.

### `LMION_Build`

Build owns the player-facing construction side:

- construction-menu entries;
- craft recipes and progression;
- dismantle and destruction salvage rules;
- Build-specific validation and UX around creating a door.

Build does not maintain a parallel Lua catalog of opening families. The active Build entities, recipes and progression definitions live in `media/scripts/`; those script files are the source of truth for the construction prototype.

Build-specific construction icons currently live as standalone PNG files under `media/textures/`; they are presentation assets, not canonical door-model data.

Build depends on Core, not Pickup.

### `LMION_Pickup`

Pickup owns the player-facing recovery/transport side:

- recognizing an existing world door;
- pickup eligibility such as unlocked/no barricade/no curtain requirements;
- tool requirements for recovering a door when needed;
- clean removal;
- serializing physical/runtime state needed for transport;
- inventory representation of a recovered door;
- requesting re-placement of that recovered door.

Pickup depends on Core, not Build.

### `LMION_Debug`

Debug owns development-only tooling:

- the door-focused LMION Inspector and its extensible report registry;
- world-square selection, highlighting and picker UI;
- the deterministic Test Zone;
- client/server LMION Lua reload helpers.

The Inspector intentionally reports only runtime facts useful to LMION door systems. Static configuration such as closed/open sprite pairs belongs to `GameEntityScript` / `SpriteConfig` and the source scripts rather than a private-field reflection dump. Future feature modules may add their own focused report sections when Debug is present.

Debug depends on Core. Core, Build and Pickup do not depend on Debug. The namespace remains `LMION.Debug` so the debug code can stay modular without leaking developer tooling into Core.

The Test Zone is intentionally a deterministic fixture. Its manifest explicitly defines which opening is spawned at each coordinate. It must not grow back into a runtime discovery scanner.

## Shared-system rule

Build and Pickup must not duplicate genuinely shared placement or persistence logic. Shared abstractions belong in Core only after a real use case proves that both modules need them.

Do not maintain a speculative parallel model of doors when equivalent runtime or script data is already available from Project Zomboid. If a future module such as Locksmith needs to attach additional state to a picked-up door, define a focused contract for that concrete requirement at that time.

## Folder rules

- `shared/LMION/` contains APIs and data structures usable by client/server code.
- `client/LMION/` contains UI, context menus and other client-only behavior.
- `server/LMION/` contains authoritative server behavior when it genuinely exists.
- The `LMION/` namespace folder is intentional; it avoids generic Lua require paths colliding with other mods.
- Developer/debug tooling belongs to `LMION_Debug`, not Core.
- Feature modules may register extra inspector sections from their own client code when Debug is present, but they must not require Debug for gameplay.
- Pickup strategies will live under `shared/LMION/Pickup/Strategies/` when the first real strategy is implemented.
- New code should be reload-friendly whenever practical: replace registrations by ID and remove/re-add event handlers instead of stacking duplicates.
- Runtime classification must not rely on sprite names alone.
- Game-loaded Lua and script files intentionally avoid source comments. Important rationale and implementation constraints belong in project documentation such as this file or `LMION_Design_Notes.md`.
- `--` line comments are forbidden in LMION game-loaded source. In `media/scripts`, if a comment is ever unavoidable, use only the Project Zomboid parser-supported multiline comment form. Lua gameplay/debug source should remain comment-free rather than introducing parser/style exceptions.
- `media/scripts` changes require a real game restart; LMION Lua reload cannot reparse script definitions.
- Development-only migration or research tooling should not remain in gameplay modules after the task it served is complete.
