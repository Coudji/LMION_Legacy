return {
    definitionId = "GarageDoors.WhiteGarageDoor",
    displayName = "White Garage Door",
    entity = "Base.WhiteGarageDoor",
    inherits = "GarageDoors.Solid",

    geometry = {
        N = {
            START = { closed = "walls_garage_01_3", open = "walls_garage_01_11" },
            MIDDLE = { closed = "walls_garage_01_4", open = "walls_garage_01_12" },
            END = { closed = "walls_garage_01_5", open = "walls_garage_01_13" },
        },
        W = {
            START = { closed = "walls_garage_01_0", open = "walls_garage_01_8" },
            MIDDLE = { closed = "walls_garage_01_1", open = "walls_garage_01_9" },
            END = { closed = "walls_garage_01_2", open = "walls_garage_01_10" },
        },
    },
}
