# Let Me In... Or Not — Development & handoff

Last updated: 2026-08-29

This is the **authoritative current-state handoff** for LMION. Read it first, then inspect current `main` and the relevant note under `Research/` before changing an unfamiliar subsystem.

> **Vanilla defines the physical opening mechanics; LMION defines the gameplay rules.**

> **LMION-managed doors have one canonical persistent physical representation: `IsoDoor`.**

`IsoThumpable(isDoor)` remains a valid source/legacy representation that Core can recognize and read, but LMION does not preserve it as a second persistent backend after LMION creates or reinstalls a door.

`newtiledefinitions.tiles` / TileDefinitions are research/reference data. Do not edit them as an LMION runtime solution.

## Repository and addon contract

One Workshop item contains four Build 42 Mod IDs:

```text
Contents/mods/
├── LMION_Core/
├── LMION_Build/
├── LMION_Pickup/
└── LMION_Debug/
```

The dependency graph is intentionally one-way:

```text
LMION_Build   ─┐
LMION_Pickup  ─┼─> LMION_Core
LMION_Debug   ─┘
```

Hard rules:

- `LMION_Core` must not depend on Build, Pickup or Debug.
- `LMION_Build`, `LMION_Pickup` and `LMION_Debug` may depend on Core, but **must not depend on one another**.
- Gameplay modules must never depend on Debug.
- A shared gameplay concept needed by more than one addon belongs in Core; addon-specific UX/actions stay in the owning addon.
- Addons may consume Core semantics independently; they must never use another addon as an implementation shortcut.

The 2026-08-29 source/dependency audit confirmed the current `mod.info` files and inspected Lua entry points still follow this graph.

## Responsibility boundaries

### `LMION_Core`

Core owns shared gameplay semantics and low-level primitives:

- LMION namespace/logging/module registration;
- opening/door profiles and profile-to-GameEntity mapping;
- semantic door identity independent from source Java class;
- canonical `IsoDoor` finalization;
- normalized state capture/restore;
- placement/finalization primitives shared by addons;
- effective max-health abstraction;
- alias-safe engine property mutation;
- large-opening topology, including large-gate A/B semantics;
- garage topology (`START / MIDDLE / END`) and the LMION garage-width policy;
- future shared access/lock and repair primitives.

Core does **not** own construction UX, Pickup UX, recipe balance or Debug tooling.

Recognizing a world door must not silently alter its durability. World/map objects keep vanilla durability unless an explicit future policy says otherwise.

### `LMION_Build`

Build owns construction/crafting:

- recipes and progression requirements;
- construction UI and localization;
- construction-time resource rules;
- Build-specific cursor/action integration;
- construction durability values supplied to Core;
- deciding whether a constructible large portal is built per A/B leaf or as one whole action when applicable.

Build does not decide the persistent Java representation. Temporary engine `IsoThumpable` doors are finalized through Core. Garages convert earlier through `LMION.Doors.onCreateGarage` because native GarageDoor mechanics are `IsoDoor`-specific.

### `LMION_Pickup`

Pickup owns transport/reinstallation:

- eligibility and Pickup/Place tools/skills;
- parcel/item identity;
- source-state capture around transport;
- placement rules and specialized multi-tile actions;
- one-half-at-a-time large-gate transport;
- variable-width garage pickup/reinstallation.

Pickup does not own construction or durability policy. It captures actual source state through Core and restores it onto canonical `IsoDoor` output.

### `LMION_Debug`

Debug owns development-only tooling: Inspector, world selection/highlighting, deterministic Test Zone, Lua reload helpers and temporary diagnostics. Nothing gameplay-critical may require Debug.

## Canonical door representation

Engine/source inputs may be:

```text
IsoDoor
IsoThumpable(isDoor)
```

LMION-managed output is:

```text
LMION-created/finalized/reinstalled door -> IsoDoor
```

Canonicalization occurs only at explicit LMION ownership boundaries. Do not attach it to generic world-load scanning and do not target non-door `IsoThumpable` objects.

Useful Core APIs include:

```text
Doors.isIsoDoor(object)
Doors.isThumpableDoor(object)
Doors.isDoorObject(object)
Doors.isCanonicalDoor(object)
Doors.ensureCanonicalDoor(object, options)
Doors.captureDoorState(object)
Doors.restoreDoorState(object, state)
Doors.getEffectiveMaxHealth(object)
Doors.restoreEffectiveMaxHealth(object, ...)
Doors.finalizePlacedDoor(object, options)
```

Source representation is diagnostic/input information, not gameplay state to restore.

## Large gates

Large portals use **A/B** semantics. Left/Right remains reserved for true paired 1x1 double doors.

Current logical topology is stable across facing:

```text
N: A={1,2}, B={3,4}
W: A={4,3}, B={2,1}
```

Core owns this topology. Build consumes it for construction and Pickup consumes it for transport without depending on each other.

Pickup identity remains:

```text
one A/B leaf = two physical DoubleDoor segments = two parcels = one placement action
```

Validated behaviors include targeting either segment of a leaf, removing only that leaf, N/W rotation, health/effective-max preservation, open-partner reconnection rules, collision refusal, and resumption of vanilla DoubleDoor synchronization once the portal is coherent.

Do not revive rejected approaches without new evidence: closing the whole portal before Pickup, forcing the untouched partner to change state, or allowing a closed/open hybrid and hoping vanilla repairs it later.

## Garage doors

Garage topology is separate from DoubleDoor topology:

```text
START + zero-or-more MIDDLE + END
```

Core defines the semantic roles and width policy. Minimum LMION/native width is L2. Default LMION safety/gameplay maximum is L12; `UnlimitedGarageWidth` removes that artificial maximum. L12 is **not** claimed to be an engine limit.

Supported families:

- Industrial Garage Door;
- Green Garage Door;
- White Garage Door;
- Grey Garage Door;
- Rolling Garage Door;
- Red Window Garage Door;
- Rolling Window Garage Door.

### Pickup/reinstallation

Transport identity:

```text
one physical member = one 20 kg parcel
_Part1 = START
_Part2 = repeatable MIDDLE
_Part3 = END
```

Pickup traverses the actual native chain. Reinstallation builds explicit `START + MIDDLE*(L-2) + END` geometry and preserves per-member health/effective max.

The two `Place` entry points intentionally differ:

```text
inventory right-click Place
-> exact InventoryItem known
-> LMION variable-width cursor/action

left Moveables sidebar Place
-> vanilla Moveables catalogue
-> historical synthetic L3 SpriteGrid
-> fixed L3 placement
```

The sidebar L3 behavior is accepted. Do not reintroduce global `ISMoveableCursor` handoffs merely to unify these paths.

### Variable-width Build — current state

Variable-width garage construction is **implemented and runtime-validated in single-player**.

Current UX/contract:

- selector in the Construction recipe detail panel: `Longueur / Length`;
- default L3, minimum L2, default maximum L12 unless unlimited option is enabled;
- selected width is preserved across ingredient-selection refreshes and quick-repeat cursor creation;
- width is frozen into the world build cursor;
- physical geometry uses the canonical L3 SpriteConfig only as a source pattern, with a per-cursor FaceInfo proxy mapping first=START, interiors=MIDDLE, last=END;
- Build does not depend on Pickup for any of this.

Current resource model is independent of skill-based reductions. Skill remains eligibility/progression only.

Solid garage at length `L`:

```text
welding protection: 1 kept item tagged base:weldingmask
SmallSheetMetal:    3L
Metal/Iron bars:    L total
Hinge:              2L
BlowTorch uses:     min(ceil(L/3), 10)
WeldingRods uses:   min(2*ceil(L/3), 20)
```

Glazed garage at length `L`:

```text
welding protection: 1 kept item tagged base:weldingmask
SmallSheetMetal:    2L
GlassPanel:         L
Metal/Iron bars:    L total
Hinge:              2L
BlowTorch uses:     min(ceil(L/3), 10)
WeldingRods uses:   min(2*ceil(L/3), 20)
```

`base:weldingmask` intentionally accepts the normal Welding Mask and the old welding goggles. Bars intentionally accept `Base.MetalBar` and `Base.IronBar` in one shared quota and may be mixed.

B42's native variable-input UI is used **only for the bar selection UX/cap**; LMION still owns the complete selected-width cost formula. For length L, no more than L bars may be selected and Build remains unavailable until L bars are selected. LMION accounts for what vanilla already consumed and only consumes the remaining selected-width delta, avoiding double payment.

Runtime evidence from the latest pass:

- L12 physical Build works in Build Cheat;
- L3 and L5 work without cheat;
- missing/removed resources correctly block construction;
- changing manual bar alternatives no longer resets selected width;
- quick-repeat ghost keeps the selected width;
- mixed MetalBar/IronBar use works;
- welding-protection alternatives appear through vanilla UI;
- selected-bar maximum and `selected >= L` validation work;
- 1x1 construction, large portals and Pickup received smoke tests without reproduced regressions;
- garage L5 Pickup/reinstallation remains working.

Do **not** claim exhaustive all-family/all-width/all-orientation normal-mode validation or multiplayer validation yet.

## Build 42 Lua/load-order guardrails

The current architecture relies on verified B42 phase behavior. See `Research/Engine/B42LuaLoadOrder.md`.

Important rules:

- files physically present in an active Lua phase tree are auto-discovered/executed; removing an explicit `require` does not make such a file inert;
- initial normal client/SP bootstrap executes shared, then client;
- `ISBuildIsoEntity` is a **server-tree** vanilla Lua class and is not available during initial client Lua;
- reusable shared Build cursor code must be inert at top level and expose an installer;
- the server-phase `GarageBuildCursorHook.lua` loads `ISBuildIsoEntity` and installs the variable garage cursor hook;
- garage tile-derived validation/mutation must wait for `OnLoadedTileDefinitions` on cold start; an immediate reload path is allowed only after a positive readiness probe.

Exact multiplayer client lifecycle for the new Build path is still not runtime-proven. Do not overclaim it.

## Resource-source alignment

Garage Build checks the same broad Build resource sources as vanilla:

- player inventory;
- the BuildLogic/container list used by the Construction panel;
- world items returned by `ISBuildIsoEntity.GetAllGroundItemsForPlayer()`.

The latter scans the vanilla 3×3 area centered on the player (±1 X/Y), not an LMION-specific wider range. Do not invent a larger pickup radius to compensate for the character walking to the build target.

## Engine-facing property aliases

PZ `PropertyContainer` values are alias-backed. Engine-facing writes use:

```text
preserve old -> write requested -> exact readback -> keep or restore
```

The current startup summary may report many `engine profiles ... rejected` sprite writes. `rejected` means an attempted engine-property projection failed exact readback and was restored; it does **not** mean the LMION profile/door was rejected.

`MaterialType`/alias behavior is a serious candidate for a later audit because Debug raw/parsed reporting suggests discrepancies. This is a **documented follow-up**, not part of the current garage chantier.

See `Research/Engine/PropertyAliases.md`.

## Runtime validation status / release caveats

Current validated baseline is primarily single-player. Before treating addon independence and the variable Build path as release-proven in every environment, a useful runtime matrix is:

```text
Core + Build only
Core + Pickup only
Core + Debug only
Core + Build + Pickup
multiplayer/server path for variable garage Build
```

The source/dependency architecture already supports those combinations; this matrix is runtime confidence, not a known architecture defect.

## Development workflow / hard rules

- User-facing delivery goes to `main`. Development branches are allowed; final delivered changes must be fast-forwarded/merged back to `main`.
- Inspect current code + relevant Research before modifying an unfamiliar subsystem.
- Prefer Java/API/vanilla-source/runtime verification over guessing.
- Runtime testing by the user is authoritative for gameplay behavior.
- `media/scripts` changes require a full restart.
- New shared Lua/load-order changes or stale monkey-patch closures may require a full restart.
- Avoid speculative Java/reflection calls in production/Debug; Kahlua Debug Mode may surface exceptions despite `pcall`.
- Do not add speculative abstractions/workarounds without a reproduced need.
- **Do not modify `DOOR_CATALOG.md` / `DOOR_CATALOG_VALUES.md` unless the current task explicitly concerns the catalog.**

## Instructions for future development / AI sessions

1. Read this file and `Research/README.md`, then inspect current `main`.
2. Reconstruct state from code/Git/Research before asking the user to rebrief.
3. Update this handoff and focused Research whenever architecture, validation or an engine conclusion materially changes.
4. Current code + runtime validation outrank stale prose; fix documentation when they disagree.
5. Do not restore persistent source-representation preservation: supported LMION output is canonical `IsoDoor`.
6. Do not revive `garage = IsoThumpable`; native GarageDoor mechanics are incomplete there.
7. Preserve addon independence: Build/Pickup/Debug consume Core, never each other.
8. Preserve the validated garage Pickup entry split: inventory right-click is variable LMION placement; Moveables sidebar stays vanilla fixed L3.
9. Do not redesign large-gate A/B topology without a reproduced issue or explicit new requirement.
10. Sound QA must be done with Debug/Cheat Invisible disabled.

## Documentation map

- `README.md` — public overview.
- `README_DEV.md` — this current-state architecture/handoff.
- `Research/README.md` — research index and evidence vocabulary.
- `Research/Architecture/CodeOrganization.md` — code ownership and module boundaries.
- `Research/Architecture/DoorObjectAbstraction.md` — canonical `IsoDoor` rationale.
- `Research/Engine/B42LuaLoadOrder.md` — verified Lua phase/load-order rules.
- `Research/Engine/GarageThumpableInteraction.md` — why garages require `IsoDoor`.
- `Research/Moveables/GarageDoorTopology.md` — native garage chain semantics.
- `Research/Moveables/GarageDoorPlacementEntryPath.md` — Pickup placement entry-point contract.
- `Research/Moveables/GarageDoorVariableWidthDesign.md` — current cross-addon variable-width design contract.
- `Research/Moveables/GarageDoorVariableBuildPrototype.md` — Build implementation evidence, formulas and validation status.
- `Research/Moveables/LargeGateLeaves.md` / `LargeGateOpenPickup.md` — large-gate transport behavior.

## Next intended work

Do not redesign the now-working garage Build/Pickup paths without a reproduced issue.

Useful later work:

1. multiplayer/runtime addon-combination validation;
2. audit engine-profile alias rejections, especially `MaterialType`;
3. optional presentation/audio polish only when a concrete need is reproduced;
4. dedicated gameplay-balance pass for Pickup/Place duration;
5. future world-door durability sandbox policy;
6. proceed toward Repair and locksmith/access-control addons on the canonical Core model.
