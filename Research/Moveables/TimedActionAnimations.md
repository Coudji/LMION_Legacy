# Timed-action animations (B42)

Last reviewed: 2026-08-27

This note records the animation vocabulary relevant to LMION Pickup/Place/Scrap work. It is intentionally focused on actions we may realistically reuse for doors, gates and garage doors rather than attempting to mirror every animation shipped by Project Zomboid.

## Primary documentation

Current B42 API documentation:

- timedAction script block: https://pz-wiki-modding.github.io/PZ-API-Docs/scripts/timedaction.html
- AnimNode XML: https://pz-wiki-modding.github.io/PZ-API-Docs/xml/animnode.html
- PZ API Docs root: https://pz-wiki-modding.github.io/PZ-API-Docs/

The `timedAction` documentation explains the important split:

- `actionAnim` selects a `PerformingAction` from the player's action AnimSets;
- `animVarKey` + `animVarVal` select AnimNode variants through conditions;
- `prop1` / `prop2` control hand props for scripted crafting actions;
- `sound` and `completionSound` are separate from the animation itself.

The actual action AnimNodes live under:

```text
media/AnimSets/player/actions/
```

Current depot file listings are useful for discovering which action XML files actually exist in the installed game:

- Windows depot 108604: https://steamdb.info/depot/108604/
- Linux depot 108603: https://steamdb.info/depot/108603/

SteamDB is a file-catalog reference, not a semantic API specification. The installed game remains authoritative for exact AnimNode contents.

## Vanilla Lua references

Useful current vanilla Lua source snapshot used by LMION research:

- `ISMoveablesAction.lua`: https://github.com/Project-Zomboid-Community-Modding/ProjectZomboid-Vanilla-Lua/blob/8a906692ac56f9d40c078d654eea6c70491cbc62/shared/Moveables/ISMoveablesAction.lua
- `ISMoveableSpriteProps.lua`: https://github.com/Project-Zomboid-Community-Modding/ProjectZomboid-Vanilla-Lua/blob/8a906692ac56f9d40c078d654eea6c70491cbc62/shared/Moveables/ISMoveableSpriteProps.lua
- `ISUnbarricadeAction.lua`: https://github.com/Project-Zomboid-Community-Modding/ProjectZomboid-Vanilla-Lua/blob/8a906692ac56f9d40c078d654eea6c70491cbc62/shared/TimedActions/ISUnbarricadeAction.lua
- `ISDismantleAction.lua`: https://github.com/Project-Zomboid-Community-Modding/ProjectZomboid-Vanilla-Lua/blob/8a906692ac56f9d40c078d654eea6c70491cbc62/shared/TimedActions/ISDismantleAction.lua
- `AnimationClipViewer.lua`: https://github.com/Project-Zomboid-Community-Modding/ProjectZomboid-Vanilla-Lua/blob/8a906692ac56f9d40c078d654eea6c70491cbc62/client/DebugUIs/AnimationClipViewer.lua

LMION runtime is currently B42.20.4. The local extracted script reference used during this research is B42.20.3, so exact installed B42.20.4 AnimSets outrank this note if they disagree.

## Three different concepts that are easy to mix up

### 1. CharacterActionAnims

Lua timed actions may use enum-backed values such as:

```lua
self:setActionAnim(CharacterActionAnims.Disassemble)
self:setActionAnim(CharacterActionAnims.Build)
self:setActionAnim(CharacterActionAnims.BuildLow)
```

This enum is only a convenience set. It is not the complete list of animations available to `setActionAnim()`.

### 2. PerformingAction strings

`setActionAnim()` can also receive a string that corresponds to a PerformingAction represented by one or more AnimNodes in `media/AnimSets/player/actions/`:

```lua
self:setActionAnim("BlowTorch")
self:setActionAnim("RemoveBarricade")
self:setActionAnim("Loot")
self:setActionAnim("SawLog")
```

### 3. AnimNode variants

A PerformingAction can select different AnimNodes through variables. Example from the API docs:

```lua
self:setActionAnim("Loot")
self:setAnimVariable("LootPosition", "Low")
```

`LootHigh.xml`, for example, inherits the base Loot action and is selected when `LootPosition = High`.

## Useful action families for LMION

| Purpose | PerformingAction / call | Known variant mechanism | Notes |
| --- | --- | --- | --- |
| generic screwdriver/disassembly | `CharacterActionAnims.Disassemble` / `"Disassemble"` | seated variants exist in AnimSets | Vanilla Moveables fallback for Scrap when neither blowtorch nor hammer is equipped. |
| electrical disassembly | `"DismantleElectrical"` timedAction -> `disassembleElectrical` AnimSet family | seated variant exists | B42 craft recipes that dismantle electronics and require a screwdriver use this family. Potential visual alternative for fine screwdriver work, but semantically electrical. |
| electrical assembly | `"MakingElectrical"` | seated variant exists | Several B42 recipes using a screwdriver use this action. More "bench/crafting" than hinge removal. |
| pry with crowbar | `"RemoveBarricade"` | `RemoveBarricade = CrowbarMid` / `CrowbarHigh` | Vanilla barricade removal. Strong candidate for LMION gate Pickup. |
| hammer/build | `CharacterActionAnims.Build` / `"Build"` | separate `BuildLow`, `BuildKneeling` files | Strong candidate for gate/garage placement. |
| hammer/build low | `CharacterActionAnims.BuildLow` / `"BuildLow"` | separate action | Useful when the target is near ground level. |
| welding | `"BlowTorch"` | separate `BlowTorchFloor` action | Vanilla Moveables Scrap chooses these when the character actually has a blowtorch equipped. |
| generic object manipulation | `"Loot"` | `LootPosition = Low/Mid/High` | Useful neutral manipulation animation if an explicit tool animation looks wrong. |
| sawing | `"SawLog"` | no LMION-specific variant identified | `ISDismantleAction` can require both saw and screwdriver yet visually uses SawLog + Hacksaw, proving that a required screwdriver does not imply a screwdriver animation. |
| generic crafting | `"Craft"`, `"Making"` | multiple specialized craft actions | Mostly unsuitable for door hinge work unless a better dedicated action is unavailable. |

Other current action files visible in the B42 depot include `Making`, `Making_Surface`, `MakingHammer_Surface`, `Chisel_Surface`, `Welding_Surface`, `UseStandingDrill`, `UseBandsaw`, `UseGrindingStone`, `UseLathe`, and many weapon/medical/animal actions. Their existence does not mean they are appropriate for LMION.

## Screwdriver-specific findings

There is no single exhaustive "screwdriver animation list" exposed by the timedAction API. The tool and the PerformingAction are separate concepts.

Current evidence:

1. **`Disassemble` is the generic vanilla Moveables screwdriver-looking action.**
   `ISMoveablesAction:start()` falls back to `CharacterActionAnims.Disassemble` and forces the hand model `"Screwdriver"` when Scrap is not recognized as blowtorch or hammer work.

2. **`disassembleElectrical` is a distinct action family with its own props.**
   The current depot contains:
   - `disassembleElectrical.xml`
   - `disassembleElectrical_Sat.xml`

   B42.20.3 `timedactions.txt` defines `DismantleElectrical` with:

   ```text
   actionAnim = disassembleElectrical
   sound = Dismantle
   prop1 = Base.Screwdriver
   prop2 = Base.Receiver
   ```

   This confirms it is not a clean one-tool hinge animation: it explicitly puts a receiver/electronics prop in the other hand. It is therefore a poor LMION door candidate despite using a screwdriver.

3. **`MakingElectrical` is another distinct screwdriver-capable family.**
   B42 recipes such as improvised electrical devices use `timedAction = MakingElectrical` with a screwdriver as one of the props/tools.

4. **Other recipes requiring a screwdriver use unrelated action families** such as `CraftWeapon1H`, `CraftWeapon2H`, `CraftKnifeSpear`, `Making`, or even a saw-focused action. Therefore searching recipes by required tool does not produce a list of "screwdriver motions".

5. **No dedicated `ScrewdriverHigh`, `ScrewdriverMid`, or `ScrewdriverLow` action files were found in the current player/actions depot listing.**
   If LMION needs height-specific hinge work, the practical choices are to test another existing PerformingAction, use a generic positional family such as Loot, or create custom AnimNodes later.

### LMION candidates to visually test for hinge work

In priority order:

1. `Disassemble` — already confirmed working and semantically close.
2. `Loot` with `LootPosition` variants — neutral fallback if height control is more valuable than explicit screwdriver motion.
3. `MakingElectrical` — possible experiment, but likely too craft/bench-like.

`DismantleElectrical` is no longer considered a good candidate because its timedAction explicitly supplies `Base.Receiver` as a second-hand prop.

Do not switch production behavior based only on the action name. Test the animation in game with a real screwdriver model in hand.

## Vanilla Animation Viewer / debug tooling

Project Zomboid ships an in-game `AnimationClipViewer` in debug builds. The current Lua implementation is `client/DebugUIs/AnimationClipViewer.lua`, backed by Java `zombie.gameStates.AnimationViewerState`.

The viewer can:

- list animation clips;
- play a selected clip on a 3D character/animal preview;
- pause playback;
- scrub the animation timeline;
- inspect keyframe positions;
- rotate the camera;
- toggle viewer options such as grid, bones and deferred movement;
- audition game sounds at chosen fractions of the clip.

Historical/current debug UI references expose it under the debug developer tools as **Animation Viewer**. An older documented shortcut is **Ctrl+F7** while running with `-debug`; if that shortcut has changed in a later B42 build, use the debug menu entry instead.

Important limitation: `AnimationClipViewer` calls `setCharacterAnimationClip` directly. It previews **raw animation clips**, not the complete gameplay `PerformingAction -> AnimNode conditions -> anim variables -> timed-action props` state machine. It is excellent for comparing body motions, but a clip that looks correct there can still behave differently when driven through `setActionAnim()` in gameplay.

For LMION animation research use this workflow:

1. use Animation Viewer to quickly browse candidate raw clips;
2. note promising clip/action names;
3. inspect corresponding `media/AnimSets/player/actions/*.xml` to find the PerformingAction and required variables;
4. verify the real result through an LMION timed action with the intended tool model and sound.

The separate **Anim Monitor** debug tool is useful for observing the live character animation state while a real action runs. For LMION, Animation Viewer is better for browsing candidates; Anim Monitor is better for understanding which state/node/variables the real action selected.

## Vanilla Scrap animation trap

`ISMoveablesAction:start()` currently follows this presentation logic for Scrap:

```text
custom startScrapAction override
else if blowtorch is EQUIPPED -> BlowTorch / BlowTorchFloor
else if hammer is EQUIPPED -> Build / BuildLow
else -> Disassemble + forced Screwdriver model
```

This means the Scrap definition may correctly require a blowtorch and welding protection, yet the visible animation can still fall into the screwdriver branch if the blowtorch is not actually equipped at the instant the action starts.

LMION must not treat that fallback as intended presentation for openings explicitly defined as blowtorch Scrap. For LMION blowtorch Scrap, ensure the real blowtorch is primary-hand equipped before vanilla `ISMoveablesAction:start()` evaluates its branch, while retaining vanilla Scrap validation, tool consumption, sound and welding-protection requirement.

## Welding protection

Current vanilla metal Scrap definitions such as `MetalBars`, `MetalPipe`, `MetalPlates`, `MetalPlatesAndBars`, `SmallMetalPlates`, `MetalScrap`, `MetalWire`, and `Plumbing` use:

```text
primary tool: Base.BlowTorch
secondary requirement: Tag.WeldingMask / Base.WeldingMask
```

B42 item scripts give both the welding mask and welding goggles/eyewear the welding-mask tag, so the shared tag is the correct requirement rather than hard-coding one specific item type.

## Current LMION presentation policy

Gameplay rule currently intended:

| Opening | Pickup | Place | Scrap |
| --- | --- | --- | --- |
| normal wooden door | Screwdriver | Screwdriver | vanilla wood: hammer/saw |
| Log Door | none | none | material rule |
| normal metal door | Screwdriver | Screwdriver | blowtorch + welding protection |
| paired wooden door | Screwdriver | Screwdriver | vanilla wood |
| paired metal door | Screwdriver | Screwdriver | blowtorch + welding protection |
| 1x1 wooden gate | Crowbar | Hammer | vanilla wood |
| 1x1 metal gate | Crowbar | Hammer | blowtorch + welding protection |
| large wooden gate | Crowbar | Hammer | vanilla wood |
| large metal gate | Crowbar | Hammer | blowtorch + welding protection |
| garage door | Crowbar | Hammer | blowtorch + welding protection |

Presentation should follow the actual gameplay tool contract:

- screwdriver -> real screwdriver in hand + chosen screwdriver action;
- crowbar -> real crowbar in hand + `RemoveBarricade` crowbar variant when visually appropriate;
- hammer -> real hammer in hand + Build-family animation + hammer sound;
- blowtorch -> real blowtorch in hand + BlowTorch-family animation + vanilla welding sound; welding mask/goggles remain a required secondary condition.

## Research rule

Names discovered in depot listings are candidates, not proof of visual suitability. Before adopting a new animation in production:

1. confirm the action exists in the current runtime build;
2. inspect its AnimNode conditions/variants where practical;
3. run it with the intended real hand tool;
4. check standing orientation and target height;
5. check sound start/loop/stop behavior;
6. only then make it the LMION default.
