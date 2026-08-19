# LMION folder architecture

This is the working layout for the current Build 42 project. Do not create empty folders merely because they may be useful someday.

```text
LMION_Workshop/
├── README.md
├── README_DEV.md
├── ARCHITECTURE.md
├── LMION_Design_Notes.md
├── CHANGELOG.md
├── Research/
├── workshop.txt
└── Contents/
    └── mods/
        ├── LMION_Core/
        │   └── 42/
        │       ├── mod.info
        │       └── media/lua/
        │           ├── shared/LMION/
        │           └── client/LMION/Debug/
        │
        ├── LMION_Build/
        │   └── 42/
        │       ├── mod.info
        │       ├── media/lua/shared/LMION/
        │       │   ├── Build.lua
        │       │   └── Build/Catalog.lua
        │       └── media/scripts/
        │           └── LMION_Build_Catalog_*.txt
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
- shared opening-family identity/definition APIs once those are formalized;
- shared low-level placement primitives when both Build and Pickup need the same implementation;
- persistence/world integration that genuinely crosses module boundaries;
- developer/debug tooling.

Core should not become a pile of hard-coded `if Build`, `if Pickup`, `if Locksmith` branches. Feature modules register what they add.

### `LMION_Build`

Build owns the player-facing construction side:

- construction-menu entries;
- craft recipes and progression;
- choosing a new opening family to place;
- Build-specific validation and UX around creating a new opening.

The current `Build/Catalog.lua` and `LMION_Build_Catalog_*.txt` files are a **research/menu snapshot** of the 77 showroom families. They are not yet the canonical door-definition registry and the placeholder recipes are intentionally not production recipes.

Build depends on Core, not Pickup.

### `LMION_Pickup`

Pickup owns the player-facing recovery/transport side:

- recognizing an existing world opening;
- clean removal;
- serializing physical/runtime state needed for transport;
- inventory representation of a recovered opening;
- requesting re-placement of that recovered opening.

Pickup depends on Core, not Build.

### Shared placement rule

Build and Pickup must not grow two independent placement engines.

The intended direction is:

```text
Core/shared opening definition + neutral placement primitives
        ↑                              ↑
      Build                          Pickup
 new construction              recovered opening
```

Build decides how a new door is acquired/crafted. Pickup decides how an existing door is removed and transported. Both should ultimately describe the same opening family to shared placement code.

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
