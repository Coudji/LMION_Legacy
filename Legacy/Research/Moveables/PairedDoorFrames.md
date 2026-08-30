# Paired door-frame runtime markers

Status: **runtime-confirmed on B42.20.3 via vanilla Tile Report**

## Confirmed mapping

A paired double-door frame exposes both a structural `DoubleDoor` flag and a descriptive cutaway hint.

Runtime examples from `fixtures_doors_frames_01`:

```text
fixtures_doors_frames_01_26
DoorWallN
DoubleDoor1
CutawayHint = DoubleDoorLeft

fixtures_doors_frames_01_27
DoorWallN
DoubleDoor2
CutawayHint = DoubleDoorRight
```

Therefore the editor labels `Double-Doorframe Left` / `Double-Doorframe Right` map at runtime to:

```text
Left  -> DoubleDoor1 + CutawayHint=DoubleDoorLeft
Right -> DoubleDoor2 + CutawayHint=DoubleDoorRight
```

`WallStyle` was not present in these vanilla Tile Reports and should not be used as the primary paired-frame classifier.

## LMION implication

Paired 1x1 door leaves can use the structural `DoubleDoor1` / `DoubleDoor2` flags to distinguish the required frame side while retaining the existing N/W frame-orientation checks. `CutawayHint` is a useful corroborating/fallback marker, not the primary structural rule.
