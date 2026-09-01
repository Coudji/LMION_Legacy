return {
    definitionId = "Doors.Wood.RoughWoodenDoor",
    entity = "Base.RoughWoodenDoor",
    inherits = "Doors.Wood.Base",

    durability = {
        worldHealth = 400,
        health = 250,
        skillBaseHealth = 150,
    },

    construction = {
        skill = { Woodwork = 3 },
        time = 90,
        xp = 15,
    },

    pickup = {
        skill = { Woodwork = 1 },
        packages = { count = 1, weight = 14 },
    },

    geometry = {
        N = {
            closed = "fixtures_doors_01_29",
            open = "fixtures_doors_01_31",
        },
        W = {
            closed = "fixtures_doors_01_28",
            open = "fixtures_doors_01_30",
        },
    },
}
