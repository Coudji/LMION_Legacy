return {
    id = "LargeGates.Wooden.HardenedWooden",
    defaults = {
        class = "wood", frame = false, materialType = "Wood_Solid", doorSound = "WoodGate", thumpSound = "ZombieThumpWood",
        engineMaterials = { "Wood", "Nails", "Screws" },
        durability = { worldHealth = 750, health = 500, skillBaseHealth = 350 },
        construction = { skill = { Woodwork = 7 }, time = 240, xp = 60, tools = { "Base.Hammer", "Base.Screwdriver" }, materials = { { item = "Base.Plank", amount = 10 }, { item = "Base.Nails", amount = 10 }, { item = "Base.Screws", amount = 8 }, { item = "Base.Hinge", amount = 4 }, { item = "Base.Doorknob", amount = 2 } } },
        pickup = { skill = { Woodwork = 3 }, tools = { "Base.Hammer", "Base.Screwdriver" }, breakChance = 0, packages = { count = 2, weight = 22 } },
        replacement = { packages = 2, tools = { "Base.Hammer", "Base.Screwdriver" }, materials = {} },
    },
}
