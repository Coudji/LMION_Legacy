return {
    defaultId = "FenceGates.Wood.Hard",

    defaults = {
        frame = false,
        materialType = "Wood_Solid",
        doorSound = "WoodGate",
        thumpSound = "ZombieThumpWood",

        engineMaterials = { "Wood", "Nails", "Screws" },

        durability = { worldHealth = 600, health = 400, skillBaseHealth = 275 },

        construction = {
            skill = { Woodwork = 5 }, time = 150, xp = 30,
            tools = { { tag = "base:hammer" }, { tag = "base:screwdriver" } },
            materials = {
                { item = "Base.Plank", amount = 5 },
                { item = "Base.Nails", amount = 5 },
                { item = "Base.Screws", amount = 4 },
                { item = "Base.Hinge", amount = 2 },
                { item = "Base.Doorknob", amount = 1 },
            },
        },

        pickup = {
            skill = { Woodwork = 2 },
            tools = { { tag = "base:crowbar" } },
            breakChance = 0,
            packages = { count = 1, weight = 18 },
        },

        replacement = {
            packages = 1,
            tools = { { tag = "base:hammer" } },
            materials = {},
        },
    },
}
