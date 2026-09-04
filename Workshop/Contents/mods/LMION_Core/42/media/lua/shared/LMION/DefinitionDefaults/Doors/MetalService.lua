return {
    defaultId = "Doors.Metal.Service",

    defaults = {
        doorType = "Simple",
        frame = "standard",
        materialType = "Metal_Light",
        doorSound = "MetalDoor",
        thumpSound = "ZombieThumpMetal",

        engineMaterials = { "MetalPlates", "Wood", "Screws" },

        durability = {
            worldHealth = 700,
            health = 375,
            skillBaseHealth = 250,
        },

        construction = {
            skill = { MetalWelding = 3 },
            time = 120,
            xp = 15,
            tools = { { tag = "base:screwdriver" } },

            materials = {
                { item = "Base.SheetMetal", amount = 1 },
                { item = "Base.SmallSheetMetal", amount = 1 },
                { item = "Base.Plank", amount = 2 },
                { item = "Base.Screws", amount = 6 },
                { item = "Base.Hinge", amount = 2 },
            },
        },

        pickup = {
            skill = { MetalWelding = 1 },
            tools = { { tag = "base:screwdriver" } },
            breakChance = 0,
            packages = { count = 1, weight = 18 },
        },

        replacement = {
            packages = 1,
            tools = { { tag = "base:screwdriver" } },
            materials = {},
        },
    },
}
