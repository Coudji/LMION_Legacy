# LMION load lifecycle and event timing

Status: **current-code verified + runtime validated where noted + Git-history recovered**

A recurring source of bugs in Project Zomboid modding is not *what* code does but *when* it does it. LMION currently uses several different lifecycle moments because they solve different classes of problem.

This note records the validated reasons so future refactors do not collapse everything into one convenient event and reintroduce already-solved startup/hot-reload bugs.

## Summary table

| Moment | LMION use | Why |
| --- | --- | --- |
| Lua file load | install/refresh Lua-side hooks and apply mutations that are safe immediately | supports ordinary startup and especially hot reload when engine data is already loaded |
| `OnGameBoot` | rewrite selected vanilla `GameEntityScript` / `SpriteConfig` topology | needs parsed scripted entities and must happen as boot-time configuration rather than after gameplay objects use the old topology |
| `OnLoadedTileDefinitions` | reapply global `IsoSprite` mutations such as engine-facing profile properties and runtime large-gate SpriteGrids | tile-definition loading/reinitialization can replace or reset sprite state established earlier |
| `LoadGridsquare` | adopt existing world doors into LMION logical durability | world squares stream in over time; the objects do not all exist at mod boot |
| `OnObjectAdded` | adopt newly added `IsoDoor` objects as they enter the world | catches doors created after a square has already loaded |
| construction hook (`ISBuildIsoEntity.setInfo`) | capture build context and normalize the just-built `IsoThumpable` into the final `IsoDoor` | construction-specific data such as skill-derived max health is available here and can be transferred immediately |

These are current LMION choices for B42.20.3. They are not a universal Project Zomboid event-order specification.

## Lua load: immediate installation is still useful

Some LMION modules call their install/apply function immediately when the Lua file executes.

Examples include:

```text
Doors.applyEngineProfiles()
installAllRuntimeSpriteGrids("lua-load")
```

This looks redundant when the same operation also has a later engine event hook, but it serves an important development case: **Lua hot reload**.

When the world is already running, `OnGameBoot` or `OnLoadedTileDefinitions` will not necessarily fire again just because a Lua source file was reloaded. Applying the current implementation immediately lets a reload update already-existing engine/script state when that is safe.

The later lifecycle hook remains necessary for a cold start.

## `OnGameBoot`: scripted-entity topology changes

Build's vanilla large-gate split is a script-definition problem, not a world-object problem.

LMION must first have access to parsed `GameEntityScript` and `SpriteConfigScript` objects, then it deliberately rewrites the vanilla SpriteConfig ownership before ordinary gameplay relies on the old full-gate topology.

The validated hook is:

```text
Events.OnGameBoot
```

The operation performs exact before/after tile-set validation and a targeted `SpriteConfigScript:PreReload()`; see `SpriteConfigLifecycle.md` for the full rationale.

Do not move this logic to `LoadGridsquare` or an object-added event. At that point the issue is already upstream: the scripted entity/sprite ownership model itself is wrong for LMION construction.

## `OnLoadedTileDefinitions`: global sprite state must be applied after tiles exist

LMION has two important systems that mutate global `IsoSprite` instances:

1. engine-facing door profile properties (`Material`, sounds, etc.);
2. runtime `IsoSpriteGrid` objects for the Chain-Link large-gate Moveables bridge.

Both are installed immediately at Lua load **and** hooked to:

```text
Events.OnLoadedTileDefinitions
```

### Why the second pass exists

The large-gate investigation produced direct runtime evidence: a SpriteGrid installed during early Lua loading logged as successfully attached, but Moveables still behaved as if the sprites were single-tile after normal startup. Reinstalling the same grids from `OnLoadedTileDefinitions` made the grouping persist and work reliably.

The practical conclusion is that normal tile-definition loading/reinitialization can rebuild/reset relevant global sprite state after an early Lua mutation.

Therefore the validated pattern is:

```text
Lua load                   -> useful for hot reload/already-loaded sessions
OnLoadedTileDefinitions    -> authoritative cold-start reapplication
```

This is why deleting the apparently duplicate call would be a regression.

The same principle is used for engine profile application: the values ultimately live on global sprite properties, so LMION reapplies them after tile definitions have loaded.

## `LoadGridsquare`: migration of existing world instances

A saved world can contain thousands of doors, but only loaded grid squares have live world objects available to the current cell.

LMION's durability migration therefore hooks:

```text
Events.LoadGridsquare
```

and calls `Doors.adoptWorldDoorsOnSquare(square)`.

This is intentionally lazy/streaming:

- a pristine matching door gets its LMION logical max when its square loads;
- a damaged door keeps its exact current health;
- modData prevents repeat adoption on later loads.

Running a one-shot map scan at boot would be both unnecessary and unable to cover unloaded cells reliably.

## `OnObjectAdded`: doors created after square load

`LoadGridsquare` only covers objects already present as the square enters the loaded world.

A new `IsoDoor` can be added afterward by construction, placement or another system. Current Core also hooks:

```text
Events.OnObjectAdded.Add(Doors.adoptWorldDoor)
```

This gives the adoption rule an instance-level path for newly appearing objects instead of waiting for the whole square to unload/reload.

The function is idempotent for already-adopted doors because it returns early when `lmionDoorMaxHealth` is already present.

## Construction hook: why build health context is captured around `setInfo`

LMION construction uses vanilla Build machinery, which creates an `IsoThumpable` representation before LMION normalizes supported door objects into `IsoDoor`.

The final construction max may depend on:

```text
profile durability base
+ skillBaseHealth * relevant craft skill level
```

The relevant `craftRecipe` and `character` are readily available on the active `ISBuildIsoEntity` instance. `LMION_Build` therefore wraps `ISBuildIsoEntity.setInfo` and creates a temporary `LMION.Doors.BuildContext` while vanilla runs.

After vanilla construction, Build finds the matching newly built `IsoThumpable` and calls `Doors.onCreateDoor(...)` with the calculated effective max, then clears the temporary context even if the wrapped call fails.

This timing matters because once only the final `IsoDoor` remains, the exact construction context that produced its skill-derived health is no longer something Core can infer reliably from the world object alone.

The context is temporary process state, not persistence. The resulting max is stored in `lmionDoorMaxHealth`.

## Why `media/scripts` is different from Lua hot reload

`media/scripts` definitions are parsed by Project Zomboid's script system during startup. LMION's Lua reloader does not reparse arbitrary GameEntity/item/craft source definitions as if the game had restarted.

Therefore changes to `media/scripts` require a **full game/server restart** for reliable testing.

Likewise, a full restart is the safe choice after:

- adding a brand-new Lua file that an already-running loader has never required;
- changing Lua load order or module metadata;
- changing `mod.info` / dependencies;
- changing monkey-patch installation structure where an old closure remains referenced by active objects;
- any test where global `IsoSprite` state from an earlier experimental version may still be attached.

## Active objects and stale closures

Reloading a Lua file changes global functions/tables, but an already-created cursor/timed action/UI object can retain references or state captured before the reload.

This was especially relevant during Moveables cursor work. A code change could appear ineffective until the player exited and re-entered Moveables mode, or until a full restart cleared the old object/closure.

Development rule:

```text
Lua-only edit
  -> reload
  -> recreate the active mode/action/object
  -> if behavior still looks stale, cold restart before rejecting the code change
```

This avoids diagnosing cached runtime state as a logic bug.

## Single-player / multiplayer reload scope

LMION_Debug historically added a global reload path and a server endpoint because reloading only the local client Lua is insufficient for code that also executes server-side in multiplayer.

The existence of separate client/server reload tooling is deliberate. A future cleanup should not collapse it into a client-only button unless multiplayer development support is explicitly dropped.

Detailed reconstruction of the reload implementation is still an archaeology backlog item; this note records only the high-level lifecycle reason currently supported by Git history.

## Addon contract

Addon authors should not assume all LMION public data is final from the first moment their Lua file loads.

In particular:

- final split vanilla large-gate SpriteConfig ownership is a boot-time result;
- global door sprite properties and Chain-Link runtime SpriteGrids should be considered final only after `OnLoadedTileDefinitions` has run;
- world-door logical max may be added lazily when the object/square loads;
- `OnObjectAdded` can mutate a new matching door's modData after it enters the world;
- code wrapping the same vanilla methods/events should preserve previous handlers and avoid stacking duplicate monkey patches during reload.

If LMION later exposes explicit addon-ready events such as `OnLMIONSpriteProfilesReady`, those should replace event-order guessing. Until then, addons that depend on these systems should document their timing assumptions.

## Revalidation triggers

Recheck this document when:

- Project Zomboid changes startup/event order;
- LMION replaces monkey patches with official engine hooks;
- an explicit LMION addon lifecycle/API is introduced;
- tile definitions no longer reset early `IsoSprite` mutations;
- script hot reload becomes officially supported for the affected GameEntity definitions.
