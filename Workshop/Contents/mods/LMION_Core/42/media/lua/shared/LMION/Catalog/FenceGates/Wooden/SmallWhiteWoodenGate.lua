return {
    definitionId = "FenceGates.Wood.SmallWhiteWoodenGate",
    entity = "Base.SmallWhiteWoodenGate",

    frame = "none",
    materialType = "Wood",
    doorSound = "WoodGateSmall",
    thumpSound = "ZombieThumpWood",

    engineMaterials = { "Wood", "Nails" },

    durability = {
        worldHealth = 425,
        health = 225,
        skillBaseHealth = 175,
    },

    construction = {
        skill = { Woodwork = 2 },
        time = 60,
        xp = 10,
        tools = { { tag = "base:hammer" } },
        materials = {
            { item = "Base.Plank", amount = 2 },
            { item = "Base.Nails", amount = 2 },
            { item = "Base.Hinge", amount = 2 },
        },
    },

    pickup = {
        skill = { Woodwork = 1 },
        tools = { { tag = "base:crowbar" } },
        breakChance = 0,
        packages = { count = 1, weight = 7 },
    },

    replacement = {
        packages = 1,
        tools = { { tag = "base:hammer" } },
        materials = {},
    },

    geometry = {
        N = {
            closed = "fixtures_doors_fences_01_9",
            open = "fixtures_doors_fences_01_11",
        },
        W = {
            closed = "fixtures_doors_fences_01_8",
            open = "fixtures_doors_fences_01_10",
        },
    },
}
