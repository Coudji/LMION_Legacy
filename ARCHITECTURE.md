# LMION folder architecture

This is the working folder layout for the current Build 42 project. Do not create empty folders merely because they may be useful someday.

```text
LMION_Workshop/
├── README.md
├── README_DEV.md
├── ARCHITECTURE.md
├── LMION_Design_Notes.md
├── CHANGELOG.md
├── workshop.txt
└── Contents/
    └── mods/
        ├── LMION_Core/
        │   └── 42/
        │       ├── mod.info
        │       └── media/lua/
        │           ├── shared/LMION/
        │           │   └── Core.lua
        │           └── client/LMION/Debug/
        │               ├── Inspector.lua
        │               ├── Registry.lua
        │               ├── Inspect/
        │               │   ├── CoreObject.lua
        │               │   ├── IsoDoor.lua
        │               │   └── ObjectInspector.lua
        │               ├── UI/
        │               │   ├── InspectorWindow.lua
        │               │   ├── ObjectPanel.lua
        │               │   ├── ReportPanel.lua
        │               │   └── SquarePanel.lua
        │               ├── Util/
        │               │   ├── Reflection.lua
        │               │   └── Safe.lua
        │               └── World/
        │                   ├── Selection.lua
        │                   └── SquareScanner.lua
        │
        └── LMION_Pickup/
            └── 42/
                ├── mod.info
                └── media/lua/shared/LMION/
                    └── Pickup.lua
```

## Rules

- `shared/LMION/` contains APIs and data structures usable by client/server code.
- `client/LMION/` contains UI, context menus, debug tools, and other client-only behavior.
- `server/LMION/` is created only when authoritative MP/server logic actually exists.
- The `LMION/` namespace folder is intentional; it avoids generic Lua require paths colliding with other mods.
- Debug tooling belongs to `LMION_Core` and is split by responsibility rather than kept in one monolithic file.
- Feature modules may register extra inspector sections from their own client code.
- Pickup strategies will live under `shared/LMION/Pickup/Strategies/` when the first real strategy is implemented.
- New code should be reload-friendly whenever practical: replace registrations by ID and remove/re-add event handlers instead of stacking duplicates.
- Runtime classification must not rely on sprite names alone.
