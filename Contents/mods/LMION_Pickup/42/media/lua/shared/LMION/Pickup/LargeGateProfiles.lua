require "LMION/Pickup/DoorProfiles"

local Profiles = LMION.Pickup.DoorProfiles

local function addLeaf(entityName, itemType, pickUpTool, placeTool, pickUpLevel)
    Profiles.entities[entityName] = {
        id = entityName,
        itemType = itemType,
        moveType = "Object",
        pickUpTool = pickUpTool,
        placeTool = placeTool,
        pickUpLevel = pickUpLevel,
        pickUpWeight = 120,
        canBreak = false,
        requiresFrame = false,
        largeGateLeaf = true,
    }
end

addLeaf("DoubleWireGate", "Base.LMION_DoubleWireGateLeft_Part1", "LMIONMetalCrowbar", "LMIONMetalHammer", 2)
addLeaf("DoubleWireGateRight", "Base.LMION_DoubleWireGateRight_Part1", "LMIONMetalCrowbar", "LMIONMetalHammer", 2)
addLeaf("DoubleFenceGate", "Base.LMION_DoubleFenceGateLeft_Part1", "LMIONMetalCrowbar", "LMIONMetalHammer", 2)
addLeaf("DoubleFenceGateRight", "Base.LMION_DoubleFenceGateRight_Part1", "LMIONMetalCrowbar", "LMIONMetalHammer", 2)
addLeaf("DoubleDoor", "Base.LMION_DoubleDoorLeft_Part1", "Crowbar", "Hammer", 2)
addLeaf("DoubleDoorRight", "Base.LMION_DoubleDoorRight_Part1", "Crowbar", "Hammer", 2)
addLeaf("LargeFarmGateLeft", "Base.LMION_LargeFarmGateLeft_Part1", "LMIONMetalCrowbar", "LMIONMetalHammer", 2)
addLeaf("LargeFarmGateRight", "Base.LMION_LargeFarmGateRight_Part1", "LMIONMetalCrowbar", "LMIONMetalHammer", 2)
addLeaf("LargeHardenedWoodenGateLeft", "Base.LMION_LargeHardenedWoodenGateLeft_Part1", "Crowbar", "Hammer", 3)
addLeaf("LargeHardenedWoodenGateRight", "Base.LMION_LargeHardenedWoodenGateRight_Part1", "Crowbar", "Hammer", 3)
addLeaf("LargeWroughtIronGateLeft", "Base.LMION_LargeWroughtIronGateLeft_Part1", "LMIONMetalCrowbar", "LMIONMetalHammer", 3)
addLeaf("LargeWroughtIronGateRight", "Base.LMION_LargeWroughtIronGateRight_Part1", "LMIONMetalCrowbar", "LMIONMetalHammer", 3)

return Profiles
