# Project Zomboid B42 Lua / script load order

Status: **engine-backed reference for B42.20.3/B42.20.4**.

This note exists because LMION has repeatedly hit startup failures caused by loading a hook from the wrong Lua tree. Treat the rules below as a development guardrail, not as incidental implementation detail.

Evidence comes from:

- B42.20.3 `projectzomboid.jar` bytecode (`zombie.Lua.LuaManager`, `zombie.core.Core`, `zombie.gameStates.GameLoadingState`, `zombie.network.GameServer`);
- B42.20.4 runtime startup logs;
- vanilla Lua repository paths.

## High-level startup order

The observed startup sequence is:

```text
media/scripts / Entity definitions
-> initial Lua shared phase
-> initial Lua client phase
-> OnGameBoot
-> later game/world loading
-> Lua server phase
-> ScriptManager.LoadedAfterLua()
-> world/tile-definition lifecycle continues
```

The runtime log independently confirms that script loading occurs before Lua loading:

```text
Chargement des scripts
...
Chargement Lua
```

Do not infer from this that every script-derived runtime structure is fully usable during the first shared Lua statement. Some engine-facing data is finalized/reapplied at later lifecycle events such as `OnLoadedTileDefinitions`.

## Exact Lua tree phases

### Normal client / single-player initial Lua load

`LuaManager.LoadDirBase()` is hard-coded as:

```text
LoadDirBase("shared")
LoadDirBase("client")
```

Therefore:

```text
shared executes first
client executes second
```

Only the Lua trees whose phase has started are available to `require()`.

Consequences:

- a file executing from `media/lua/shared` must not require a file that exists only in `media/lua/client` or `media/lua/server`;
- a file executing from the initial client phase must not require a server-tree file;
- `BuildingObjects/ISBuildIsoEntity.lua` is a **server-tree vanilla file**, not a client-tree file;
- `require("BuildingObjects/ISBuildIsoEntity")` therefore fails both from shared and from the initial client phase on B42.20.4.

This last point was runtime-confirmed by the variable-width garage Build prototype. The client loader and the initial version of `GarageBuildUI.lua` both attempted the require and received:

```text
require("BuildingObjects/ISBuildIsoEntity") failed
```

The same dependency then loaded successfully once the later server phase began.

### Single-player game loading

`GameLoadingState.enter()` later calls:

```text
LoadDirBase("server")
finishChecksum()
ScriptManager.LoadedAfterLua()
```

So server Lua is a **later phase**, not part of the initial `shared -> client` load.

Consequences:

- shared code must not assume server-tree Lua is available;
- client code must not assume a server-tree implementation has already attached functions;
- an API whose implementation is attached from `media/lua/server` may legitimately be `nil` during earlier client setup; resolve/check it at use time when appropriate;
- server-side hooks can require server-tree `BuildingObjects` once the server phase is active.

This explains both:

- the already validated Pickup pattern where the client inventory wrapper can exist before the server-tree garage placement cursor attaches `GarageDoor.openPlacementCursor`;
- the Build pattern where client UI records the selected garage width, while the `ISBuildIsoEntity` hook itself is installed from the server phase.

### Dedicated server

`GameServer` performs:

```text
LoadDirBase("shared")
LoadDirBase("client", true)
LoadDirBase("server")
```

The boolean `true` causes the client tree to be discovered/checksummed without executing its Lua files. Shared and server files execute.

Practical rule:

> Never put authoritative server behavior only in `media/lua/client`, and never rely on a client-side hook having executed on a dedicated server.

## What `LoadDirBase(phase)` actually does

For each phase, B42's `LuaManager`:

1. adds that phase to the known Lua paths;
2. scans vanilla/base files for that phase;
3. scans enabled mods for the same phase;
4. sorts discovered relative Lua paths with `String.CASE_INSENSITIVE_ORDER`;
5. executes each unique relative path.

The important implications are:

- filesystem enumeration order is **not** the execution contract;
- every discovered Lua file in the active phase is automatically executed, whether or not another LMION file explicitly `require()`s it;
- putting a module in `media/lua/shared` therefore means its top-level statements execute during the shared phase.

Within a phase, automatic execution is alphabetically sorted, case-insensitively. Do not rely on creation order, directory listing order, Workshop order, or Git order.

### `require()` and phase availability

`require()` is the preferred way to express a dependency, but it cannot cross into a Lua tree whose phase has not been registered yet.

Safe client example:

```text
media/lua/client/LMION/MyUIHook.lua
    require "Entity/ISUI/BuildRecipe/ISBuildPanel"
```

when the required vanilla file is itself in the client tree.

Safe server example for `ISBuildIsoEntity`:

```text
media/lua/server/LMION/MyBuildHook.lua
    require "BuildingObjects/ISBuildIsoEntity"
```

Unsafe examples:

```text
media/lua/shared/LMION/Build.lua
    require "BuildingObjects/ISBuildIsoEntity"

media/lua/client/LMION/MyUIHook.lua
    require "BuildingObjects/ISBuildIsoEntity"
```

because `ISBuildIsoEntity.lua` lives in the server tree and that phase has not started yet.

The first variable-width Build prototype additionally exposed a subtler failure. Moving the explicit `require` out of `Build.lua` did **not** solve the crash while `GarageBuildCursor.lua` itself remained physically under `media/lua/shared`: PZ auto-executed that shared file anyway, and its top-level access to `ISBuildIsoEntity.new` still ran too early.

The correct pattern is therefore:

```text
shared GarageBuildCursor module
-> declarations / installCursorHook() only
-> no top-level dereference of ISBuildIsoEntity

server GarageBuildCursorHook
-> require BuildingObjects/ISBuildIsoEntity
-> require shared module
-> call installCursorHook()
```

## LMION placement rules

Use these defaults unless engine evidence for a specific subsystem requires otherwise.

### `media/lua/shared`

Good candidates:

- constants and enums;
- pure topology/data models;
- functions operating on Java APIs already exposed globally;
- profile tables;
- serialization/state semantics needed by both client and server;
- APIs that do not dereference client/server-only Lua classes at file load time;
- inert reusable hook bodies whose installation is explicitly deferred to the correct phase.

Avoid:

- direct monkey-patching of vanilla classes defined only in client/server Lua;
- top-level `require()` of client/server-only files;
- top-level reads such as `ISBuildIsoEntity.new`, `ISMoveableCursor.isValid`, etc. unless their defining tree is definitely active.

### `media/lua/client`

Good candidates:

- UI widgets/windows;
- inventory/context menu hooks;
- player input/key handling;
- client-only cursors/classes whose definitions really live in the client tree;
- monkey-patches of vanilla client Lua classes after requiring their client file.

Client UI may prepare state that a later server-tree class consumes, but it must not force-load that server class early. For example, `GarageBuildUI.lua` can copy `lmionGarageLength` onto a build entity created by vanilla once it exists; it does not need to `require("BuildingObjects/ISBuildIsoEntity")` itself.

### `media/lua/server`

Good candidates:

- authoritative construction/placement completion;
- server-side item/world mutation;
- hooks that must execute in dedicated-server runtime;
- gameplay implementation intentionally deferred until game/world loading;
- patches of vanilla server-tree classes such as `BuildingObjects/ISBuildIsoEntity`.

Do not use `server` merely as a synonym for "gameplay code". If client and server both need an API contract, put the contract/model in shared and attach environment-specific behavior in the appropriate phase.

## Recommended hook pattern

For a vanilla Lua class whose definition is phase-specific:

```text
shared/LMION/FeatureModel.lua
-> pure data/model only

client/LMION/FeatureUI.lua
-> require only client-tree dependencies
-> manipulate client UI/state

server/LMION/FeatureHook.lua
-> require vanilla server-tree class
-> require/use shared LMION model
-> install authoritative/server hook
```

If implementation code is physically stored in shared for reuse, its top level must remain safe when auto-executed in shared. Phase-specific dereferences belong inside an installer invoked by the correct client/server loader.

## Lifecycle events are a separate axis

Lua-tree phase and engine lifecycle event are not the same concept.

Examples:

```text
shared/client/server
-> controls when Lua files become visible/executed

OnGameBoot
OnLoadedTileDefinitions
OnGameStart
...
-> controls when particular engine state is ready
```

A file can load successfully in shared yet still need to defer an engine mutation until `OnLoadedTileDefinitions`.

B42.20.4 provided a concrete garage example. During the initial shared Lua pass, the target sprites already exist, but their `GarageDoor=1/2/3` properties are still absent. Validating them at that moment produced misleading LMION errors such as:

```text
GarageDoor=nil, expected 1
```

Later, immediately after:

```text
LoadTileDefinitions end
triggerEvent OnLoadedTileDefinitions
```

LMION successfully installed all 14 garage runtime SpriteGrids and configured all 84 garage sprites for Moveables. Runtime Pickup/reinstallation then worked.

Rule:

> Do not classify missing tile-derived properties as invalid before `OnLoadedTileDefinitions`. On cold start, defer validation/mutation to that event. An immediate path may still be used during an in-world Lua reload if a readiness probe confirms the tile properties already exist.

LMION Core engine-profile application follows the same lifecycle distinction.

## Reload warning

`Core.ResetLua()` repeats the initial Lua bootstrap and then triggers:

```text
OnGameBoot
OnMainMenuEnter
OnResetLua
```

Monkey-patches must therefore remain reload-safe:

- save the original function once;
- do not wrap an already wrapped closure repeatedly;
- remember that server-phase code may not have rerun yet when an early client/shared reload callback fires;
- if a lifecycle event such as `OnLoadedTileDefinitions` has already fired, use a positive readiness check before doing an immediate reinstall rather than assuming either cold-start or in-world state.

A full restart remains mandatory when validating script changes and is strongly preferred after changing Lua tree placement/load-order code.

## Debugging checklist for startup failures

When a startup log reports:

```text
require("...") failed
```

check in this order:

1. Which tree contains the caller: shared, client or server?
2. Which tree **physically contains the required vanilla/mod file**?
3. Has that target tree's phase started yet?
4. Is the `require` path the Lua-relative path without `.lua`?
5. Does the failing file dereference the expected global immediately after a failed require?
6. Is the failing file itself being auto-executed merely because it sits in the active phase tree?
7. Is an event/lifecycle readiness issue being confused with a Lua-path issue?

For load-order regressions, preserve the first relevant `require failed` line and the first LMION stack trace. Later nil/index errors are often only consequences.

## Confirmed B42 facts vs assumptions

Confirmed from B42.20.3 bytecode / B42.20.4 runtime / vanilla tree paths:

- scripts load before the initial Lua bootstrap;
- normal initial Lua execution is shared then client;
- single-player loads server Lua later from `GameLoadingState`;
- dedicated server discovers but does not execute client Lua, then executes server Lua;
- each phase's discovered Lua paths are case-insensitively sorted before automatic execution;
- discovered files in an active phase are automatically executed even without an explicit LMION `require`;
- `OnGameBoot` occurs after the initial shared/client bootstrap;
- `ScriptManager.LoadedAfterLua()` occurs after the later server load in `GameLoadingState`;
- vanilla `ISBuildIsoEntity.lua` is in `media/lua/server/BuildingObjects`;
- `require("BuildingObjects/ISBuildIsoEntity")` fails during shared and initial client loading on B42.20.4 and succeeds once server Lua is active;
- garage sprite `GarageDoor` properties can be absent during initial shared Lua and present after `OnLoadedTileDefinitions`.

Not established here:

- a complete ordering of every PZ lifecycle event;
- a universal guarantee that every Java/script-derived subsystem is ready immediately after `media/scripts` parsing;
- exact multiplayer client connection lifecycle beyond the phase behavior above.

Add evidence here rather than guessing when a future subsystem exposes another timing boundary.
