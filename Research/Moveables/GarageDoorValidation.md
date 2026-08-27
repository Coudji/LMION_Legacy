# Garage-door Pickup validation

Status: **runtime-validated across all seven current LMION garage families for the complete closed-state Pickup path**.

Validated families:

- `IndustrialGarageDoor`
- `GreenGarageDoor`
- `WhiteGarageDoor`
- `GreyGarageDoor`
- `RollingGarageDoor`
- `RedWindowGarageDoor`
- `RollingWindowGarageDoor`

The current implementation has been exercised successfully in game across the supported closed-state workflow. Pickup and replacement work in both N and W orientations, rotation/replacement behavior is correct, restored garages resume their normal vanilla synchronized opening/closing behavior, the three-part transport identity remains coherent, garages can be picked up again after replacement, and door health is preserved through transport.

`IndustrialGarageDoor` remains the original reference family used to establish the engine-index mapping and the three-segment transport contract documented in `GarageDoorTopology.md`; the six generalized families now share the same validated gameplay status.

The runtime `GarageDoor = 1/2/3` sprite-property validation remains intentionally in place as a fail-closed guard against future tile-definition or engine changes.

Open-state Pickup is still outside the supported/reference path. No further garage Pickup validation work is currently required unless Project Zomboid changes the garage-door topology or a regression is reproduced.
