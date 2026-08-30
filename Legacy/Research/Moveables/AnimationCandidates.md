# LMION animation candidates

Last updated: 2026-08-27

This note records visual candidates selected in Project Zomboid's in-game **Animation Viewer** for LMION Pickup/Place presentation, and their current implementation/validation state.

See also:

- `Research/Moveables/TimedActionAnimations.md`
- timedAction docs: https://pz-wiki-modding.github.io/PZ-API-Docs/scripts/timedaction.html
- AnimNode docs: https://pz-wiki-modding.github.io/PZ-API-Docs/xml/animnode.html

## Implemented animation mapping

LMION exposes two module-owned PerformingActions through small AnimNodes that reuse vanilla clips without copying animation assets:

| LMION action | Vanilla clip | Intended use | State |
| --- | --- | --- | --- |
| `LMION_ScrewdriverHinge` | `Bob_IdleMakingLow` | screwdriver Pickup + Place | runtime validated |
| `LMION_CrowbarPickupLow` | `Bob_IdleLeverOpenLow` | crowbar Pickup for gates/garages | runtime validated |

Files:

```text
Contents/mods/LMION_Pickup/42/media/AnimSets/player/actions/LMION_ScrewdriverHinge.xml
Contents/mods/LMION_Pickup/42/media/AnimSets/player/actions/LMION_CrowbarPickupLow.xml
```

`PickupAnimation.lua` selects these PerformingActions while continuing to provide the real configured hand tool and the existing LMION/vanilla sound handling.

Because these are AnimSet files, a **full game restart** is required after XML changes. Ordinary Lua-only presentation changes may be tested through Lua reload unless an old monkey-patch closure is still resident.

## Crowbar / gate and garage Pickup

### `IdleLeverOpenLow`

**Selected, implemented and runtime validated.**

Observed in Animation Viewer and in live Pickup as a low, ground-level levering motion. This fits LMION especially well for:

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

The real crowbar remains the primary-hand model. LMION intentionally does **not** force two-handed equip for this action; runtime/Animation Viewer checks showed the chosen clip is acceptable with the crowbar kept one-handed.

Current crowbar sound remains `BeginRemoveBarricadePlankCrowbar` for both wooden and metal Pickup. Material-specific crowbar audio is deliberately deferred until suitable vanilla events have been auditioned in game. Do not add a speculative metal replacement yet.

### `Bob_Crowbar_DoorLeft`

Earlier candidate. The motion reads as pulling/prying a door or panel and is more opening-specific than `RemoveBarricade`, but `IdleLeverOpenLow` was preferred for LMION's intended crowbar work.

## Screwdriver / normal door Pickup and Place

### `IdleMakingLow`

**Selected, implemented and runtime validated.**

The low hand-working posture fits unscrewing/rescrewing hinges while the door remains the object being worked on. In Animation Viewer and live Pickup/Place it reads more naturally for LMION than `Disassemble`.

Production mapping:

```text
PerformingAction: LMION_ScrewdriverHinge
clip:             Bob_IdleMakingLow
speed scale:      0.80
```

Uses:

- normal wooden door Pickup;
- normal wooden door Place;
- normal metal door Pickup;
- normal metal door Place;
- paired-door equivalents.

The real screwdriver remains the primary-hand model. The action does not introduce a second-hand prop.

## Hammer Place

Hammer placement intentionally stays on vanilla `Build` with the real configured hammer in hand.

A temporary experiment attempted to replace the carpentry `Hammering` sound on `LMIONMetalHammer` placement with repeated `SmithingHammerHit` pulses. Runtime testing still sounded like wood and metal were overlapping, and the experiment required an additional `ISMoveablesAction.update()` monkey-patch. Because the result was not validated and the user deferred this polish, that experiment was removed.

Current production state therefore remains:

```text
wood Hammer Place  -> Build + configured Hammering
metal Hammer Place -> Build + configured Hammering
```

Material-specific metal hammer audio is a future polish task. Candidate events such as `SmithingHammerHit` / `BallPeenHammerHit` should be auditioned before reimplementation.

## Blowtorch Scrap

Vanilla `ISMoveablesAction.start()` can incorrectly fall back to `Disassemble + Screwdriver` even when the active ScrapDefinition requires `Base.BlowTorch`, because its animation selection separately checks whether a blowtorch is already equipped.

LMION fixes presentation only:

1. identify ScrapDefinitions that actually require `Base.BlowTorch`;
2. find/equip the real usable blowtorch before vanilla `start()`;
3. let vanilla start the Scrap normally;
4. re-apply `BlowTorch` / `BlowTorchFloor` and the real hand model afterward.

Runtime validation confirms metal garage/gate Scrap now displays the blowtorch animation and real torch correctly. Eligibility, welding protection, duration, sound lifecycle, consumption and yields remain vanilla-owned.

## Audio QA constraint: Invisible cheat

A misleading sound investigation was traced to Debug/Cheat **Invisible** mode. With Invisible enabled, some character/object sounds can be inaudible, including blowtorch work and door weapon-hit sounds, while other sounds such as hammering may still be audible.

This was reproduced even in an unmodded solo game. Therefore:

> **Always disable Invisible before diagnosing LMION sound behavior.**

Silence observed while Invisible is enabled is not evidence of an LMION sound integration bug.

## Rejected / weak animation candidates

### `DismantleElectrical` / `disassembleElectrical`

Rejected for LMION hinge work. B42 timed-action data explicitly supplies both a screwdriver and an electronics/receiver prop, so the action visually carries electronics semantics rather than clean one-tool hinge work.

### `Disassemble`

Not rejected as a valid engine action, but no longer preferred for LMION screwdriver Pickup/Place. The visual language suggests dismantling an object held/manipulated in front of the character, which is less suitable for door hinges than `IdleMakingLow`.

## Current presentation policy

- screwdriver Pickup/Place -> `LMION_ScrewdriverHinge` -> `Bob_IdleMakingLow`;
- crowbar Pickup -> `LMION_CrowbarPickupLow` -> `Bob_IdleLeverOpenLow`;
- hammer Place -> vanilla `Build`;
- blowtorch Scrap -> vanilla `BlowTorch` / `BlowTorchFloor` presentation forced only when the real ScrapDefinition requires `Base.BlowTorch`;
- no per-door animation customization without a reproduced need;
- no material-specific crowbar/hammer sound override until suitable events are selected and runtime validated.

The intent remains one animation family per tool/action contract.

## Validation rule

For every future animation/sound presentation change:

1. disable Debug/Cheat Invisible;
2. confirm the PerformingAction resolves after a full restart when AnimSet XML changed;
3. ensure the intended real tool is visible in hand;
4. check standing orientation and target height;
5. check the animation loops for the full timed-action duration;
6. check sound start/loop/stop behavior;
7. confirm no unwanted secondary-hand prop appears;
8. only then mark the mapping runtime validated.
