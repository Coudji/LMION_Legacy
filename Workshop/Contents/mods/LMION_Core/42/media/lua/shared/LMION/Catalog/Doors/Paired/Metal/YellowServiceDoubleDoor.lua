return {
    definitionId = "Doors.Metal.YellowServiceDoubleDoor",
    inherits = "Doors.Metal.Service",
    doorType = "Paired",
    frame = "paired",

    entities = {
        left = "Base.YellowServiceDoubleDoorLeft",
        right = "Base.YellowServiceDoubleDoorRight",
    },

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
            left = {
                closed = "fixtures_doors_02_57",
                open = "fixtures_doors_02_59",
            },
            right = {
                closed = "fixtures_doors_02_61",
                open = "fixtures_doors_02_63",
            },
        },
        W = {
            left = {
                closed = "fixtures_doors_02_60",
                open = "fixtures_doors_02_62",
            },
            right = {
                closed = "fixtures_doors_02_56",
                open = "fixtures_doors_02_58",
            },
        },
    },
}
