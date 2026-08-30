LMION.Pickup = LMION.Pickup or {}

local Profiles = {
    entities = {},
}

local function add(entityName, tool, level, weightKg)
    Profiles.entities[entityName] = {
        id = entityName,
        itemType = "Base.LMION_" .. entityName,
        moveType = "Object",
        pickUpTool = tool,
        placeTool = tool,
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

-- Standard wooden doors: unscrew/rescrew hinges with a screwdriver.
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

-- Standard metal doors use the same hinge logic, but retain MetalWelding as the
-- governing transport perk through LMIONMetalScrewdriver.
add("MetalDoorLvl1", "LMIONMetalScrewdriver", 1, 20)
add("MetalDoorLvl2", "LMIONMetalScrewdriver", 2, 22)
add("WhiteMetalDoor", "LMIONMetalScrewdriver", 2, 24)
add("TanMetalDoor", "LMIONMetalScrewdriver", 2, 24)
add("BlackMetalDoorWithWindow", "LMIONMetalScrewdriver", 2, 22)
add("TanMetalDoorWithWindow", "LMIONMetalScrewdriver", 2, 22)
add("BlackTwoPaneMetalDoor", "LMIONMetalScrewdriver", 2, 21)
add("BlueServiceDoor", "LMIONMetalScrewdriver", 1, 18)
add("OrangeServiceDoor", "LMIONMetalScrewdriver", 1, 18)
add("LightRedServiceDoor", "LMIONMetalScrewdriver", 1, 18)
add("BlackServiceDoor", "LMIONMetalScrewdriver", 1, 18)
add("GreenServiceDoor", "LMIONMetalScrewdriver", 1, 18)
add("RedServiceDoor", "LMIONMetalScrewdriver", 1, 18)
add("WhiteServiceDoorWithPorthole", "LMIONMetalScrewdriver", 1, 17)
add("JailDoor", "LMIONMetalScrewdriver", 5, 30)
add("SecurityDoor", "LMIONMetalScrewdriver", 5, 35)

-- Log Door is the explicit no-tool exception for Pickup and Place.
add("LogDoor", nil, 0, 25)

-- Paired double doors are still independent 1x1 leaves and follow their material
-- equivalent: wooden leaves use Screwdriver, metal leaves LMIONMetalScrewdriver.
addPaired("BlackTwoPaneDoubleDoorLeft", "LMIONMetalScrewdriver", 2, 21, 1)
addPaired("BlackTwoPaneDoubleDoorRight", "LMIONMetalScrewdriver", 2, 21, 2)
addPaired("GreyMetalDoubleDoorLeft", "LMIONMetalScrewdriver", 2, 24, 1)
addPaired("GreyMetalDoubleDoorRight", "LMIONMetalScrewdriver", 2, 24, 2)
addPaired("YellowServiceDoubleDoorLeft", "LMIONMetalScrewdriver", 1, 17, 1)
addPaired("YellowServiceDoubleDoorRight", "LMIONMetalScrewdriver", 1, 17, 2)
addPaired("BlueChurchDoubleDoorLeft", "Screwdriver", 3, 17, 1)
addPaired("BlueChurchDoubleDoorRight", "Screwdriver", 3, 17, 2)
addPaired("BrownChurchDoubleDoorLeft", "Screwdriver", 3, 17, 1)
addPaired("BrownChurchDoubleDoorRight", "Screwdriver", 3, 17, 2)

-- Gates and sliding gate-like openings are pried free, then fixed back in place
-- with a hammer. Metal variants keep MetalWelding as their transport perk.
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
