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
        │       └── media/lua/
        │           ├── shared/LMION/
        │           │   ├── Core.lua
        │           │   ├── Doors.lua
        │           │   └── Doors/Models.lua
        │           └── client/LMION/Debug/
        │
        ├── LMION_Build/
        │   └── 42/
        │       ├── mod.info
        │       └── media/
        │           ├── lua/shared/LMION/
        │           │   ├── Build.lua
        │           │   └── Build/
        │           │       ├── Catalog.lua
        │           │       └── Drafts.lua
        │           ├── scripts/
        │           └── textures/
        │
        └── LMION_Pickup/
            └── 42/
                ├── mod.info
                └── media/lua/shared/LMION/
                    └── Pickup.lua
```

## Module responsibilities

### `LMION_Core`

Core owns functionality that must stay neutral and reusable across feature modules:

- module registration and cross-module hooks;
- the shared `LMION.Doors` registry and canonical `DoorModel` data;
- shared low-level placement primitives when both Build and Pickup need the same implementation;
- persistence/world integration that genuinely crosses module boundaries;
- developer/debug tooling.

A `DoorModel` describes only shared facts about a door that multiple modules need. The current model intentionally stays minimal: a stable `doorId`, optional source identity, and the closed sprites needed for placement by orientation. Do not add mechanism/gameplay classifications merely because they might be useful later.

Core should not become a pile of hard-coded `if Build`, `if Pickup`, `if Locksmith` branches. Feature modules register what they add through Core APIs.

### `LMION_Build`

Build owns the player-facing construction side:

- construction-menu entries;
- craft recipes and progression;
- dismantle and destruction salvage rules;
- Build-specific validation and UX around creating a door.

The current `Build/Catalog.lua` is a **research/menu snapshot** of the showroom door set. It is not the canonical `DoorModel` registry. `Build/Drafts.lua` contains provisional Build-facing names, classifications, and recipe choices used while the construction system is still being developed.

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

### Shared door-model rule

Build and Pickup must not grow separate definitions or placement engines for the same door.

The intended direction is:

```text
Core / LMION.Doors / DoorModel + neutral placement primitives
               ↑                              ↑
             Build                          Pickup
      construction/economy            recovery/transport
```

Build and Pickup know only Core contracts plus their own data. They do not depend on each other. Module-specific data stays owned by that module and may be attached to a `doorId` through `LMION.Doors.extend(...)` when cross-module lookup is useful.

Core does not currently need to model open-state sprites, hinge/sliding mechanisms, double-door classifications, garage-door classifications, or runtime grouping. Multi-sprite placement data will be added only when a real placement/pickup case proves what structure is required.

## Folder rules

- `shared/LMION/` contains APIs and data structures usable by client/server code.
- `client/LMION/` contains UI, context menus, debug tools, and other client-only behavior.
- `server/LMION/` is created only when authoritative MP/server logic actually exists.
- The `LMION/` namespace folder is intentional; it avoids generic Lua require paths colliding with other mods.
- Debug tooling belongs to `LMION_Core` and is split by responsibility rather than kept in one monolithic file.
- Feature modules may register extra inspector sections from their own client code.
- Pickup strategies will live under `shared/LMION/Pickup/Strategies/` when the first real strategy is implemented.
- New code should be reload-friendly whenever practical: replace registrations by ID and remove/re-add event handlers instead of stacking duplicates.
- Runtime classification must not rely on sprite names alone.
- `media/scripts` changes require a real game restart; LMION Lua reload cannot reparse script definitions.
- Development-only migration tooling should not remain in the repository after the migration it served is complete.
