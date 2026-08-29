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

Critically, the client Lua search path is not registered until the client phase begins.

Consequences:

- a file executing from `media/lua/shared` must not require a file that exists only in `media/lua/client`;
- `require("BuildingObjects/ISBuildIsoEntity")` from shared fails because `ISBuildIsoEntity.lua` is a client-tree vanilla file;
- moving the require into a client loader is valid because the client path exists at that point.

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
- server-side hooks that need vanilla BuildingObjects can require them once the server phase is active if that vanilla path is available in that runtime context.

This explains the already validated Pickup pattern where the client inventory wrapper can exist before the server-tree garage placement cursor attaches `GarageDoor.openPlacementCursor`.

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

The important implication is that filesystem enumeration order is **not** the execution contract. Within a phase, automatic execution is alphabetically sorted, case-insensitively.

Do not rely on creation order, directory listing order, Workshop order, or Git order.

### `require()` and phase availability

`require()` is the preferred way to express a dependency, but it cannot cross into a Lua tree whose phase has not been registered yet.

Safe example:

```text
media/lua/client/LMION/MyHook.lua
    require "BuildingObjects/ISBuildIsoEntity"
```

because the client phase is active and the vanilla client path is known.

Unsafe example:

```text
media/lua/shared/LMION/Build.lua
    require "BuildingObjects/ISBuildIsoEntity"
```

because execution is still in the shared phase and the vanilla client path is not yet available.

This was reproduced on B42.20.4 by the first variable-width Build prototype:

```text
require("BuildingObjects/ISBuildIsoEntity") failed
attempted index: new of non-table: null
GarageBuildCursor.lua
```

The fix was to keep pure shared data/model code in shared and load the `ISBuildIsoEntity` hook from client/server phase loaders instead.

## LMION placement rules

Use these defaults unless engine evidence for a specific subsystem requires otherwise.

### `media/lua/shared`

Good candidates:

- constants and enums;
- pure topology/data models;
- functions operating on Java APIs already exposed globally;
- profile tables;
- serialization/state semantics needed by both client and server;
- APIs that do not dereference client/server-only Lua classes at file load time.

Avoid:

- direct monkey-patching of vanilla classes defined only in client/server Lua;
- top-level `require()` of client/server-only files;
- top-level reads such as `ISBuildIsoEntity.new`, `ISMoveableCursor.isValid`, etc. unless their defining tree is definitely active.

### `media/lua/client`

Good candidates:

- UI widgets/windows;
- inventory/context menu hooks;
- player input/key handling;
- client cursor setup;
- monkey-patches of vanilla client Lua classes after requiring their client file.

### `media/lua/server`

Good candidates:

- authoritative construction/placement completion;
- server-side item/world mutation;
- hooks that must execute in dedicated-server runtime;
- gameplay implementation intentionally deferred until game/world loading.

Do not use `server` merely as a synonym for "gameplay code". If client and server both need an API contract, put the contract/model in shared and attach environment-specific behavior in the appropriate phase.

## Recommended hook pattern

For a vanilla Lua class whose definition is phase-specific:

```text
shared/LMION/FeatureModel.lua
-> pure data/model only

client/LMION/FeatureHook.lua
-> require vanilla client class
-> require/use shared LMION model
-> install client hook

server/LMION/FeatureHook.lua
-> require vanilla class needed by server runtime
-> require/use shared LMION model
-> install authoritative/server hook
```

If both environments need to install exactly the same patch body, the implementation may live in a reusable LMION module, but **do not execute that module from shared if it dereferences the phase-specific vanilla class at top level**. Trigger it from phase loaders.

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

LMION already relies on this distinction for engine-facing door/tile profile application.

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
- remember that server-phase code may not have rerun yet when an early client/shared reload callback fires.

A full restart remains mandatory when validating script changes and is strongly preferred after changing Lua tree placement/load-order code.

## Debugging checklist for startup failures

When a startup log reports:

```text
require("...") failed
```

check in this order:

1. Which tree contains the caller: shared, client or server?
2. Which tree contains the required vanilla/mod file?
3. Has that target tree's phase started yet?
4. Is the `require` path the Lua-relative path without `.lua`?
5. Does the failing file dereference the expected global immediately after a failed require?
6. Is an event/lifecycle readiness issue being confused with a Lua-path issue?

For load-order regressions, preserve the first relevant `require failed` line and the first LMION stack trace. Later nil/index errors are often only consequences.

## Confirmed B42 facts vs assumptions

Confirmed from B42.20.3 bytecode / B42.20.4 runtime:

- scripts load before the initial Lua bootstrap;
- normal initial Lua execution is shared then client;
- single-player loads server Lua later from `GameLoadingState`;
- dedicated server discovers but does not execute client Lua, then executes server Lua;
- each phase's discovered Lua paths are case-insensitively sorted before automatic execution;
- `OnGameBoot` occurs after the initial shared/client bootstrap;
- `ScriptManager.LoadedAfterLua()` occurs after the later server load in `GameLoadingState`;
- a shared-to-client `require("BuildingObjects/ISBuildIsoEntity")` fails in B42.20.4.

Not established here:

- a complete ordering of every PZ lifecycle event;
- a universal guarantee that every Java/script-derived subsystem is ready immediately after `media/scripts` parsing;
- exact multiplayer client connection lifecycle beyond the phase behavior above.

Add evidence here rather than guessing when a future subsystem exposes another timing boundary.
