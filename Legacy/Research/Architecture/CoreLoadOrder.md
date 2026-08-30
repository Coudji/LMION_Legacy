# LMION Core load order

Status: verified against the uploaded Project Zomboid B42.20.3 jar on 2026-08-30.

## Project Zomboid Lua scopes

Client load order:

```text
shared
client
```

Dedicated server load order:

```text
shared
client scanned without execution
server
```

The server scans client Lua for checksum purposes but does not execute it.

Canonical Core registration shared by client and server therefore belongs in `media/lua/shared`.

## Active mod order

For each Lua scope, `LuaManager.LoadDirBase(scope)` obtains active mod IDs from `ZomboidFileSystem.getModIDs()` and processes them in that order.

Inside one mod, discovered Lua paths are sorted case-insensitively before execution.

Consequences:

1. mod load order is observable and authoritative;
2. file order inside one mod is deterministic;
3. third-party LMION content mods must depend on Core so Core loads first;
4. extension conflicts naturally follow registration/load order;
5. later same-layer extension writes win.

LMION adds no separate priority score.

## Core API versus Core startup

`LMION/API.lua` exposes the public API only. Requiring the API does not bootstrap built-in content.

The runtime entry point is:

```text
media/lua/shared/LMION_Core.lua
```

Its job is small:

```text
require public API
-> bootstrap LMION built-ins through that API
-> register OnGameBoot diagnostics/final indexing checkpoint
```

Catalog and DefinitionDefault files remain pure data with no registration side effects.

## Third-party registration timing

PZ loads one active mod's Lua files before moving to the next mod in that scope.

With a normal dependency order:

```text
LMION_Core shared Lua
    -> built-in content registered

ThirdPartyMod shared Lua
    -> require "LMION/API"
    -> registerDefault/registerDefinition/registerExtension
```

External mods never need to place files inside LMION folders.

## OnGameBoot checkpoint

The B42.20.3 jar triggers `OnGameBoot` after normal Lua mod loading on client and dedicated server.

LMION uses it as a checkpoint, not as the preferred registration phase.

At that point Core rebuilds the reverse GameEntity index and validates indexed GameEntities against `ScriptManager`.

Normal development output is intentionally compact:

```text
[LMION:Core] OnGameBoot registry snapshot: ...
[LMION:Core] GameEntity index ready: ...
[LMION:Core] PZ GameEntity validation: ...
```

Missing mappings are printed individually. The previous one-line-per-definition dump has been removed after the initial bootstrap validation because it added noise without providing new runtime information.

## Future addons

Build, Pickup and Lock must not start Core or own catalog registration.

Their normal relationship is:

```text
addon loads after Core
-> require "LMION/API"
-> consume registered opening data
```

If a mechanic needs a finalized post-registration lookup structure, Core's `OnGameBoot` checkpoint is the appropriate place to prepare it.
