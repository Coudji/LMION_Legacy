return {
    definitionId = "Doors.Metal.MetalDoorLvl1",
    entity = "Base.MetalDoorLvl1",

    frame = "standard",
    materialType = "Metal_Light",
    doorSound = "MetalDoor",
    thumpSound = "ZombieThumpMetal",

    engineMaterials = { "MetalPlates", "MetalScrap" },

    durability = {
        worldHealth = 650,
        health = 350,
        skillBaseHealth = 250,
    },

    construction = {
        skill = { MetalWelding = 3 },
        time = 120,
        xp = 20,
        tools = { { tag = "base:weldingmask" } },
        materials = {
            { item = "Base.BlowTorch", uses = 4 },
            { item = "Base.SmallSheetMetal", amount = 3 },
            { item = "Base.Hinge", amount = 2 },
            { item = "Base.WeldingRods", uses = 4 },
            { item = "Base.Doorknob", amount = 1 },
        },
    },

    pickup = {
        skill = { MetalWelding = 1 },
        tools = { { tag = "base:screwdriver" } },
        breakChance = 0,
        packages = { count = 1, weight = 20 },
    },

    replacement = {
        packages = 1,
        tools = { { tag = "base:screwdriver" } },
        materials = {},
    },

    geometry = {
        N = {
            closed = "fixtures_doors_01_69",
            open = "fixtures_doors_01_71",
        },
        W = {
            closed = "fixtures_doors_01_68",
            open = "fixtures_doors_01_70",
        },
    },
}
