return {
    id = "FenceGates.Wooden.HardenedWooden",
    defaults = {
        class = "wood", frame = false, materialType = "Wood_Solid", doorSound = "WoodGate", thumpSound = "ZombieThumpWood",
        engineMaterials = { "Wood", "Nails", "Screws" },
        durability = { worldHealth = 600, health = 400, skillBaseHealth = 275 },
        construction = { skill = { Woodwork = 5 }, time = 150, xp = 30, tools = { "Base.Hammer", "Base.Screwdriver" }, materials = { { item = "Base.Plank", amount = 5 }, { item = "Base.Nails", amount = 5 }, { item = "Base.Screws", amount = 4 }, { item = "Base.Hinge", amount = 2 }, { item = "Base.Doorknob", amount = 1 } } },
        pickup = { skill = { Woodwork = 2 }, tools = { "Base.Hammer", "Base.Screwdriver" }, breakChance = 0, packages = { count = 1, weight = 18 } },
        replacement = { packages = 1, tools = { "Base.Hammer", "Base.Screwdriver" }, materials = {} },
    },
}
