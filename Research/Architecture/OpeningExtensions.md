# Opening extension registry

Status: transitional architecture introduced 2026-08-28.

## Why this exists

LMION sub-mods are intended to depend on `LMION_Core`, not on each other. A gameplay module may nevertheless change how an opening is represented for its own feature, and other modules need a way to observe that effective representation without requiring or naming the module that introduced it.

The first concrete case is large gates:

- Core's base representation is a complete four-member large gate;
- Build needs independent left/right construction leaves;
- Pickup should eventually use the effective representation: complete gate when Build is absent, split leaves when Build contributes the split;
- Debug should report the same effective state rather than duplicating detection logic.

## Contract

`LMION.Openings` is owned by Core and currently exposes a deliberately small API:

- `registerDefinition(id, definition)` — register a Core base definition;
- `registerExtension(targetId, extensionId, extension)` — contribute an extension without replacing the base definition;
- `resolveId(id)` — resolve a base id or known alias to the Core base id;
- `getBaseDefinition(id)` — read the unmodified Core definition;
- `getEffectiveDefinition(id)` — read base + ordered extension values;
- `getExtensions(id)` — inspect the ordered extensions contributing to the result.

Definitions and extension values are plain Lua tables. Readers receive copies, so consumers should treat the registry as read-only and must not mutate Core state directly.

Extensions have:

- an `id` unique for the target definition;
- a `source` for diagnostics;
- an optional numeric `priority`;
- optional aliases;
- a `values` table merged into the effective definition.

Extensions are resolved by ascending priority and then extension id for deterministic behavior.

## Stable identity vs active topology

Core must recognize persistent identities independently from whichever gameplay extension is active.

This matters for existing saves: a world object may still carry a split-leaf entity id such as `LargeWroughtIronGateRight` after `LMION_Build` is disabled. That id still belongs to the `LargeWroughtIronGate` family even though split-leaf gameplay is no longer active.

Therefore Core base definitions own the known left/right aliases. Build does **not** own recognition of those ids; Build only contributes the active topology change.

Example without Build:

```text
observed id        = LargeWroughtIronGateRight
base id            = LargeWroughtIronGate
base topology      = complete
effective topology = complete
extensions         = <none>
```

Example with Build active:

```text
observed id        = LargeWroughtIronGateRight
base id            = LargeWroughtIronGate
base topology      = complete
effective topology = splitLeaves
extension source   = LMION_Build
```

## Current large-gate model

Core registers six base large-gate families with:

```text
kind = largeGate
topology = complete
```

Core also owns all currently known left/right entity ids as aliases of those families.

Build registers `LMION_Build.largeGateSplit` for each family. Its effective values are:

```text
topology = splitLeaves
leaves.left = <left entity id>
leaves.right = <right entity id>
```

## Important transitional constraint

This first step does **not** change gameplay behavior.

Build still installs its existing runtime-derived split `Doors.Profiles` and SpriteConfig ownership changes. Pickup still uses its existing leaf-based implementation. The registry currently describes that state in parallel so it can be validated before consumers migrate to it.

Do not remove the existing Build split implementation until Build/Pickup migration has been runtime-validated.

## Intended dependency rule

A module may contribute information to Core, but other modules must consume Core's effective state rather than detecting the contributing module directly.

Correct:

```text
Build -> Core registry <- Pickup
                      <- Debug
```

Avoid:

```text
Pickup -> LMION.Build
Debug  -> LMION.Build
```

A future module such as access control should query shared capabilities/definitions from Core. If window support is later registered in Core with a compatible capability, the access-control module should be able to discover it without a hard dependency on the module that introduced windows.

## Current validation target

With Debug enabled, Inspector should expose an `LMION Opening` section for recognized large gates showing:

- observed id;
- Core base id;
- kind/family;
- base topology;
- effective topology;
- left/right leaf ids when split;
- contributing extensions.

Expected state for this transitional step:

- without Build: `baseTopology=complete`, `effectiveTopology=complete`, no extension;
- with Build: `baseTopology=complete`, `effectiveTopology=splitLeaves`, source `LMION_Build`.

Pickup behavior is intentionally unchanged until this state has been verified.
