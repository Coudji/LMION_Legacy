# LMION — Design notes

## Fixed architecture

- One Workshop item.
- Several internal Mod IDs.
- `LMION_Core` orchestrates only shared systems and persistence conventions that are proven necessary by gameplay modules.
- `LMION_Build` owns construction/crafting concerns.
- `LMION_Pickup` is the single user-facing pickup module for passable opening systems.
- `LMION_Debug` owns development-only tooling such as the Inspector, Test Zone and Lua reload helpers.
- Internal complexity is handled through Pickup strategies, not through separate user-facing pickup mods for each opening family.

`LMION_Debug` depends on Core, but Core, Build and Pickup do not depend on Debug.

Core deliberately avoids speculative abstractions. The old generic event bus and parallel `LMION.Doors` model registry were removed because there was no concrete consumer and the model duplicated information already available from Project Zomboid runtime objects and `GameEntityScript` / `SpriteConfig` data. If future modules such as Locksmith need to exchange additional door state with Pickup, define a focused contract for that real requirement rather than restoring a generic bus pre-emptively.

## Pickup rule

> If it opens and the player can pass through it, Pickup owns it.

Synchronization between world objects does not automatically make them one inventory item. Pickup identity follows the physical/gameplay unit that makes sense to transport and reinstall.

## General pickup behavior

Pickup is a non-destructive alternative to vanilla dismantling.

For normal hinged doors, current intended eligibility is:

- the door must be unlocked;
- barricades must be removed first;
- curtains must be removed first;
- required tools and skill levels will be defined later.

The door does **not** need to be open before removal. An earlier design tied removal more closely to hinge/frame mechanics, but that approach was abandoned.

The primary physical condition observed so far is `health / maxHealth`. `modData.itemCondition` is not reliable as the authoritative damage state: damaged doors/gates can keep `itemCondition = 10/10`, and some linked pieces have no such modData at all.

## Runtime findings

### Generic `IsoDoor`

Multiple visually and behaviorally different opening families use `zombie.iso.objects.IsoDoor`. Runtime class alone is therefore not enough to classify an opening.

For tested doors, internal `closedSprite` and `openSprite` remain available regardless of the current open/closed state. The debug inspector retrieves them through controlled reflection. This avoids guessing sprite-number relationships or toggling the door just to serialize it.

For `IsoDoor` orientation, prefer door-specific orientation data such as `north` / `doorN` / `doorW` over generic `dir`; garage tests showed `dir = N` while the actual door orientation was west-facing.

### Simple / autonomous 1×1 doors

Observed classic doors generally expose:

- `doubleDoorIndex = -1`;
- `garageDoorIndex = -1`;
- one closed sprite and one open sprite;
- north/west wall orientation;
- individual health/maxHealth.

This is not yet a sufficient classifier by itself because tested sliding doors can share the same broad runtime shape.

### Visually glazed doors

Tested doors that look glazed do not appear to contain an independently breakable window component. Shooting or striking the visible glass did not produce a separate glass state in the tested samples.

Do not serialize a door `glassState` unless a real vanilla runtime state is later found.

### Sliding doors

Tested sliding doors are also `IsoDoor` and can report:

- `doubleDoorIndex = -1`;
- `garageDoorIndex = -1`;
- closed/open sprite pairs;
- 1×1 footprint behavior.

Do not assume a dedicated sliding-door class exists for classification.

### Double doors and large gates

Large gate pieces tested as `IsoDoor` expose a `DoubleDoor` property and non-negative `doubleDoorIndex` values.

Observed large-gate structure strongly suggests fixed logical member indexes across a grouped opening. A partially destroyed/removed group can still resolve non-contiguous members, so synchronization is not simply nearest-neighbor propagation.

A large gate leaf is physically multi-tile. Damage is stored per component, but destroying one component through normal gameplay can destroy the corresponding leaf while leaving the other leaf of the double gate intact.

Working hypothesis, still to be validated across more vanilla families:

```text
Double opening
├── leaf A: logical members 1 + 2
└── leaf B: logical members 3 + 4
```

Do not encode this assumption as universal until more complete double doors/gates are inspected.

### Garage doors

Garage doors are also composed of `IsoDoor` objects, but use a distinct linkage system:

- `doubleDoorIndex = -1`;
- `garageDoorIndex >= 0`;
- `garage.first` identifies the start of the contiguous chain;
- `garage.prev` / `garage.next` link neighboring compatible pieces.

Tests with a four-tile garage door showed the likely role pattern:

```text
[START][MIDDLE][MIDDLE][END]
   1       2       2      3
```

This matches earlier gameplay tests where arbitrarily long contiguous garage doors synchronize, while a gap breaks propagation.

Although vanilla stores separate `IsoDoor` components, LMION should treat a functioning garage door as one transportable opening rather than exposing individual garage segments as inventory items.

## Debug tooling

The LMION Inspector belongs to the dedicated `LMION_Debug` module because it is a general developer tool, not gameplay runtime.

The current architecture separates:

- generic/specialized object inspection;
- safe utility/reflection helpers;
- square scanning and selection state;
- UI panels.

The Inspector is implemented as a dedicated window. Object selection drives the report content directly, and the world picker supports persistent selected/active-square highlights and multi-square selection.

The old dynamic showroom/research scanner has been retired. Runtime checks now use a deterministic Test Zone whose manifest explicitly defines every placed opening and its coordinates. The Test Zone is a fixture, not a discovery mechanism.

## Build prototype

Build currently covers the researched opening set through `media/scripts` construction definitions. Those scripts are the source of truth for current Build entities, recipes and progression; the old Lua catalog and draft recipe generator have been removed.

The recipes and balance are still provisional and can evolve independently from Core's shared engine adapters.

Build presentation currently uses standalone PNG construction icons under the Build module's `media/textures` directory. Multi-tile objects should be represented by icons showing the complete opening rather than a single anchor tile.

## Future module ideas

### Locksmith

Possible scope includes:

- removable/installable cylinders or barrels;
- Key ID belonging conceptually to the cylinder;
- rekeying;
- duplicating keys from blanks with appropriate tools/machines;
- padlocks and hasps;
- hinge wear/breakage and replacement;
- forced entry based on material, strength, lock type, damage, and injury risk.

### Access Control

Possible scope includes:

- powered keypad/code access;
- mechanical key fallback;
- fail-secure/fail-safe behavior depending on hardware;
- battery-backed keypads;
- RFID/badges;
- exit buttons;
- alarms after repeated failed codes;
- codes/credentials found in notes, maps, zombies, or containers.

## First gameplay MVP

Pick up and replace one vanilla autonomous 1×1 door correctly, preserving the runtime data that actually matters and rejecting opening families that require specialized handling.
