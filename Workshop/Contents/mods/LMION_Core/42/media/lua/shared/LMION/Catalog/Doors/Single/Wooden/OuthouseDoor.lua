return {
    definitionId = "Doors.Wood.OuthouseDoor",
    entity = "Base.OuthouseDoor",
    inherits = "Doors.Wood.Base",

    materialType = "Wood",

    durability = {
        worldHealth = 250,
        health = 250,
        skillBaseHealth = 0,
    },

    construction = {
        skill = { Woodwork = 1 },
        time = 50,
        xp = 5,
        materials = {
            { item = "Base.Plank", amount = 3 },
            { item = "Base.Nails", amount = 4 },
            { item = "Base.Hinge", amount = 2 },
            { item = "Base.Doorknob", amount = 1 },
        },
    },

    pickup = {
        skill = { Woodwork = 0 },
        packages = { count = 1, weight = 10 },
    },

    geometry = {
        N = {
            closed = "fixtures_bathroom_02_33",
            open = "fixtures_bathroom_02_35",
        },
        W = {
            closed = "fixtures_bathroom_02_32",
            open = "fixtures_bathroom_02_34",
        },
    },
}
