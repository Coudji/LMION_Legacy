# Variable-width garage Build implementation

Status: **implemented and runtime-validated in single-player on the current development path.** Multiplayer remains unvalidated.

This note records the current LMION_Build implementation, the exact cost model, important B42 integration constraints, and what has actually been tested. It does not replace the Pickup variable-width notes.

## User contract

Garage width is selected in the Construction recipe panel before world placement:

```text
Longueur / Length :  [ - ]  3  [ + ]
```

Rules:

- garage recipes only;
- default L3;
- minimum L2;
- default LMION safety maximum L12;
- no artificial LMION maximum when `UnlimitedGarageWidth` is enabled;
- selected-width requirements update in the recipe panel;
- selected width survives vanilla recipe/input refreshes;
- selected width is frozen into the world build cursor;
- quick-repeat construction recreates the ghost at the same selected width;
- width is not changed from the world cursor.

## Exact cost model

Skill affects eligibility/progression only. The material model does not use skill-based cost reduction.

Welding protection is one kept item with tag:

```text
base:weldingmask
```

This intentionally accepts the normal Welding Mask and old welding goggles.

Solid garage families:

```text
SmallSheetMetal = 3L
Bars            = L total
Hinge           = 2L
BlowTorch uses  = min(ceil(L/3), 10)
WeldingRods     = min(2*ceil(L/3), 20)
```

Glazed families (`RedWindowGarageDoor`, `RollingWindowGarageDoor`):

```text
SmallSheetMetal = 2L
GlassPanel      = L
Bars            = L total
Hinge           = 2L
BlowTorch uses  = min(ceil(L/3), 10)
WeldingRods     = min(2*ceil(L/3), 20)
```

The bar quota accepts:

```text
Base.MetalBar
Base.IronBar
```

They share one common quantity and may be mixed in any proportion. `Base.SteelBar` is intentionally **not** part of the LMION garage recipe merely because some vanilla forge-era recipes accept it.

Examples, solid:

```text
L2  -> torch1 sheets6  bars2  hinges4  rods2
L3  -> torch1 sheets9  bars3  hinges6  rods2
L5  -> torch2 sheets15 bars5  hinges10 rods4
L12 -> torch4 sheets36 bars12 hinges24 rods8
L30 -> torch10 sheets90 bars30 hinges60 rods20
```

## Why the whole recipe is not a generic variable-ratio recipe

B42's variable-input ratio is a generic quantity mechanism. A single common ratio does not express LMION's mixed formulas cleanly:

- sheets scale linearly at either 3L or 2L;
- glass scales at L only for glazed families;
- hinges scale at 2L;
- torch/rods use stepped formulas with caps.

Therefore LMION keeps an explicit selected-width cost model.

One narrow exception is intentional: the **bar input** uses B42's native variable-input mechanism for manual selection UX and the maximum selectable count. This does not make the complete cost model ratio-driven.

For selected length L:

- vanilla UI may select at most L bars;
- LMION additionally requires the manual selected-bar count to reach L before Build is allowed;
- vanilla may consume already-selected bars through its normal recipe path;
- LMION accounts for that native consumption and consumes only the remaining selected-width amount, preventing double payment.

## Geometry

The canonical garage SpriteConfig remains the native/historical L3 pattern. Variable construction does **not** generate a new SpriteGrid per width.

A per-build-cursor FaceInfo proxy exposes the selected dimensions to `ISBuildIsoEntity` while delegating normal FaceInfo behavior back to the original object.

For selected length L, the source pattern is mapped to:

```text
first member      -> START
interior members  -> MIDDLE
last member       -> END
```

This consumes Core's garage topology semantics without depending on LMION_Pickup.

## Length state and vanilla refreshes

B42 routinely replaces/refills `CraftRecipeData` during operations such as recipe refresh, manual input changes, and completion/repeat.

Storing LMION width only in `CraftRecipeData.modData` caused observed resets to L3.

`BuildLogic` itself is a Java object and cannot safely receive arbitrary Lua fields (`attempted index of non-table`). The current solution is a Lua side table keyed by the `BuildLogic` object, mirrored into current `CraftRecipeData` whenever available.

This state is used by:

- the length selector;
- requirement rendering;
- variable-bar ratio/cap;
- cursor creation;
- quick-repeat reconstruction.

## B42 variable-bar selection details

Declaring an unbounded variable input caused vanilla to auto-select every available bar before LMION restored the selected width. The current path:

1. sets the native target variable ratio for the current garage length;
2. trims any vanilla auto-selected bars above L;
3. prevents selecting more than L;
4. separately enforces `selected bars >= L` because B42's native satisfaction check still uses the static minimum of the input.

The last rule is implemented as LMION Build UI validation rather than pretending the engine's variable minimum changes dynamically.

## Resource sources

Selected-width affordability uses the vanilla Build resource sources available to this path:

- player inventory;
- current BuildLogic containers;
- `ISBuildIsoEntity.GetAllGroundItemsForPlayer()`.

The ground helper scans the vanilla 3×3 area centered on the player (±1 X/Y). LMION does not enlarge that radius when the character walks toward the build target.

## Consumption and metadata

The original implementation used a static L2 recipe as the native base and consumed the selected-width delta separately. The current bar-variable integration additionally accounts for the number/types of bars actually consumed by vanilla before consuming any remainder.

For mixed bars, build metadata records the actual consumed `Base.MetalBar` / `Base.IronBar` quantities rather than rewriting the whole quota as one type.

Torch and welding rods keep their intended non-recorded/drainable behavior.

## Lua phase / hook installation

`ISBuildIsoEntity` is a **server-tree** vanilla Lua file.

Important verified consequence:

- shared and initial client Lua must not top-level `require "BuildingObjects/ISBuildIsoEntity"`;
- `shared/LMION/Build/GarageBuildCursor.lua` must remain top-level inert and only define its installer;
- `server/LMION/GarageBuildCursorHook.lua` requires the vanilla class and installs the hook in the later server phase.

See `Research/Engine/B42LuaLoadOrder.md` for bytecode/runtime evidence.

## Runtime validation status

Validated in single-player during the 2026-08-29 pass:

- L12 physical garage Build in Build Cheat;
- L3 and L5 Build without cheat;
- resource insufficiency blocks construction;
- resource loss after selection also blocks construction;
- manual alternative selection no longer resets width;
- quick-repeat ghost preserves width;
- welding mask / old welding goggles appear as alternatives;
- MetalBar/IronBar alternatives appear through the vanilla UI;
- mixed bar types are consumed successfully;
- variable bar selection cannot exceed L;
- Build remains unavailable until L bars are manually selected;
- 1x1 LMION door construction smoke test passed;
- large portal construction smoke test passed;
- Pickup paths still appeared functional;
- garage L5 Pickup/reinstallation remained functional.

Not yet claimed:

- exhaustive L2..L12 normal-mode construction across every family and both facings;
- exhaustive glazed-family consumption verification;
- multiplayer/server-client runtime validation;
- every possible addon enable/disable combination at runtime.

## Rejected / historical paths

Do not rediscover these as if they were current architecture:

- one generic variable ratio for the complete resource model — insufficient for stepped/capped mixed formulas;
- keeping width only in `CraftRecipeData.modData` — lost on vanilla refresh;
- writing arbitrary state directly onto Java `BuildLogic` — invalid Kahlua object mutation;
- top-level shared/client `require` of `ISBuildIsoEntity` — wrong B42 phase/path;
- variable input left effectively unlimited during recipe auto-fill — selected every available bar;
- relying on vanilla variable-input satisfaction alone — its minimum remained tied to the static base input.

## Current architectural conclusion

Variable garage Build is a **Build-owned feature using Core-owned topology**. Pickup has a separate variable transport/reinstallation implementation. They share semantics through Core and have no dependency on one another.
