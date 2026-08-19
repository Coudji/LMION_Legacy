# Let Me In... Or Not — Development

## Current bootstrap

The project currently contains two Build 42 modules:

- `LMION_Core`
- `LMION_Pickup`

`LMION_Pickup` requires `LMION_Core`.

## First validation in game

1. Put/extract these files into the root of `LMION_Workshop`.
2. Start Project Zomboid Build 42.
3. Enable `Let Me In... Or Not - Core`.
4. Enable `Let Me In... Or Not - Pickup`.
5. Start a test game.
6. Check `console.txt`.

Expected messages:

```text
[LMION:Core] loaded 0.0.1-dev
[LMION:Core] registered module: LMION_Pickup
[LMION:Pickup] loaded 0.0.1-dev
```

If those lines appear, the base architecture loads and Pickup sees Core.

## Next milestone

Add a temporary in-game inspector for world opening objects.

Its purpose will be to log the real properties/classes/sprites of:

- simple doors;
- double-door leaves;
- sliding doors;
- large gates;
- garage-door segments.

Only after that inspection layer works should the first real pickup strategy be implemented.
