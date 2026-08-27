# Vanilla Moveables behavior relevant to LMION

Status: **B42.20.3/B42 current-source behavior researched; LMION policy changes not decided yet**.

This note records vanilla Moveables rules that matter for LMION's remaining Pickup polish work: action duration, parcel count/destination, sounds and animation behavior.

## Action duration

`ISMoveablesAction:getDuration()` delegates Pickup/Place timing to `ISMoveableSpriteProps:getActionTime()`.

Vanilla calculates:

```text
actionTime = toolDef.baseActionTime + (rawWeight * 2)
actionTime = actionTime - actionTime * (perkLevel * 0.05)
```

where `rawWeight` is Moveables weight in tenths of a kilogram.

Current vanilla tool definitions include:

```text
Hammer  -> baseActionTime 75
Crowbar -> baseActionTime 150
```

LMION currently mirrors those bases for `LMIONMetalHammer` and `LMIONMetalCrowbar`, while using `MetalWelding` as the perk.

This makes heavy doors disproportionately slow because the raw-weight term dominates. Example for a 20 kg garage parcel at MetalWelding 3:

```text
rawWeight = 200
Pickup = (150 + 400) * 0.85 = 467.5
Place  = ( 75 + 400) * 0.85 = 403.75
```

This explains the runtime observation that dismantling/replacing a garage can take substantially longer than constructing one.

LMION should not reduce the item's real weight merely to shorten the action. A future timing policy should instead override/cap the vanilla weight contribution for LMION openings.

## Parcel count

Vanilla multisprite Moveables use the sprite grid to decide how many objects/items participate.

Normal multisprite behavior:

- every grid member is removed separately;
- `pickUpMoveableInternal()` is called for every member;
- one parcel/item is produced per member.

If the sprite has `ForceSingleItem`:

- all grid members are still removed;
- per-member item creation is disabled;
- one item is created afterward from the grid anchor sprite.

This is why a two-tile object can legitimately produce one package: it is a multisprite object explicitly opting into `ForceSingleItem` rather than vanilla automatically merging all two-tile furniture.

## Inventory versus ground

Vanilla also uses multisprite status to choose where produced items go.

Single-sprite Moveable:

```text
item -> character inventory
```

Normal multisprite Moveable:

```text
each member item -> world inventory item on that member's square
```

`ForceSingleItem` multisprite:

```text
single resulting item -> character inventory
```

Capacity checks follow the same policy. Normal multisprites do not require room for the complete resulting structure because their packages are left in the world. A single-sprite or `ForceSingleItem` pickup must fit the resulting item in inventory.

### Current LMION divergence

Large-gate and garage Pickup currently force their member MoveProps into single-sprite mode before calling `pickUpMoveableInternal()`. This intentionally made the custom parcels enter character inventory, but it diverges from vanilla multisprite parcel behavior and can overload the player with the complete 24-60 kg result.

This should be revisited. If LMION keeps multi-parcel transport identity, the vanilla-consistent default is likely to leave those parcels on the ground rather than inject all of them into inventory.

## Moveables sounds

`ISMoveablesAction:start()` calls `setActionSound()`. Pickup/Place resolve their action sound through `ISMoveableSpriteProps:getSoundFromTool()`.

Vanilla tool definitions for Hammer and Crowbar both currently use the `Hammering` sound. LMION's custom Hammer/Crowbar definitions also request `Hammering`, so completely silent LMION Pickup/Place is not the expected vanilla behavior and should be treated as a bug/integration issue rather than a design choice.

On completion vanilla additionally plays UI sounds:

```text
Pickup -> UIObjectMenuObjectPickup
Place  -> UIObjectMenuObjectPlace
Rotate -> UIObjectMenuObjectRotate
```

## Moveables animations

Vanilla `ISMoveablesAction:start()` explicitly assigns action animations for Scrap/Repair paths, but does not assign a dedicated action animation for ordinary Pickup/Place.

Therefore adding visible dismantle/place animations for LMION doors would be an intentional LMION presentation improvement rather than merely restoring a missing vanilla Moveables animation.

## Construction timed-action reference

B42.20.3 generated timed-action scripts define, for example:

```text
BuildWallMetal:
  metabolics = HeavyWork
  actionAnim = BlowTorch
  sound = BlowTorch
  completionSound = BuildMetalStructureWallFrame
  prop1 = Base.CraftingWeldingTorch

BuildWoodenStructureMedium:
  metabolics = HeavyWork
  actionAnim = Build
  completionSound = BuildWoodenStructureMedium
```

LMION construction recipes that use these timed actions should therefore not be globally silent. Missing construction sounds/animations require a separate Build pipeline audit.

## Door impact/thump sound engine behavior

B42.20.3 `IsoDoor` Java behavior distinguishes three concepts:

- `DoorSound` on the door's **closed sprite** provides `IsoDoor:getSoundPrefix()`;
- player weapon hits use that sound prefix to select the melee-hit surface material (`GarageDoor`, `MetalDoor`, `WoodDoor`, etc.);
- `ThumpSound` is used for thumping, with a fallback derived from `DoorSound` when no explicit thump sound exists.

`MaterialType` is not the selector used by `IsoDoor:WeaponHit()` for the door-hit surface.

LMION profiles already declare `DoorSound` and `ThumpSound`, and Core attempts to apply them to SpriteConfig sprites. Since runtime LMION doors are reported as silent when struck, the next diagnostic should verify the actual closed sprite's `DoorSound` / `ThumpSound` and the runtime values returned by `door:getSoundPrefix()` / `door:getThumpSound()`.

## Remaining design/work items

Before considering Pickup presentation complete:

1. define an LMION-specific Pickup/Place duration policy that does not inherit the excessive `rawWeight * 2` penalty unchanged;
2. decide whether multi-parcel large gates and garages should follow vanilla and drop parcels on the ground;
3. fix missing Pickup/Place action sounds;
4. diagnose/fix door weapon-hit and zombie-thump sounds;
5. audit Build timed-action sounds and animations;
6. decide whether LMION should add explicit Pickup/Place animations beyond vanilla Moveables behavior.
