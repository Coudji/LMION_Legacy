return function(add)
    --[[
    These entities are grouped as paired doors because they form visual/construction
    double-door sets, not because their open state is synchronized. Each physical
    1x1 leaf is independent in vanilla gameplay: opening one does not open the other.
    Future Pickup support should therefore transport and replace each leaf separately.
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
