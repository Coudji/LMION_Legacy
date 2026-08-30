return {
    id = "FenceGates.Wooden.SmallWooden",
    defaults = {
        class = "wood", frame = false, materialType = "Wood", doorSound = "WoodGateSmall", thumpSound = "ZombieThumpWood",
        engineMaterials = { "Wood", "Nails" },
        durability = { worldHealth = 425, health = 225, skillBaseHealth = 175 },
        construction = { skill = { Woodwork = 2 }, time = 60, xp = 10, tools = { "Base.Hammer" }, materials = { { item = "Base.Plank", amount = 2 }, { item = "Base.Nails", amount = 2 }, { item = "Base.Hinge", amount = 2 } } },
        pickup = { skill = { Woodwork = 1 }, tools = { "Base.Hammer" }, breakChance = 0, packages = { count = 1, weight = 7 } },
        replacement = { packages = 1, tools = { "Base.Hammer" }, materials = {} },
    },
}
