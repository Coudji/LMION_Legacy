return function(add)
    --[[
    These entities are grouped as paired doors because they form visual/construction
    double-door sets, not because their open state is synchronized. Each physical
    1x1 leaf is independent in vanilla gameplay: opening one does not open the other.
    Pickup therefore transports and replaces each leaf separately through the normal
    framed 1x1 door path.

    B42 runtime frame markers are structural:
    Left -> DoubleDoor1, Right -> DoubleDoor2.
    ]]
    add("BlackTwoPaneDoubleDoorLeft", "Black Two-Pane Double Door", "metal_glazed", 650, "MetalWelding", 350, 225, "MetalPlates", "MetalBars", nil, "Metal_Solid", "MetalDoor", "ZombieThumpWindow", "paired", 1)
    add("BlackTwoPaneDoubleDoorRight", "Black Two-Pane Double Door", "metal_glazed", 650, "MetalWelding", 350, 225, "MetalPlates", "MetalBars", nil, "Metal_Solid", "MetalDoor", "ZombieThumpWindow", "paired", 2)
    add("GreyMetalDoubleDoorLeft", "Grey Metal Double Door", "metal", 800, "MetalWelding", 425, 275, "MetalPlates", "MetalBars", nil, "Metal_Solid", "MetalDoor", "ZombieThumpMetal", "paired", 1)
    add("GreyMetalDoubleDoorRight", "Grey Metal Double Door", "metal", 800, "MetalWelding", 425, 275, "MetalPlates", "MetalBars", nil, "Metal_Solid", "MetalDoor", "ZombieThumpMetal", "paired", 2)
    add("YellowServiceDoubleDoorLeft", "Yellow Service Double Door", "metal_glazed", 650, "MetalWelding", 325, 225, "MetalPlates", "Wood", "Screws", "Metal_Light", "MetalDoor", "ZombieThumpMetal", "paired", 1)
    add("YellowServiceDoubleDoorRight", "Yellow Service Double Door", "metal_glazed", 650, "MetalWelding", 325, 225, "MetalPlates", "Wood", "Screws", "Metal_Light", "MetalDoor", "ZombieThumpMetal", "paired", 2)
    add("BlueChurchDoubleDoorLeft", "Blue Church Double Door", "wood", 625, "Woodwork", 450, 275, "Wood", "Nails", "Screws", "Wood_Solid", "WoodDoor", "ZombieThumpWood", "paired", 1)
    add("BlueChurchDoubleDoorRight", "Blue Church Double Door", "wood", 625, "Woodwork", 450, 275, "Wood", "Nails", "Screws", "Wood_Solid", "WoodDoor", "ZombieThumpWood", "paired", 2)
    add("BrownChurchDoubleDoorLeft", "Brown Church Double Door", "wood", 625, "Woodwork", 450, 275, "Wood", "Nails", "Screws", "Wood_Solid", "WoodDoor", "ZombieThumpWood", "paired", 1)
    add("BrownChurchDoubleDoorRight", "Brown Church Double Door", "wood", 625, "Woodwork", 450, 275, "Wood", "Nails", "Screws", "Wood_Solid", "WoodDoor", "ZombieThumpWood", "paired", 2)
end
