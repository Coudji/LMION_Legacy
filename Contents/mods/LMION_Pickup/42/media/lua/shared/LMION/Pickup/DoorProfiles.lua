LMION.Pickup = LMION.Pickup or {}

local Profiles = {
    knownDefault = {
        pickUpTool = "Hammer",
        placeTool = "Hammer",
        pickUpLevel = 2,
        pickUpWeight = 200,
        canBreak = false,
    },
    unknownDefault = {
        pickUpTool = "Hammer",
        placeTool = "Hammer",
        pickUpLevel = 2,
        pickUpWeight = 200,
        canBreak = false,
    },
    entities = {},
}

LMION.Pickup.DoorProfiles = Profiles

return Profiles
