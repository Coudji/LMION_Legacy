return {
    definitionId = "GarageDoors.GreenGarageDoor",
    displayName = "Green Garage Door",
    entity = "Base.GreenGarageDoor",
    inherits = "GarageDoors.Solid",

    geometry = {
        N = {
            START = { closed = "walls_garage_01_19", open = "walls_garage_01_27" },
            MIDDLE = { closed = "walls_garage_01_20", open = "walls_garage_01_28" },
            END = { closed = "walls_garage_01_21", open = "walls_garage_01_29" },
        },
        W = {
            START = { closed = "walls_garage_01_16", open = "walls_garage_01_24" },
            MIDDLE = { closed = "walls_garage_01_17", open = "walls_garage_01_25" },
            END = { closed = "walls_garage_01_18", open = "walls_garage_01_26" },
        },
    },
}
