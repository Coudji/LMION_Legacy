# LMION animation candidates

Last updated: 2026-08-27

This note records visual candidates selected in Project Zomboid's in-game **Animation Viewer** for LMION Pickup/Place presentation. These are raw animation clips seen in the viewer; they are **not yet assumed to be directly usable as `setActionAnim()` values**. Before production use, map each clip to the relevant AnimNode / PerformingAction and validate it in a real timed action with the intended tool model and sound.

See also:

- `Research/Moveables/TimedActionAnimations.md`
- timedAction docs: https://pz-wiki-modding.github.io/PZ-API-Docs/scripts/timedaction.html
- AnimNode docs: https://pz-wiki-modding.github.io/PZ-API-Docs/xml/animnode.html

## Crowbar / gate and garage Pickup

### `IdleLeverOpenLow`

**Current preferred visual candidate.**

Observed in Animation Viewer as a low, ground-level levering motion. This fits LMION especially well for:

- garage-door Pickup;
- small gates / wicket gates;
- large gates;
- other openings removed with a crowbar near their lower anchoring points.

It is visually preferred over the currently implemented `RemoveBarricade + CrowbarMid` presentation.

### `Bob_Crowbar_DoorLeft`

Earlier candidate. The motion reads as pulling/prying a door or panel and is more opening-specific than `RemoveBarricade`, but `IdleLeverOpenLow` currently looks better for LMION's intended crowbar work.

## Screwdriver / normal door Pickup and Place

### `IdleMakingLow`

**Current preferred visual candidate for screwdriver hinge work.**

The low hand-working posture fits unscrewing/rescrewing hinges while the door remains the object being worked on. In Animation Viewer it reads more naturally for LMION than `Disassemble`.

Candidate uses:

- normal wooden door Pickup;
- normal wooden door Place;
- normal metal door Pickup;
- normal metal door Place;
- paired-door equivalents.

`Disassemble` is visually weaker for LMION hinge work because its motion reads as if the character is dismantling/manipulating an object held in the other hand rather than working on a fixed hinge. It remains the current production animation only until `IdleMakingLow` is mapped to a usable AnimNode / PerformingAction and runtime-tested with the real screwdriver in hand.

## Rejected / weak candidates

### `DismantleElectrical` / `disassembleElectrical`

Rejected for LMION hinge work. B42 timed-action data explicitly supplies both a screwdriver and an electronics/receiver prop, so the action visually carries electronics semantics rather than clean one-tool hinge work.

### `Disassemble`

Not rejected as a valid engine action, but no longer preferred for LMION screwdriver Pickup/Place. The visual language suggests dismantling an object held/manipulated in front of the character, which is less suitable for door hinges than `IdleMakingLow`.

## Validation rule

For every candidate:

1. identify the AnimNode / PerformingAction that drives the raw clip;
2. identify any required animation variables;
3. ensure LMION can keep the real required tool in hand without unwanted secondary props;
4. validate orientation/height against actual doors, gates and garages;
5. validate sound lifecycle separately;
6. only then replace the current production animation.
