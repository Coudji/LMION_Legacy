# Variable-width garage design

Status: **Pickup variable-width transport and inventory reinstallation are implemented and runtime-validated. Inventory right-click `Place` uses LMION's dedicated variable-width cursor. The persistent Moveables sidebar `Place` intentionally remains vanilla and therefore places the historical L3 garage. Build variable-width construction has not started yet.**

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

The current option can lift this LMION limit for players who explicitly want larger garages. The semantic contract is:

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

**No MP/admin authority rule is decided yet.** Do not bake a client-only or admin-only assumption into the current single-player/general architecture.

Core exposes one width-policy query so future sandbox/server authority can replace the current settings source without rewriting Build or Pickup.

## Build UX — future work

Garage width should be chosen in the construction window before entering placement mode.

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

The frozen Build width must belong to the specific construction action/placement plan, not to shared SpriteConfig state.

## Build recipe scaling — future work

The current L3 recipes were authored for three physical members. Variable Build width must convert this to explicit fixed + variable costs rather than blindly multiplying the complete recipe.

Confirmed design rule:

- `Base.BlowTorch` usage is a **fixed recipe cost** and does not increase indefinitely with garage width, because torch charge capacity is finite and an ever-growing single-tool charge requirement would eventually become impossible/awkward;
- other materials may scale with width according to a later family/balance formula;
- requirements shown in the construction window must exactly match the frozen selected width that will be built.

The exact per-family/per-material scaling values are still implementation/balance work and should be documented once chosen.

## Build topology — future work

A build plan for width `L` is:

```text
role 1: start
roles 2..L-1: middle (zero or more)
role L: end
```

The existing three role sprites per family remain useful. They are role sprites, not three unique one-off physical members.

Do not globally mutate one SpriteConfig's dimensions based on a player's current selection. Width belongs to the individual construction action/instance so future multiplayer and simultaneous builds remain possible.

The previously researched `FaceInfo` proxy technique remains the preferred Build direction because it can expose per-instance variable geometry without transferring Core's representation ownership into Build. See `GarageDoorVariableWidthPlacementResearch.md`.

## Pickup transport model

Garage transport is a collection of physical compatible parts rather than a fixed three-piece bundle.

For one family:

```text
1 x Start
0..N x Middle
1 x End
```

Pickup traverses the actual native chain from Start through repeated Middle members to End and creates one parcel per physical member.

Each parcel preserves the exact durability state of the physical segment it came from.

There is no hidden garage/bundle identity. Same-family physical parts are intentionally interchangeable.

### Parcel identity and presentation

The existing script item IDs remain `_Part1`, `_Part2`, `_Part3` for compatibility and save stability, but they are **role prototypes**, not a fixed denominator of three physical members:

```text
_Part1 -> Start
_Part2 -> Middle panel, repeatable
_Part3 -> End
```

User-facing translations should therefore describe Start / Middle Panel / End (or localized equivalents), never imply a fixed `(1/3)`, `(2/3)`, `(3/3)` garage bundle.

## Pickup reinstallation width

Reinstallation width depends on compatible parts currently available to the character from the supported inventory/nearby-floor range.

Examples:

```text
Start + 3 Middle + End -> maximum L5
Start + 2 Middle + End -> maximum L4
Start + 0 Middle + End -> maximum L2
```

If a player picks up L5, discards one Middle, then reinstalls, LMION can build L4 from the remaining compatible pieces.

The dedicated placement cursor starts at the maximum currently available permitted length and lets the player decrease/increase the desired width.

## Pickup width controls

Current configurable bindings default to:

```text
Decrease garage width -> Numpad -
Increase garage width -> Numpad +
Rotate Building       -> N/W toggle
```

During dedicated Pickup/reinstallation placement:

- left mouse remains dedicated to placement;
- changing width recalculates the explicit plan and ghost validity;
- width may not exceed the number of compatible parts available;
- while the LMION safety limit is active, width may not exceed L12;
- with the safety limit lifted, there is no LMION numeric maximum;
- orientation is intentionally N/W only.

## Dedicated Pickup placement architecture

The failed fixed-SpriteGrid experiment established that variable reinstallation must not be implemented by making vanilla `ISMoveableCursor` pretend a fixed L3 multisprite has arbitrary geometry.

Current architecture deliberately separates pickup discovery from reinstallation:

```text
vanilla ISMoveableCursor
-> still used for world pickup/discovery
-> synthetic historical L3 SpriteGrid may remain for Moveables identity

inventory right-click Place on garage parcel
-> ISMoveableContextMenu.openMovableCursor(item, playerObj)
-> exact InventoryItem is available before vanilla SpriteGrid normalization
-> LMION inventory wrapper recognizes family/role
-> GarageDoor.openPlacementCursor()
-> LMIONGaragePlacementCursor : ISBuildingObject
-> explicit variable placement plan
-> LMIONGaragePlacementAction
```

`LMIONGaragePlacementCursor` owns only garage-specific placement state:

```text
familyId
selectedLength
facing N/W
character/player
```

Its geometry comes from `GarageDoor.buildPlacementPlan()`:

```text
START + MIDDLE * (L-2) + END
```

Every physical planned member is validated and placed as a single segment (`isMultiSprite=false`) so the historical L3 SpriteGrid cannot reassert fixed geometry during variable placement.

The dedicated timed action revalidates the same plan and only consumes parcels after all physical members are successfully created. An unexpected partial creation is cleaned up and leaves parcels untouched.

### Lua loading rule

The client-side file registers key bindings and wraps the inventory UI entry point only when its vanilla entry point and LMION GarageDoor table are available.

`GarageDoorCursor.lua` lives in gameplay/server BuildingObjects context and later attaches `GarageDoor.openPlacementCursor`.

Do **not** force-load that server-tree cursor from the early client file. The UI wrapper is allowed to exist before `openPlacementCursor` is attached; it resolves/checks the method at click time.

See `GarageDoorPlacementEntryPath.md` for the exact loading and handoff contract.

## Persistent Moveables sidebar `Place`

The left-side Moveables `Place` icon is intentionally **not** another route into the dedicated variable cursor.

It enters generic vanilla Moveables Place mode without an explicit item parameter. The selected catalogue entry is resolved later through `getInventoryObjectList()` / `objectIndex`, after multisprite entries have been normalized through their SpriteGrid anchor.

For LMION garage parcels this means:

```text
sidebar Place
-> vanilla ISMoveableCursor catalogue
-> historical synthetic L3 SpriteGrid
-> fixed L3 garage placement
```

This behavior has been accepted as the final UX contract:

```text
inventory right-click Place -> variable LMION garage
sidebar Place               -> vanilla L3 garage
```

Do not reintroduce the reverted sidebar handoff, global `isValid()` hooks, rotate/TAB interception or a hybrid Moveables state machine merely to make the two controls behave identically.

## Family compatibility

Default LMION policy: parts are interchangeable **within the same garage family**, not across families.

Examples:

```text
White Start + White Middle(s) + White End -> valid
White Start + Green Middle + White End -> reject by LMION
```

Vanilla may be permissive enough to operate visually mixed role chains, but native acceptance alone is not a reason for LMION to expose mixed-family garages as normal gameplay. Cross-family mixing can remain an addon/compatibility extension if desired later.

## Architecture ownership

Keep submods independent:

```text
Core
-> semantic garage roles/topology/chain helpers
-> width-policy primitive suitable for future sandbox/server authority

Build
-> future construction-window width selection
-> future frozen per-build width
-> future variable recipe requirements/build plan

Pickup
-> actual-chain traversal
-> parcels for Start/Middle/End physical pieces
-> inventory-derived reinstallation width
-> dedicated variable placement cursor/action
-> configurable placement width keybinds
```

Build and Pickup must not depend on each other. Both consume Core semantics.

## Current implementation/runtime status

Implemented:

- Core semantic garage roles and actual-chain traversal;
- artificial L12 policy with option to lift it;
- Pickup actual-chain dismantling;
- one parcel per physical chain member, including repeatable Middle parcels;
- variable reinstallation planning from compatible available parts;
- configurable width keys;
- dedicated `ISBuildingObject` garage placement cursor;
- dedicated placement timed action independent from fixed SpriteGrid geometry;
- exact-item inventory context-menu handoff;
- intentional vanilla sidebar L3 fallback/behavior.

Runtime-validated current behavior:

- variable garages can be picked up as their actual physical chain;
- inventory right-click `Place` reaches the dedicated variable cursor;
- width changes and N/W rotation work on that path;
- variable physical placement works;
- exact physical-segment durability survives Pickup/replacement;
- resulting garages resume native synchronized behavior;
- left Moveables sidebar `Place` remains vanilla and places L3, which is intentional.

Build variable-width implementation has intentionally not started yet.

## Remaining implementation order

1. **Pickup variable transport/reinstallation — implemented and validated.** Preserve the inventory/sidebar split unless a new requirement appears.
2. Build: determine the clean B42 construction-window extension point and per-instance width storage.
3. Build: implement dynamic requirements with fixed BlowTorch cost and chosen material scaling.
4. Build: generate variable-width construction placement safely without globally mutating shared SpriteConfigs.
5. Runtime validate Build L2/L3/L5/L12 in N/W and verify material requirements match the frozen width.
6. Only after single-player Build behavior is stable, revisit multiplayer/server-admin authority for oversized garages.
