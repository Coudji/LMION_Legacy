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
        │           ├── Pickup.lua
        │           └── Pickup/
        │               └── DoorMoveables.lua
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
                    │   ├── Inspector.lua
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
- LMION door profiles containing only gameplay rules that LMION actually overrides;
- mapping those profiles to `GameEntityScript` / `SpriteConfig` tile names;
- alias-safe application of engine-facing door properties such as materials;
- shared low-level placement and persistence primitives used by real modules;
- logical max-health storage in door modData;
- world-door durability adoption when an LMION durability profile exists;
- low-level health repair capped by LMION logical max rather than engine `IsoDoor.maxHealth`;
- `media/scripts` entity definitions needed by the project.

Core does not own player-facing construction, pickup or repair UX. A future gameplay repair module should depend on Core and own tools, materials, skills, timed actions and menu/UI behavior.

Core intentionally has no generic event bus and no speculative parallel model duplicating facts already available from Project Zomboid runtime objects and `GameEntityScript` / `SpriteConfig` data. The profile registry exists only for LMION-owned gameplay overrides.

Future cross-module contracts should be added only for concrete requirements. Core should not accumulate generic abstractions merely because a later module might need them.

### `LMION_Build`

Build owns the player-facing construction side:

- construction-menu entries;
- craft recipes and progression;
- dismantle and destruction salvage rules when those are Build-owned gameplay decisions;
- Build-specific validation and UX around creating a door.

Build-specific construction definitions live in `media/scripts/`. LMION profiles in Core may override shared gameplay properties, but Build should not duplicate a separate door-family catalog.

Build-specific construction icons currently live as standalone PNG files under `media/textures/`; they are presentation assets, not canonical door-model data.

Build depends on Core, not Pickup.

### `LMION_Pickup`

Pickup owns the player-facing recovery/transport side:

- recognizing LMION-enabled world doors through the shared profile mapping;
- pickup eligibility and Moveables integration;
- tool/skill requirements for recovering and placing a door;
- clean removal;
- serializing physical/runtime state needed for transport;
- inventory representation of a recovered door;
- requesting re-placement of that recovered door;
- restoring current health and LMION logical max on the actual placed `IsoDoor`.

For the validated simple-door path, inventory modData carries:

```text
lmionDoorHealth
lmionDoorMaxHealth
```

Pickup depends on Core, not Build.

### `LMION_Debug`

Debug owns development-only tooling:

- the door-focused LMION Inspector and its extensible report registry;
- world-square selection, highlighting and picker UI;
- the deterministic Test Zone;
- client/server LMION Lua reload helpers;
- temporary validation actions such as the current `LMION Repair +50 HP` context action.

Temporary Debug validation actions must not silently become gameplay systems. Once a real feature module exists, Debug should return to inspection/testing support only.

The Inspector intentionally reports only runtime facts useful to LMION door systems. Static configuration such as closed/open sprite pairs belongs to `GameEntityScript` / `SpriteConfig` and the source scripts rather than a private-field reflection dump.

Debug depends on Core. Core, Build and Pickup do not depend on Debug. The namespace remains `LMION.Debug` so the debug code can stay modular without leaking developer tooling into Core.

The Test Zone is intentionally a deterministic fixture. Its manifest explicitly defines which opening is spawned at each coordinate. It must not grow back into a runtime discovery scanner.

## Shared-system rule

Build and Pickup must not duplicate genuinely shared placement, persistence or durability logic. Shared primitives belong in Core only after a real use case proves that more than one gameplay module needs them.

Do not maintain a speculative parallel model of doors when equivalent runtime or script data is already available from Project Zomboid. Profiles are for LMION-owned gameplay overrides only.

## Durability rule

`IsoDoor` exposes current health and engine max health, but production Lua has no usable `IsoDoor:setMaxHealth()` path. LMION therefore keeps an authoritative logical max in modData:

```text
lmionDoorMaxHealth
```

Current health may legitimately exceed `IsoDoor:getMaxHealth()`.

Existing world-door adoption uses a conservative migration rule:

- if current health equals engine max on first adoption, current health is raised to the new LMION world max;
- if the door is already damaged, current health is not changed;
- the LMION logical max is stored in both cases;
- an already-adopted door is not re-adopted merely because its square loads again.

Do not replace this with ratio-based scaling or unconditional healing without an explicit design change.

## Material-property safety rule

Project Zomboid property values are alias-backed. Unknown string values can resolve to the wrong valid alias. Engine-facing property application must verify exact readback and restore the previous property when the requested value does not survive exactly.

Do not blindly call `PropertyContainer:set(name, arbitraryString)` for LMION gameplay data.

## Folder rules

- `shared/LMION/` contains APIs and data structures usable by client/server code.
- `client/LMION/` contains UI, context menus and other client-only behavior.
- `server/LMION/` contains authoritative server behavior when it genuinely exists.
- The `LMION/` namespace folder is intentional; it avoids generic Lua require paths colliding with other mods.
- Developer/debug tooling belongs to `LMION_Debug`, not Core.
- Feature modules may register extra inspector sections from their own client code when Debug is present, but they must not require Debug for gameplay.
- Pickup strategies may live under `shared/LMION/Pickup/Strategies/` when specialized opening handling requires them; do not create speculative strategy layers before they are needed.
- New code should be reload-friendly whenever practical: replace registrations by ID and remove/re-add event handlers instead of stacking duplicates.
- Runtime classification must not rely on sprite names alone when the engine exposes stronger data.
- Game-loaded Lua and script files intentionally avoid source comments. Important rationale and implementation constraints belong in project documentation such as this file, `LMION_Design_Notes.md` or `CURRENT_STATE.md`.
- `--` line comments are forbidden in LMION game-loaded source. In `media/scripts`, if a comment is ever unavoidable, use only the Project Zomboid parser-supported multiline comment form. Lua gameplay/debug source should remain comment-free rather than introducing parser/style exceptions.
- `media/scripts` changes require a real game restart; LMION Lua reload cannot reparse script definitions.
- New Lua files, changed load order, mod metadata changes or stale monkey-patch closures can also require a full restart.
- Development-only migration or research tooling should not remain in gameplay modules after the task it served is complete.
- Do not reintroduce the removed intrusive `MoveablesTrace.lua` diagnostic unless a new, nonintrusive design is explicitly required.

## Documentation roles

- `CURRENT_STATE.md` is the active handoff/checkpoint document. Update it after meaningful validated milestones or architecture-impacting decisions, not mechanically after every commit.
- `ARCHITECTURE.md` documents module boundaries, ownership and guardrails.
- `LMION_Design_Notes.md` documents durable gameplay/design decisions and engine research conclusions.
- `README_DEV.md` gives the practical developer workflow and current high-level status.
