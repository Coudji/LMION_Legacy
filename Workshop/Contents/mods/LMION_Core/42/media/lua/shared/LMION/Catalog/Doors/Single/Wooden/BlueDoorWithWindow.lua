return {
    definitionId = "Doors.Wood.BlueDoorWithWindow",
    entity = "Base.BlueDoorWithWindow",
    inherits = "Doors.Wood.OneGlass",

    doorSound = "MetalDoor",

    durability = {
        worldHealth = 575,
        health = 425,
        skillBaseHealth = 250,
    },

    construction = {
        skill = { Woodwork = 7 },
        time = 180,
        xp = 45,
    },

    pickup = {
        packages = { count = 1, weight = 17 },
    },

    geometry = {
        N = {
            closed = "location_restaurant_pileocrepe_01_49",
            open = "location_restaurant_pileocrepe_01_51",
        },
        W = {
            closed = "location_restaurant_pileocrepe_01_48",
            open = "location_restaurant_pileocrepe_01_50",
        },
    },
}
