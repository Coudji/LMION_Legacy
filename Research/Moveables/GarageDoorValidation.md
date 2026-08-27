# Garage-door Pickup validation

Status: **runtime-validated for the complete closed-state Pickup path across all seven current LMION garage families; open-state Pickup runtime-validated on the reference garage path in both N and W**.

Validated closed-state families:

- `IndustrialGarageDoor`
- `GreenGarageDoor`
- `WhiteGarageDoor`
- `GreyGarageDoor`
- `RollingGarageDoor`
- `RedWindowGarageDoor`
- `RollingWindowGarageDoor`

The closed implementation has been exercised successfully in game across the supported workflow. Pickup and replacement work in both N and W orientations, rotation/replacement behavior is correct, restored garages resume their normal vanilla synchronized opening/closing behavior, the three-part transport identity remains coherent, garages can be picked up again after replacement, and door health is preserved through transport.

## Open-state runtime contract

Runtime reports on B42.20.3 for `IndustrialGarageDoor` confirm the same vanilla topology in both orientations:

```text
N closed: 35 / 36 / 37
N open:   43 / 44 / 45

W closed: 32 / 33 / 34
W open:   40 / 41 / 42
```

Therefore each open garage sprite is the matching closed sprite `+8`.

Opening a garage:

- keeps the same three `IsoDoor` objects on the same squares;
- preserves normalized `GarageDoor` member identity 1/2/3;
- preserves `first / prev / next` linkage;
- preserves current health and `lmionMaxHealth`;
- does not recreate or relocate members.

Open sprites are not vanilla Moveables, so LMION marks the derived open aliases `IsMoveAble` at runtime and assigns them the same family/part/tool/skill identity as their closed counterparts.

Pickup accepts only a complete three-member chain whose members all share the same family, orientation and open/closed state. Open members are removed directly from the world; LMION serializes every resulting parcel with the corresponding **closed canonical sprite** instead of closing the garage first.

The transport invariant is therefore:

```text
closed garage -> Pickup -> 3 closed canonical parcels -> placement closed
open garage   -> Pickup -> 3 closed canonical parcels -> placement closed
```

Placement remains the existing closed-state path, including N/W rotation and durability restoration.

`IndustrialGarageDoor` remains the reference family used to establish the engine-index mapping and the three-segment transport contract documented in `GarageDoorTopology.md`; the other six families use the same existing vanilla garage sprite layout.

The runtime `GarageDoor = 1/2/3` validation remains intentionally in place as a fail-closed guard against future tile-definition or engine changes.

## Runtime validation result

The open-state path is now confirmed in game on the reference garage workflow:

- N open Pickup works;
- W open Pickup works;
- targeting the open garage resolves the complete three-member structure;
- all three floor squares are highlighted in Pickup mode;
- exactly three parcels are produced;
- parcel identities remain Part1 / Part2 / Part3 and use closed canonical world sprites;
- N/W rotation remains correct;
- replacement is always closed;
- current health and `lmionMaxHealth` survive open -> Pickup -> replace;
- the restored garage resumes normal synchronized vanilla opening/closing behavior.

Because all seven LMION garage families share the same vanilla `GarageDoor` 1/2/3 topology and the same closed-to-open `+8` sprite layout used by the generalized implementation, no separate open-state code path exists per family.
