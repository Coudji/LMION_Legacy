return {
    id = "Doors.Wooden.RestroomFullHeight",
    defaults = {
        class = "wood", frame = "standard", materialType = "Plastic", doorSound = "MetalDoor", thumpSound = "ZombieThumpGeneric",
        engineMaterials = { "Wood", "Screws" },
        durability = { worldHealth = 200, health = 200, skillBaseHealth = 0 },
        construction = { skill = { Woodwork = 1 }, time = 50, xp = 5, tools = { "Base.Screwdriver" }, materials = { { item = "Base.Plank", amount = 2 }, { item = "Base.Screws", amount = 4 }, { item = "Base.Hinge", amount = 2 } } },
        pickup = { skill = { Woodwork = 0 }, tools = { "Base.Screwdriver" }, breakChance = 0, packages = { count = 1, weight = 10 } },
        replacement = { packages = 1, tools = { "Base.Screwdriver" }, materials = {} },
    },
}
