return {
    id = "Doors.Wooden.Log",
    defaults = {
        class = "heavy_wood", frame = "standard", materialType = "Wood_Solid", doorSound = "WoodDoor", thumpSound = "ZombieThumpWood",
        engineMaterials = { "Log" },
        durability = { worldHealth = 700, health = 700, skillBaseHealth = 0 },
        construction = { skill = { Woodwork = 0 }, time = 80, xp = 5, tools = {}, materials = { { item = "Base.Log", amount = 4 }, { item = "Base.RippedSheets", amount = 4 } } },
        pickup = { skill = { Woodwork = 0 }, tools = {}, breakChance = 0, packages = { count = 1, weight = 25 } },
        replacement = { packages = 1, tools = {}, materials = {} },
    },
}
