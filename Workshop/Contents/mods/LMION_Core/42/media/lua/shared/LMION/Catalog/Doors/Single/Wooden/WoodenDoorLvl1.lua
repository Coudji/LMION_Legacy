return {
    definitionId = "Doors.Wood.WoodenDoorLvl1",
    entity = "Base.WoodenDoorLvl1",
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
        packages = { count = 1, weight = 15 },
    },

    geometry = {
        N = {
            closed = "carpentry_01_49",
            open = "carpentry_01_51",
        },
        W = {
            closed = "carpentry_01_48",
            open = "carpentry_01_50",
        },
    },
}
