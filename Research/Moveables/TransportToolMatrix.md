# LMION Pickup / Place / Scrap tool matrix

Last updated: 2026-08-27

This note records the intended gameplay/presentation contract for LMION opening transport. It is a deliberate LMION rule, not a claim that vanilla Moveables applies these tools uniformly to all furniture.

## Standard wooden doors

Exception: `LogDoor` intentionally requires no Pickup or Place tool.

All other supported standard wooden doors:

- Pickup: screwdriver
- Place: screwdriver
- Pickup/Place animation: `CharacterActionAnims.Disassemble`
- Pickup/Place sound: vanilla Moveables `Screwdriver` tool sound (`Dismantle`) when audible
- Scrap: vanilla wood dismantling rules (hammer/saw behavior owned by vanilla/material definitions)

Rationale: transport removes/reinstalls the complete door leaf by unscrewing/rescrewing its hinges; Scrap destroys it into materials and is a separate system.

## Standard metal doors

Includes metal paired-door leaves.

- Pickup: screwdriver
- Place: screwdriver
- Transport perk: MetalWelding through LMION `LMIONMetalScrewdriver`
- Pickup/Place animation: `CharacterActionAnims.Disassemble`
- Pickup/Place sound: configured `Dismantle`
- Scrap: vanilla metal scrap path using BlowTorch
- Welding protection: vanilla `Tag.WeldingMask`

B42 script verification: both `Base.WeldingMask` and `Base.Glasses_OldWeldingGoggles` carry the `weldingmask` tag, so either satisfies vanilla metal Scrap protection.

## Paired doors

Paired doors are independent 1x1 leaves and inherit their material-equivalent standard-door contract:

- wooden paired leaf -> standard wooden door rules
- metal paired leaf -> standard metal door rules

Their structural DoubleDoor1/DoubleDoor2 frame-side placement restriction remains separate from tool choice.

## Small gates / gate-like 1x1 openings

Wood:

- Pickup: Crowbar
- Place: Hammer
- Scrap: vanilla wood path

Metal:

- Pickup: LMIONMetalCrowbar
- Place: LMIONMetalHammer
- Scrap: vanilla metal BlowTorch + welding protection path

Transport presentation:

- Crowbar Pickup: vanilla `RemoveBarricade` animation with `CrowbarMid`, real crowbar hand model, `BeginRemoveBarricadePlankCrowbar` sound
- Hammer Place: vanilla `Build` animation, real hammer hand model, configured `Hammering` sound

Sliding glass gate-like openings currently follow the same Pickup Crowbar / Place Hammer transport contract.

## Large gates

Same tool/presentation rules as small gates, applied per two-segment leaf:

- wooden leaf: Crowbar Pickup / Hammer Place / vanilla wood Scrap
- metal leaf: LMIONMetalCrowbar Pickup / LMIONMetalHammer Place / vanilla metal Scrap

Large-gate parcel topology is unchanged: one leaf = two physical segments = two parcels = one placement action.

## Garage doors

- Pickup: LMIONMetalCrowbar
- Place: LMIONMetalHammer
- Scrap: vanilla metal BlowTorch + welding protection
- Pickup animation/sound: Crowbar `RemoveBarricade` / `CrowbarMid` + crowbar removal sound
- Place animation/sound: `Build` + `Hammering`

Garage topology is unchanged: three physical segments = three parcels = one placement action.

## Implementation notes

`ISMoveableCursor:walkToAndEquip()` normally queues tool equipment before `ISMoveablesAction`, but specialized multi-part placement was runtime-observed leaving the previous Pickup tool visible during the Place action and equipping the hammer only after completion. LMION client presentation therefore resolves the configured Pickup/Place tool again at `ISMoveablesAction:start()`, makes it the real primary-hand item immediately, and applies the matching animation/hand model.

Scrap remains vanilla-owned. `ISMoveablesAction:start()` already selects BlowTorch/Build/Disassemble animation based on the equipped Scrap tool, and vanilla metal scrap definitions require `Base.BlowTorch` plus `Tag.WeldingMask` and use the `BlowTorch` sound.

## Validation status

As of this note, screwdriver Pickup animation on a normal door is runtime validated. The full matrix above (especially screwdriver Place, crowbar Pickup, hammer Place, correct live hand state, and sounds across small gates/large gates/garages) still requires runtime validation after a full restart.
