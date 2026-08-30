# Opening definitions and extension registry

Status: A/B large-gate topology refactor under runtime validation, 2026-08-28.

## Why this exists

LMION feature modules are intended to depend on `LMION_Core`, not on each other. Core therefore owns the shared description of openings, while feature modules consume that description and may contribute feature-specific extensions without requiring one another.

The important distinction is:

- **Core describes what the opening is.**
- **Feature modules describe what they can do with it.**

This avoids a Build decision silently becoming a Pickup rule, or a future Locks module depending directly on a future Windows module.

## Registry contract

`LMION.Openings` is owned by Core and exposes a deliberately small API:

- `registerDefinition(id, definition)` — register a Core base definition;
- `registerExtension(targetId, extensionId, extension)` — contribute feature-specific values without replacing the base definition;
- `resolveId(id)` — resolve a base id or active alias to the Core family id;
- `getBaseDefinition(id)` — read the unmodified Core definition;
- `getEffectiveDefinition(id)` — read base + ordered extension values;
- `getExtensions(id)` — inspect extensions contributing to the effective result.

Definitions and extension values are plain Lua tables. Readers receive copies and must treat Core registry state as read-only.

Extensions are deterministic: ascending numeric priority, then extension id.

## Large gates: permanent Core topology

Large gates are no longer modeled as `complete` unless Build contributes a split.

Core now defines the physical/gameplay structure permanently as:

```text
large gate
├── leaf A = two DoubleDoor members
└── leaf B = two DoubleDoor members
```

The stable leaf identity is **A/B**, not Left/Right. Screen-side left/right changes between N and W orientation, while A/B remains tied to the same logical DoubleDoor members.

Core mapping:

```text
leaf A
  N = indices 1,2
  W = indices 4,3

leaf B
  N = indices 3,4
  W = indices 2,1
```

All six supported large-gate families therefore use:

```text
kind = largeGate
topology = twoLeaves
leaves.A
leaves.B
```

Pickup consumes these Core indices instead of maintaining a second copy of the topology.

## Vanilla construction vs Build

The permanent A/B topology does **not** mean Core replaces vanilla full-gate construction.

Without `LMION_Build`:

```text
vanilla construction action
        ↓
complete four-member gate
        ↓
Core interprets members as A + B
```

The vanilla full GameEntity remains intact. Core does not narrow the vanilla SpriteConfig simply because the A/B topology exists.

With `LMION_Build` enabled, Build exposes independent construction of A and B. For the three vanilla `DoubleDoor`, `DoubleWireGate` and `DoubleFenceGate` families, Build temporarily narrows the vanilla GameEntity SpriteConfig to leaf A and provides a separate B GameEntity. This is an engine adaptation required for Build's construction feature; it is **not** the source of the A/B topology.

The three other large-gate families use explicit Core GameEntities suffixed `A` and `B`, with Build adding CraftRecipe/UiConfig components to them.

## Pickup

Pickup always transports one logical leaf, regardless of whether Build is enabled:

```text
one leaf = two physical IsoDoor segments = two parcels = one placement action
```

Pickup does not ask whether Build is installed. It reads Core topology and maps the selected physical segment to leaf A or B.

This naturally supports a gate where one leaf has been destroyed: the surviving valid two-member leaf remains independently transportable.

## A/B naming rule

For large gates only:

- code concepts use `leaf`, `leafA`, `leafB`;
- technical ids use `...GateA` / `...GateB` where a separate id is required;
- in-game names use the compact suffix `A` / `B` (for example `Grand portail en fer forgé A`);
- transport items use `... A (1/2)`, `... A (2/2)`, etc.

Paired 1x1 double doors keep **Left/Right** because left/right is meaningful for their frame-side placement contract. Do not apply the large-gate A/B rename to those doors.

## Dependency rule

Correct:

```text
                 Core opening definitions
                         ▲
          ┌──────────────┼──────────────┐
          │              │              │
        Build          Pickup          Debug
```

Build may register feature-specific capabilities in Core, but Pickup and Debug must consume Core state rather than directly inspecting `LMION.Build`.

Avoid:

```text
Pickup -> LMION.Build
Debug  -> LMION.Build
```

The same rule is intended for future systems such as Locks or Windows: shared identity/capability vocabulary belongs to Core; feature modules discover it through Core.

## Development-save policy

This A/B refactor intentionally renames persistent development ids previously using `Left/Right` for large gates and their Pickup parcels.

**Old development saves are not supported by this refactor. Use a new world for runtime validation.**

This is acceptable before public release. Once LMION is published, persistent ids must be treated as compatibility contracts and require migration/deprecation handling instead of destructive renames.

## Runtime validation required before merge

Use a new world and validate at minimum:

1. **Core only** — vanilla full-gate construction still creates a complete working A+B gate with vanilla-equivalent health behavior.
2. **Core + Build** — A and B can be constructed independently; assembling both resumes vanilla synchronized opening/closing.
3. **Core + Pickup** — either A or B can be picked up/replaced independently from a full gate; two parcels are produced; N/W rotation and durability survive.
4. **Core + Build + Pickup** — the same leaf transport works on Build-created A/B gates.
5. **Destroyed leaf** — if one leaf is absent/destroyed, the surviving valid leaf can still be transported without inventing the missing one.

Debug Inspector should report `topology = twoLeaves` and `leaf = A` or `B` on recognized large-gate members.
