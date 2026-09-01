return {
    definitionId = "Doors.Wood.LogDoor",
    entity = "Base.LogDoor",

    frame = "standard",
    materialType = "Wood_Solid",
    doorSound = "WoodDoor",
    thumpSound = "ZombieThumpWood",

    engineMaterials = { "Log" },

    durability = {
        worldHealth = 700,
        health = 700,
        skillBaseHealth = 0,
    },

    construction = {
        time = 80,
        xp = 5,
        tools = {},
        materials = {
            { item = "Base.Log", amount = 4 },
            {
                anyOf = {
                    "Base.RippedSheets",
                    "Base.RippedSheetsDirty",
                    "Base.Twine",
                    "Base.Rope",
                    "Base.SheetRope",
                },
                amount = 4,
            },
        },
    },

    pickup = {
        skill = { Woodwork = 0 },
        tools = { { tag = "base:screwdriver" } },
        breakChance = 0,
        packages = { count = 1, weight = 25 },
    },

    replacement = {
        packages = 1,
        tools = { { tag = "base:screwdriver" } },
        materials = {},
    },

    geometry = {
        N = {
            closed = "walls_logs_41",
            open = "walls_logs_43",
        },
        W = {
            closed = "walls_logs_40",
            open = "walls_logs_42",
        },
    },
}
