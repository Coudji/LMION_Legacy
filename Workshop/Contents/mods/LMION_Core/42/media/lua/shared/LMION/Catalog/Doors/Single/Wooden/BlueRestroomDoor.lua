return {
    definitionId = "Doors.Wood.BlueRestroomDoor",
    entity = "Base.BlueRestroomDoor",
    inherits = "Doors.Wood.Restroom",

    materialType = "Plastic",
    doorSound = "MetalDoor",
    thumpSound = "ZombieThumpGeneric",

    durability = {
        worldHealth = 200,
        health = 200,
        skillBaseHealth = 0,
    },

    pickup = {
        packages = { count = 1, weight = 10 },
    },

    geometry = {
        N = {
            closed = "fixtures_bathroom_02_17",
            open = "fixtures_bathroom_02_19",
        },
        W = {
            closed = "fixtures_bathroom_02_16",
            open = "fixtures_bathroom_02_18",
        },
    },
}
