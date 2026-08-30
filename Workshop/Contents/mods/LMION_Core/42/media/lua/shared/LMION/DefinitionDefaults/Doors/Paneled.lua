return {
    id = "Doors.Wooden.Paneled",
    defaults = {
        class = "wood", frame = "standard", materialType = "Wood_Solid", doorSound = "WoodDoor", thumpSound = "ZombieThumpWood",
        engineMaterials = { "Wood", "Nails", "Screws" },
        durability = { worldHealth = 625, health = 450, skillBaseHealth = 275 },
        construction = { skill = { Woodwork = 6 }, time = 150, xp = 35, tools = { "Base.Hammer", "Base.Screwdriver" }, materials = { { item = "Base.Plank", amount = 4 }, { item = "Base.Nails", amount = 4 }, { item = "Base.Hinge", amount = 2 }, { item = "Base.Screws", amount = 4 }, { item = "Base.Doorknob", amount = 1 } } },
        pickup = { skill = { Woodwork = 3 }, tools = { "Base.Hammer", "Base.Screwdriver" }, breakChance = 0, packages = { count = 1, weight = 17 } },
        replacement = { packages = 1, tools = { "Base.Hammer", "Base.Screwdriver" }, materials = {} },
    },
}
