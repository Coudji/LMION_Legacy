return {
    definitionId = "Doors.Metal.JailDoor",
    entity = "Base.JailDoor",

    frame = "standard",
    materialType = "Metal_Solid",
    doorSound = "PrisonMetalDoor",
    thumpSound = "ZombieThumpMetal",

    engineMaterials = { "MetalBars", "MetalPlates", "Screws" },

    durability = {
        worldHealth = 2000,
        health = 1000,
        skillBaseHealth = 500,
    },

    construction = {
        skill = { MetalWelding = 10 },
        time = 300,
        xp = 75,
        tools = {
            { tag = "base:weldingmask" },
            { tag = "base:screwdriver" },
        },
        materials = {
            { item = "Base.BlowTorch", uses = 10 },
            { item = "Base.SteelBar", amount = 7 },
            { item = "Base.SmallSheetMetal", amount = 2 },
            { item = "Base.Hinge", amount = 4 },
            { item = "Base.Screws", amount = 8 },
            { item = "Base.Doorknob", amount = 1 },
            { item = "Base.WeldingRods", uses = 8 },
        },
    },

    pickup = {
        skill = { MetalWelding = 5 },
        tools = { { tag = "base:screwdriver" } },
        breakChance = 0,
        packages = { count = 1, weight = 30 },
    },

    replacement = {
        packages = 1,
        tools = { { tag = "base:screwdriver" } },
        materials = {},
    },

    geometry = {
        N = {
            closed = "location_community_police_01_5",
            open = "location_community_police_01_7",
        },
        W = {
            closed = "location_community_police_01_4",
            open = "location_community_police_01_6",
        },
    },
}
