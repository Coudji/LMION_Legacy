# LMION Core load order

Status: verified against the uploaded Project Zomboid B42.20.3 jar on 2026-08-30.

This document records the engine loading facts that the new Core runtime relies on.

## Project Zomboid Lua scopes

The current B42.20.3 `LuaManager` loads Lua directories in this order on a client:

```text
shared
client
```

A dedicated server loads:

```text
shared
client scanned without execution
server
```

The server still scans the client scope for checksum purposes but does not execute those Lua files.

Therefore LMION content registration that must exist on both client and server belongs in `media/lua/shared`.

Do not put canonical opening definitions or Core extensions only in `client` or only in `server` unless they are deliberately side-specific data.

## Active mod order

For each Lua scope, `LuaManager.LoadDirBase(scope)` obtains the active mod IDs from `ZomboidFileSystem.getModIDs()` and processes them in that order.

Inside each individual mod, discovered Lua file paths are sorted with Java's case-insensitive string ordering before execution.

Consequences:

1. mod load order is real and observable;
2. file alphabetical order inside one mod is also real;
3. third-party mods that use LMION Core must declare Core as a dependency so Core is loaded first;
4. LMION extension conflict behavior can naturally follow registration/load order;
5. when two extensions at the same resolution layer write the same field, the extension registered last wins.

LMION deliberately does not add a separate priority score on top of PZ's mod order.

## Core API versus Core startup

`LMION/API.lua` defines and returns the public API only.

It must not bootstrap built-in content by itself. Loading the API is not the same operation as starting Core.

The runtime entry point is:

```text
media/lua/shared/LMION_Core.lua
```

Its job is deliberately small:

```text
require public API
-> bootstrap LMION built-in content through that API
-> log the built-in registration count
-> register the OnGameBoot diagnostic checkpoint
```

Built-in data still lives in pure files under `DefinitionDefaults/` and `Catalog/`. Those files can be executed by PZ's recursive Lua loader, but they only return tables and cause no registration side effect themselves.

## Why explicit bootstrap is safe for third-party content

PZ loads the Lua files of one active mod before moving on to the next active mod in that scope.

Therefore when `LMION_Core` is ordered before a dependent third-party mod:

```text
LMION_Core shared Lua
    -> LMION_Core.lua bootstraps built-ins

ThirdPartyMod shared Lua
    -> require "LMION/API"
    -> registerDefault/registerDefinition/registerExtension
```

A third-party mod does not write into LMION folders and does not need to mirror LMION's internal directory structure.

The recommended integration file belongs in the third-party mod's `media/lua/shared` tree.

## OnGameBoot checkpoint

The uploaded B42.20.3 jar triggers `OnGameBoot` after Lua loading has completed on both client and dedicated server.

LMION therefore uses `OnGameBoot` as a **checkpoint**, not as the normal registration phase.

At that point, normal shared registrations from active dependent mods should already exist.

The current development runtime logs:

```text
[LMION:Core] OnGameBoot registry snapshot: ...
[LMION:Catalog] <definitionId> -> <GameEntity/topology>
```

This is intentionally verbose during reconstruction so a game launch proves that Core actually booted and that the expected definitions resolved.

Later this full dump should move behind Debug/development tooling once runtime registration is proven stable.

## Important rule for future addons

Build, Pickup and Lock must not assume they are responsible for starting Core or registering the opening catalog.

Their dependency is:

```text
addon loads after Core
-> require "LMION/API"
-> consume already registered Core data
```

Content-adding third-party mods similarly register shared content after Core has started.

If a mechanic needs a final post-registration index or validation pass, `OnGameBoot` is an appropriate place to finalize it because all normal Lua mod loading has already occurred.
