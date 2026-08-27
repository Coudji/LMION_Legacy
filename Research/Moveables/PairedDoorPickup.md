# Paired-door Pickup

Status: **implemented on the generic framed 1x1 Pickup path; runtime validation pending**.

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

## Implementation

The ten current paired entities are registered in `LMION_Pickup`'s normal `DoorProfiles` table. No paired-specific Moveables hooks, neighbor resolution, multi-item transport, SpriteGrid or synchronization code is used.

Dedicated `Base.LMION_<Entity>` Moveable items exist for each Left/Right leaf so inventory identity remains unambiguous.

Because these item definitions live under `media/scripts`, a full game/server restart is required after this implementation before runtime validation.

## Runtime validation target

A representative metal and wooden pair should confirm:

- Left and Right can each be picked independently;
- the untouched neighbor remains in world;
- inventory names distinguish the leaf;
- N/W rotation follows the entity's normal one-square faces;
- placement requires a compatible frame;
- current health and `lmionDoorMaxHealth` survive pickup/replacement.
