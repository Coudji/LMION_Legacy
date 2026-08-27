# Paired-door Pickup

Status: **generic framed 1x1 Pickup path runtime-validated; corrected Left/Right N/W face mapping pending targeted runtime revalidation**.

## Gameplay contract

LMION paired doors are visual/construction double-door sets, not synchronized transport units.

- each physical Left/Right leaf is an independent 1x1 `IsoDoor`;
- Pickup removes exactly one selected leaf and creates exactly one inventory Moveable;
- the other leaf is neither required nor modified;
- Left and Right remain distinct item/entity identities through transport and rotation;
- replacement uses the same health / `lmionDoorMaxHealth` persistence hooks as ordinary 1x1 doors.

## Frame rule

Core keeps `frame = "paired"` as a semantic classification, but paired profiles require a frame exactly like `frame = "standard"` profiles.

B42 does not currently provide LMION with a useful distinction between an ordinary door frame and a paired/double-door frame. LMION therefore deliberately accepts any vanilla-compatible frame of the correct N/W orientation instead of maintaining a custom sprite catalog for paired frames.

This is an intentional simplification: a player may place one paired leaf in a visually imperfect ordinary frame, but Pickup remains aligned with the engine's normal framed-door rules.

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

## Implementation

The ten current paired entities are registered in `LMION_Pickup`'s normal `DoorProfiles` table. No paired-specific Moveables hooks, neighbor resolution, multi-item transport, SpriteGrid or synchronization code is used.

Dedicated `Base.LMION_<Entity>` Moveable items exist for each Left/Right leaf so inventory identity remains unambiguous.

Because the face definitions live under `media/scripts`, a full game/server restart is required after face-mapping changes before runtime validation.

## Runtime validation target

After the corrected face mapping, verify at least one pair through:

- construct Left and Right in N and confirm visual identity;
- rotate/place each in W and confirm Left remains Left and Right remains Right;
- open/close both orientations and confirm the open face matches the same leaf;
- pickup/replacement still preserves current health and `lmionDoorMaxHealth`.
