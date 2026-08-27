# LMION animation candidates

Last updated: 2026-08-27

This note records visual candidates selected in Project Zomboid's in-game **Animation Viewer** for LMION Pickup/Place presentation, and their current implementation state.

See also:

- `Research/Moveables/TimedActionAnimations.md`
- timedAction docs: https://pz-wiki-modding.github.io/PZ-API-Docs/scripts/timedaction.html
- AnimNode docs: https://pz-wiki-modding.github.io/PZ-API-Docs/xml/animnode.html

## Implemented animation mapping

LMION now exposes two module-owned PerformingActions through small AnimNodes that reuse vanilla clips without copying animation assets:

| LMION action | Vanilla clip | Intended use | State |
| --- | --- | --- | --- |
| `LMION_ScrewdriverHinge` | `Bob_IdleMakingLow` | screwdriver Pickup + Place | implemented, runtime validation pending |
| `LMION_CrowbarPickupLow` | `Bob_IdleLeverOpenLow` | crowbar Pickup for gates/garages | implemented, runtime validation pending |

Files:

```text
Contents/mods/LMION_Pickup/42/media/AnimSets/player/actions/LMION_ScrewdriverHinge.xml
Contents/mods/LMION_Pickup/42/media/AnimSets/player/actions/LMION_CrowbarPickupLow.xml
```

`PickupAnimation.lua` selects these PerformingActions while continuing to provide the real configured hand tool and existing LMION sound handling.

Because these are new AnimSet files, validate after a **full game restart**, not Lua hot reload alone.

## Crowbar / gate and garage Pickup

### `IdleLeverOpenLow`

**Selected and implemented.**

Observed in Animation Viewer as a low, ground-level levering motion. This fits LMION especially well for:

- garage-door Pickup;
- small gates / wicket gates;
- large gates;
- other openings removed with a crowbar near their lower anchoring points.

It is visually preferred over the previous `RemoveBarricade + CrowbarMid` presentation.

Production mapping:

```text
PerformingAction: LMION_CrowbarPickupLow
clip:             Bob_IdleLeverOpenLow
```

The real crowbar remains the primary-hand model. LMION intentionally does **not** force two-handed equip for this action; the user confirmed the chosen clip looks correct with the crowbar kept one-handed.

### `Bob_Crowbar_DoorLeft`

Earlier candidate. The motion reads as pulling/prying a door or panel and is more opening-specific than `RemoveBarricade`, but `IdleLeverOpenLow` was preferred for LMION's intended crowbar work.

## Screwdriver / normal door Pickup and Place

### `IdleMakingLow`

**Selected and implemented.**

The low hand-working posture fits unscrewing/rescrewing hinges while the door remains the object being worked on. In Animation Viewer it reads more naturally for LMION than `Disassemble`.

Production mapping:

```text
PerformingAction: LMION_ScrewdriverHinge
clip:             Bob_IdleMakingLow
speed scale:      0.80
```

Intended uses:

- normal wooden door Pickup;
- normal wooden door Place;
- normal metal door Pickup;
- normal metal door Place;
- paired-door equivalents.

The real screwdriver remains the primary-hand model. The action does not introduce a second-hand prop.

## Rejected / weak candidates

### `DismantleElectrical` / `disassembleElectrical`

Rejected for LMION hinge work. B42 timed-action data explicitly supplies both a screwdriver and an electronics/receiver prop, so the action visually carries electronics semantics rather than clean one-tool hinge work.

### `Disassemble`

Not rejected as a valid engine action, but no longer preferred for LMION screwdriver Pickup/Place. The visual language suggests dismantling an object held/manipulated in front of the character, which is less suitable for door hinges than `IdleMakingLow`.

## Current presentation policy

- screwdriver Pickup/Place -> `LMION_ScrewdriverHinge` -> `Bob_IdleMakingLow`;
- crowbar Pickup -> `LMION_CrowbarPickupLow` -> `Bob_IdleLeverOpenLow`;
- hammer Place -> vanilla `Build`;
- blowtorch Scrap -> vanilla `BlowTorch` / `BlowTorchFloor` selection once the real blowtorch is equipped before vanilla action-start evaluation.

Avoid per-door animation customization unless a concrete visual/mechanical failure is reproduced. The intent is one animation family per tool/action contract.

## Validation rule

For every animation change:

1. confirm the PerformingAction resolves after a full restart;
2. ensure the intended real tool is visible in hand;
3. check standing orientation and target height;
4. check the animation loops for the full timed-action duration;
5. check sound start/loop/stop behavior;
6. confirm no unwanted secondary-hand prop appears;
7. only then mark the mapping runtime validated.
