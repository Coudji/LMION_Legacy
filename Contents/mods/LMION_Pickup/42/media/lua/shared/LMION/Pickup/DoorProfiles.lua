LMION.Pickup = LMION.Pickup or {}

local Profiles = {
    entities = {},
}

local function add(entityName, tool, level, weightKg)
    local placeTool = tool == "Screwdriver" and "Hammer" or tool

    Profiles.entities[entityName] = {
        id = entityName,
        itemType = "Base.LMION_" .. entityName,
        moveType = "Object",
        pickUpTool = tool,
        placeTool = placeTool,
        pickUpLevel = level,
        pickUpWeight = weightKg * 10,
        canBreak = false,
        requiresFrame = true,
    }
end

local function addPaired(entityName, tool, level, weightKg, frameSide)
    add(entityName, tool, level, weightKg)
    Profiles.entities[entityName].pairedFrameSide = frameSide
end

local function addGate(entityName, pickUpTool, placeTool, level, weightKg)
    Profiles.entities[entityName] = {
        id = entityName,
        itemType = "Base.LMION_" .. entityName,
        moveType = "Object",
        pickUpTool = pickUpTool,
        placeTool = placeTool,
        pickUpLevel = level,
        pickUpWeight = weightKg * 10,
        canBreak = false,
        requiresFrame = false,
    }
end

add("BlackRestroomStallDoor", "Screwdriver", 0, 8)
add("BlueRestroomStallDoor", "Screwdriver", 0, 8)
add("BrownRestroomStallDoor", "Screwdriver", 0, 8)
add("PinkRestroomStallDoor", "Screwdriver", 0, 8)
add("WhiteRestroomStallDoor", "Screwdriver", 0, 8)
add("BlueRestroomDoor", "Screwdriver", 0, 10)
add("WoodenDoorLvl1", "Screwdriver", 1, 15)
add("RoughWoodenDoor", "Screwdriver", 1, 14)
add("WoodenDoorLvl2", "Screwdriver", 2, 15)
add("RusticWoodenDoor", "Screwdriver", 2, 15)
add("WoodenDoorLvl3", "Screwdriver", 3, 15)
add("OuthouseDoor", "Screwdriver", 0, 10)
add("WhitePanelDoor", "Screwdriver", 3, 17)
add("BrownPanelDoor", "Screwdriver", 3, 17)
add("MahoganyPanelDoor", "Screwdriver", 3, 17)
add("BluePanelDoor", "Screwdriver", 3, 17)
add("WhiteDoorWithWindows", "Screwdriver", 3, 16)
add("BrownDoorWithWindows", "Screwdriver", 3, 16)
add("BlueDoorWithWindow", "Screwdriver", 3, 17)
add("RedTwoPaneDoor", "Screwdriver", 3, 16)
add("BlueTwoPaneDoor", "Screwdriver", 3, 16)
add("GreenStripedTwoPaneDoor", "Screwdriver", 3, 16)
add("BrownTwoPaneDoor", "Screwdriver", 3, 16)
add("DarkBrownTwoPaneDoor", "Screwdriver", 3, 16)
add("BlackFullGlassDoor", "Screwdriver", 3, 14)
add("BrownFullGlassDoor", "Screwdriver", 3, 14)
add("MetalDoorLvl1", "Metal", 1, 20)
add("MetalDoorLvl2", "Metal", 2, 22)
add("WhiteMetalDoor", "Metal", 2, 24)
add("TanMetalDoor", "Metal", 2, 24)
add("BlackMetalDoorWithWindow", "Metal", 2, 22)
add("TanMetalDoorWithWindow", "Metal", 2, 22)
add("BlackTwoPaneMetalDoor", "Metal", 2, 21)
add("BlueServiceDoor", "Metal", 1, 18)
add("OrangeServiceDoor", "Metal", 1, 18)
add("LightRedServiceDoor", "Metal", 1, 18)
add("BlackServiceDoor", "Metal", 1, 18)
add("GreenServiceDoor", "Metal", 1, 18)
add("RedServiceDoor", "Metal", 1, 18)
add("WhiteServiceDoorWithPorthole", "Metal", 1, 17)
add("LogDoor", nil, 0, 25)
add("JailDoor", "Metal", 5, 30)
add("SecurityDoor", "Metal", 5, 35)

-- Paired double doors remain independent 1x1 leaves, but replacement is only
-- valid in the matching structural double-door frame side reported by B42:
-- Left -> DoubleDoor1, Right -> DoubleDoor2.
addPaired("BlackTwoPaneDoubleDoorLeft", "Metal", 2, 21, 1)
addPaired("BlackTwoPaneDoubleDoorRight", "Metal", 2, 21, 2)
addPaired("GreyMetalDoubleDoorLeft", "Metal", 2, 24, 1)
addPaired("GreyMetalDoubleDoorRight", "Metal", 2, 24, 2)
addPaired("YellowServiceDoubleDoorLeft", "Metal", 1, 17, 1)
addPaired("YellowServiceDoubleDoorRight", "Metal", 1, 17, 2)
addPaired("BlueChurchDoubleDoorLeft", "Screwdriver", 3, 17, 1)
addPaired("BlueChurchDoubleDoorRight", "Screwdriver", 3, 17, 2)
addPaired("BrownChurchDoubleDoorLeft", "Screwdriver", 3, 17, 1)
addPaired("BrownChurchDoubleDoorRight", "Screwdriver", 3, 17, 2)

addGate("SmallWhiteWoodenGate", "Crowbar", "Hammer", 1, 7)
addGate("WoodFenceGate", "Crowbar", "Hammer", 1, 14)
addGate("HardenedWoodenGate", "Crowbar", "Hammer", 2, 18)
addGate("MetalWireFenceGateSmall", "LMIONMetalCrowbar", "LMIONMetalHammer", 1, 6)
addGate("MetalWireFenceGate", "LMIONMetalCrowbar", "LMIONMetalHammer", 1, 12)
addGate("MetalPoleFenceGateSmall", "LMIONMetalCrowbar", "LMIONMetalHammer", 1, 8)
addGate("MetalPoleFenceGate", "LMIONMetalCrowbar", "LMIONMetalHammer", 1, 16)
addGate("SmallWroughtIronGate", "LMIONMetalCrowbar", "LMIONMetalHammer", 1, 12)
addGate("WroughtIronGate", "LMIONMetalCrowbar", "LMIONMetalHammer", 2, 25)
addGate("BrownSlidingGlassDoor", "LMIONMetalCrowbar", "LMIONMetalHammer", 1, 20)
addGate("WhiteSlidingGlassDoor", "LMIONMetalCrowbar", "LMIONMetalHammer", 1, 20)

LMION.Pickup.DoorProfiles = Profiles

return Profiles
