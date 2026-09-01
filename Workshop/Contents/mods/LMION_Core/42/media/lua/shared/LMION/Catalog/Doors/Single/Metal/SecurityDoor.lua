return {
    definitionId = "Doors.Metal.SecurityDoor",
    entity = "Base.SecurityDoor",

    frame = "standard",
    materialType = "Metal_Solid",
    doorSound = "MetalDoor",
    thumpSound = "ZombieThumpMetal",

    engineMaterials = { "MetalBars", "MetalPlates", "MetalWire" },

    durability = {
        worldHealth = 3000,
        health = 1250,
        skillBaseHealth = 650,
    },

    construction = {
        skill = { MetalWelding = 10 },
        time = 400,
        xp = 100,
        tools = {
            { tag = "base:weldingmask" },
            { tag = "base:screwdriver" },
        },
        materials = {
            { item = "Base.BlowTorch", uses = 12 },
            { item = "Base.SteelBar", amount = 6 },
            { item = "Base.SheetMetal", amount = 2 },
            { item = "Base.GlassPanel", amount = 2 },
            { item = "Base.Wire", amount = 4 },
            { item = "Base.Hinge", amount = 4 },
            { item = "Base.Screws", amount = 8 },
            { item = "Base.Doorknob", amount = 1 },
            { item = "Base.ElectronicsScrap", amount = 2 },
            { item = "Base.ElectricWire", amount = 2 },
            { item = "Base.WeldingRods", uses = 10 },
        },
    },

    pickup = {
        skill = { MetalWelding = 5 },
        tools = { { tag = "base:screwdriver" } },
        breakChance = 0,
        packages = { count = 1, weight = 35 },
    },

    replacement = {
        packages = 1,
        tools = { { tag = "base:screwdriver" } },
        materials = {},
    },

    geometry = {
        N = {
            closed = "fixtures_doors_01_33",
            open = "fixtures_doors_01_35",
        },
        W = {
            closed = "fixtures_doors_01_32",
            open = "fixtures_doors_01_34",
        },
    },
}
