# Paired-door Pickup

Status: **generic framed 1x1 Pickup path runtime-validated; corrected Left/Right N/W face mapping runtime-validated; strict paired-frame placement implemented, pending runtime validation**.

## Gameplay contract

LMION paired doors are visual/construction double-door sets, not synchronized transport units.

- each physical Left/Right leaf is an independent 1x1 `IsoDoor`;
- Pickup removes exactly one selected leaf and creates exactly one inventory Moveable;
- the other leaf is neither required nor modified;
- Left and Right remain distinct item/entity identities through transport and rotation;
- replacement uses the same health / `lmionDoorMaxHealth` persistence hooks as ordinary 1x1 doors.

## Frame rule

Vanilla Tile Report runtime evidence on B42.20.3 confirms dedicated structural markers on paired double-door frames:

```text
Left frame  -> DoubleDoor1
Right frame -> DoubleDoor2
```

The same tiles also expose `CutawayHint=DoubleDoorLeft/DoubleDoorRight`, but LMION does not use that as a production fallback. `DoubleDoor1/2` is the strict structural requirement.

Paired placement therefore requires both:

- the existing correct N/W frame orientation;
- the matching structural paired-frame side on the same frame object.

Consequences:

```text
paired Left  -> only a DoubleDoor1 frame
paired Right -> only a DoubleDoor2 frame
ordinary frame -> rejected for paired leaves
wrong paired side -> rejected
```

Ordinary 1x1 framed doors keep the existing generic frame rule unchanged.

Runtime marker evidence is recorded in `Research/Moveables/PairedDoorFrames.md`.

## Left/Right face identity

The initial SpriteConfig split incorrectly assumed that each consecutive block of four sprites represented one permanent leaf across both N and W orientations. Runtime inspection of the Black Two-Pane pair showed that the paired geometry crosses those blocks for W.

Reference mapping:

```text
Left:  N closed/open = fixtures_doors_02_41 / 43
       W closed/open = fixtures_doors_02_44 / 46

Right: N closed/open = fixtures_doors_02_45 / 47
       W closed/open = fixtures_doors_02_40 / 42
```

The same eight-sprite layout is used by all five current paired families, so their W and W_OPEN faces are crossed between Left and Right while N and N_OPEN remain unchanged. This keeps the semantic leaf identity stable when rotating between N and W.

## Open-state transport invariant

All generic LMION 1x1 doors, framed or frameless, use a **closed canonical inventory identity**.

```text
closed world door -> Pickup -> closed Moveable face -> placement closed
open world door   -> Pickup -> closed Moveable face -> placement closed
```

An open SpriteConfig face may be the world sprite selected for Pickup, but it is never meant to survive as the Moveable item's placement sprite. Keeping the open sprite in the item breaks the normal N/W face rotation path and allows a door to be reinstalled already open.

The generic 1x1 registry therefore recovers N/W orientation for any known open sprite through the engine `doorN` / `doorW` flags. Inventory serialization and placement then canonicalize that orientation back to the profile's closed `N` / `W` face. This also lets previously serialized open-sprite items recover their normal closed-face rotation/placement path when they are loaded through the corrected registry.

## Implementation

The ten current paired entities are registered in `LMION_Pickup`'s normal `DoorProfiles` table, with `pairedFrameSide=1` for Left and `pairedFrameSide=2` for Right. The shared placement helper accepts that optional side requirement and checks the corresponding `IsoFlagType.DoubleDoor1/DoubleDoor2` flag on the orientation-matching frame object.

No paired-specific neighbor resolution, multi-item transport, SpriteGrid or synchronization code is used.

Dedicated `Base.LMION_<Entity>` Moveable items exist for each Left/Right leaf so inventory identity remains unambiguous.

## Runtime validation target

Verify at least one paired family in both orientations:

- Left on matching `DoubleDoor1` frame -> allowed;
- Left on `DoubleDoor2` frame -> rejected;
- Right on matching `DoubleDoor2` frame -> allowed;
- Right on `DoubleDoor1` frame -> rejected;
- either paired leaf on a normal frame -> rejected;
- rotate N/W and repeat the side checks;
- pickup while open -> inventory/placement preview uses the closed face;
- replacement is always closed;
- current health and `lmionDoorMaxHealth` survive pickup/replacement.
