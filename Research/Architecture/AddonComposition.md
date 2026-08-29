# LMION addon composition contract

Last reviewed: 2026-08-29

## Why this contract exists

LMION addon independence is stronger than an absence of direct `require()` calls.

A feature module can be **behaviorally dependent** on another module without ever importing it. Example: if Build changes the world representation of a large gate and Pickup only understands that changed representation, then Pickup effectively depends on Build even if no Pickup file references `LMION.Build`.

The architecture must therefore be checked in terms of **world state and semantics**, not only source dependencies.

The governing rule is:

> **Core defines the stable meaning of an opening. Each addon must be correct when it is the only gameplay addon present with Core. Other addons may add capabilities, but may not be required preparation steps.**

## Dependency versus composition

### Source dependency

A direct code/module dependency such as:

```text
Pickup -> require Build
```

is forbidden.

### Behavioral/preparation dependency

Also forbidden:

```text
Build changes a Core/world object into form X
Pickup only understands form X
therefore Pickup silently requires Build to have run first
```

This is forbidden even if the source graph still says only:

```text
Build  -> Core
Pickup -> Core
```

### Valid composition

The correct model is:

```text
                  stable Core semantics
                         ▲
          ┌──────────────┼──────────────┐
          │              │              │
        Build          Pickup          Debug
          │              │              │
 construction        transport        tooling
 capability          capability       capability
```

Build and Pickup may implement very different engine adapters, but both must interpret the same Core concept correctly when the other addon is absent.

## Required addon subsets

With Core mandatory and Build/Pickup/Debug optional, the supported composition space is:

```text
Core
Core + Build
Core + Pickup
Core + Debug
Core + Build + Pickup
Core + Build + Debug
Core + Pickup + Debug
Core + Build + Pickup + Debug
```

Every shared gameplay architecture change must be reviewed against these subsets. It is not enough to test only the full development stack.

Debug is development-only, so its presence must never change gameplay semantics. It may observe a different set of optional addon-owned entities when those addons are present.

## Composition invariants

For every gameplay feature:

1. **Core-only meaning is complete.** Core must be able to describe the opening without Build or Pickup being loaded.
2. **Addon X has an absence path.** `Core + X` must not assume another addon has already rewritten profiles, sprites, topology, state or persistent data.
3. **Shared semantics do not move with capability.** Enabling Build may add construction choices; enabling Pickup may add transport choices. The meaning of the opening itself stays Core-owned.
4. **Engine adaptations are not semantic truth.** A Build-specific SpriteConfig rewrite or a Pickup-specific runtime SpriteGrid is an implementation adapter, not the definition other addons should inspect.
5. **Addon outputs rejoin the Core contract.** Build-created and Pickup-reinstalled world doors end in Core's canonical `IsoDoor` representation and shared state model.
6. **Do not infer another addon's presence from world shape.** A full vanilla portal, a Build-created A/B portal and a partially destroyed portal must all be interpreted through Core topology rather than through assumptions about who created them.
7. **Optional-addon artifacts stay addon-owned.** Pickup parcel items and Build recipe/UI state may disappear with their owning addon; they must not become required Core state.
8. **Persistent cross-addon artifacts require an explicit decision.** If disabling an addon after it created a persistent world entity could make that entity undefined, that is a migration/compatibility contract and must be documented or removed.

## Current composition audit

### 1x1 doors and gates

Core owns semantic door recognition, state and canonical representation.

```text
Core + Build
-> Build may receive a temporary IsoThumpable from B42 construction
-> Core finalizes it
-> persistent output IsoDoor

Core + Pickup
-> source may be world IsoDoor or vanilla/legacy IsoThumpable(isDoor)
-> Pickup captures state through Core
-> Core finalizes reinstallation
-> persistent output IsoDoor
```

Neither path needs the other addon.

With both enabled, Pickup consumes the Core-normalized world object produced by Build rather than Build-specific recipe state.

### Paired 1x1 doors

Left/Right is a Core/placement semantic tied to matching DoubleDoor1/2 frame sides. Build construction and Pickup placement use the same physical meaning independently.

This is distinct from large-gate A/B topology.

### Large gates

This is the reference case for behavioral independence.

Core permanently defines every supported large gate as:

```text
A = two DoubleDoor members
B = two DoubleDoor members

N: A={1,2}, B={3,4}
W: A={4,3}, B={2,1}
```

#### Without Build

The three vanilla `DoubleDoor` / `DoubleWireGate` / `DoubleFenceGate` GameEntities remain complete four-member construction definitions.

```text
vanilla full-gate construction
-> complete four-member portal
-> Core still interprets it as logical A + B
```

Pickup does **not** require Build to split that GameEntity. Its large-gate path maps physical sprites to a logical leaf and gets the authoritative DoubleDoor index sets from `LMION.Openings`.

Pickup also installs its own two-member runtime SpriteGrid bridge directly on the relevant sprites for Moveables transport. That SpriteGrid is Pickup infrastructure; it is not Core topology and Build does not need it.

Therefore:

```text
Core + Pickup, Build absent
-> a vanilla complete gate is still pickable one A/B leaf at a time
```

The separate Build-only `Double*B` GameEntity is not required by Pickup placement; Pickup places the selected two physical members through its Moveables path and Core finalization.

#### With Build

Build adds the construction capability:

```text
A recipe/action
B recipe/action
```

For the three vanilla `Double*` families only, Build narrows the vanilla SpriteConfig to A while Build is active and supplies a B construction GameEntity. For the other families, Core already provides explicit A/B GameEntities and Build adds construction components.

This is an engine adapter owned by Build. It does not create the A/B semantic used by Pickup.

When Build + Pickup are both present, Pickup still resolves leaf identity from Core topology/raw physical segments rather than by asking Build which recipe/entity produced the gate.

#### Important API rule

`LMION.Doors.Profiles` is an engine/profile registry whose concrete ids can change when Build installs its per-leaf construction adapter. It must **not** be treated by future addons as the stable large-gate topology API.

Stable family/leaf semantics come from:

```text
LMION.Openings.resolveId(...)
LMION.Openings.getBaseDefinition(...)
LMION.Openings.getEffectiveDefinition(...)
```

This distinction is required to keep future addons independent from Build presence.

### Garage doors

Core owns:

```text
START = 1
MIDDLE = 2
END = 3
valid chain = START + MIDDLE* + END
LMION width policy
```

Build and Pickup consume that independently.

```text
Core + Build
-> width selected in construction UI
-> Build cursor maps source pattern to START/MIDDLE*/END
-> Core garage OnCreate/finalization keeps native IsoDoor semantics

Core + Pickup
-> inspect actual native chain through Doors.getGarageChain()
-> one parcel per physical member
-> explicit START/MIDDLE*/END reinstallation
-> no Build recipe/cursor state involved
```

With both enabled, the only shared contract is Core topology/width/representation. Pickup does not reuse Build geometry and Build does not reuse Pickup parcel placement.

### Debug

Debug depends only on Core and may be combined with any subset.

Its reload helper discovers the LMION Lua files that are actually loaded, so `Core + Debug` does not require Build or Pickup files to exist in the active Lua environment.

The Test Zone intentionally marks the three vanilla large-gate B construction entities as optional: they exist when Build is present and are skipped rather than treated as a Debug failure when Build is absent.

Inspector opening semantics are read through `LMION.Openings`, not `LMION.Build` or `LMION.Pickup`.

## Current risk hotspots found by the audit

No current direct behavioral dependency requiring Build for Pickup or Pickup for Build was found in the inspected 1x1, large-gate or garage paths. However the audit identified structural areas that can create future composition bugs if changed casually.

### Garage-family identity is duplicated

The seven built-in garage family ids currently appear in multiple addon-owned tables:

- Core door profiles;
- Build's garage-id/glazed classification;
- Pickup's garage visual/parcel specs;
- Debug Test Zone manifest.

The current lists agree, so this is not a reproduced runtime defect. It is a **drift risk**: adding or renaming a garage in one addon can leave another addon silently unaware.

Shared family identity should eventually have a small explicit Core registry/query. Build-specific material balance and Pickup-specific parcel/sprite data should remain in their owning addons.

### Build large-gate adapter duplicates some Core family metadata

`LMION.Openings` is authoritative for family and A/B topology, but `Build/LargeGateProfiles.lua` still carries a Build-local family table to install construction profiles.

The current table agrees with Core and Pickup already reads the Core DoubleDoor indices. This is not a current functional dependency, but future changes should prefer deriving shared ids/entities from Core definitions and keeping only genuinely Build-specific adaptation data locally.

### Build changes the concrete Core profile registry

While Build is enabled it adds/removes concrete entries in `Doors.Profiles` to match the per-leaf engine SpriteConfig ownership needed for construction.

That is currently compatible with Pickup because Pickup does not use that table as its topology source. Future addons must preserve that discipline. If stable cross-addon capabilities need to be advertised, use a Core semantic registry/extension rather than inspecting the current `Doors.Profiles` shape.

### Addon removal after persistent creation is a separate compatibility question

The simultaneous composition audit answers “does `Core + X` work when Y is absent from this boot?”. It does not yet prove every **addon removal from an existing save** case.

In particular, the three vanilla large-gate B construction GameEntities are Build-owned engine definitions while Build is enabled. Whether a world containing such a Build-created B leaf is fully safe to load after removing Build has not been established here.

Likewise, Pickup parcel inventory items are naturally Pickup-owned and are not expected to remain meaningful if Pickup itself is removed.

Do not silently assume addon-uninstall compatibility. Decide and test it explicitly before public release if LMION intends to support disabling individual addons mid-save.

## Required review checklist for future changes

Whenever a change touches shared representation, topology, profiles, engine properties or persistent state, answer these questions before considering the architecture complete:

1. What is the Core-only meaning/state before any optional addon runs?
2. What happens with only `Core + this addon`?
3. Does this addon accept vanilla/world objects that were **not** prepared by another LMION addon?
4. If another addon is enabled, what extra capability appears without changing the Core meaning?
5. If that other addon is absent, is there a real fallback path rather than a nil/error/unsupported shape?
6. Is any shared family/id/topology duplicated locally and able to drift?
7. Is the addon reading another addon's engine adaptation instead of a stable Core semantic API?
8. Does the addon create persistent world state that another composition must later understand?
9. Are Debug/testing tools themselves safe when the gameplay addons they inspect are absent?
10. Which subset(s) still require runtime validation after the static composition audit?

For a new gameplay addon `X`, minimum review is:

```text
Core
Core + X
Core + every existing addon individually
Core + X + every existing addon individually
Core + X + all existing gameplay addons
```

Do not treat a successful full-stack test as proof that `Core + X` is independent.

## Runtime confidence still required

Static inspection establishes that the current code has explicit absence paths. Runtime should still validate the most important subsets on a clean boot:

```text
Core only
Core + Build
Core + Pickup
Core + Debug
Core + Build + Pickup
Core + Build + Debug
Core + Pickup + Debug
Core + Build + Pickup + Debug
```

The highest-value behavioral checks are:

- Core-only vanilla full large-gate construction remains a complete working gate while Core reports A/B semantics;
- Core + Pickup can pick/reinstall either leaf from a vanilla complete gate with Build never enabled;
- Core + Build creates/repeats variable garages and A/B gates with Pickup never enabled;
- Core + Pickup handles native variable garages with Build never enabled;
- Debug starts/reloads/Test Zone works with Build and Pickup both absent;
- full stack produces the same shared Core semantics, with only the expected additional capabilities.

Runtime validation changes confidence; it does not change the architectural rule above.