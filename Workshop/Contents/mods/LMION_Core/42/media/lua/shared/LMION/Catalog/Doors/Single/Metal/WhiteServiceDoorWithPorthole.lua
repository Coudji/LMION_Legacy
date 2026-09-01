return {
    definitionId = "Doors.Metal.WhiteServiceDoorWithPorthole",
    entity = "Base.WhiteServiceDoorWithPorthole",
    inherits = "Doors.Metal.Service",

    durability = {
        worldHealth = 650,
        health = 325,
        skillBaseHealth = 225,
    },

    construction = {
        materials = {
            { item = "Base.SheetMetal", amount = 1 },
            { item = "Base.SmallSheetMetal", amount = 1 },
            { item = "Base.Plank", amount = 2 },
            { item = "Base.Screws", amount = 6 },
            { item = "Base.Hinge", amount = 2 },
            { item = "Base.GlassPanel", amount = 1 },
        },
    },

    pickup = {
        packages = { count = 1, weight = 17 },
    },

    geometry = {
        N = {
            closed = "fixtures_doors_01_61",
            open = "fixtures_doors_01_63",
        },
        W = {
            closed = "fixtures_doors_01_60",
            open = "fixtures_doors_01_62",
        },
    },
}
