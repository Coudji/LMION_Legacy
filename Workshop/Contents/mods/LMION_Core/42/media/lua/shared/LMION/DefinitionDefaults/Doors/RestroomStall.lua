return {
    id = "Doors.Wooden.RestroomStall",
    defaults = {
        class = "wood", frame = "standard", materialType = "Wood", doorSound = "WoodDoor", thumpSound = "ZombieThumpWood",
        engineMaterials = { "Wood", "Screws" },
        durability = { worldHealth = 150, health = 150, skillBaseHealth = 0 },
        construction = { skill = { Woodwork = 1 }, time = 50, xp = 5, tools = { "Base.Screwdriver" }, materials = { { item = "Base.Plank", amount = 2 }, { item = "Base.Screws", amount = 4 }, { item = "Base.Hinge", amount = 2 } } },
        pickup = { skill = { Woodwork = 0 }, tools = { "Base.Screwdriver" }, breakChance = 0, packages = { count = 1, weight = 8 } },
        replacement = { packages = 1, tools = { "Base.Screwdriver" }, materials = {} },
    },
}
