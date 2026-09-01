return {
    definitionId = "GarageDoors.GreyGarageDoor",
    displayName = "Grey Garage Door",
    entity = "Base.GreyGarageDoor",
    inherits = "GarageDoors.Solid",

    geometry = {
        N = {
            START = { closed = "walls_garage_01_51", open = "walls_garage_01_59" },
            MIDDLE = { closed = "walls_garage_01_52", open = "walls_garage_01_60" },
            END = { closed = "walls_garage_01_53", open = "walls_garage_01_61" },
        },
        W = {
            START = { closed = "walls_garage_01_48", open = "walls_garage_01_56" },
            MIDDLE = { closed = "walls_garage_01_49", open = "walls_garage_01_57" },
            END = { closed = "walls_garage_01_50", open = "walls_garage_01_58" },
        },
    },
}
