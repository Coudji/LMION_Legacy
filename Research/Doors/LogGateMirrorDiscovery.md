# Large Log Gate mirror-set discovery

Status: **observed in-game, not yet researched historically, not implemented in LMION**.

This note records a potentially useful Build 42 discovery made while reconstructing door/gate sprites with the Brush Tool. The goal is to preserve the exact sprite relationships and the working behavior before any attempt is made to use them.

## Context

Project Zomboid currently exposes a constructible **Large Log Gate / Grand portail en bûches** that occupies two tiles. While inspecting the surrounding `walls_log` tiles, a second mirrored set was found that appears to form the opposite half of the same gate family.

Both reconstructed two-tile leaves can be placed manually and behave as functioning doors/gates. Opening and closing works correctly. This strongly suggests the tiles belong to a deliberately paired left/right gate design rather than being unrelated artwork.

It is currently only a hypothesis that Indie Stone previously intended, exposed, or removed a complete four-tile double log gate. Historical confirmation still needs to be searched for in Build 42 unstable changelogs, forum posts, bug reports, or older game data.

## Sprite groups

`*-` below marks the pivot tile observed during reconstruction.

### Original leaf — `walls_log_80` to `walls_log_87`

| State | Pivot / first tile | Second tile |
|---|---|---|
| West closed | `walls_log_81` | `walls_log_80` |
| West open | `walls_log_84` | `walls_log_85` |
| North closed | `walls_log_82` | `walls_log_83` |
| North open | `walls_log_87` | `walls_log_86` |

### Mirrored leaf — `walls_log_88` to `walls_log_95`

| State | Pivot / first tile | Second tile |
|---|---|---|
| West closed | `walls_log_89` | `walls_log_88` |
| West open | `walls_log_92` | `walls_log_93` |
| North closed | `walls_log_90` | `walls_log_91` |
| North open | `walls_log_95` | `walls_log_94` |

The mirrored family follows the same layout exactly eight sprite indices later than the original family.

## Observed behavior

- Each reconstructed leaf occupies two tiles.
- Both the original and mirrored leaf can be opened and closed successfully in-game.
- The closed versions visually form plausible opposite-handed halves of a larger gate.
- The engine behavior itself appears functional; this is not merely a set of decorative sprites.
- A visible join/seam problem exists in the **open state reached from the North-closed orientation**. The two open sprites do not connect perfectly. No equivalent functional failure was observed; the issue appears visual at this stage.

## Working hypothesis

The two 8-sprite blocks look like a left/right pair of two-tile gate leaves:

```text
walls_log_80..87   = one two-tile leaf
walls_log_88..95   = mirrored two-tile leaf
```

Together they could plausibly represent a four-tile double log gate with two independently pivoting leaves.

This is particularly interesting for LMION because it suggests some large gates may be better modeled as **paired multi-tile leaves** rather than one monolithic multi-tile object. If historically confirmed, this family could become a useful test case for pickup/replacement of large gates.

## Research to do before using it

1. Search Project Zomboid Build 42 unstable changelogs for log-gate, double-gate, gate, `walls_log`, or related construction fixes/removals.
2. Search The Indie Stone forums and public bug reports for problems involving the Large Log Gate / double log gate during the unstable period before stable Build 42.
3. Inspect older Build 42 scripts/tile definitions if available to determine whether a complete paired entity or recipe once referenced `walls_log_88..95`.
4. Inspect the current tile properties for `walls_log_80..95` and compare pivot/door flags, open offsets, collision flags, and object grouping.
5. Determine whether the North-open seam is an artwork defect, wrong pairing/order, offset issue, or evidence that one or more sprites were intended for a slightly different assembly.
6. Do not integrate the mirrored family into LMION until the topology and historical intent are understood well enough to avoid building on a broken vanilla design.

## Preservation note

The discovery was reproduced manually with the Brush Tool in Build 42 and visually confirmed in-game. Even if the eventual historical search shows the full four-tile gate was never publicly exposed, the mirrored tile family and its functioning open/close states remain technically relevant for LMION research.
