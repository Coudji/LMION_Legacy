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

addLeaf("DoubleWireGate", "Base.LMION_DoubleWireGateA_Part1", "LMIONMetalCrowbar", "LMIONMetalHammer", 2)
addLeaf("DoubleWireGateB", "Base.LMION_DoubleWireGateB_Part1", "LMIONMetalCrowbar", "LMIONMetalHammer", 2)
addLeaf("DoubleFenceGate", "Base.LMION_DoubleFenceGateA_Part1", "LMIONMetalCrowbar", "LMIONMetalHammer", 2)
addLeaf("DoubleFenceGateB", "Base.LMION_DoubleFenceGateB_Part1", "LMIONMetalCrowbar", "LMIONMetalHammer", 2)
addLeaf("DoubleDoor", "Base.LMION_DoubleDoorA_Part1", "Crowbar", "Hammer", 2)
addLeaf("DoubleDoorB", "Base.LMION_DoubleDoorB_Part1", "Crowbar", "Hammer", 2)
addLeaf("LargeFarmGateA", "Base.LMION_LargeFarmGateA_Part1", "LMIONMetalCrowbar", "LMIONMetalHammer", 2)
addLeaf("LargeFarmGateB", "Base.LMION_LargeFarmGateB_Part1", "LMIONMetalCrowbar", "LMIONMetalHammer", 2)
addLeaf("LargeHardenedWoodenGateA", "Base.LMION_LargeHardenedWoodenGateA_Part1", "Crowbar", "Hammer", 3)
addLeaf("LargeHardenedWoodenGateB", "Base.LMION_LargeHardenedWoodenGateB_Part1", "Crowbar", "Hammer", 3)
addLeaf("LargeWroughtIronGateA", "Base.LMION_LargeWroughtIronGateA_Part1", "LMIONMetalCrowbar", "LMIONMetalHammer", 3)
addLeaf("LargeWroughtIronGateB", "Base.LMION_LargeWroughtIronGateB_Part1", "LMIONMetalCrowbar", "LMIONMetalHammer", 3)

return Profiles
