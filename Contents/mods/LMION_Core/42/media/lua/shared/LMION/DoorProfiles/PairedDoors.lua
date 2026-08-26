return function(add)
    --[[
    Paired doors share vanilla synchronized behavior, but each physical 1x1 leaf
    remains an independent gameplay unit. Future Pickup support must not require
    transporting both leaves together.
    ]]
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
end
