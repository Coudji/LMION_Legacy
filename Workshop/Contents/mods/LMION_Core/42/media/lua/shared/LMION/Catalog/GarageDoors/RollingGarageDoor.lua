return {
    definitionId = "GarageDoors.RollingGarageDoor",
    displayName = "Rolling Garage Door",
    entity = "Base.RollingGarageDoor",
    inherits = "GarageDoors.Solid",

    geometry = {
        N = {
            START = { closed = "walls_garage_02_3", open = "walls_garage_02_11" },
            MIDDLE = { closed = "walls_garage_02_4", open = "walls_garage_02_12" },
            END = { closed = "walls_garage_02_5", open = "walls_garage_02_13" },
        },
        W = {
            START = { closed = "walls_garage_02_0", open = "walls_garage_02_8" },
            MIDDLE = { closed = "walls_garage_02_1", open = "walls_garage_02_9" },
            END = { closed = "walls_garage_02_2", open = "walls_garage_02_10" },
        },
    },
}
