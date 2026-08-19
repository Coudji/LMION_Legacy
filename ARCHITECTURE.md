# LMION folder architecture

This is the folder layout we keep from now on. Do not create empty folders merely
because we may need them someday.

```text
LMION_Workshop/
├── ARCHITECTURE.md
├── LMION_Design_Notes.md
└── Contents/
    └── mods/
        ├── LMION_Core/
        │   └── 42/
        │       ├── mod.info
        │       └── media/
        │           └── lua/
        │               ├── shared/
        │               │   └── LMION/
        │               │       └── Core.lua
        │               └── client/
        │                   └── LMION/
        │                       └── Debug/
        │                           ├── Registry.lua
        │                           └── Inspector.lua
        │
        └── LMION_Pickup/
            └── 42/
                ├── mod.info
                └── media/
                    └── lua/
                        └── shared/
                            └── LMION/
                                └── Pickup.lua
```

## Rules

- `shared/LMION/` = APIs and data structures usable by client/server.
- `client/LMION/` = UI, context menus and developer tools.
- `server/LMION/` is created only when we actually add authoritative MP/server logic.
- No empty `common/` directory for now.
- No empty strategy directories for now.
- Pickup strategies will later live under
  `shared/LMION/Pickup/Strategies/` when the first real strategy exists.
- Debug tools belong to Core.
- Feature modules may register extra inspector sections from their own client code.
- New code should be reload-friendly whenever possible: replace registrations by ID
  and remove/re-add event handlers instead of stacking duplicates.
