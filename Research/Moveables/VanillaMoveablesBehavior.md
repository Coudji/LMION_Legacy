# Vanilla Moveables behavior relevant to LMION

Status: **B42.20.3/B42 current-source behavior researched; LMION parcel destination, durability presentation, transport-weight handling and current presentation baseline runtime-validated on current reference paths**.

This note records vanilla Moveables rules that matter for LMION's Pickup polish work: action duration, parcel count/destination, transport weight, sounds and animation behavior.

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

### LMION policy

LMION follows that destination model:

- simple 1x1 doors / paired 1x1 leaves remain single inventory items;
- a two-segment large-gate leaf produces two parcels on the ground;
- a three-segment garage produces three parcels on the ground.

The specialized large-gate and garage placement paths search for required parcels first in character inventory and then on nearby ground, using the same 3-tile Moveables search radius as vanilla. A placement may therefore consume one parcel carried by the player and the remaining required parcels from the floor.

This preserves realistic transport weight without requiring the player to hold the complete 24 kg large-gate leaf or 60 kg garage at once.

Current transport weights remain:

```text
large-gate leaf: 2 x 12 kg = 24 kg
garage:          3 x 20 kg = 60 kg
```

The 60 kg garage total is retained as a plausible steel sectional-garage-door mass and is no longer a placement blocker because floor parcels are directly consumable.

### Runtime validation

The vanilla-style destination change is confirmed in game:

- garage Pickup produces three parcels on the ground;
- large-gate leaf Pickup produces two parcels on the ground;
- both structures can be reinstalled successfully from nearby parcels;
- placement works after N/W rotation;
- exact current health and `lmionDoorMaxHealth` remain preserved through the new ground-parcel path.

## Interchangeable parcels

Current parcel lookup is by required LMION part item type, not by an assembly/bundle identifier. Runtime testing confirms that compatible parcels from multiple identical garages are deliberately interchangeable.

Validated scenario:

1. Pick up two identical garages, producing six floor parcels.
2. Reinstall one garage from the mixed pool: only one Part1, one Part2 and one Part3 are consumed, leaving three parcels on the floor.
3. Damage Part1 of one garage and Part3 of another.
4. Pick up both garages, discard one undamaged Part3, substitute the damaged Part3 from the second garage, then rebuild.
5. The rebuilt garage correctly has both Part1 and Part3 damaged.

So LMION currently treats the parcels as independent physical replacement parts rather than preserving a hidden assembly identity:

```text
Part1 parcel state + Part2 parcel state + Part3 parcel state
    -> rebuilt garage carrying those exact three per-part states
```

Durability remains attached to each parcel through `lmionDoorHealth` / `lmionDoorMaxHealth`. This behavior is accepted and useful; no bundle identity should be added unless a future gameplay requirement specifically needs it.

## Durability presentation

Because interchangeable parcels can have materially different durability, LMION appends the authoritative logical durability to inventory tooltips:

```text
FR: PV : current / max
EN: HP : current / max
```

No percentage is shown by design.

The tooltip reads `lmionDoorHealth` and `lmionDoorMaxHealth` from item `modData`, so it follows the same logical-health model used during replacement instead of engine `getMaxHealth()`.

Runtime validation confirms the tooltip works on garage parcels and transport items without replacing vanilla's tooltip content. The implementation extends `ISToolTipInv` after vanilla rendering rather than drawing directly through Java-owned `ObjectTooltip` internals.

## Transport weight synchronization

LMION owns explicit gameplay weights through MoveProps/profiles. Vanilla `ISMoveableSpriteProps:instanceItem()` calls `ReadFromWorldSprite()`, then restores `actualWeight`, but B42 inventory presentation can still expose the other `InventoryItem.weight` field. This produced a visible 1.0 kg garage parcel even though its script/profile weight was 20 kg.

LMION normalizes both fields after the complete specialized `instanceItem()` chain:

```text
item:setActualWeight(moveProps.weight)
item:setWeight(moveProps.weight)
```

This is limited to LMION transport MoveProps.

Runtime validation confirms correct displayed/effective weights for:

- garage parcels (20 kg per current garage segment);
- ordinary 1x1 LMION door transport items;
- the shared normalization path used by large-gate parcels.

Do not reduce these real transport weights as a workaround for excessive action duration; timing is a separate policy problem.

## Moveables sounds

`ISMoveablesAction:start()` calls `setActionSound()`. Pickup/Place resolve their action sound through `ISMoveableSpriteProps:getSoundFromTool()`.

Vanilla tool definitions for Hammer and Crowbar currently use `Hammering`. LMION's custom metal Hammer/Crowbar definitions also request `Hammering`. Crowbar Pickup presentation then replaces that audible event with `BeginRemoveBarricadePlankCrowbar`.

On completion vanilla additionally plays UI sounds:

```text
Pickup -> UIObjectMenuObjectPickup
Place  -> UIObjectMenuObjectPlace
Rotate -> UIObjectMenuObjectRotate
```

### Audio QA: Invisible cheat

Earlier reports that LMION Pickup/Place, blowtorch Scrap and door hits were generically silent were contaminated by Debug/Cheat **Invisible** mode.

Runtime testing established that with Invisible enabled, some audible action/object sounds may be suppressed even in a completely unmodded solo game. Blowtorch and door-hit sounds were affected, while hammering could still remain audible.

After disabling Invisible, the supposedly missing sounds returned.

Therefore:

> **Disable Invisible before diagnosing any LMION sound problem.**

There is currently no reproduced generic missing-sound defect for blowtorch or door impacts with Invisible off.

Material-specific fidelity remains separate from sound correctness:

- current crowbar Pickup uses a wood-barricade crowbar event for both wooden and metal openings;
- current Hammer Place uses configured `Hammering` for both wooden and metal openings;
- material-specific metal alternatives are optional polish and should be selected by listening to candidate vanilla events in game rather than guessing from names.

A temporary `SmithingHammerHit` pulse experiment for metal Hammer Place was removed because it still appeared to overlap with the wood-like sound and required an extra `ISMoveablesAction.update()` wrapper. It is not part of the current production path.

## Moveables animations

Vanilla `ISMoveablesAction:start()` explicitly assigns action animations for Scrap/Repair paths, but does not assign a dedicated action animation for ordinary Pickup/Place.

LMION intentionally improves that presentation:

```text
Screwdriver Pickup/Place -> LMION_ScrewdriverHinge -> Bob_IdleMakingLow
Crowbar Pickup           -> LMION_CrowbarPickupLow -> Bob_IdleLeverOpenLow
Hammer Place             -> vanilla Build
```

The two custom AnimNode mappings have been runtime validated with their real tools in hand.

### Blowtorch Scrap presentation trap

Vanilla's ScrapDefinition may correctly require `Base.BlowTorch`, yet `ISMoveablesAction.start()` separately checks the currently equipped tool to choose the animation. If the torch is not equipped at that exact point, vanilla can fall through to `Disassemble + Screwdriver`.

LMION therefore equips the actual usable blowtorch before vanilla `start()` when the active ScrapDefinition requires `Base.BlowTorch`, then re-applies `BlowTorch` / `BlowTorchFloor` and the real torch hand model afterward.

This is runtime validated. Vanilla remains authoritative for requirements, welding protection, duration, sound lifecycle, consumption and scrap yields.

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

LMION construction recipes that use these timed actions inherit that presentation path. Audit Build separately only when a concrete construction presentation issue is reproduced.

## Door impact/thump sound engine behavior

B42.20.3 `IsoDoor` Java behavior distinguishes three concepts:

- `DoorSound` on the door's **closed sprite** provides `IsoDoor:getSoundPrefix()`;
- player weapon hits use that sound prefix to select the melee-hit surface material (`GarageDoor`, `MetalDoor`, `WoodDoor`, etc.);
- `ThumpSound` is used for thumping, with a fallback derived from `DoorSound` when no explicit thump sound exists.

`MaterialType` is not the selector used by `IsoDoor:WeaponHit()` for the door-hit surface.

LMION profiles declare `DoorSound` and `ThumpSound`, and Core applies them through its alias-safe property path. The previous claim that LMION doors were silent when struck is no longer considered a reproduced defect because the tests were performed with Invisible enabled. With Invisible disabled, impact audio is audible.

If a specific door family later has an incorrect impact/thump sound, inspect that family's actual closed-sprite `DoorSound` / `ThumpSound` and runtime `door:getSoundPrefix()` / `door:getThumpSound()` before changing global behavior.

## Remaining design/work items

Before considering Pickup presentation fully polished:

1. define an LMION-specific Pickup/Place duration policy that does not inherit the excessive `rawWeight * 2` penalty unchanged;
2. decide the visual/naming treatment of simple 1x1 inventory items if explicit package presentation is desired;
3. optionally add material-specific crowbar/hammer sounds after auditioning suitable vanilla events;
4. audit Build timed-action presentation only if a concrete issue is reproduced.

The custom screwdriver/crowbar animations, blowtorch Scrap presentation, current sounds with Invisible disabled, parcel logistics, durability and transport weights are no longer open generic defects.
