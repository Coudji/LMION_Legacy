# LMION — Design notes (short foundation copy)

## Fixed architecture

- One Workshop item.
- Several internal Mod IDs.
- `LMION_Core` orchestrates shared systems and optional-module interactions.
- `LMION_Pickup` is a single user-facing pickup module for all passable opening systems.
- Internal complexity is handled through Pickup strategies, not through separate user-facing pickup mods.

## Pickup rule

> If it opens and the player can pass through it, Pickup owns it.

Known families to investigate:

- simple doors;
- double-door leaves (left/right);
- small doors / one-tile gates;
- sliding doors;
- large gate leaves (pivot + end);
- garage doors with contiguous-segment propagation.

## First MVP

Pick up and replace one vanilla simple door correctly.

Before implementing it, build an inspector so the mod can report the real runtime properties of every tested opening family.
