return {
    definitionId = "Doors.Wood.WoodenDoorLvl3",
    entity = "Base.WoodenDoorLvl3",
    inherits = "Doors.Wood.Base",

    durability = {
        worldHealth = 600,
        health = 350,
        skillBaseHealth = 250,
    },

    construction = {
        skill = { Woodwork = 7 },
        time = 160,
        xp = 40,
    },

    pickup = {
        skill = { Woodwork = 3 },
        packages = { count = 1, weight = 15 },
    },

    geometry = {
        N = {
            closed = "carpentry_01_57",
            open = "carpentry_01_59",
        },
        W = {
            closed = "carpentry_01_56",
            open = "carpentry_01_58",
        },
    },
}
