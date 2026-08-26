require "LMION/Pickup/DoorProfiles"

local Profiles = LMION.Pickup.DoorProfiles

local function addLeaf(entityName, itemType)
    Profiles.entities[entityName] = {
        id = entityName,
        itemType = itemType,
        moveType = "Object",
        pickUpTool = "LMIONMetalCrowbar",
        placeTool = "LMIONMetalHammer",
        pickUpLevel = 2,
        pickUpWeight = 120,
        canBreak = false,
        requiresFrame = false,
        largeGateLeaf = true,
    }
end

addLeaf("DoubleWireGate", "Base.LMION_DoubleWireGateLeft_Part1")
addLeaf("DoubleWireGateRight", "Base.LMION_DoubleWireGateRight_Part1")
addLeaf("DoubleFenceGate", "Base.LMION_DoubleFenceGateLeft_Part1")
addLeaf("DoubleFenceGateRight", "Base.LMION_DoubleFenceGateRight_Part1")

return Profiles
