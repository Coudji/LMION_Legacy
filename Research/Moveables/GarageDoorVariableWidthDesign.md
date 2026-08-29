# Variable-width garage design

Status: **implementation in progress — variable-width Pickup chain works; placement cursor wiring corrected to the gameplay `GarageDoorCursor.lua` path and awaiting runtime validation.**

This note is the implementation handoff for generalizing LMION garage doors from the former fixed-width L3 model to Project Zomboid's native variable-length garage topology.

## Engine fact already validated

GarageDoor normalized values are topological roles, not fixed member numbers:

```text
1 = start
2 = middle
3 = end
```

Vanilla accepts:

```text
L2  = start + end
L3  = start + middle + end
L4+ = start + middle x N + end
```

B42.20.4 runtime tests confirmed native synchronized opening/closing for L2, vanilla L5, BrushTool L6 and BrushTool L12. No actual engine maximum width is currently known.

See `Research/Moveables/GarageDoorTopology.md` for the bytecode/runtime evidence.

## LMION width policy

LMION must **not pretend that L12 is an engine limit**.

Gameplay policy:

```text
engine-known minimum: L2
LMION default maximum: L12
actual PZ maximum: unknown
```

L12 is an **artificial safety/gameplay limit chosen by LMION**, not a reverse-engineered engine boundary.

A sandbox/mod option must be able to lift this LMION limit for players who explicitly want larger garages. The semantic contract is:

```text
Default mode
-> selectable/reinstallable width: L2..L12

Limit lifted
-> no LMION hard maximum
-> width is constrained only by available compatible parts, placement geometry and whatever limit PZ itself eventually imposes
```

Do not replace the lifted mode with a guessed large numeric cap unless runtime evidence later identifies a real engine safety boundary.

## Multiplayer policy is deliberately deferred

Very large garages can create obvious grief/performance risks in multiplayer. The future MP design may decide that:

- the server/admin owns whether the L12 safety limit can be lifted;
- clients cannot independently bypass the server policy;
- or another server-side cap is appropriate.

**No MP/admin authority rule is decided yet.** Do not bake a client-only or admin-only assumption into the first implementation merely to anticipate future multiplayer work.

Single-player/general architecture should expose one width-policy query that can later be backed by sandbox/server authority without rewriting Build or Pickup.

## Build UX

Garage width is chosen in the construction window before entering placement mode.

Intended UI:

```text
Width:  [ - ]  3  [ + ]
```

Rules:

- default width = L3;
- minimum = L2;
- maximum = L12 while the LMION safety limit is enabled;
- when the limit is lifted, the UI is not constrained by an LMION hard maximum;
- displayed recipe requirements update while width is changed in the construction window;
- once the player confirms/leaves the construction window and enters world placement, the selected width is **frozen**;
- Build placement must not allow keyboard +/- width changes, because that could silently change material requirements after the player last saw them.

The frozen build width becomes part of the specific construction action/placement plan, not a mutable global SpriteConfig setting.

## Build recipe scaling

The current L3 recipes were authored for three physical members. Variable width must convert this to explicit fixed + variable costs rather than blindly multiplying the complete recipe.

Confirmed design rule:

- `Base.BlowTorch` usage is a **fixed recipe cost** and does not increase indefinitely with garage width, because torch charge capacity is finite and an ever-growing single-tool charge requirement would eventually become impossible/awkward;
- other materials may scale with width according to a later family/balance formula;
- requirements shown in the construction window must exactly match the frozen selected width that will be built.

The exact per-family/per-material scaling values are still implementation/balance work and should be documented once chosen.

## Build topology

A build plan for width `L` is:

```text
role 1: start
roles 2..L-1: middle (zero or more)
role L: end
```

The existing three role sprites per family remain useful. They should be modeled as role sprites rather than three unique one-off members.

Do not globally mutate one SpriteConfig's dimensions based on a player's current selection. Width belongs to the individual construction action/instance so future multiplayer and simultaneous builds remain possible.

## Pickup transport model

Garage transport becomes a collection of physical compatible parts rather than a fixed three-piece bundle.

For one family:

```text
1 x Start
0..N x Middle
1 x End
```

Pickup must traverse the actual native chain from start through repeated middle members to end and create one parcel per physical member.

Each parcel preserves the exact durability state of the physical segment it came from.

There is no hidden garage/bundle identity. Previous runtime evidence already showed that same-family garage pieces can be exchanged between different physical garages, which is why parcel durability is displayed in inventory.

### Parcel identity and presentation

The existing script item IDs remain `_Part1`, `_Part2`, `_Part3` for compatibility and save stability, but they are **role prototypes**, not a fixed denominator of three physical members:

```text
_Part1 -> Start
_Part2 -> Middle panel, repeatable
_Part3 -> End
```

User-facing translations must therefore say Start / Middle Panel / End (or localized equivalents), never `(1/3)`, `(2/3)`, `(3/3)`.

## Pickup reinstallation width

Reinstallation width depends on compatible parts the player has available.

Examples:

```text
Start + 3 Middle + End -> maximum L5
Start + 2 Middle + End -> maximum L4
Start + 0 Middle + End -> L2
```

If a player picks up L5, discards one Middle, then reinstalls, LMION can build L4 from the remaining compatible pieces.

The placement cursor should start from an appropriate available width and allow the player to decrease/increase the desired width without using clickable UI controls near the world cursor.

## Pickup width controls

Use keyboard bindings, with intended defaults:

```text
Decrease garage width -> Numpad -
Increase garage width -> Numpad +
```

These must be exposed as **configurable LMION key bindings** in Project Zomboid's key-binding options so players without a numeric keypad can rebind them.

During Pickup/reinstallation placement:

- left mouse remains dedicated to placement;
- no clickable +/- buttons should sit under/near the world cursor;
- changing width recalculates ghost geometry and placement validity;
- width may not exceed the number of compatible parts available;
- while the LMION safety limit is active, width may not exceed L12;
- with the safety limit lifted, there is no LMION numeric maximum.

A non-interactive text indicator in the Moveables information panel shows current and maximum available width.

## B42 Lua-context discovery: cursor hooks belong in gameplay/server Lua

A failed implementation attempt established an important B42 loading rule.

The client-side ModOptions file initially tried:

```lua
require "BuildingObjects/ISMoveableCursor"
```

and then hooked `ISMoveableCursor.renderSpriteGrid` directly. During main-menu/client Lua loading, that require failed and `ISMoveableCursor` was nil, producing a boot-time error:

```text
require("BuildingObjects/ISMoveableCursor") failed
attempted index: renderSpriteGrid of non-table: null
```

Adding client-side timing/retry guards stopped the crash but still did not affect the actual gameplay cursor.

The repository already had the correct proven integration point:

```text
media/lua/server/LMION/Pickup/GarageDoorCursor.lua
```

That file can require `BuildingObjects/ISMoveableCursor` in the same gameplay Lua context used by vanilla BuildingObjects and already successfully owns garage cursor rendering.

Durable rule:

```text
client GarageWidthKeys.lua
-> register persistent/configurable ModOptions key bindings only

gameplay/server GarageDoorCursor.lua
-> hook ISMoveableCursor
-> render variable footprint
-> show width feedback
-> react to width keys during placement
```

Do not move `ISMoveableCursor` hooks back into the early client ModOptions loader.

A temporary validation log is emitted when the gameplay hooks load:

```text
[LMION:Pickup] garage variable-width cursor hooks installed
```

If variable placement appears inactive, check for that line before researching geometry or parcel counting.

## Family compatibility

Default LMION policy: parts are interchangeable **within the same garage family**, not across families.

Examples:

```text
White Start + White Middle(s) + White End -> valid
White Start + Green Middle + White End -> reject by LMION
```

Vanilla may be permissive enough to operate visually mixed role chains, but native acceptance alone is not a reason for LMION to expose Frankenstein garages as normal gameplay. Cross-family mixing can remain an addon/compatibility extension if desired later.

## Architecture ownership

Keep submods independent:

```text
Core
-> semantic garage roles/topology/chain helpers
-> width-policy primitive suitable for future sandbox/server authority

Build
-> construction-window width selection
-> frozen per-build width
-> variable recipe requirements
-> variable build plan

Pickup
-> actual-chain traversal
-> parcels for Start/Middle/End physical pieces
-> inventory-derived reinstallation width
-> configurable placement width keybinds
```

Build and Pickup must not depend on each other. Both consume Core semantics.

## Current implementation/runtime status

Implemented:

- Core variable roles and actual-chain traversal;
- artificial L12 policy with option to lift it;
- Pickup actual-chain dismantling;
- repeatable Middle parcels;
- variable reinstallation planning from compatible available parts;
- configurable width-key definitions;
- gameplay cursor variable-footprint rendering/feedback/key handler wired through `GarageDoorCursor.lua`.

Runtime validated so far:

- variable-width Pickup successfully dismantles a tested garage and creates all physical parcels.

Still awaiting validation after the gameplay-cursor wiring correction:

- L2/L3/L5/L12 variable placement ghost;
- +/- visible resizing;
- current/max width feedback;
- actual placement and consumption of only selected pieces;
- N/W rotation for variable widths.

Build variable-width implementation has intentionally not started yet; Pickup placement should be stable first.

## Implementation order

1. Core: formalize variable garage roles/chain traversal and width-policy constants/query — **implemented**;
2. Pickup: refactor fixed assumptions into Start/Middle/End roles and variable chain capture — **implemented; Pickup runtime works**;
3. Pickup: variable reinstallation plan + configurable width keybinds + L12 safety policy — **implemented, placement runtime validation pending**;
4. Build: determine the clean B42 construction-window extension point and per-instance width storage;
5. Build: implement dynamic requirements with fixed BlowTorch cost and chosen material scaling;
6. Build: generate variable-width construction placement safely without globally mutating shared SpriteConfigs;
7. runtime validate L2, L3, L5 and L12 in N/W, including Pickup shrink/rebuild scenarios;
8. only after single-player behavior is stable, revisit multiplayer/server-admin authority for oversized garages.
