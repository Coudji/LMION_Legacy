return {
    definitionId = "GarageDoors.RollingWindowGarageDoor",
    displayName = "Rolling Window Garage Door",
    entity = "Base.RollingWindowGarageDoor",
    inherits = "GarageDoors.Glazed",

    geometry = {
        N = {
            START = { closed = "walls_garage_02_51", open = "walls_garage_02_59" },
            MIDDLE = { closed = "walls_garage_02_52", open = "walls_garage_02_60" },
            END = { closed = "walls_garage_02_53", open = "walls_garage_02_61" },
        },
        W = {
            START = { closed = "walls_garage_02_48", open = "walls_garage_02_56" },
            MIDDLE = { closed = "walls_garage_02_49", open = "walls_garage_02_57" },
            END = { closed = "walls_garage_02_50", open = "walls_garage_02_58" },
        },
    },
}
