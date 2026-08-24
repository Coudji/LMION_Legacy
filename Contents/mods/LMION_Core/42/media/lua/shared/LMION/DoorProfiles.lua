local Profiles = {}

local function add(id, name, durabilityClass, worldMaxHealth, skill, health, skillBaseHealth, material1, material2, material3, materialType, doorSound, thumpSound, frame)
    Profiles[id] = {
        id = id,
        fallbackName = name,
        class = durabilityClass,
        frame = frame,
        requiresFrame = frame == "standard",
        durability = {
            worldMaxHealth = worldMaxHealth,
            health = health,
            skillBaseHealth = skillBaseHealth,
            skill = skill,
        },
        materials = {
            primary = material1,
            secondary = material2,
            tertiary = material3,
            materialType = materialType,
        },
        sounds = {
            door = doorSound,
            thump = thumpSound,
        },
    }
end

add("IndustrialGarageDoor", "Industrial Garage Door", "metal", 1200, "MetalWelding", 600, 400, "MetalPlates", "MetalBars", nil, "Metal_Light", "GarageDoor", "ZombieThumpGarageDoor", "none")
add("GreenGarageDoor", "Green Garage Door", "metal", 1200, "MetalWelding", 600, 400, "MetalPlates", "MetalBars", nil, "Metal_Light", "GarageDoor", "ZombieThumpGarageDoor", "none")
add("WhiteGarageDoor", "White Garage Door", "metal", 1200, "MetalWelding", 600, 400, "MetalPlates", "MetalBars", nil, "Metal_Light", "GarageDoor", "ZombieThumpGarageDoor", "none")
add("GreyGarageDoor", "Grey Garage Door", "metal", 1200, "MetalWelding", 600, 400, "MetalPlates", "MetalBars", nil, "Metal_Light", "GarageDoor", "ZombieThumpGarageDoor", "none")
add("RollingGarageDoor", "Rolling Garage Door", "metal", 1200, "MetalWelding", 600, 400, "MetalPlates", "MetalBars", nil, "Metal_Light", "GarageDoor", "ZombieThumpGarageDoor", "none")
add("RedWindowGarageDoor", "Red Window Garage Door", "metal_glazed", 1000, "MetalWelding", 500, 350, "MetalPlates", "MetalBars", nil, "Metal_Light", "GarageDoor", "ZombieThumpGarageDoor", "none")
add("RollingWindowGarageDoor", "Rolling Window Garage Door", "metal_glazed", 1000, "MetalWelding", 500, 350, "MetalPlates", "MetalBars", nil, "Metal_Light", "GarageDoor", "ZombieThumpGarageDoor", "none")
add("DoubleDoor", "Large Wooden Gate", "wood", 650, "Woodwork", 400, 300, "Wood", "Nails", nil, "Wood_Solid", "WoodGate", "ZombieThumpWood", "none")
add("LargeHardenedWoodenGate", "Large Hardened Wooden Gate", "wood", 750, "Woodwork", 500, 350, "Wood", "Nails", "Screws", "Wood_Solid", "WoodGate", "ZombieThumpWood", "none")
add("LargeFarmGate", "Large Farm Gate", "metal", 500, "MetalWelding", 300, 200, "MetalPipe", nil, nil, "Metal_Light", "FarmGate", "ZombieThumpMetalPoleGate", "none")
add("DoubleWireGate", "Large Chain-Link Gate", "metal", 850, "MetalWelding", 400, 275, "MetalPipe", "MetalWire", nil, "Metal_Light", "MetalGate", "ZombieThumpChainlinkFence", "none")
add("DoubleFenceGate", "Large Scrap Metal Gate", "metal", 850, "MetalWelding", 400, 275, "MetalPipe", "MetalScrap", nil, "Metal_Light", "MetalGate", "ZombieThumpChainlinkFence", "none")
add("LargeWroughtIronGate", "Large Wrought Iron Gate", "metal", 1200, "MetalWelding", 500, 375, "MetalBars", "MetalPipe", nil, "Metal_Solid", "MetalPoleGateDouble", "ZombieThumpMetalPoleGate", "none")
add("BlackTwoPaneDoubleDoorLeft", "Black Two-Pane Double Door", "metal_glazed", 650, "MetalWelding", 350, 225, "MetalPlates", "MetalBars", nil, "Metal_Solid", "MetalDoor", "ZombieThumpWindow", "paired")
add("BlackTwoPaneDoubleDoorRight", "Black Two-Pane Double Door", "metal_glazed", 650, "MetalWelding", 350, 225, "MetalPlates", "MetalBars", nil, "Metal_Solid", "MetalDoor", "ZombieThumpWindow", "paired")
add("GreyMetalDoubleDoorLeft", "Grey Metal Double Door", "metal", 800, "MetalWelding", 425, 275, "MetalPlates", "MetalBars", nil, "Metal_Solid", "MetalDoor", "ZombieThumpMetal", "paired")
add("GreyMetalDoubleDoorRight", "Grey Metal Double Door", "metal", 800, "MetalWelding", 425, 275, "MetalPlates", "MetalBars", nil, "Metal_Solid", "MetalDoor", "ZombieThumpMetal", "paired")
add("YellowServiceDoubleDoorLeft", "Yellow Service Double Door", "metal_glazed", 650, "MetalWelding", 325, 225, "MetalPlates", "Wood", "Screws", "Metal_Light", "MetalDoor", "ZombieThumpMetal", "paired")
add("YellowServiceDoubleDoorRight", "Yellow Service Double Door", "metal_glazed", 650, "MetalWelding", 325, 225, "MetalPlates", "Wood", "Screws", "Metal_Light", "MetalDoor", "ZombieThumpMetal", "paired")
add("BlueChurchDoubleDoorLeft", "Blue Church Double Door", "wood", 625, "Woodwork", 450, 275, "Wood", "Nails", "Screws", "Wood_Solid", "WoodDoor", "ZombieThumpWood", "paired")
add("BlueChurchDoubleDoorRight", "Blue Church Double Door", "wood", 625, "Woodwork", 450, 275, "Wood", "Nails", "Screws", "Wood_Solid", "WoodDoor", "ZombieThumpWood", "paired")
add("BrownChurchDoubleDoorLeft", "Brown Church Double Door", "wood", 625, "Woodwork", 450, 275, "Wood", "Nails", "Screws", "Wood_Solid", "WoodDoor", "ZombieThumpWood", "paired")
add("BrownChurchDoubleDoorRight", "Brown Church Double Door", "wood", 625, "Woodwork", 450, 275, "Wood", "Nails", "Screws", "Wood_Solid", "WoodDoor", "ZombieThumpWood", "paired")
add("SmallWhiteWoodenGate", "Small White Wooden Gate", "wood", 425, "Woodwork", 225, 175, "Wood", "Nails", nil, "Wood", "WoodGateSmall", "ZombieThumpWood", "none")
add("WoodFenceGate", "Wooden Gate", "wood", 500, "Woodwork", 300, 225, "Wood", "Nails", nil, "Wood_Solid", "WoodGate", "ZombieThumpWood", "none")
add("HardenedWoodenGate", "Hardened Wooden Gate", "wood", 600, "Woodwork", 400, 275, "Wood", "Nails", "Screws", "Wood_Solid", "WoodGate", "ZombieThumpWood", "none")
add("MetalWireFenceGateSmall", "Small Chain-Link Gate", "metal", 450, "MetalWelding", 250, 175, "MetalPipe", "MetalWire", nil, "Metal_Light", "MetalGate", "ZombieThumpChainlinkFence", "none")
add("MetalWireFenceGate", "Chain-Link Gate", "metal", 600, "MetalWelding", 300, 225, "MetalPipe", "MetalWire", nil, "Metal_Light", "MetalGate", "ZombieThumpChainlinkFence", "none")
add("MetalPoleFenceGateSmall", "Small Scrap Metal Gate", "metal", 450, "MetalWelding", 250, 175, "MetalPipe", "MetalScrap", nil, "Metal_Light", "MetalPoleGateSmall", "ZombieThumpMetalPoleGate", "none")
add("MetalPoleFenceGate", "Scrap Metal Gate", "metal", 600, "MetalWelding", 300, 225, "MetalPipe", "MetalScrap", nil, "Metal_Light", "MetalPoleGate", "ZombieThumpMetalPoleGate", "none")
add("SmallWroughtIronGate", "Small Wrought Iron Gate", "metal", 650, "MetalWelding", 325, 250, "MetalBars", "MetalPipe", nil, "Metal_Solid", "MetalPoleGateSmall", "ZombieThumpMetalPoleGate", "none")
add("WroughtIronGate", "Wrought Iron Gate", "metal", 850, "MetalWelding", 400, 300, "MetalBars", "MetalPipe", nil, "Metal_Solid", "MetalPoleGate", "ZombieThumpMetalPoleGate", "none")
add("BlackRestroomStallDoor", "Black Restroom Stall Door", "wood", 150, "Woodwork", 150, 0, "Wood", "Screws", nil, "Wood", "WoodDoor", "ZombieThumpWood", "standard")
add("BlueRestroomStallDoor", "Blue Restroom Stall Door", "wood", 150, "Woodwork", 150, 0, "Wood", "Screws", nil, "Wood", "WoodDoor", "ZombieThumpWood", "standard")
add("BrownRestroomStallDoor", "Brown Restroom Stall Door", "wood", 150, "Woodwork", 150, 0, "Wood", "Screws", nil, "Wood", "WoodDoor", "ZombieThumpWood", "standard")
add("PinkRestroomStallDoor", "Pink Restroom Stall Door", "wood", 150, "Woodwork", 150, 0, "Wood", "Screws", nil, "Wood", "WoodDoor", "ZombieThumpWood", "standard")
add("WhiteRestroomStallDoor", "White Restroom Stall Door", "wood", 150, "Woodwork", 150, 0, "Wood", "Screws", nil, "Wood", "WoodDoor", "ZombieThumpWood", "standard")
add("BlueRestroomDoor", "Blue Restroom Door", "wood", 200, "Woodwork", 200, 0, "Wood", "Screws", nil, "Plastic", "MetalDoor", "ZombieThumpGeneric", "standard")
add("BrownSlidingGlassDoor", "Brown Sliding Glass Door", "glass", 250, "MetalWelding", 250, 0, "MetalPlates", "MetalBars", "Glass", "Glass_Solid", "SlidingGlassDoor", "ZombieThumpWindow", "none")
add("WhiteSlidingGlassDoor", "White Sliding Glass Door", "glass", 250, "MetalWelding", 250, 0, "MetalPlates", "MetalBars", "Glass", "Glass_Solid", "SlidingGlassDoor", "ZombieThumpWindow", "none")
add("WoodenDoorLvl1", "Basic Wooden Door", "wood", 400, "Woodwork", 250, 150, "Wood", "Nails", nil, "Wood_Solid", "WoodDoor", "ZombieThumpWood", "standard")
add("RoughWoodenDoor", "Rough Wooden Door", "wood", 400, "Woodwork", 250, 150, "Wood", "Nails", nil, "Wood_Solid", "WoodDoor", "ZombieThumpWood", "standard")
add("WoodenDoorLvl2", "Sturdy Wooden Door", "wood", 500, "Woodwork", 300, 200, "Wood", "Nails", nil, "Wood_Solid", "WoodDoor", "ZombieThumpWood", "standard")
add("RusticWoodenDoor", "Rustic Wooden Door", "wood", 500, "Woodwork", 300, 200, "Wood", "Nails", nil, "Wood_Solid", "WoodDoor", "ZombieThumpWood", "standard")
add("WoodenDoorLvl3", "Artisan Wooden Door", "wood", 600, "Woodwork", 350, 250, "Wood", "Nails", nil, "Wood_Solid", "WoodDoor", "ZombieThumpWood", "standard")
add("OuthouseDoor", "Outhouse Door", "wood", 250, "Woodwork", 250, 0, "Wood", "Nails", nil, "Wood", "WoodDoor", "ZombieThumpWood", "standard")
add("WhitePanelDoor", "White Panel Door", "wood", 625, "Woodwork", 450, 275, "Wood", "Nails", "Screws", "Wood_Solid", "WoodDoor", "ZombieThumpWood", "standard")
add("BrownPanelDoor", "Brown Panel Door", "wood", 625, "Woodwork", 450, 275, "Wood", "Nails", "Screws", "Wood_Solid", "WoodDoor", "ZombieThumpWood", "standard")
add("MahoganyPanelDoor", "Mahogany Panel Door", "wood", 625, "Woodwork", 450, 275, "Wood", "Nails", "Screws", "Wood_Solid", "WoodDoor", "ZombieThumpWood", "standard")
add("BluePanelDoor", "Blue Panel Door", "wood", 625, "Woodwork", 450, 275, "Wood", "Nails", "Screws", "Wood_Solid", "WoodDoor", "ZombieThumpWood", "standard")
add("WhiteDoorWithWindows", "White Door with Windows", "wood_glazed", 550, "Woodwork", 400, 250, "Wood", "Nails", "Screws", "Wood_Solid", "WoodDoor", "ZombieThumpWood", "standard")
add("BrownDoorWithWindows", "Brown Door with Windows", "wood_glazed", 550, "Woodwork", 400, 250, "Wood", "Nails", "Screws", "Wood_Solid", "WoodDoor", "ZombieThumpWood", "standard")
add("BlueDoorWithWindow", "Blue Door with Window", "wood_glazed", 575, "Woodwork", 425, 250, "Wood", "Nails", "Screws", "Wood_Solid", "MetalDoor", "ZombieThumpWood", "standard")
add("RedTwoPaneDoor", "Red Two-Pane Door", "wood_glazed", 500, "Woodwork", 350, 225, "Wood", "Nails", "Screws", "Wood_Solid", "MetalDoor", "ZombieThumpWindow", "standard")
add("BlueTwoPaneDoor", "Blue Two-Pane Door", "wood_glazed", 500, "Woodwork", 350, 225, "Wood", "Nails", "Screws", "Wood_Solid", "MetalDoor", "ZombieThumpWindow", "standard")
add("GreenStripedTwoPaneDoor", "Green-Striped Two-Pane Door", "wood_glazed", 500, "Woodwork", 350, 225, "Wood", "Nails", "Screws", "Wood_Solid", "MetalDoor", "ZombieThumpWindow", "standard")
add("BrownTwoPaneDoor", "Brown Two-Pane Door", "wood_glazed", 500, "Woodwork", 350, 225, "Wood", "Nails", "Screws", "Wood_Solid", "MetalDoor", "ZombieThumpWindow", "standard")
add("DarkBrownTwoPaneDoor", "Dark Brown Two-Pane Door", "wood_glazed", 500, "Woodwork", 350, 225, "Wood", "Nails", "Screws", "Wood_Solid", "MetalDoor", "ZombieThumpWindow", "standard")
add("BlackFullGlassDoor", "Black Full-Glass Door", "wood_glazed", 425, "Woodwork", 300, 175, "Wood", "Nails", "Screws", "Glass_Solid", "MetalDoor", "ZombieThumpWindow", "standard")
add("BrownFullGlassDoor", "Brown Full-Glass Door", "wood_glazed", 425, "Woodwork", 300, 175, "Wood", "Nails", "Screws", "Glass_Solid", "MetalDoor", "ZombieThumpWindow", "standard")
add("MetalDoorLvl1", "Basic Metal Door", "metal", 650, "MetalWelding", 350, 250, "MetalPlates", "MetalScrap", nil, "Metal_Light", "MetalDoor", "ZombieThumpMetal", "standard")
add("MetalDoorLvl2", "Simple Metal Door", "metal", 750, "MetalWelding", 400, 275, "MetalPlates", nil, nil, "Metal_Light", "MetalDoor", "ZombieThumpMetal", "standard")
add("WhiteMetalDoor", "White Metal Door", "metal", 800, "MetalWelding", 425, 275, "MetalPlates", "MetalBars", nil, "Metal_Solid", "MetalDoor", "ZombieThumpMetal", "standard")
add("TanMetalDoor", "Tan Metal Door", "metal", 800, "MetalWelding", 425, 275, "MetalPlates", "MetalBars", nil, "Metal_Solid", "MetalDoor", "ZombieThumpMetal", "standard")
add("BlackMetalDoorWithWindow", "Black Metal Door with Window", "metal_glazed", 700, "MetalWelding", 375, 225, "MetalPlates", "MetalBars", nil, "Metal_Solid", "MetalDoor", "ZombieThumpMetal", "standard")
add("TanMetalDoorWithWindow", "Tan Metal Door with Window", "metal_glazed", 700, "MetalWelding", 375, 225, "MetalPlates", "MetalBars", nil, "Metal_Solid", "MetalDoor", "ZombieThumpMetal", "standard")
add("BlackTwoPaneMetalDoor", "Black Two-Pane Metal Door", "metal_glazed", 650, "MetalWelding", 350, 225, "MetalPlates", "MetalBars", nil, "Metal_Solid", "MetalDoor", "ZombieThumpWindow", "standard")
add("BlueServiceDoor", "Blue Service Door", "metal", 700, "MetalWelding", 375, 250, "MetalPlates", "Wood", "Screws", "Metal_Light", "MetalDoor", "ZombieThumpMetal", "standard")
add("OrangeServiceDoor", "Orange Service Door", "metal", 700, "MetalWelding", 375, 250, "MetalPlates", "Wood", "Screws", "Metal_Light", "MetalDoor", "ZombieThumpMetal", "standard")
add("LightRedServiceDoor", "Light Red Service Door", "metal", 700, "MetalWelding", 375, 250, "MetalPlates", "Wood", "Screws", "Metal_Light", "MetalDoor", "ZombieThumpMetal", "standard")
add("BlackServiceDoor", "Black Service Door", "metal", 700, "MetalWelding", 375, 250, "MetalPlates", "Wood", "Screws", "Metal_Light", "MetalDoor", "ZombieThumpMetal", "standard")
add("GreenServiceDoor", "Green Service Door", "metal", 700, "MetalWelding", 375, 250, "MetalPlates", "Wood", "Screws", "Metal_Light", "MetalDoor", "ZombieThumpMetal", "standard")
add("RedServiceDoor", "Red Service Door", "metal", 700, "MetalWelding", 375, 250, "MetalPlates", "Wood", "Screws", "Metal_Light", "MetalDoor", "ZombieThumpMetal", "standard")
add("WhiteServiceDoorWithPorthole", "White Service Door with Porthole", "metal_glazed", 650, "MetalWelding", 325, 225, "MetalPlates", "Wood", "Screws", "Metal_Light", "MetalDoor", "ZombieThumpMetal", "standard")
add("LogDoor", "Log Door", "heavy_wood", 700, "Woodwork", 700, 0, "Log", nil, nil, "Wood_Solid", "WoodDoor", "ZombieThumpWood", "standard")
add("JailDoor", "Jail Door", "jail", 2000, "MetalWelding", 1000, 500, "MetalBars", "MetalPlates", "Screws", "Metal_Solid", "PrisonMetalDoor", "ZombieThumpMetal", "standard")
add("SecurityDoor", "Security Door", "security", 3000, "MetalWelding", 1250, 650, "MetalBars", "MetalPlates", "MetalWire", "Metal_Solid", "MetalDoor", "ZombieThumpMetal", "standard")

return Profiles
